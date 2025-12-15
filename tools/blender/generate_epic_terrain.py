"""
ELDER SCROLLS STYLE EPIC TERRAIN GENERATOR
Dramatic mountains, deep valleys, ancient ruins feel
Run with: blender --background --python generate_epic_terrain.py
"""

import bpy
import bmesh
import math
import random
import os
from mathutils import Vector, noise

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ==========================================
# EPIC TERRAIN CONFIG - ELDER SCROLLS STYLE
# ==========================================

WORLD_SIZE = 2000  # Studs
RESOLUTION = 128   # High detail
MAX_HEIGHT = 500   # Towering peaks

# Biome definitions
BIOMES = {
    "frozen_wastes": {
        "color": (0.9, 0.95, 1.0),
        "roughness": 0.9,
        "snow_coverage": 0.8,
    },
    "volcanic": {
        "color": (0.3, 0.2, 0.15),
        "roughness": 0.7,
        "lava_pools": True,
    },
    "ancient_forest": {
        "color": (0.2, 0.35, 0.15),
        "roughness": 0.5,
        "dense_trees": True,
    },
    "cursed_swamp": {
        "color": (0.25, 0.3, 0.2),
        "roughness": 0.3,
        "fog": True,
    },
}

# ==========================================
# ADVANCED NOISE FUNCTIONS
# ==========================================

def fbm(x, y, z=0, octaves=8, persistence=0.5, lacunarity=2.0, seed=0):
    """Fractal Brownian Motion - multi-octave noise"""
    total = 0.0
    frequency = 1.0
    amplitude = 1.0
    max_value = 0.0

    for _ in range(octaves):
        total += noise.noise(Vector((x * frequency + seed, y * frequency + seed, z + seed))) * amplitude
        max_value += amplitude
        amplitude *= persistence
        frequency *= lacunarity

    return total / max_value


def ridged_multifractal(x, y, octaves=6, seed=0):
    """Creates sharp ridges like mountain spines"""
    total = 0.0
    frequency = 1.0
    amplitude = 1.0
    prev = 1.0

    for i in range(octaves):
        n = noise.noise(Vector((x * frequency + seed, y * frequency + seed, seed * 0.1)))
        n = 1.0 - abs(n)  # Create ridges
        n = n * n         # Sharpen
        n = n * prev      # Weight by previous
        prev = n
        total += n * amplitude
        amplitude *= 0.5
        frequency *= 2.1

    return total


def swiss_turbulence(x, y, octaves=5, seed=0):
    """Creates eroded, weathered look"""
    total = 0.0
    frequency = 1.0
    amplitude = 1.0

    dx_sum = 0.0
    dy_sum = 0.0

    for _ in range(octaves):
        # Calculate gradient
        eps = 0.01
        n = noise.noise(Vector((x * frequency + seed + dx_sum, y * frequency + seed + dy_sum, 0)))
        dx = noise.noise(Vector((x * frequency + seed + dx_sum + eps, y * frequency + seed + dy_sum, 0))) - n
        dy = noise.noise(Vector((x * frequency + seed + dx_sum, y * frequency + seed + dy_sum + eps, 0))) - n

        dx_sum += dx * amplitude * 0.5
        dy_sum += dy * amplitude * 0.5

        total += n * amplitude
        amplitude *= 0.5
        frequency *= 2.0

    return total


def voronoi_ridges(x, y, scale=1.0, seed=0):
    """Creates natural-looking ridge patterns"""
    # Simplified voronoi using noise
    n1 = noise.noise(Vector((x * scale + seed, y * scale + seed, 0)))
    n2 = noise.noise(Vector((x * scale * 1.5 + seed + 100, y * scale * 1.5 + seed + 100, 0)))
    return abs(n1 - n2)


# ==========================================
# TERRAIN GENERATION
# ==========================================

def generate_heightmap(size, resolution, seed=42):
    """Generate a detailed heightmap array"""

    random.seed(seed)
    heightmap = []

    step = size / resolution
    half = size / 2

    for iy in range(resolution + 1):
        row = []
        for ix in range(resolution + 1):
            x = (-half + ix * step) / size
            y = (-half + iy * step) / size

            # Base continental shape
            base = fbm(x * 2, y * 2, octaves=4, seed=seed) * 0.3

            # Mountain ridges (the dramatic peaks)
            ridges = ridged_multifractal(x * 3, y * 3, seed=seed + 100) * 0.5

            # Erosion detail
            erosion = swiss_turbulence(x * 5, y * 5, seed=seed + 200) * 0.15

            # Valley carving
            valleys = voronoi_ridges(x * 4, y * 4, seed=seed + 300) * 0.2

            # Combine
            h = base + ridges * (0.5 + base) - valleys * 0.3 + erosion

            # Add some dramatic peaks
            peak_influence = 0
            peak_positions = [
                (0.3, -0.4, 1.0),   # Frozen Peaks
                (0.4, -0.2, 0.85),  # Shadow Mountains
                (0.2, 0.2, 0.7),    # Ember Ridge
                (0.35, 0.35, 0.95), # The Giants
                (-0.35, 0.3, 0.5),  # Broken Hills
            ]

            for px, py, intensity in peak_positions:
                dist = math.sqrt((x - px) ** 2 + (y - py) ** 2)
                if dist < 0.3:
                    peak_h = (1 - dist / 0.3) ** 2 * intensity
                    # Add local detail to peaks
                    peak_h *= (1 + ridged_multifractal(x * 10 + px, y * 10 + py, seed=seed + 400) * 0.3)
                    peak_influence = max(peak_influence, peak_h)

            h = h * 0.4 + peak_influence * 0.6

            # Distance falloff (ocean at edges)
            dist_from_center = math.sqrt(x ** 2 + y ** 2) * 1.5
            if dist_from_center > 0.7:
                falloff = max(0, 1 - (dist_from_center - 0.7) / 0.3)
                h *= falloff
                h -= (1 - falloff) * 0.1  # Below sea level

            row.append(max(-0.1, h))  # Clamp minimum

        heightmap.append(row)

    return heightmap


