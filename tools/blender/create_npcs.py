#!/usr/bin/env python3
"""
Faultline Fear: NPC Model Generator

Creates NPC models for the game:
- PetCompanion: Small dog-like companion that follows player
- Survivor: Generic human survivor model

Usage:
    blender --background --python tools/blender/create_npcs.py

Output:
    assets/models/npcs/PetCompanion.fbx
    assets/models/npcs/Survivor.fbx
"""

import bpy
import os
import sys

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


def create_pet_companion():
    """
    Create a cute dog-like companion.
    Small, friendly, with expressive features.
    """
    clear_scene()
    parts = []

    # Body (elongated sphere)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.4,
        location=(0, 0, 0.4),
        scale=(1.2, 0.7, 0.7)
    )
    body = bpy.context.active_object
    body.name = "Body"
    bpy.ops.object.shade_smooth()
    parts.append(body)

    # Create body material (tan/golden)
    body_mat = create_material("PetBody", (0.7, 0.55, 0.35, 1.0))
    body.data.materials.append(body_mat)

    # Head (sphere, larger than body proportionally for cute look)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.3,
        location=(0.45, 0, 0.5)
    )
    head = bpy.context.active_object
    head.name = "Head"
    bpy.ops.object.shade_smooth()
    head.data.materials.append(body_mat)
    parts.append(head)

    # Snout (small cone)
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.12,
        radius2=0.05,
        depth=0.2,
        location=(0.65, 0, 0.45),
        rotation=(0, 1.57, 0)  # Point forward
    )
    snout = bpy.context.active_object
    snout.name = "Snout"
    bpy.ops.object.shade_smooth()
    snout.data.materials.append(body_mat)
    parts.append(snout)

    # Nose (small black sphere)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.05,
        location=(0.75, 0, 0.45)
    )
    nose = bpy.context.active_object
    nose.name = "Nose"
    bpy.ops.object.shade_smooth()
    nose_mat = create_material("PetNose", (0.1, 0.08, 0.08, 1.0))
    nose.data.materials.append(nose_mat)
    parts.append(nose)

    # Eyes (two black spheres)
    eye_mat = create_material("PetEyes", (0.1, 0.1, 0.1, 1.0))
    for z_offset in [0.08, -0.08]:
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.06,
            location=(0.6, z_offset, 0.58)
        )
        eye = bpy.context.active_object
        eye.name = f"Eye_{z_offset}"
        bpy.ops.object.shade_smooth()
        eye.data.materials.append(eye_mat)
        parts.append(eye)

    # Ears (two triangular shapes)
    ear_mat = create_material("PetEars", (0.6, 0.45, 0.3, 1.0))
    for z_offset, z_rot in [(0.15, 0.3), (-0.15, -0.3)]:
        bpy.ops.mesh.primitive_cone_add(
            radius1=0.08,
            radius2=0.02,
            depth=0.2,
            location=(0.35, z_offset, 0.75),
            rotation=(0.3, 0, z_rot)
        )
        ear = bpy.context.active_object
        ear.name = f"Ear_{z_offset}"
        bpy.ops.object.shade_smooth()
        ear.data.materials.append(ear_mat)
        parts.append(ear)

    # Legs (4 cylinders)
    leg_positions = [
        (0.2, 0.15, 0.15),   # Front right
        (0.2, -0.15, 0.15),  # Front left
        (-0.2, 0.15, 0.15),  # Back right
        (-0.2, -0.15, 0.15), # Back left
    ]
    for i, pos in enumerate(leg_positions):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.06,
            depth=0.3,
            location=pos
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{i}"
        bpy.ops.object.shade_smooth()
        leg.data.materials.append(body_mat)
        parts.append(leg)

    # Tail (curved cylinder approximation)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.04,
        depth=0.3,
        location=(-0.45, 0, 0.55),
        rotation=(0, 0.8, 0)  # Angle up and back
    )
    tail = bpy.context.active_object
    tail.name = "Tail"
    bpy.ops.object.shade_smooth()
    tail.data.materials.append(body_mat)
    parts.append(tail)

    # Join all parts
    model = join_objects(parts, "PetCompanion")
    set_origin_to_bottom(model)

    return model


def create_survivor():
    """
    Create a simple humanoid survivor NPC.
    Basic human proportions with clothing colors.
    """
    clear_scene()
    parts = []

    # Body/Torso
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 1.1),
        scale=(0.4, 0.25, 0.5)
    )
    torso = bpy.context.active_object
    torso.name = "Torso"
    parts.append(torso)

    # Shirt material (varied colors possible)
    shirt_mat = create_material("SurvivorShirt", (0.3, 0.4, 0.5, 1.0))
    torso.data.materials.append(shirt_mat)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.2,
        location=(0, 0, 1.65)
    )
    head = bpy.context.active_object
    head.name = "Head"
    bpy.ops.object.shade_smooth()
    skin_mat = create_material("SurvivorSkin", (0.8, 0.65, 0.5, 1.0))
    head.data.materials.append(skin_mat)
    parts.append(head)

    # Legs (pants)
    pants_mat = create_material("SurvivorPants", (0.2, 0.2, 0.25, 1.0))
    for z_offset in [0.12, -0.12]:
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.1,
            depth=0.7,
            location=(0, z_offset, 0.35)
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{z_offset}"
        leg.data.materials.append(pants_mat)
        parts.append(leg)

    # Arms
    for z_offset, z_rot in [(0.35, 0.2), (-0.35, -0.2)]:
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.06,
            depth=0.5,
            location=(0, z_offset, 1.0),
            rotation=(0, 0, z_rot)
        )
        arm = bpy.context.active_object
        arm.name = f"Arm_{z_offset}"
        arm.data.materials.append(shirt_mat)
        parts.append(arm)

    # Hands
    for z_offset in [0.45, -0.45]:
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.06,
            location=(0, z_offset, 0.75)
        )
        hand = bpy.context.active_object
        hand.name = f"Hand_{z_offset}"
        bpy.ops.object.shade_smooth()
        hand.data.materials.append(skin_mat)
        parts.append(hand)

    # Feet
    shoes_mat = create_material("SurvivorShoes", (0.15, 0.12, 0.1, 1.0))
    for z_offset in [0.12, -0.12]:
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0.05, z_offset, 0.05),
            scale=(0.15, 0.08, 0.05)
        )
        foot = bpy.context.active_object
        foot.name = f"Foot_{z_offset}"
        foot.data.materials.append(shoes_mat)
        parts.append(foot)

    # Join all parts
    model = join_objects(parts, "Survivor")
    set_origin_to_bottom(model)

    return model


def main():
    """Generate all NPC models."""
    print("=" * 50)
    print("Faultline Fear: NPC Model Generator")
    print("=" * 50)

    output_dir = create_export_directory("assets/models/npcs")
    setup_fbx_export()

    # Generate models
    models = [
        ("PetCompanion", create_pet_companion),
        ("Survivor", create_survivor),
    ]

    for name, create_func in models:
        print(f"\nCreating {name}...")
        model = create_func()

        filepath = os.path.join(output_dir, f"{name}.fbx")
        export_model(model, filepath)
        print(f"  Exported: {filepath}")

    print("\n" + "=" * 50)
    print(f"Generated {len(models)} NPC models")
    print("=" * 50)


if __name__ == "__main__":
    main()
