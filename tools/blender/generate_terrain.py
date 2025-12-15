"""
Mertin-Flemmer Terrain Generator
Generates procedural mountain meshes using Blender's Python API
Run with: blender --background --python generate_terrain.py

Creates realistic mountain terrain using multi-octave Perlin noise
Exports to FBX for import into Roblox Studio
"""

import bpy
import bmesh
import math
import random
import os
from mathutils import Vector, noise

# ==========================================
# CONFIGURATION
# ==========================================

# Output directory
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Mountain definitions matching our game world
MOUNTAINS = [
    {
        "name": "Frozen_Peaks",
        "position": (300, -400),
        "size": 400,
        "height": 350,
        "roughness": 0.7,
        "peaks": 3,
        "snow_line": 200,
    },
    {
        "name": "Shadow_Mountains",
        "position": (400, -200),
        "size": 350,
        "height": 300,
        "roughness": 0.8,
        "peaks": 4,
        "snow_line": 250,
    },
    {
        "name": "Ember_Ridge",
        "position": (200, 200),
        "size": 300,
        "height": 250,
        "roughness": 0.6,
        "peaks": 2,
        "snow_line": 300,  # No snow (volcanic)
    },
    {
        "name": "The_Giants",
        "position": (350, 350),
        "size": 450,
        "height": 400,
        "roughness": 0.75,
        "peaks": 5,
        "snow_line": 180,
    },
    {
        "name": "Broken_Hills",
        "position": (-350, 300),
        "size": 250,
        "height": 150,
        "roughness": 0.5,
        "peaks": 6,
        "snow_line": 200,
    },
]

# Terrain resolution (vertices per unit)
RESOLUTION = 64  # Higher = more detail but larger file

# Noise parameters
NOISE_OCTAVES = 6
NOISE_PERSISTENCE = 0.5
NOISE_LACUNARITY = 2.0


# ==========================================
# NOISE FUNCTIONS
# ==========================================

def fbm_noise(x, y, octaves=NOISE_OCTAVES, persistence=NOISE_PERSISTENCE, lacunarity=NOISE_LACUNARITY, seed=0):
    """Fractal Brownian Motion noise - creates natural-looking terrain"""
    total = 0.0
    frequency = 1.0
    amplitude = 1.0
    max_value = 0.0

    for i in range(octaves):
        # Use Blender's built-in noise
        total += noise.noise(Vector((x * frequency + seed, y * frequency + seed, seed))) * amplitude
        max_value += amplitude
        amplitude *= persistence
        frequency *= lacunarity

    return total / max_value


def ridged_noise(x, y, octaves=4, seed=0):
    """Ridged multifractal noise - creates sharp mountain ridges"""
    total = 0.0
    frequency = 1.0
    amplitude = 1.0

    for i in range(octaves):
        n = noise.noise(Vector((x * frequency + seed, y * frequency + seed, seed * 0.5)))
        n = 1.0 - abs(n)  # Create ridges
        n = n * n  # Sharpen ridges
        total += n * amplitude
        amplitude *= 0.5
        frequency *= 2.0

    return total


def domain_warp(x, y, strength=0.3, seed=0):
    """Warp the domain for more organic shapes"""
    warp_x = fbm_noise(x + 100, y + 100, octaves=3, seed=seed) * strength
    warp_y = fbm_noise(x + 200, y + 200, octaves=3, seed=seed + 50) * strength
    return x + warp_x, y + warp_y


# ==========================================
# MESH GENERATION
# ==========================================

