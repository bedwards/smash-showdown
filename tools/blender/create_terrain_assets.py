#!/usr/bin/env python3
"""
Faultline Fear: Terrain Asset Generator

Creates terrain feature assets (NOT base terrain):
- Rock formations (boulders, clusters)
- Fault line crack edges
- Steam vents
- Cliff props

These are placed on top of the procedurally generated terrain.

Usage:
    blender --background --python tools/blender/create_terrain_assets.py

Output:
    assets/models/terrain/*.fbx
"""

import bpy
import bmesh
import os
import sys
import math
import random

# Add parent directory for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from blender_utils import (
    clear_scene,
    setup_fbx_export,
    create_export_directory,
    export_model,
    set_origin_to_bottom,
    join_objects,
    create_material,
)


def add_noise_displacement(obj, strength=0.2, scale=2.0):
    """Add noise-based displacement for organic look."""
    # Add subdivision surface for more geometry
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_add(type='SUBSURF')
    obj.modifiers["Subdivision"].levels = 2
    obj.modifiers["Subdivision"].render_levels = 2
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    # Displace vertices with noise
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)

    for v in bm.verts:
        # Simple noise-like displacement
        noise_val = (
            math.sin(v.co.x * scale * 3.14) *
            math.cos(v.co.y * scale * 2.71) *
            math.sin(v.co.z * scale * 1.41)
        )
        v.co += v.normal * noise_val * strength

    bm.to_mesh(mesh)
    bm.free()


def create_boulder(size="medium", seed=0):
    """
    Create a natural-looking boulder.
    Sizes: small, medium, large, huge
    """
    clear_scene()
    random.seed(seed)

    sizes = {
        "small": (0.5, 0.4, 0.35),
        "medium": (1.2, 1.0, 0.8),
        "large": (2.5, 2.0, 1.5),
        "huge": (5.0, 4.0, 3.0),
    }

    scale = sizes.get(size, sizes["medium"])

    # Start with icosphere
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=3,
        radius=1,
        location=(0, 0, scale[2] * 0.5)
    )
    boulder = bpy.context.active_object
    boulder.name = f"Boulder_{size}"

    # Scale non-uniformly for natural shape
    boulder.scale = (
        scale[0] * (0.8 + random.random() * 0.4),
        scale[1] * (0.8 + random.random() * 0.4),
        scale[2] * (0.7 + random.random() * 0.3)
    )
    bpy.ops.object.transform_apply(scale=True)

    # Add displacement for rocky texture
    add_noise_displacement(boulder, strength=scale[0] * 0.15, scale=1.5)

    # Material (grey rock)
    rock_mat = create_material("RockGrey", (0.4, 0.38, 0.35, 1.0))
    boulder.data.materials.append(rock_mat)

    bpy.ops.object.shade_smooth()
    set_origin_to_bottom(boulder)

    return boulder


def create_rock_cluster(seed=0):
    """Create a cluster of small rocks."""
    clear_scene()
    random.seed(seed)
    parts = []

    # Create 5-8 rocks in a cluster
    num_rocks = random.randint(5, 8)

    for i in range(num_rocks):
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=0.2 + random.random() * 0.3,
            location=(
                (random.random() - 0.5) * 2,
                (random.random() - 0.5) * 2,
                0.1 + random.random() * 0.2
            )
        )
        rock = bpy.context.active_object
        rock.name = f"ClusterRock_{i}"

        # Random scale
        rock.scale = (
            0.8 + random.random() * 0.4,
            0.8 + random.random() * 0.4,
            0.6 + random.random() * 0.3
        )
        bpy.ops.object.transform_apply(scale=True)

        parts.append(rock)

    # Material
    rock_mat = create_material("RockCluster", (0.35, 0.33, 0.3, 1.0))
    for rock in parts:
        rock.data.materials.append(rock_mat)

    model = join_objects(parts, "RockCluster")
    set_origin_to_bottom(model)

    return model