def create_terrain_mesh(heightmap, size, max_height, name="EpicTerrain"):
    """Create mesh from heightmap"""

    print(f"Creating {name}...")

    resolution = len(heightmap) - 1
    step = size / resolution
    half = size / 2

    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()

    # Create vertices
    verts = []
    for iy, row in enumerate(heightmap):
        for ix, h in enumerate(row):
            x = -half + ix * step
            y = -half + iy * step
            z = h * max_height
            verts.append(bm.verts.new((x, y, z)))

    bm.verts.ensure_lookup_table()

    # Create faces
    for iy in range(resolution):
        for ix in range(resolution):
            i = iy * (resolution + 1) + ix
            v1 = verts[i]
            v2 = verts[i + 1]
            v3 = verts[i + resolution + 1]
            v4 = verts[i + resolution + 2]

            # Two triangles per quad for better topology
            bm.faces.new([v1, v2, v4, v3])

    # Smooth normals
    for face in bm.faces:
        face.smooth = True

    bm.to_mesh(mesh)
    bm.free()

    # Add material with vertex colors based on height
    mat = bpy.data.materials.new(name=f"{name}_Material")
    mat.use_nodes = True

    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.4, 0.35, 0.3, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.9

    obj.data.materials.append(mat)

    print(f"  Created with {len(mesh.vertices)} vertices, {len(mesh.polygons)} faces")

    return obj


def create_cliff_meshes(heightmap, size, max_height, threshold=0.3):
    """Generate dramatic cliff faces where terrain is steep"""

    print("Generating cliff details...")

    resolution = len(heightmap) - 1
    step = size / resolution
    half = size / 2

    cliffs = []

    # Find steep areas
    for iy in range(1, resolution):
        for ix in range(1, resolution):
            h = heightmap[iy][ix]
            h_left = heightmap[iy][ix - 1]
            h_right = heightmap[iy][ix + 1]
            h_up = heightmap[iy - 1][ix]
            h_down = heightmap[iy + 1][ix]

            # Calculate slope
            slope_x = abs(h_right - h_left) / (2 * step) * max_height
            slope_y = abs(h_down - h_up) / (2 * step) * max_height
            slope = math.sqrt(slope_x ** 2 + slope_y ** 2)

            if slope > threshold * max_height and h > 0.2:
                x = -half + ix * step
                y = -half + iy * step
                z = h * max_height

                # Create a cliff rock
                if random.random() < 0.1:  # Don't create too many
                    cliff = create_cliff_rock(x, y, z, slope * 0.5)
                    if cliff:
                        cliffs.append(cliff)

    print(f"  Created {len(cliffs)} cliff details")
    return cliffs


