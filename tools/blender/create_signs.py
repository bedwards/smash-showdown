#!/usr/bin/env python3
"""
Faultline Fear: Sign Asset Generator

Creates sign-related assets:
- Directional sign post
- Warning sign post
- Story plaque
- Objective marker post

Usage:
    blender --background --python tools/blender/create_signs.py

Output:
    assets/models/signs/*.fbx
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


def create_directional_sign():
    """
    Create a highway-style directional sign.
    Green background, white text area, single post.
    """
    clear_scene()
    parts = []

    # Sign board
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 6),
        scale=(4, 0.15, 1.5)
    )
    board = bpy.context.active_object
    board.name = "SignBoard"
    board_mat = create_material("DirectionalBoard", (0.0, 0.4, 0.2, 1.0))
    board.data.materials.append(board_mat)
    parts.append(board)

    # Post
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.15,
        depth=5,
        location=(0, 0, 2.5)
    )
    post = bpy.context.active_object
    post.name = "Post"
    post_mat = create_material("MetalPost", (0.3, 0.3, 0.32, 1.0))
    post.data.materials.append(post_mat)
    parts.append(post)

    # Base plate
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.4,
        depth=0.1,
        location=(0, 0, 0.05)
    )
    base = bpy.context.active_object
    base.name = "Base"
    base.data.materials.append(post_mat)
    parts.append(base)

    model = join_objects(parts, "DirectionalSign")
    set_origin_to_bottom(model)
    return model


def create_warning_sign():
    """
    Create a diamond-shaped warning sign.
    Yellow background, black border.
    """
    clear_scene()
    parts = []

    # Diamond sign (rotated square)
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 5),
        scale=(2, 0.1, 2)
    )
    board = bpy.context.active_object
    board.name = "WarnBoard"
    board.rotation_euler.y = math.pi / 4  # 45 degree rotation for diamond
    bpy.ops.object.transform_apply(rotation=True)
    board_mat = create_material("WarningYellow", (1.0, 0.8, 0.0, 1.0))
    board.data.materials.append(board_mat)
    parts.append(board)

    # Post
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 2),
        scale=(0.2, 0.2, 4)
    )
    post = bpy.context.active_object
    post.name = "Post"
    post_mat = create_material("WarnPost", (0.25, 0.25, 0.27, 1.0))
    post.data.materials.append(post_mat)
    parts.append(post)

    model = join_objects(parts, "WarningSign")
    set_origin_to_bottom(model)
    return model


def create_story_plaque():
    """
    Create a historical/story plaque on a stone base.
    Weathered wood appearance.
    """
    clear_scene()
    parts = []

    # Plaque board (wooden)
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 3.5),
        scale=(3.5, 0.2, 2.5)
    )
    board = bpy.context.active_object
    board.name = "PlaqueBoard"
    board_mat = create_material("WoodPlaque", (0.3, 0.2, 0.12, 1.0))
    board.data.materials.append(board_mat)
    parts.append(board)

    # Frame around plaque
    frame_mat = create_material("WoodFrame", (0.4, 0.25, 0.15, 1.0))

    # Top frame
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, -0.15, 4.8),
        scale=(3.7, 0.12, 0.15)
    )
    frame_top = bpy.context.active_object
    frame_top.name = "FrameTop"
    frame_top.data.materials.append(frame_mat)
    parts.append(frame_top)

    # Bottom frame
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, -0.15, 2.2),
        scale=(3.7, 0.12, 0.15)
    )
    frame_bottom = bpy.context.active_object
    frame_bottom.name = "FrameBottom"
    frame_bottom.data.materials.append(frame_mat)
    parts.append(frame_bottom)

    # Posts (two)
    post_mat = create_material("WoodPost", (0.35, 0.22, 0.12, 1.0))

    for x in [-1.3, 1.3]:
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x, 0, 1.75),
            scale=(0.2, 0.2, 3.5)
        )
        post = bpy.context.active_object
        post.name = "Post"
        post.data.materials.append(post_mat)
        parts.append(post)

    # Stone base
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 0.15),
        scale=(3.8, 0.8, 0.3)
    )
    base = bpy.context.active_object
    base.name = "StoneBase"
    base_mat = create_material("Stone", (0.5, 0.48, 0.45, 1.0))
    base.data.materials.append(base_mat)
    parts.append(base)

    model = join_objects(parts, "StoryPlaque")
    set_origin_to_bottom(model)
    return model


def create_objective_marker():
    """
    Create an objective/checkpoint marker.
    Tall post with flag-like sign.
    """
    clear_scene()
    parts = []

    # Main post (tall)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.12,
        depth=7,
        location=(0, 0, 3.5)
    )
    post = bpy.context.active_object
    post.name = "MainPost"
    post_mat = create_material("BlueMetal", (0.2, 0.3, 0.5, 1.0))
    post.data.materials.append(post_mat)
    parts.append(post)

    # Sign board (flag-style, extends to side)
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(1.5, 0, 6),
        scale=(3, 0.15, 2)
    )
    board = bpy.context.active_object
    board.name = "FlagBoard"
    board_mat = create_material("BlueBoard", (0.0, 0.3, 0.6, 1.0))
    board.data.materials.append(board_mat)
    parts.append(board)

    # Gold accent stripe
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(1.5, -0.08, 6),
        scale=(3.1, 0.02, 0.3)
    )
    stripe = bpy.context.active_object
    stripe.name = "GoldStripe"
    stripe_mat = create_material("GoldAccent", (1.0, 0.8, 0.2, 1.0))
    stripe.data.materials.append(stripe_mat)
    parts.append(stripe)

    # Top cap
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.2,
        location=(0, 0, 7.1)
    )
    cap = bpy.context.active_object
    cap.name = "TopCap"
    cap.data.materials.append(stripe_mat)
    parts.append(cap)

    # Base
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.5,
        depth=0.15,
        location=(0, 0, 0.075)
    )
    base = bpy.context.active_object
    base.name = "Base"
    base.data.materials.append(post_mat)
    parts.append(base)

    model = join_objects(parts, "ObjectiveMarker")
    set_origin_to_bottom(model)
    return model


def create_road_sign():
    """
    Create a simple road sign (rectangular).
    """
    clear_scene()
    parts = []

    # Sign board
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 5),
        scale=(4, 0.1, 2)
    )
    board = bpy.context.active_object
    board.name = "RoadBoard"
    board_mat = create_material("WhiteBoard", (0.95, 0.95, 0.95, 1.0))
    board.data.materials.append(board_mat)
    parts.append(board)

    # Border frame
    frame_mat = create_material("GreenBorder", (0.0, 0.35, 0.15, 1.0))

    # All four sides of frame
    for pos, scale in [
        ((0, -0.06, 6.05), (4.2, 0.02, 0.15)),  # Top
        ((0, -0.06, 3.95), (4.2, 0.02, 0.15)),  # Bottom
        ((-2.05, -0.06, 5), (0.15, 0.02, 2.2)), # Left
        ((2.05, -0.06, 5), (0.15, 0.02, 2.2)),  # Right
    ]:
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=pos,
            scale=scale
        )
        frame = bpy.context.active_object
        frame.name = "Frame"
        frame.data.materials.append(frame_mat)
        parts.append(frame)

    # Posts (two)
    post_mat = create_material("GrayPost", (0.4, 0.4, 0.42, 1.0))

    for x in [-1.5, 1.5]:
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x, 0, 2),
            scale=(0.15, 0.15, 4)
        )
        post = bpy.context.active_object
        post.name = "Post"
        post.data.materials.append(post_mat)
        parts.append(post)

    model = join_objects(parts, "RoadSign")
    set_origin_to_bottom(model)
    return model


def main():
    """Generate all sign assets."""
    print("=" * 50)
    print("Faultline Fear: Sign Asset Generator")
    print("=" * 50)

    output_dir = create_export_directory("assets/models/signs")
    setup_fbx_export()

    # Generate models
    models = [
        ("DirectionalSign", create_directional_sign),
        ("WarningSign", create_warning_sign),
        ("StoryPlaque", create_story_plaque),
        ("ObjectiveMarker", create_objective_marker),
        ("RoadSign", create_road_sign),
    ]

    for name, create_func in models:
        print(f"\nCreating {name}...")
        model = create_func()

        filepath = os.path.join(output_dir, f"{name}.fbx")
        export_model(model, filepath)
        print(f"  Exported: {filepath}")

    print("\n" + "=" * 50)
    print(f"Generated {len(models)} sign assets")
    print("=" * 50)


if __name__ == "__main__":
    main()
