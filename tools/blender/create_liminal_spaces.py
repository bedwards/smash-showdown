#!/usr/bin/env python3
"""
Faultline Fear: Liminal Space Asset Generator

Creates eerie liminal space environments:
- Abandoned mall section
- Hotel lobby
- School classroom
- Hospital corridor
- Highway underpass

These spaces create unsettling atmosphere through:
- Repetitive architecture
- Harsh fluorescent lighting
- Empty, abandoned feel
- Earthquake damage

Usage:
    blender --background --python tools/blender/create_liminal_spaces.py

Output:
    assets/models/liminal/*.fbx
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


def create_mall_section():
    """
    Create an abandoned mall section.
    Features: tile floor, glass storefronts, benches, fluorescent lights.
    """
    clear_scene()
    parts = []

    width = 20
    depth = 15
    height = 6

    # Floor - polished tile
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, 0.01),
        scale=(width, depth, 1)
    )
    floor = bpy.context.active_object
    floor.name = "MallFloor"
    floor_mat = create_material("MallTile", (0.78, 0.76, 0.74, 1.0))
    floor.data.materials.append(floor_mat)
    parts.append(floor)

    # Walls
    wall_mat = create_material("MallWall", (0.85, 0.82, 0.8, 1.0))

    for i, (pos, scale) in enumerate([
        ((0, -depth / 2, height / 2), (width, 0.2, height)),  # Back
        ((-width / 2, 0, height / 2), (0.2, depth, height)),  # Left
        ((width / 2, 0, height / 2), (0.2, depth, height)),   # Right
    ]):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=pos,
            scale=scale
        )
        wall = bpy.context.active_object
        wall.name = f"MallWall_{i}"
        wall.data.materials.append(wall_mat)
        parts.append(wall)

    # Ceiling with light fixtures
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, height),
        scale=(width, depth, 1)
    )
    ceiling = bpy.context.active_object
    ceiling.name = "MallCeiling"
    ceiling.rotation_euler.x = math.pi
    ceiling_mat = create_material("MallCeiling", (0.9, 0.88, 0.86, 1.0))
    ceiling.data.materials.append(ceiling_mat)
    parts.append(ceiling)

    # Fluorescent light fixtures
    light_mat = create_material("FluorescentLight", (1.0, 0.98, 0.95, 1.0))

    for i in range(3):
        y = -depth / 2 + 3 + i * 5
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, y, height - 0.1),
            scale=(6, 0.3, 0.1)
        )
        light = bpy.context.active_object
        light.name = f"LightFixture_{i}"
        light.data.materials.append(light_mat)
        parts.append(light)

    # Glass storefront panels
    glass_mat = create_material("StoreGlass", (0.7, 0.8, 0.9, 0.3))

    for i in range(2):
        x = -width / 2 + 3 + i * 8
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x, -depth / 2 + 0.5, 2.5),
            scale=(5, 0.1, 4)
        )
        glass = bpy.context.active_object
        glass.name = f"Storefront_{i}"
        glass.data.materials.append(glass_mat)
        parts.append(glass)

    # Mall bench
    bench_mat = create_material("MallBench", (0.4, 0.4, 0.42, 1.0))
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 2, 0.4),
        scale=(4, 1, 0.8)
    )
    bench = bpy.context.active_object
    bench.name = "MallBench"
    bench.data.materials.append(bench_mat)
    parts.append(bench)

    model = join_objects(parts, "AbandonedMall")
    set_origin_to_bottom(model)
    return model


def create_hotel_lobby():
    """
    Create a hotel lobby.
    Features: front desk, chandelier, luggage, grand but empty.
    """
    clear_scene()
    parts = []

    width = 12
    depth = 16
    height = 8

    # Floor - carpet
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, 0.01),
        scale=(width, depth, 1)
    )
    floor = bpy.context.active_object
    floor.name = "LobbyFloor"
    floor_mat = create_material("HotelCarpet", (0.4, 0.25, 0.25, 1.0))
    floor.data.materials.append(floor_mat)
    parts.append(floor)

    # Walls
    wall_mat = create_material("HotelWall", (0.9, 0.85, 0.75, 1.0))

    for i, (pos, scale) in enumerate([
        ((0, -depth / 2, height / 2), (width, 0.3, height)),
        ((-width / 2, 0, height / 2), (0.3, depth, height)),
        ((width / 2, 0, height / 2), (0.3, depth, height)),
    ]):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=pos,
            scale=scale
        )
        wall = bpy.context.active_object
        wall.name = f"LobbyWall_{i}"
        wall.data.materials.append(wall_mat)
        parts.append(wall)

    # Ceiling
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, height),
        scale=(width, depth, 1)
    )
    ceiling = bpy.context.active_object
    ceiling.name = "LobbyCeiling"
    ceiling.rotation_euler.x = math.pi
    ceiling_mat = create_material("HotelCeiling", (0.95, 0.92, 0.88, 1.0))
    ceiling.data.materials.append(ceiling_mat)
    parts.append(ceiling)

    # Front desk
    desk_mat = create_material("FrontDesk", (0.3, 0.2, 0.12, 1.0))
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, -depth / 2 + 2, 0.9),
        scale=(6, 1.5, 1.8)
    )
    desk = bpy.context.active_object
    desk.name = "FrontDesk"
    desk.data.materials.append(desk_mat)
    parts.append(desk)

    # Chandelier
    chandelier_mat = create_material("Chandelier", (0.95, 0.9, 0.75, 1.0))
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=1.2,
        location=(0, 0, height - 2)
    )
    chandelier = bpy.context.active_object
    chandelier.name = "Chandelier"
    chandelier.scale = (1, 1, 0.6)
    bpy.ops.object.transform_apply(scale=True)
    chandelier.data.materials.append(chandelier_mat)
    parts.append(chandelier)

    # Abandoned luggage
    luggage_colors = [
        (0.35, 0.25, 0.2, 1.0),
        (0.25, 0.3, 0.35, 1.0),
        (0.4, 0.2, 0.2, 1.0),
    ]

    for i in range(3):
        luggage_mat = create_material(f"Luggage_{i}", luggage_colors[i])
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(
                -2 + i * 2 + random.random(),
                depth / 2 - 3 + random.random() * 2,
                0.4
            ),
            scale=(0.6, 0.35, 0.8)
        )
        luggage = bpy.context.active_object
        luggage.name = f"Luggage_{i}"
        luggage.rotation_euler.z = random.random() * 0.5
        luggage.data.materials.append(luggage_mat)
        parts.append(luggage)

    model = join_objects(parts, "HotelLobby")
    set_origin_to_bottom(model)
    return model


def create_school_room():
    """
    Create an abandoned school classroom.
    Features: desks in rows, chalkboard, clock stopped.
    """
    clear_scene()
    parts = []

    width = 12
    depth = 10
    height = 4

    # Floor
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, 0.01),
        scale=(width, depth, 1)
    )
    floor = bpy.context.active_object
    floor.name = "SchoolFloor"
    floor_mat = create_material("SchoolTile", (0.7, 0.68, 0.65, 1.0))
    floor.data.materials.append(floor_mat)
    parts.append(floor)

    # Walls
    wall_mat = create_material("SchoolWall", (0.85, 0.8, 0.75, 1.0))

    for i, (pos, scale) in enumerate([
        ((0, -depth / 2, height / 2), (width, 0.2, height)),
        ((-width / 2, 0, height / 2), (0.2, depth, height)),
        ((width / 2, 0, height / 2), (0.2, depth, height)),
        ((0, depth / 2, height / 2), (width, 0.2, height)),
    ]):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=pos,
            scale=scale
        )
        wall = bpy.context.active_object
        wall.name = f"SchoolWall_{i}"
        wall.data.materials.append(wall_mat)
        parts.append(wall)

    # Ceiling
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, height),
        scale=(width, depth, 1)
    )
    ceiling = bpy.context.active_object
    ceiling.name = "SchoolCeiling"
    ceiling.rotation_euler.x = math.pi
    ceiling_mat = create_material("SchoolCeiling", (0.92, 0.9, 0.88, 1.0))
    ceiling.data.materials.append(ceiling_mat)
    parts.append(ceiling)

    # Chalkboard
    board_mat = create_material("Chalkboard", (0.12, 0.18, 0.12, 1.0))
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, -depth / 2 + 0.15, 2),
        scale=(6, 0.1, 2)
    )
    board = bpy.context.active_object
    board.name = "Chalkboard"
    board.data.materials.append(board_mat)
    parts.append(board)

    # Student desks
    desk_mat = create_material("StudentDesk", (0.7, 0.6, 0.45, 1.0))

    rows = 3
    cols = 4
    for r in range(rows):
        for c in range(cols):
            bpy.ops.mesh.primitive_cube_add(
                size=1,
                location=(
                    -width / 2 + 2 + c * 2.5,
                    -depth / 2 + 3 + r * 2.5,
                    0.6
                ),
                scale=(1.2, 0.8, 0.05)
            )
            desk = bpy.context.active_object
            desk.name = f"Desk_{r}_{c}"
            desk.data.materials.append(desk_mat)
            parts.append(desk)

            # Desk legs
            for lx, ly in [(-0.5, -0.3), (0.5, -0.3), (-0.5, 0.3), (0.5, 0.3)]:
                bpy.ops.mesh.primitive_cylinder_add(
                    radius=0.03,
                    depth=0.6,
                    location=(
                        -width / 2 + 2 + c * 2.5 + lx,
                        -depth / 2 + 3 + r * 2.5 + ly,
                        0.3
                    )
                )
                leg = bpy.context.active_object
                leg.name = f"DeskLeg_{r}_{c}"
                leg.data.materials.append(desk_mat)
                parts.append(leg)

    # Clock
    clock_mat = create_material("Clock", (0.9, 0.88, 0.85, 1.0))
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.4,
        depth=0.1,
        location=(width / 2 - 1, -depth / 2 + 0.1, height - 0.5),
        rotation=(math.pi / 2, 0, 0)
    )
    clock = bpy.context.active_object
    clock.name = "Clock"
    clock.data.materials.append(clock_mat)
    parts.append(clock)

    model = join_objects(parts, "AbandonedSchool")
    set_origin_to_bottom(model)
    return model


def create_hospital_corridor():
    """
    Create a hospital corridor.
    Features: gurney, equipment, flickering lights feel.
    """
    clear_scene()
    parts = []

    width = 6
    depth = 18
    height = 4

    # Floor
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, 0.01),
        scale=(width, depth, 1)
    )
    floor = bpy.context.active_object
    floor.name = "HospitalFloor"
    floor_mat = create_material("HospitalTile", (0.85, 0.82, 0.8, 1.0))
    floor.data.materials.append(floor_mat)
    parts.append(floor)

    # Walls - greenish hospital tint
    wall_mat = create_material("HospitalWall", (0.8, 0.85, 0.8, 1.0))

    for i, (pos, scale) in enumerate([
        ((-width / 2, 0, height / 2), (0.2, depth, height)),
        ((width / 2, 0, height / 2), (0.2, depth, height)),
    ]):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=pos,
            scale=scale
        )
        wall = bpy.context.active_object
        wall.name = f"HospitalWall_{i}"
        wall.data.materials.append(wall_mat)
        parts.append(wall)

    # Ceiling with lights
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, height),
        scale=(width, depth, 1)
    )
    ceiling = bpy.context.active_object
    ceiling.name = "HospitalCeiling"
    ceiling.rotation_euler.x = math.pi
    ceiling_mat = create_material("HospitalCeiling", (0.9, 0.92, 0.9, 1.0))
    ceiling.data.materials.append(ceiling_mat)
    parts.append(ceiling)

    # Fluorescent lights
    light_mat = create_material("HospitalLight", (1.0, 1.0, 0.98, 1.0))

    for i in range(5):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, -depth / 2 + 2 + i * 4, height - 0.05),
            scale=(4, 0.4, 0.1)
        )
        light = bpy.context.active_object
        light.name = f"HospitalLight_{i}"
        light.data.materials.append(light_mat)
        parts.append(light)

    # Gurney
    gurney_mat = create_material("Gurney", (0.85, 0.85, 0.85, 1.0))
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(1, 2, 0.6),
        scale=(1.2, 2.5, 0.1)
    )
    gurney = bpy.context.active_object
    gurney.name = "GurneyTop"
    gurney.rotation_euler.z = 0.1
    gurney.data.materials.append(gurney_mat)
    parts.append(gurney)

    # Gurney legs
    for lx, ly in [(-0.5, -1), (0.5, -1), (-0.5, 1), (0.5, 1)]:
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.04,
            depth=0.5,
            location=(1 + lx, 2 + ly, 0.25)
        )
        leg = bpy.context.active_object
        leg.name = "GurneyLeg"
        leg.data.materials.append(gurney_mat)
        parts.append(leg)

    # Medical monitor
    monitor_mat = create_material("Monitor", (0.2, 0.2, 0.22, 1.0))
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(-width / 2 + 0.5, -4, 1.8),
        scale=(0.1, 0.5, 0.6)
    )
    monitor = bpy.context.active_object
    monitor.name = "Monitor"
    monitor.data.materials.append(monitor_mat)
    parts.append(monitor)

    # IV stand
    iv_mat = create_material("IVStand", (0.7, 0.7, 0.72, 1.0))
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.03,
        depth=2,
        location=(-1, 3, 1)
    )
    iv = bpy.context.active_object
    iv.name = "IVStand"
    iv.data.materials.append(iv_mat)
    parts.append(iv)

    model = join_objects(parts, "Hospital")
    set_origin_to_bottom(model)
    return model


def create_highway_underpass():
    """
    Create a highway underpass.
    Features: support pillars, orange sodium lighting, graffiti.
    """
    clear_scene()
    parts = []

    width = 10
    depth = 20
    height = 5

    # Ground
    bpy.ops.mesh.primitive_plane_add(
        size=1,
        location=(0, 0, 0.01),
        scale=(width, depth, 1)
    )
    ground = bpy.context.active_object
    ground.name = "UnderpassGround"
    ground_mat = create_material("AsphaltGround", (0.2, 0.2, 0.22, 1.0))
    ground.data.materials.append(ground_mat)
    parts.append(ground)

    # Overpass structure (ceiling)
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, height + 0.5),
        scale=(width + 2, depth + 2, 1)
    )
    ceiling = bpy.context.active_object
    ceiling.name = "UnderpassCeiling"
    ceiling_mat = create_material("ConcreteCeiling", (0.45, 0.45, 0.47, 1.0))
    ceiling.data.materials.append(ceiling_mat)
    parts.append(ceiling)

    # Support pillars
    pillar_mat = create_material("ConcretePillar", (0.5, 0.5, 0.52, 1.0))

    for i in range(3):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, -depth / 2 + 3 + i * 7, height / 2),
            scale=(1.5, 1.5, height)
        )
        pillar = bpy.context.active_object
        pillar.name = f"Pillar_{i}"
        pillar.data.materials.append(pillar_mat)
        parts.append(pillar)

    # Graffiti sections (colored rectangles on pillars)
    graffiti_colors = [
        (0.8, 0.2, 0.3, 1.0),
        (0.2, 0.6, 0.8, 1.0),
        (0.9, 0.7, 0.1, 1.0),
    ]

    for i, color in enumerate(graffiti_colors):
        graffiti_mat = create_material(f"Graffiti_{i}", color)
        bpy.ops.mesh.primitive_plane_add(
            size=1,
            location=(
                0.76,
                -depth / 2 + 3 + i * 7,
                2
            ),
            scale=(0.7, 2, 1)
        )
        graffiti = bpy.context.active_object
        graffiti.name = f"Graffiti_{i}"
        graffiti.rotation_euler.y = math.pi / 2
        graffiti.data.materials.append(graffiti_mat)
        parts.append(graffiti)

    # Sodium light fixtures (orange glow)
    light_mat = create_material("SodiumLight", (1.0, 0.7, 0.4, 1.0))

    for i in range(3):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.15,
            depth=0.3,
            location=(3, -depth / 2 + 5 + i * 6, height - 0.2),
            rotation=(math.pi / 2, 0, 0)
        )
        light = bpy.context.active_object
        light.name = f"SodiumLight_{i}"
        light.data.materials.append(light_mat)
        parts.append(light)

    # Abandoned camp
    tent_mat = create_material("Tent", (0.3, 0.35, 0.3, 1.0))
    bpy.ops.mesh.primitive_cone_add(
        radius1=1.5,
        depth=1.5,
        location=(-3, 5, 0.75)
    )
    tent = bpy.context.active_object
    tent.name = "AbandonedTent"
    tent.data.materials.append(tent_mat)
    parts.append(tent)

    model = join_objects(parts, "HighwayUnderpass")
    set_origin_to_bottom(model)
    return model


def main():
    """Generate all liminal space assets."""
    print("=" * 50)
    print("Faultline Fear: Liminal Space Generator")
    print("=" * 50)

    output_dir = create_export_directory("assets/models/liminal")
    setup_fbx_export()

    # Generate models
    models = [
        ("AbandonedMall", create_mall_section),
        ("HotelLobby", create_hotel_lobby),
        ("AbandonedSchool", create_school_room),
        ("Hospital", create_hospital_corridor),
        ("HighwayUnderpass", create_highway_underpass),
    ]

    for name, create_func in models:
        print(f"\nCreating {name}...")
        model = create_func()

        filepath = os.path.join(output_dir, f"{name}.fbx")
        export_model(model, filepath)
        print(f"  Exported: {filepath}")

    print("\n" + "=" * 50)
    print(f"Generated {len(models)} liminal space assets")
    print("=" * 50)


if __name__ == "__main__":
    main()