def create_cliff_rock(x, y, z, size):
    """Create a dramatic cliff/rock formation"""

    bpy.ops.mesh.primitive_cube_add(size=size, location=(x, y, z))
    rock = bpy.context.object
    rock.name = f"CliffRock_{x:.0f}_{y:.0f}"

    # Deform into rocky shape
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.subdivide(number_cuts=2)
    bpy.ops.object.mode_set(mode='OBJECT')

    # Randomize vertices
    for vert in rock.data.vertices:
        vert.co.x += random.uniform(-size * 0.3, size * 0.3)
        vert.co.y += random.uniform(-size * 0.3, size * 0.3)
        vert.co.z += random.uniform(-size * 0.2, size * 0.4)

    # Material
    mat = bpy.data.materials.new(name=f"Rock_{x:.0f}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.35, 0.3, 0.25, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    rock.data.materials.append(mat)

    return rock


def create_water_plane(size, height=-5):
    """Create water surface"""

    print("Creating water plane...")

    bpy.ops.mesh.primitive_plane_add(size=size * 1.2, location=(0, 0, height))
    water = bpy.context.object
    water.name = "WaterSurface"

    # Water material
    mat = bpy.data.materials.new(name="Water")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.1, 0.2, 0.4, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.1
    bsdf.inputs["Alpha"].default_value = 0.7
    mat.blend_method = 'BLEND'
    water.data.materials.append(mat)

    return water


def create_ancient_ruins(heightmap, size, max_height, count=5):
    """Scatter ancient ruins across the landscape"""

    print(f"Placing {count} ancient ruins...")

    resolution = len(heightmap) - 1
    step = size / resolution
    half = size / 2
    ruins = []

    for i in range(count):
        # Find a suitable flat-ish spot
        attempts = 0
        while attempts < 100:
            ix = random.randint(20, resolution - 20)
            iy = random.randint(20, resolution - 20)

            h = heightmap[iy][ix]
            if 0.15 < h < 0.5:  # Not too high, not underwater
                x = -half + ix * step
                y = -half + iy * step
                z = h * max_height

                ruin = create_ruin_structure(x, y, z, random.choice(["pillar", "arch", "wall"]))
                ruins.append(ruin)
                break

            attempts += 1

    return ruins


def create_ruin_structure(x, y, z, style="pillar"):
    """Create an ancient ruin element"""

    ruin = bpy.data.objects.new(f"Ruin_{style}_{x:.0f}", None)
    bpy.context.collection.objects.link(ruin)
    ruin.location = (x, y, z)

    if style == "pillar":
        # Broken pillar
        bpy.ops.mesh.primitive_cylinder_add(
            radius=3,
            depth=random.uniform(15, 40),
            location=(x, y, z + 10)
        )
        pillar = bpy.context.object
        pillar.name = f"Pillar_{x:.0f}"
        pillar.parent = ruin

        # Tilt it slightly
        pillar.rotation_euler.x = random.uniform(-0.1, 0.1)
        pillar.rotation_euler.y = random.uniform(-0.1, 0.1)

    elif style == "arch":
        # Stone arch
        bpy.ops.mesh.primitive_torus_add(
            major_radius=8,
            minor_radius=2,
            location=(x, y, z + 8)
        )
        arch = bpy.context.object
        arch.name = f"Arch_{x:.0f}"
        arch.scale.z = 1.5
        arch.rotation_euler.x = math.radians(90)

        # Cut it in half (keep only top)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.bisect(plane_co=(0, 0, 0), plane_no=(0, 0, 1), clear_inner=True)
        bpy.ops.object.mode_set(mode='OBJECT')

        arch.parent = ruin

    elif style == "wall":
        # Crumbling wall
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x, y, z + 5)
        )
        wall = bpy.context.object
        wall.name = f"Wall_{x:.0f}"
        wall.scale = (15, 2, random.uniform(8, 15))
        wall.rotation_euler.z = random.uniform(0, math.pi)

        # Deform for weathered look
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.subdivide(number_cuts=3)
        bpy.ops.object.mode_set(mode='OBJECT')

        for vert in wall.data.vertices:
            if vert.co.z > 0.3:  # Top of wall
                vert.co.z += random.uniform(-0.3, 0.1)
            vert.co.x += random.uniform(-0.05, 0.05)
            vert.co.y += random.uniform(-0.05, 0.05)

        wall.parent = ruin

    # Stone material
    mat = bpy.data.materials.new(name=f"AncientStone_{x:.0f}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.5, 0.48, 0.45, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.95

    for child in ruin.children:
        if child.data:
            child.data.materials.append(mat)

    return ruin


# ==========================================
# EXPORT
# ==========================================

def export_terrain(objects, filename):
    """Export to FBX for Roblox"""

    filepath = os.path.join(OUTPUT_DIR, filename)

    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        if obj:
            obj.select_set(True)
            for child in obj.children_recursive:
                child.select_set(True)

    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=True,
        global_scale=1.0,
        apply_scale_options='FBX_SCALE_NONE',
        use_mesh_modifiers=True,
        mesh_smooth_type='FACE',
        use_triangles=True,
    )

    print(f"Exported: {filepath}")
    return filepath


# ==========================================
# MAIN
# ==========================================

def main():
    print("\n" + "=" * 60)
    print("   ELDER SCROLLS STYLE EPIC TERRAIN GENERATOR")
    print("=" * 60 + "\n")

    # Clear scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    all_objects = []

    # Generate heightmap
    print("Generating epic heightmap...")
    heightmap = generate_heightmap(WORLD_SIZE, RESOLUTION, seed=12345)

    # Create main terrain
    terrain = create_terrain_mesh(heightmap, WORLD_SIZE, MAX_HEIGHT, "MertinFlemmer_Terrain")
    all_objects.append(terrain)

    # Add cliff details
    cliffs = create_cliff_meshes(heightmap, WORLD_SIZE, MAX_HEIGHT)
    all_objects.extend(cliffs)

    # Add water
    water = create_water_plane(WORLD_SIZE, height=-10)
    all_objects.append(water)

    # Add ancient ruins
    ruins = create_ancient_ruins(heightmap, WORLD_SIZE, MAX_HEIGHT, count=8)
    all_objects.extend(ruins)

    print("\n" + "-" * 60)
    print(f"Total objects created: {len(all_objects)}")
    print("-" * 60 + "\n")

    # Export
    export_terrain(all_objects, "epic_terrain.fbx")

    # Also export terrain mesh separately
    export_terrain([terrain], "terrain_mesh.fbx")

    print("\n" + "=" * 60)
    print("   EPIC TERRAIN GENERATION COMPLETE!")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