def create_mountain_mesh(mountain_config, seed=None):
    """Generate a mountain mesh using procedural noise"""

    if seed is None:
        seed = random.randint(0, 10000)

    name = mountain_config["name"]
    size = mountain_config["size"]
    height = mountain_config["height"]
    roughness = mountain_config["roughness"]
    num_peaks = mountain_config["peaks"]

    print(f"Generating {name}...")

    # Create mesh
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)

    # Link to scene
    bpy.context.collection.objects.link(obj)

    # Create BMesh for editing
    bm = bmesh.new()

    # Generate grid of vertices
    verts = []
    half_size = size / 2
    step = size / RESOLUTION

    # Generate peak positions
    peak_positions = []
    for i in range(num_peaks):
        angle = (i / num_peaks) * math.pi * 2 + random.uniform(-0.3, 0.3)
        dist = random.uniform(0.1, 0.4) * half_size
        px = math.cos(angle) * dist
        py = math.sin(angle) * dist
        peak_positions.append((px, py, random.uniform(0.7, 1.0)))

    for iy in range(RESOLUTION + 1):
        for ix in range(RESOLUTION + 1):
            x = -half_size + ix * step
            y = -half_size + iy * step

            # Normalize to 0-1 range for noise
            nx = x / size
            ny = y / size

            # Apply domain warping for organic shapes
            wx, wy = domain_warp(nx, ny, strength=0.4, seed=seed)

            # Base height from FBM noise
            h = fbm_noise(wx * 3, wy * 3, seed=seed) * 0.5 + 0.5

            # Add ridged noise for mountain ridges
            ridge = ridged_noise(wx * 2, wy * 2, seed=seed + 100) * roughness
            h = h * 0.6 + ridge * 0.4

            # Add influence from peaks
            for px, py, peak_height in peak_positions:
                dist = math.sqrt((x - px) ** 2 + (y - py) ** 2)
                influence = max(0, 1 - (dist / (half_size * 0.8)))
                influence = influence ** 2  # Sharper falloff
                h = max(h, influence * peak_height)

            # Distance falloff from center (makes it island-like)
            dist_from_center = math.sqrt(x ** 2 + y ** 2) / half_size
            falloff = max(0, 1 - dist_from_center ** 1.5)
            h *= falloff

            # Scale to actual height
            z = h * height

            # Add vertex
            vert = bm.verts.new((x, y, z))
            verts.append(vert)

    bm.verts.ensure_lookup_table()

    # Create faces
    for iy in range(RESOLUTION):
        for ix in range(RESOLUTION):
            i = iy * (RESOLUTION + 1) + ix

            # Two triangles per quad
            v1 = verts[i]
            v2 = verts[i + 1]
            v3 = verts[i + RESOLUTION + 1]
            v4 = verts[i + RESOLUTION + 2]

            bm.faces.new([v1, v2, v4, v3])

    # Smooth normals
    for face in bm.faces:
        face.smooth = True

    # Write to mesh
    bm.to_mesh(mesh)
    bm.free()

    # Add subdivision modifier for smoother results
    subsurf = obj.modifiers.new(name="Subsurf", type='SUBSURF')
    subsurf.levels = 1
    subsurf.render_levels = 2

    # Apply position offset
    obj.location = (mountain_config["position"][0], mountain_config["position"][1], 0)

    print(f"  Created {name} with {len(mesh.vertices)} vertices")

    return obj


def create_river_mesh(name, waypoints, width=15, depth=2):
    """Generate a river mesh following waypoints"""

    print(f"Generating river: {name}...")

    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()

    # Generate vertices along the river path
    segments_per_section = 8
    verts_left = []
    verts_right = []

    for i in range(len(waypoints) - 1):
        p1 = Vector(waypoints[i])
        p2 = Vector(waypoints[i + 1])

        for j in range(segments_per_section):
            t = j / segments_per_section

            # Interpolate position
            pos = p1.lerp(p2, t)

            # Calculate perpendicular direction
            direction = (p2 - p1).normalized()
            perp = Vector((-direction.y, direction.x, 0))

            # Add some waviness
            wave = math.sin(i * 2 + j * 0.5) * width * 0.2

            # Create left and right bank vertices
            left_pos = pos + perp * (width / 2 + wave)
            right_pos = pos - perp * (width / 2 - wave)

            left_pos.z = -depth
            right_pos.z = -depth

            verts_left.append(bm.verts.new(left_pos))
            verts_right.append(bm.verts.new(right_pos))

    # Add final point
    final_pos = Vector(waypoints[-1])
    direction = (Vector(waypoints[-1]) - Vector(waypoints[-2])).normalized()
    perp = Vector((-direction.y, direction.x, 0))

    verts_left.append(bm.verts.new(final_pos + perp * width / 2))
    verts_right.append(bm.verts.new(final_pos - perp * width / 2))

    bm.verts.ensure_lookup_table()

    # Create faces
    for i in range(len(verts_left) - 1):
        bm.faces.new([verts_left[i], verts_left[i + 1], verts_right[i + 1], verts_right[i]])

    bm.to_mesh(mesh)
    bm.free()

    # Set material for water look
    mat = bpy.data.materials.new(name=f"{name}_Material")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.1, 0.3, 0.5, 1.0)
    mat.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.7
    obj.data.materials.append(mat)

    print(f"  Created {name}")

    return obj