def create_fault_edge(side="left"):
    """
    Create a fault line edge piece.
    These line the edges of the fault line crack.
    """
    clear_scene()
    parts = []

    # Main edge wall
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, -1.5),
        scale=(4, 0.5, 3)  # Long, thin, tall
    )
    wall = bpy.context.active_object
    wall.name = "FaultWall"

    # Add some roughness
    bpy.context.view_layer.objects.active = wall
    bpy.ops.object.modifier_add(type='SUBSURF')
    wall.modifiers["Subdivision"].levels = 2
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    # Displace for rocky look
    mesh = wall.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        noise = math.sin(v.co.x * 2) * math.cos(v.co.z * 1.5) * 0.2
        if side == "left":
            v.co.y += abs(noise)
        else:
            v.co.y -= abs(noise)
    bm.to_mesh(mesh)
    bm.free()

    parts.append(wall)

    # Add exposed rock layers (horizontal striations)
    layer_mat = create_material("RockLayer", (0.45, 0.4, 0.35, 1.0))
    dark_mat = create_material("RockDark", (0.3, 0.28, 0.25, 1.0))

    for i in range(3):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0.2 if side == "left" else -0.2, -0.5 - i * 1.0),
            scale=(3.8, 0.15, 0.3)
        )
        layer = bpy.context.active_object
        layer.name = f"RockLayer_{i}"
        layer.data.materials.append(layer_mat if i % 2 == 0 else dark_mat)
        parts.append(layer)

    # Main wall material
    wall_mat = create_material("FaultWall", (0.38, 0.35, 0.32, 1.0))
    wall.data.materials.append(wall_mat)

    model = join_objects(parts, f"FaultEdge_{side.capitalize()}")
    set_origin_to_bottom(model)

    return model


def create_steam_vent():
    """
    Create a steam vent model.
    Cone-shaped opening in the ground with rocks around it.
    """
    clear_scene()
    parts = []

    # Vent hole (cone going down)
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.8,
        radius2=0.3,
        depth=1.5,
        location=(0, 0, -0.5)
    )
    vent = bpy.context.active_object
    vent.name = "VentHole"

    # Invert normals to make it look like a hole
    bpy.context.view_layer.objects.active = vent
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.flip_normals()
    bpy.ops.object.mode_set(mode='OBJECT')

    vent_mat = create_material("VentInner", (0.2, 0.15, 0.1, 1.0))
    vent.data.materials.append(vent_mat)
    parts.append(vent)

    # Ring of rocks around the vent
    rock_mat = create_material("VentRocks", (0.35, 0.32, 0.28, 1.0))
    num_rocks = 8
    for i in range(num_rocks):
        angle = (i / num_rocks) * math.pi * 2
        radius = 0.9 + random.random() * 0.3
        x = math.cos(angle) * radius
        y = math.sin(angle) * radius

        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=0.2 + random.random() * 0.15,
            location=(x, y, 0.1)
        )
        rock = bpy.context.active_object
        rock.name = f"VentRock_{i}"
        rock.scale = (1, 1, 0.6)
        bpy.ops.object.transform_apply(scale=True)
        rock.data.materials.append(rock_mat)
        parts.append(rock)

    model = join_objects(parts, "SteamVent")
    set_origin_to_bottom(model)

    return model


