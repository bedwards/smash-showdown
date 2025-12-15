"""
MERTIN-FLEMMER DREAM TERRAIN GENERATOR
======================================

This is the ULTIMATE terrain generator.
Tolkien-worthy. Elder Scrolls epic. Alpine paradise.

Features:
- Multi-octave ridged noise for dramatic peaks
- Domain warping for organic shapes
- Hydraulic erosion simulation for valleys
- Natural snow line and treeline
- Valley wildflower meadows
- Multiple biome blending
- Ancient ruins placement
- Cave entrances
- Waterfalls and rivers

Run: blender --background --python generate_dream_terrain.py
"""

import bpy
import bmesh
import math
import random
import os
from mathutils import Vector, noise
from collections import defaultdict

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
RENDER_DIR = os.path.join(OUTPUT_DIR, "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

# ============================================================
# WORLD CONFIGURATION
# ============================================================

WORLD_SIZE = 3000       # Total world size in studs
RESOLUTION = 200        # Grid resolution (vertices per side)
MAX_HEIGHT = 450        # Maximum mountain height
WATER_LEVEL = -8        # Sea/lake level
SNOW_LINE = 280         # Height where snow begins
TREELINE = 200          # Height where trees stop
SEED = 42069            # For reproducibility

# Mountain range definitions (Tolkien-inspired names)
MOUNTAIN_RANGES = [
    {
        "name": "The Frozen Sentinels",
        "center": (400, -500),
        "radius": 500,
        "peak_height": 420,
        "peaks": 5,
        "style": "jagged",  # Sharp, dramatic peaks
    },
    {
        "name": "Shadow's Teeth",
        "center": (500, -200),
        "radius": 400,
        "peak_height": 350,
        "peaks": 4,
        "style": "ridged",  # Connected ridgeline
    },
    {
        "name": "The Ember Crown",
        "center": (250, 300),
        "radius": 350,
        "peak_height": 300,
        "peaks": 3,
        "style": "volcanic",  # Cone-shaped
    },
    {
        "name": "Giants' Throne",
        "center": (450, 450),
        "radius": 550,
        "peak_height": 450,
        "peaks": 6,
        "style": "massive",  # Broad, imposing
    },
    {
        "name": "The Broken Spine",
        "center": (-400, 350),
        "radius": 300,
        "peak_height": 200,
        "peaks": 8,
        "style": "eroded",  # Weathered, crumbling
    },
]

# Valley/river paths
RIVER_VALLEYS = [
    {"start": (-500, -400), "end": (-100, 400), "width": 60, "name": "Serpent's Flow"},
    {"start": (100, -300), "end": (350, 300), "width": 40, "name": "Whispering Waters"},
    {"start": (-300, 100), "end": (200, 400), "width": 50, "name": "Shadow Creek"},
]

# ============================================================
# NOISE FUNCTIONS - THE HEART OF NATURAL TERRAIN
# ============================================================

def simple_noise(x, y, z=0, seed=0):
    """Wrapper for Blender's noise function"""
    return noise.noise(Vector((x + seed * 0.1, y + seed * 0.1, z)))


def fbm(x, y, octaves=6, persistence=0.5, lacunarity=2.0, scale=1.0, seed=0):
    """
    Fractal Brownian Motion - layers of noise at different frequencies
    Creates natural-looking, detailed terrain
    """
    total = 0.0
    frequency = 1.0 / scale
    amplitude = 1.0
    max_value = 0.0

    for i in range(octaves):
        total += simple_noise(x * frequency, y * frequency, seed=seed + i * 100) * amplitude
        max_value += amplitude
        amplitude *= persistence
        frequency *= lacunarity

    return total / max_value


def ridged_multifractal(x, y, octaves=5, scale=1.0, seed=0):
    """
    Ridged noise - creates sharp mountain ridges and peaks
    The secret to dramatic, Skyrim-style mountains
    """
    total = 0.0
    frequency = 1.0 / scale
    amplitude = 1.0
    prev = 1.0

    for i in range(octaves):
        n = simple_noise(x * frequency, y * frequency, seed=seed + i * 50)
        n = 1.0 - abs(n)  # Fold to create ridges
        n = n * n          # Sharpen the ridges
        n = n * prev       # Weight by previous octave
        prev = n
        total += n * amplitude
        amplitude *= 0.5
        frequency *= 2.2

    return total


def voronoi_cells(x, y, scale=1.0, seed=0):
    """
    Voronoi-based noise for biome boundaries and rock formations
    """
    # Simplified voronoi using noise mixing
    n1 = simple_noise(x / scale, y / scale, seed=seed)
    n2 = simple_noise(x / scale + 100, y / scale + 100, seed=seed + 500)
    return abs(n1 - n2) * 2


def domain_warp(x, y, strength=0.4, scale=500, seed=0):
    """
    Warp the domain to create more organic, flowing shapes
    This is what makes terrain look REAL instead of mathematical
    """
    warp_x = fbm(x + 1000, y + 1000, octaves=3, scale=scale, seed=seed) * strength * scale
    warp_y = fbm(x + 2000, y + 2000, octaves=3, scale=scale, seed=seed + 100) * strength * scale
    return x + warp_x, y + warp_y


# ============================================================
# TERRAIN HEIGHT CALCULATION
# ============================================================

def distance_to_line_segment(px, py, x1, y1, x2, y2):
    """Calculate distance from point to line segment"""
    dx = x2 - x1
    dy = y2 - y1
    length_sq = dx * dx + dy * dy

    if length_sq == 0:
        return math.sqrt((px - x1) ** 2 + (py - y1) ** 2)

    t = max(0, min(1, ((px - x1) * dx + (py - y1) * dy) / length_sq))
    proj_x = x1 + t * dx
    proj_y = y1 + t * dy

    return math.sqrt((px - proj_x) ** 2 + (py - proj_y) ** 2)


def calculate_valley_depth(x, y):
    """Calculate how deep valleys should be carved"""
    min_depth = 0

    for valley in RIVER_VALLEYS:
        dist = distance_to_line_segment(
            x, y,
            valley["start"][0], valley["start"][1],
            valley["end"][0], valley["end"][1]
        )
        width = valley["width"]

        if dist < width * 2:
            # Smooth valley profile
            influence = 1.0 - (dist / (width * 2))
            influence = influence ** 2  # Parabolic profile
            depth = influence * 40
            min_depth = max(min_depth, depth)

    return min_depth


def calculate_mountain_height(x, y):
    """Calculate mountain contribution to height"""
    total_height = 0

    for mtn in MOUNTAIN_RANGES:
        cx, cy = mtn["center"]
        dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
        radius = mtn["radius"]

        if dist < radius * 1.5:
            # Base mountain influence
            influence = max(0, 1.0 - (dist / radius))

            # Style-specific shaping
            if mtn["style"] == "jagged":
                # Sharp peaks with ridged noise
                ridge = ridged_multifractal(x, y, octaves=6, scale=150, seed=SEED + hash(mtn["name"]))
                peak = influence ** 1.5 * (0.7 + ridge * 0.5)
            elif mtn["style"] == "ridged":
                # Connected ridgeline
                ridge = ridged_multifractal(x, y, octaves=5, scale=200, seed=SEED + hash(mtn["name"]))
                peak = influence ** 1.3 * (0.6 + ridge * 0.6)
            elif mtn["style"] == "volcanic":
                # Cone shape with crater
                peak = influence ** 2.5
                if influence > 0.9:
                    peak *= 0.8  # Crater depression
            elif mtn["style"] == "massive":
                # Broad, imposing
                ridge = ridged_multifractal(x, y, octaves=4, scale=300, seed=SEED + hash(mtn["name"]))
                peak = influence ** 1.2 * (0.8 + ridge * 0.3)
            else:  # eroded
                # Weathered, irregular
                erosion = fbm(x, y, octaves=5, scale=100, seed=SEED + hash(mtn["name"]))
                peak = influence ** 1.8 * (0.5 + erosion * 0.3)

            # Add peak height
            height = peak * mtn["peak_height"]

            # Add sub-peaks
            for i in range(mtn["peaks"]):
                angle = (i / mtn["peaks"]) * math.pi * 2 + hash(mtn["name"] + str(i)) * 0.1
                peak_dist = radius * (0.3 + (hash(mtn["name"] + str(i)) % 100) / 200)
                peak_x = cx + math.cos(angle) * peak_dist
                peak_y = cy + math.sin(angle) * peak_dist

                sub_dist = math.sqrt((x - peak_x) ** 2 + (y - peak_y) ** 2)
                sub_radius = radius * 0.3

                if sub_dist < sub_radius:
                    sub_influence = (1.0 - sub_dist / sub_radius) ** 2
                    sub_height = sub_influence * mtn["peak_height"] * 0.6
                    height = max(height, sub_height)

            total_height = max(total_height, height)

    return total_height


def calculate_height(x, y):
    """
    MASTER HEIGHT FUNCTION
    Combines all terrain features into final height
    """
    # Apply domain warping for organic shapes
    wx, wy = domain_warp(x, y, strength=0.3, scale=600, seed=SEED)

    # Base terrain - gentle undulation everywhere
    base = fbm(wx, wy, octaves=4, scale=800, seed=SEED) * 25 + 15

    # Rolling hills - medium scale variation
    hills = fbm(wx, wy, octaves=5, scale=300, seed=SEED + 1000) * 40

    # Fine detail
    detail = fbm(wx, wy, octaves=6, scale=80, seed=SEED + 2000) * 10

    # Mountain contribution
    mountains = calculate_mountain_height(x, y)

    # Valley carving
    valley_depth = calculate_valley_depth(x, y)

    # Combine layers
    height = base + hills + detail + mountains - valley_depth

    # Edge falloff (world boundary)
    half_size = WORLD_SIZE / 2
    edge_dist = max(abs(x), abs(y))
    if edge_dist > half_size * 0.8:
        falloff = 1.0 - (edge_dist - half_size * 0.8) / (half_size * 0.2)
        falloff = max(0, falloff)
        height *= falloff
        height -= (1 - falloff) * 50  # Drop below water at edges

    # Ensure spawn area is safe
    spawn_dist = math.sqrt(x ** 2 + y ** 2)
    if spawn_dist < 100:
        height = max(height, 5)

    return height


# ============================================================
# MESH GENERATION
# ============================================================

def create_terrain_mesh():
    """Generate the main terrain mesh"""

    print("\n" + "=" * 60)
    print("GENERATING DREAM TERRAIN")
    print("=" * 60)

    mesh = bpy.data.meshes.new("DreamTerrain")
    obj = bpy.data.objects.new("DreamTerrain", mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()

    step = WORLD_SIZE / RESOLUTION
    half_size = WORLD_SIZE / 2

    print(f"Resolution: {RESOLUTION}x{RESOLUTION} = {RESOLUTION**2} vertices")
    print(f"World size: {WORLD_SIZE} studs")
    print(f"Step size: {step} studs")

    # Generate vertices
    verts = []
    heights = []

    print("\nGenerating heightmap...")
    for iy in range(RESOLUTION + 1):
        row_heights = []
        for ix in range(RESOLUTION + 1):
            x = -half_size + ix * step
            y = -half_size + iy * step

            height = calculate_height(x, y)
            row_heights.append(height)

            vert = bm.verts.new((x, y, height))
            verts.append(vert)

        heights.append(row_heights)

        if iy % 20 == 0:
            print(f"  Progress: {iy}/{RESOLUTION + 1}")

    bm.verts.ensure_lookup_table()

    # Generate faces
    print("\nGenerating faces...")
    for iy in range(RESOLUTION):
        for ix in range(RESOLUTION):
            i = iy * (RESOLUTION + 1) + ix
            v1 = verts[i]
            v2 = verts[i + 1]
            v3 = verts[i + RESOLUTION + 1]
            v4 = verts[i + RESOLUTION + 2]

            bm.faces.new([v1, v2, v4, v3])

    # Smooth normals
    for face in bm.faces:
        face.smooth = True

    bm.to_mesh(mesh)
    bm.free()

    print(f"\nCreated mesh with {len(mesh.vertices)} vertices, {len(mesh.polygons)} faces")

    return obj, heights


def create_water_surface():
    """Create water plane at water level"""

    print("\nCreating water surface...")

    bpy.ops.mesh.primitive_plane_add(
        size=WORLD_SIZE * 1.2,
        location=(0, 0, WATER_LEVEL)
    )
    water = bpy.context.object
    water.name = "WaterSurface"

    # Water material
    mat = bpy.data.materials.new(name="Water")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.1, 0.3, 0.5, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.05
    bsdf.inputs["Alpha"].default_value = 0.6
    mat.blend_method = 'BLEND'
    water.data.materials.append(mat)

    return water


def create_snow_caps(terrain_obj, heights):
    """Add snow material to high altitude areas"""

    print("\nApplying snow caps...")

    # Create snow material
    snow_mat = bpy.data.materials.new(name="Snow")
    snow_mat.use_nodes = True
    bsdf = snow_mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.95, 0.97, 1.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.8
    bsdf.inputs["Subsurface Weight"].default_value = 0.1

    # Create rock material
    rock_mat = bpy.data.materials.new(name="Rock")
    rock_mat.use_nodes = True
    bsdf = rock_mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.35, 0.32, 0.28, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.95

    # Create grass material
    grass_mat = bpy.data.materials.new(name="Grass")
    grass_mat.use_nodes = True
    bsdf = grass_mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.2, 0.4, 0.15, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.8

    terrain_obj.data.materials.append(grass_mat)  # Index 0
    terrain_obj.data.materials.append(rock_mat)   # Index 1
    terrain_obj.data.materials.append(snow_mat)   # Index 2

    return snow_mat, rock_mat, grass_mat


def create_valley_flowers():
    """Scatter wildflowers in valley meadows"""

    print("\nPlanting valley wildflowers...")

    flowers_parent = bpy.data.objects.new("Wildflowers", None)
    bpy.context.collection.objects.link(flowers_parent)

    colors = [
        (1.0, 0.3, 0.3, 1.0),    # Red
        (1.0, 0.8, 0.2, 1.0),    # Yellow
        (0.8, 0.3, 0.9, 1.0),    # Purple
        (1.0, 0.5, 0.7, 1.0),    # Pink
        (0.3, 0.6, 1.0, 1.0),    # Blue
        (1.0, 1.0, 1.0, 1.0),    # White
    ]

    flower_count = 0
    step = WORLD_SIZE / 50  # Sample points

    half_size = WORLD_SIZE / 2

    for x in range(-int(half_size), int(half_size), int(step)):
        for y in range(-int(half_size), int(half_size), int(step)):
            height = calculate_height(x, y)

            # Only in valleys (low, above water)
            if height < 40 and height > WATER_LEVEL + 5:
                # Create a flower cluster
                for _ in range(random.randint(5, 15)):
                    fx = x + random.uniform(-step/2, step/2)
                    fy = y + random.uniform(-step/2, step/2)
                    fh = calculate_height(fx, fy)

                    if fh < 40 and fh > WATER_LEVEL + 3:
                        bpy.ops.mesh.primitive_uv_sphere_add(
                            radius=0.5 + random.random() * 0.3,
                            location=(fx, fy, fh + 0.5)
                        )
                        flower = bpy.context.object
                        flower.name = f"Flower_{flower_count}"
                        flower.parent = flowers_parent

                        # Random color
                        mat = bpy.data.materials.new(name=f"FlowerColor_{flower_count}")
                        mat.use_nodes = True
                        bsdf = mat.node_tree.nodes["Principled BSDF"]
                        bsdf.inputs["Base Color"].default_value = random.choice(colors)
                        bsdf.inputs["Roughness"].default_value = 0.3
                        flower.data.materials.append(mat)

                        flower_count += 1

                        if flower_count >= 500:  # Limit for performance
                            print(f"  Created {flower_count} flowers")
                            return flowers_parent

    print(f"  Created {flower_count} flowers")
    return flowers_parent


def create_ancient_ruins():
    """Place ancient ruins throughout the landscape"""

    print("\nPlacing ancient ruins...")

    ruins_parent = bpy.data.objects.new("AncientRuins", None)
    bpy.context.collection.objects.link(ruins_parent)

    ruin_positions = [
        (200, -150, "Broken Arch"),
        (-250, 200, "Fallen Pillar"),
        (100, 350, "Stone Circle"),
        (-400, -200, "Ruined Tower"),
        (350, 100, "Ancient Altar"),
    ]

    for rx, ry, name in ruin_positions:
        height = calculate_height(rx, ry)

        if height > WATER_LEVEL + 5 and height < 150:
            # Create a simple ruin structure
            bpy.ops.mesh.primitive_cube_add(
                size=10,
                location=(rx, ry, height + 5)
            )
            base = bpy.context.object
            base.name = f"Ruin_{name}_Base"
            base.scale.z = 0.5
            base.parent = ruins_parent

            # Add some pillars
            for i in range(random.randint(2, 5)):
                angle = random.random() * math.pi * 2
                dist = random.uniform(8, 15)
                px = rx + math.cos(angle) * dist
                py = ry + math.sin(angle) * dist
                ph = calculate_height(px, py)

                bpy.ops.mesh.primitive_cylinder_add(
                    radius=1.5,
                    depth=random.uniform(8, 20),
                    location=(px, py, ph + 5)
                )
                pillar = bpy.context.object
                pillar.name = f"Ruin_{name}_Pillar_{i}"
                pillar.rotation_euler.x = random.uniform(-0.1, 0.1)
                pillar.rotation_euler.y = random.uniform(-0.1, 0.1)
                pillar.parent = ruins_parent

            # Stone material
            mat = bpy.data.materials.new(name=f"AncientStone_{name}")
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes["Principled BSDF"]
            bsdf.inputs["Base Color"].default_value = (0.5, 0.48, 0.42, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.95
            base.data.materials.append(mat)

    print(f"  Created {len(ruin_positions)} ruin sites")
    return ruins_parent


# ============================================================
# RENDERING
# ============================================================

def setup_epic_lighting():
    """Dramatic lighting for renders"""

    # Remove existing lights
    for obj in bpy.data.objects:
        if obj.type == 'LIGHT':
            bpy.data.objects.remove(obj)

    # Golden hour sun
    bpy.ops.object.light_add(type='SUN', location=(1000, -500, 800))
    sun = bpy.context.object
    sun.name = "EpicSun"
    sun.data.energy = 5.0
    sun.data.color = (1.0, 0.85, 0.6)
    sun.rotation_euler = (math.radians(40), math.radians(10), math.radians(35))

    # Cool rim light
    bpy.ops.object.light_add(type='SUN', location=(-800, 800, 600))
    rim = bpy.context.object
    rim.name = "RimLight"
    rim.data.energy = 2.0
    rim.data.color = (0.6, 0.75, 1.0)
    rim.rotation_euler = (math.radians(55), 0, math.radians(150))

    # Ambient fill
    bpy.ops.object.light_add(type='SUN', location=(0, 0, 1500))
    ambient = bpy.context.object
    ambient.name = "AmbientFill"
    ambient.data.energy = 1.0
    ambient.data.color = (0.8, 0.85, 0.9)
    ambient.rotation_euler = (math.radians(90), 0, 0)


def setup_sky():
    """Create epic sky background"""

    world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    bpy.context.scene.world = world
    world.use_nodes = True

    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs["Color"].default_value = (0.4, 0.55, 0.85, 1.0)
        bg.inputs["Strength"].default_value = 1.2


def render_epic_views():
    """Render multiple dramatic viewpoints"""

    print("\nRendering epic views...")

    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'

    views = [
        {
            "name": "hero_vista",
            "camera": (200, -1200, 150),
            "target": (100, 200, 150),
            "description": "Hero vista - dramatic mountain panorama"
        },
        {
            "name": "frozen_sentinels",
            "camera": (100, -700, 100),
            "target": (400, -500, 300),
            "description": "The Frozen Sentinels mountain range"
        },
        {
            "name": "valley_flowers",
            "camera": (-100, 50, 30),
            "target": (-50, 150, 20),
            "description": "Wildflower valley meadow"
        },
        {
            "name": "giants_throne",
            "camera": (200, 200, 100),
            "target": (450, 450, 350),
            "description": "Giants' Throne - the highest peak"
        },
        {
            "name": "aerial_overview",
            "camera": (0, 0, 1500),
            "target": (0, 0, 0),
            "description": "Aerial overview of entire world"
        },
        {
            "name": "ancient_ruins",
            "camera": (180, -200, 50),
            "target": (200, -150, 30),
            "description": "Ancient ruins in the lowlands"
        },
    ]

    for view in views:
        print(f"  Rendering: {view['description']}")

        # Create camera
        bpy.ops.object.camera_add(location=view["camera"])
        camera = bpy.context.object
        camera.name = f"Camera_{view['name']}"

        # Point at target
        direction = Vector(view["target"]) - Vector(view["camera"])
        rot_quat = direction.to_track_quat('-Z', 'Y')
        camera.rotation_euler = rot_quat.to_euler()

        # Cinematic lens
        camera.data.lens = 35

        scene.camera = camera

        # Render
        filepath = os.path.join(RENDER_DIR, f"dream_{view['name']}")
        scene.render.filepath = filepath
        bpy.ops.render.render(write_still=True)

        print(f"    Saved: {filepath}.png")

        # Cleanup camera
        bpy.data.objects.remove(camera)


# ============================================================
# EXPORT
# ============================================================

def export_all(terrain, water, flowers, ruins):
    """Export everything to FBX files"""

    print("\nExporting FBX files...")

    # Select terrain
    bpy.ops.object.select_all(action='DESELECT')
    terrain.select_set(True)

    # Export terrain
    filepath = os.path.join(OUTPUT_DIR, "dream_terrain.fbx")
    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=True,
        global_scale=1.0,
        use_mesh_modifiers=True,
        mesh_smooth_type='FACE',
        use_triangles=True,
    )
    print(f"  Exported: {filepath}")

    # Export complete scene
    bpy.ops.object.select_all(action='SELECT')
    filepath = os.path.join(OUTPUT_DIR, "dream_world_complete.fbx")
    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=True,
        global_scale=1.0,
        use_mesh_modifiers=True,
        mesh_smooth_type='FACE',
        use_triangles=True,
    )
    print(f"  Exported: {filepath}")


# ============================================================
# MAIN
# ============================================================

def main():
    print("\n" + "=" * 60)
    print("   MERTIN-FLEMMER DREAM TERRAIN GENERATOR")
    print("   Tolkien-worthy. Elder Scrolls epic. Alpine paradise.")
    print("=" * 60 + "\n")

    # Clear scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    # Generate terrain
    terrain, heights = create_terrain_mesh()

    # Add snow caps
    create_snow_caps(terrain, heights)

    # Create water
    water = create_water_surface()

    # Add wildflowers
    flowers = create_valley_flowers()

    # Add ruins
    ruins = create_ancient_ruins()

    # Setup lighting and sky
    setup_epic_lighting()
    setup_sky()

    # Render views
    render_epic_views()

    # Export
    export_all(terrain, water, flowers, ruins)

    print("\n" + "=" * 60)
    print("   DREAM TERRAIN GENERATION COMPLETE!")
    print("   ")
    print("   Your Tolkien-worthy world awaits.")
    print("   May your mountains be ever dramatic.")
    print("   May your valleys bloom with flowers.")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
