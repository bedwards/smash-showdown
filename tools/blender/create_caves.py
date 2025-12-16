#!/usr/bin/env python3
"""
Faultline Fear: Cave Asset Generator

Creates cave-related assets:
- Cave entrances (exterior)
- Cave interior segments
- Stalactites/stalagmites
- Rock formations

Usage:
    blender --background --python tools/blender/create_caves.py

Output:
    assets/models/caves/*.fbx
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


def create_cave_entrance(size="medium"):
    """
    Create a cave entrance - arch-shaped opening in rock.
    """
    clear_scene()
    parts = []

    sizes = {
        "small": (3, 2.5, 2),
        "medium": (5, 4, 3),
        "large": (8, 6, 4),
    }

    width, height, depth = sizes.get(size, sizes["medium"])

    # Main rock mass around the entrance
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, height / 2),
        scale=(width * 1.5, depth, height)
    )
    rock = bpy.context.active_object
    rock.name = "EntranceRock"

    # Add subdivision for displacement
    bpy.context.view_layer.objects.active = rock
    bpy.ops.object.modifier_add(type='SUBSURF')
    rock.modifiers["Subdivision"].levels = 2
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    # Carve out entrance hole using boolean-like vertex displacement
    mesh = rock.data
    bm = bmesh.new()
    bm.from_mesh(mesh)

    for v in bm.verts:
        # Check if vertex is in entrance area
        if abs(v.co.x) < width / 2 and v.co.y > -depth / 2:
            # Arch shape
            entrance_height = height * (1 - (v.co.x / (width / 2)) ** 2)
            if v.co.z < entrance_height * 0.9:
                # Push back to create opening
                v.co.y = max(v.co.y, depth / 3)

        # Add rocky texture to exterior
        if v.co.y < 0:
            noise = math.sin(v.co.x * 2) * math.sin(v.co.z * 1.5) * 0.3
            v.co.y -= abs(noise)

    bm.to_mesh(mesh)
    bm.free()

    rock_mat = create_material("CaveRock", (0.35, 0.32, 0.3, 1.0))
    rock.data.materials.append(rock_mat)
    bpy.ops.object.shade_smooth()
    parts.append(rock)

    # Floor extending into cave
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, depth / 4, 0.01),
        scale=(width * 0.8, depth * 0.8, 1)
    )
    floor = bpy.context.active_object
    floor.name = "CaveFloor"
    floor_mat = create_material("CaveFloor", (0.25, 0.22, 0.2, 1.0))
    floor.data.materials.append(floor_mat)
    parts.append(floor)

    # Add some rocks around entrance
    for i in range(5):
        x = (random.random() - 0.5) * width * 1.8
        y = -depth / 2 - random.random() * 2
        z = 0.2 + random.random() * 0.3

        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=0.2 + random.random() * 0.3,
            location=(x, y, z)
        )
        debris = bpy.context.active_object
        debris.name = f"EntranceRock_{i}"
        debris.scale = (1, 1, 0.6)
        bpy.ops.object.transform_apply(scale=True)
        debris.data.materials.append(rock_mat)
        parts.append(debris)

    model = join_objects(parts, f"CaveEntrance_{size.capitalize()}")
    set_origin_to_bottom(model)
    return model


def create_stalactite(length=1.5):
    """Create a hanging stalactite."""
    clear_scene()

    bpy.ops.mesh.primitive_cone_add(
        radius1=0.3 * length / 1.5,
        radius2=0.02,
        depth=length,
        location=(0, 0, -length / 2)
    )
    stalactite = bpy.context.active_object
    stalactite.name = "Stalactite"

    # Add bumps/texture
    bpy.context.view_layer.objects.active = stalactite
    bpy.ops.object.modifier_add(type='SUBSURF')
    stalactite.modifiers["Subdivision"].levels = 2
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    mesh = stalactite.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        noise = math.sin(v.co.z * 5) * 0.05
        dist = math.sqrt(v.co.x ** 2 + v.co.y ** 2)
        v.co.x += noise * dist
        v.co.y += noise * dist
    bm.to_mesh(mesh)
    bm.free()

    mat = create_material("Stalactite", (0.5, 0.48, 0.45, 1.0))
    stalactite.data.materials.append(mat)
    bpy.ops.object.shade_smooth()

    set_origin_to_bottom(stalactite)
    return stalactite


def create_stalagmite(height=1.0):
    """Create a floor stalagmite."""
    clear_scene()

    bpy.ops.mesh.primitive_cone_add(
        radius1=0.25 * height,
        radius2=0.03,
        depth=height,
        location=(0, 0, height / 2)
    )
    stalagmite = bpy.context.active_object
    stalagmite.name = "Stalagmite"

    # Add texture
    bpy.context.view_layer.objects.active = stalagmite
    bpy.ops.object.modifier_add(type='SUBSURF')
    stalagmite.modifiers["Subdivision"].levels = 2
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    mesh = stalagmite.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        noise = math.sin(v.co.z * 6) * 0.04
        dist = math.sqrt(v.co.x ** 2 + v.co.y ** 2)
        v.co.x += noise * dist
        v.co.y += noise * dist
    bm.to_mesh(mesh)
    bm.free()

    mat = create_material("Stalagmite", (0.45, 0.42, 0.4, 1.0))
    stalagmite.data.materials.append(mat)
    bpy.ops.object.shade_smooth()

    set_origin_to_bottom(stalagmite)
    return stalagmite


def create_cave_interior_segment():
    """
    Create a cave interior segment - tunnel section.
    """
    clear_scene()
    parts = []

    # Main tunnel shape (hollow cylinder approximation)
    length = 10
    radius = 4

    # Create outer shell
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius,
        depth=length,
        location=(0, length / 2, radius * 0.8),
        rotation=(1.57, 0, 0)
    )
    outer = bpy.context.active_object
    outer.name = "TunnelOuter"

    # Scale to make elliptical
    outer.scale = (1.2, 1, 0.8)
    bpy.ops.object.transform_apply(scale=True)

    # Add subdivision
    bpy.context.view_layer.objects.active = outer
    bpy.ops.object.modifier_add(type='SUBSURF')
    outer.modifiers["Subdivision"].levels = 2
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    # Displace for rocky texture
    mesh = outer.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        noise = (
            math.sin(v.co.x * 2 + v.co.y * 1.5) *
            math.sin(v.co.z * 2) * 0.3
        )
        # Only displace outward (exterior)
        dist = math.sqrt(v.co.x ** 2 + (v.co.z - radius * 0.8) ** 2)
        if dist > radius * 0.5:
            direction = v.co.normalized()
            v.co += direction * abs(noise)
    bm.to_mesh(mesh)
    bm.free()

    rock_mat = create_material("CaveInterior", (0.28, 0.25, 0.23, 1.0))
    outer.data.materials.append(rock_mat)
    bpy.ops.object.shade_smooth()
    parts.append(outer)

    # Floor
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, length / 2, 0.01),
        scale=(radius * 1.5, length * 0.9, 1)
    )
    floor = bpy.context.active_object
    floor.name = "TunnelFloor"
    floor_mat = create_material("CaveFloorInterior", (0.2, 0.18, 0.16, 1.0))
    floor.data.materials.append(floor_mat)
    parts.append(floor)

    # Add stalactites
    for i in range(4):
        x = (random.random() - 0.5) * radius
        y = random.random() * length
        z = radius * 1.4 + random.random() * 0.5

        bpy.ops.mesh.primitive_cone_add(
            radius1=0.15 + random.random() * 0.1,
            radius2=0.02,
            depth=0.8 + random.random() * 0.5,
            location=(x, y, z),
            rotation=(3.14, 0, 0)
        )
        stal = bpy.context.active_object
        stal.name = f"Stalactite_{i}"
        stal_mat = create_material(f"Stal_{i}", (0.45, 0.42, 0.4, 1.0))
        stal.data.materials.append(stal_mat)
        parts.append(stal)

    model = join_objects(parts, "CaveInteriorSegment")
    set_origin_to_bottom(model)
    return model


def create_cave_chamber():
    """
    Create a larger cave chamber - open room.
    """
    clear_scene()
    parts = []

    radius = 8
    height = 6

    # Dome ceiling
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius,
        location=(0, 0, 0),
        scale=(1, 1, height / radius)
    )
    dome = bpy.context.active_object
    dome.name = "ChamberDome"

    # Only keep top half
    bpy.context.view_layer.objects.active = dome
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.bisect(
        plane_co=(0, 0, 0),
        plane_no=(0, 0, 1),
        clear_inner=True
    )
    bpy.ops.object.mode_set(mode='OBJECT')

    # Add rocky texture
    bpy.ops.object.modifier_add(type='SUBSURF')
    dome.modifiers["Subdivision"].levels = 2
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    mesh = dome.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        noise = math.sin(v.co.x * 1.5) * math.sin(v.co.y * 1.5) * 0.5
        v.co.z += abs(noise) * (v.co.z / height)
    bm.to_mesh(mesh)
    bm.free()

    rock_mat = create_material("ChamberRock", (0.3, 0.27, 0.25, 1.0))
    dome.data.materials.append(rock_mat)
    bpy.ops.object.shade_smooth()
    parts.append(dome)

    # Floor
    bpy.ops.mesh.primitive_circle_add(
        radius=radius * 1.1,
        fill_type='NGON',
        location=(0, 0, 0.01)
    )
    floor = bpy.context.active_object
    floor.name = "ChamberFloor"
    floor_mat = create_material("ChamberFloor", (0.22, 0.2, 0.18, 1.0))
    floor.data.materials.append(floor_mat)
    parts.append(floor)

    # Add stalagmites
    for i in range(6):
        angle = (i / 6) * math.pi * 2
        dist = radius * 0.6 + random.random() * radius * 0.2
        x = math.cos(angle) * dist
        y = math.sin(angle) * dist

        bpy.ops.mesh.primitive_cone_add(
            radius1=0.3 + random.random() * 0.2,
            radius2=0.03,
            depth=1 + random.random() * 1.5,
            location=(x, y, 0)
        )
        stal = bpy.context.active_object
        stal.name = f"Stalagmite_{i}"
        # Move up so base is at floor
        stal.location.z = stal.dimensions.z / 2
        stal_mat = create_material(f"ChamberStal_{i}", (0.4, 0.38, 0.35, 1.0))
        stal.data.materials.append(stal_mat)
        parts.append(stal)

    model = join_objects(parts, "CaveChamber")
    set_origin_to_bottom(model)
    return model


def create_rock_pillar():
    """Create a floor-to-ceiling rock pillar."""
    clear_scene()
    parts = []

    height = 5
    radius = 0.8

    # Main pillar
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius,
        depth=height,
        location=(0, 0, height / 2)
    )
    pillar = bpy.context.active_object
    pillar.name = "Pillar"

    # Add irregular shape
    bpy.context.view_layer.objects.active = pillar
    bpy.ops.object.modifier_add(type='SUBSURF')
    pillar.modifiers["Subdivision"].levels = 2
    bpy.ops.object.modifier_apply(modifier="Subdivision")

    mesh = pillar.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for v in bm.verts:
        noise = math.sin(v.co.z * 3) * math.sin(v.co.x * 4 + v.co.y * 4) * 0.15
        dist = math.sqrt(v.co.x ** 2 + v.co.y ** 2)
        if dist > 0.1:
            direction_x = v.co.x / dist
            direction_y = v.co.y / dist
            v.co.x += direction_x * noise
            v.co.y += direction_y * noise
    bm.to_mesh(mesh)
    bm.free()

    mat = create_material("PillarRock", (0.38, 0.35, 0.32, 1.0))
    pillar.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    parts.append(pillar)

    model = join_objects(parts, "RockPillar")
    set_origin_to_bottom(model)
    return model


def main():
    """Generate all cave assets."""
    print("=" * 50)
    print("Faultline Fear: Cave Asset Generator")
    print("=" * 50)

    output_dir = create_export_directory("assets/models/caves")
    setup_fbx_export()

    # Generate models
    models = [
        # Cave entrances
        ("CaveEntrance_Small", lambda: create_cave_entrance("small")),
        ("CaveEntrance_Medium", lambda: create_cave_entrance("medium")),
        ("CaveEntrance_Large", lambda: create_cave_entrance("large")),

        # Interior elements
        ("CaveInteriorSegment", create_cave_interior_segment),
        ("CaveChamber", create_cave_chamber),
        ("RockPillar", create_rock_pillar),

        # Details
        ("Stalactite", create_stalactite),
        ("Stalagmite", create_stalagmite),
    ]

    for name, create_func in models:
        print(f"\nCreating {name}...")
        model = create_func()

        filepath = os.path.join(output_dir, f"{name}.fbx")
        export_model(model, filepath)
        print(f"  Exported: {filepath}")

    print("\n" + "=" * 50)
    print(f"Generated {len(models)} cave assets")
    print("=" * 50)


if __name__ == "__main__":
    main()