def create_cliff_face(cliff_type="coastal"):
    """
    Create a cliff face prop.
    Types: coastal, mountain
    """
    clear_scene()
    parts = []

    if cliff_type == "coastal":
        # Coastal cliff - more weathered, horizontal layers
        color = (0.6, 0.55, 0.45, 1.0)  # Sandy/beige
        height = 8
        width = 10
    else:
        # Mountain cliff - more jagged, darker
        color = (0.4, 0.38, 0.35, 1.0)  # Grey
        height = 12
        width = 8

    # Main cliff face
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, height / 2),
        scale=(width, 2, height)
    )
    cliff = bpy.context.active_object
    cliff.name = "CliffFace"

    # Add subdivisions for displacement
    bpy.context.view_layer.objects.active = cliff
    bpy.ops.object.modifier_add(type='SUBSURF')
    cliff.modifiers["Subdivision"].levels = 3
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    # Displace front face for rocky texture
    mesh = cliff.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        if v.co.y > 0.8:  # Front face
            noise = (
                math.sin(v.co.x * 1.5) * math.sin(v.co.z * 2) * 0.5 +
                math.sin(v.co.x * 4) * math.sin(v.co.z * 3) * 0.2
            )
            v.co.y += noise
    bm.to_mesh(mesh)
    bm.free()

    cliff_mat = create_material(f"Cliff{cliff_type.capitalize()}", color)
    cliff.data.materials.append(cliff_mat)
    bpy.ops.object.shade_smooth()
    parts.append(cliff)

    # Add rock debris at base
    debris_mat = create_material("CliffDebris", (color[0] * 0.9, color[1] * 0.9, color[2] * 0.9, 1.0))
    for i in range(6):
        x = (random.random() - 0.5) * width * 0.8
        y = 1 + random.random() * 0.5
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=0.3 + random.random() * 0.4,
            location=(x, y, 0.2)
        )
        debris = bpy.context.active_object
        debris.name = f"Debris_{i}"
        debris.scale = (1, 1, 0.6)
        bpy.ops.object.transform_apply(scale=True)
        debris.data.materials.append(debris_mat)
        parts.append(debris)

    model = join_objects(parts, f"Cliff_{cliff_type.capitalize()}")
    set_origin_to_bottom(model)

    return model


def create_fallen_rocks():
    """Create a pile of fallen rocks/debris."""
    clear_scene()
    parts = []

    rock_mat = create_material("FallenRocks", (0.4, 0.37, 0.33, 1.0))

    # Create a pile of rocks
    for i in range(12):
        size = 0.2 + random.random() * 0.5
        x = (random.random() - 0.5) * 3
        y = (random.random() - 0.5) * 3
        z = size * 0.5 + random.random() * 0.3

        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=size,
            location=(x, y, z)
        )
        rock = bpy.context.active_object
        rock.name = f"FallenRock_{i}"

        # Flatten slightly
        rock.scale = (
            0.8 + random.random() * 0.4,
            0.8 + random.random() * 0.4,
            0.5 + random.random() * 0.3
        )
        bpy.ops.object.transform_apply(scale=True)

        rock.data.materials.append(rock_mat)
        parts.append(rock)

    model = join_objects(parts, "FallenRocks")
    set_origin_to_bottom(model)

    return model


def main():
    """Generate all terrain assets."""
    print("=" * 50)
    print("Faultline Fear: Terrain Asset Generator")
    print("=" * 50)

    output_dir = create_export_directory("assets/models/terrain")
    setup_fbx_export()

    # Generate models
    models = [
        # Boulders (multiple sizes)
        ("Boulder_Small", lambda: create_boulder("small", seed=1)),
        ("Boulder_Medium", lambda: create_boulder("medium", seed=2)),
        ("Boulder_Large", lambda: create_boulder("large", seed=3)),
        ("Boulder_Huge", lambda: create_boulder("huge", seed=4)),

        # Rock formations
        ("RockCluster_1", lambda: create_rock_cluster(seed=10)),
        ("RockCluster_2", lambda: create_rock_cluster(seed=20)),
        ("FallenRocks", create_fallen_rocks),

        # Fault line pieces
        ("FaultEdge_Left", lambda: create_fault_edge("left")),
        ("FaultEdge_Right", lambda: create_fault_edge("right")),
        ("SteamVent", create_steam_vent),

        # Cliffs
        ("Cliff_Coastal", lambda: create_cliff_face("coastal")),
        ("Cliff_Mountain", lambda: create_cliff_face("mountain")),
    ]

    for name, create_func in models:
        print(f"\nCreating {name}...")
        model = create_func()

        filepath = os.path.join(output_dir, f"{name}.fbx")
        export_model(model, filepath)
        print(f"  Exported: {filepath}")

    print("\n" + "=" * 50)
    print(f"Generated {len(models)} terrain assets")
    print("=" * 50)


if __name__ == "__main__":
    main()