# ==========================================
# EXPORT FUNCTIONS
# ==========================================

def export_to_fbx(objects, filename):
    """Export selected objects to FBX"""

    filepath = os.path.join(OUTPUT_DIR, filename)

    # Deselect all
    bpy.ops.object.select_all(action='DESELECT')

    # Select our objects
    for obj in objects:
        obj.select_set(True)

    # Export
    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=True,
        global_scale=1.0,
        apply_scale_options='FBX_SCALE_NONE',
        use_mesh_modifiers=True,
        mesh_smooth_type='FACE',
        use_triangles=True,
    )

    print(f"Exported to: {filepath}")
    return filepath


def export_to_obj(objects, filename):
    """Export to OBJ format (alternative for Roblox)"""

    filepath = os.path.join(OUTPUT_DIR, filename)

    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)

    bpy.ops.export_scene.obj(
        filepath=filepath,
        use_selection=True,
        use_mesh_modifiers=True,
        use_triangles=True,
    )

    print(f"Exported OBJ to: {filepath}")
    return filepath


# ==========================================
# MAIN GENERATION
# ==========================================

def clear_scene():
    """Clear existing objects"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def generate_all_terrain():
    """Generate complete terrain set"""

    print("\n" + "=" * 50)
    print("MERTIN-FLEMMER TERRAIN GENERATOR")
    print("=" * 50 + "\n")

    clear_scene()

    generated_objects = []

    # Generate mountains
    for i, mountain in enumerate(MOUNTAINS):
        obj = create_mountain_mesh(mountain, seed=i * 1000)
        generated_objects.append(obj)

    # Generate rivers (simplified waypoints)
    rivers = [
        {
            "name": "Serpent_River",
            "waypoints": [
                (-400, -300, 0), (-350, -250, 0), (-300, -200, 0),
                (-280, -100, 0), (-320, 0, 0), (-280, 100, 0),
                (-200, 150, 0), (-150, 200, 0), (-100, 280, 0),
            ],
            "width": 15,
        },
        {
            "name": "Whispering_Brook",
            "waypoints": [
                (-200, 100, 0), (-150, 150, 0), (-80, 180, 0),
                (0, 200, 0), (80, 250, 0), (150, 300, 0),
            ],
            "width": 8,
        },
    ]

    for river in rivers:
        obj = create_river_mesh(river["name"], river["waypoints"], river["width"])
        generated_objects.append(obj)

    print("\n" + "-" * 50)
    print(f"Generated {len(generated_objects)} terrain objects")
    print("-" * 50 + "\n")

    # Export
    export_to_fbx(generated_objects, "mertin_terrain.fbx")

    # Also export individual mountains
    for obj in generated_objects:
        if "Mountain" in obj.name or "Peaks" in obj.name or "Ridge" in obj.name or "Giants" in obj.name or "Hills" in obj.name:
            export_to_fbx([obj], f"{obj.name}.fbx")

    print("\n" + "=" * 50)
    print("TERRAIN GENERATION COMPLETE!")
    print("=" * 50 + "\n")

    return generated_objects


# ==========================================
# RUN
# ==========================================

if __name__ == "__main__":
    generate_all_terrain()
