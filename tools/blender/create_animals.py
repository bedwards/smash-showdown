#!/usr/bin/env python3
"""
Faultline Fear: Animal Model Generator

Creates wildlife animal models:
- Day animals (passive): Deer, Bird, Rabbit, Fish
- Night predators (hostile): Wolf, Coyote, MountainLion

Usage:
    blender --background --python tools/blender/create_animals.py

Output:
    assets/models/animals/*.fbx
"""

import bpy
import os
import sys
import math

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


def create_deer():
    """Create a deer model - graceful quadruped."""
    clear_scene()
    parts = []

    # Body
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.5,
        location=(0, 0, 0.8),
        scale=(1.5, 0.6, 0.8)
    )
    body = bpy.context.active_object
    body.name = "Body"
    bpy.ops.object.shade_smooth()
    parts.append(body)

    body_mat = create_material("DeerBody", (0.55, 0.4, 0.28, 1.0))
    body.data.materials.append(body_mat)

    # Neck
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.15,
        depth=0.6,
        location=(0.5, 0, 1.1),
        rotation=(0, -0.5, 0)
    )
    neck = bpy.context.active_object
    neck.name = "Neck"
    neck.data.materials.append(body_mat)
    parts.append(neck)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.2,
        location=(0.75, 0, 1.35),
        scale=(1.3, 0.8, 1)
    )
    head = bpy.context.active_object
    head.name = "Head"
    bpy.ops.object.shade_smooth()
    head.data.materials.append(body_mat)
    parts.append(head)

    # Snout
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.1,
        radius2=0.05,
        depth=0.2,
        location=(0.9, 0, 1.3),
        rotation=(0, 1.57, 0)
    )
    snout = bpy.context.active_object
    snout.name = "Snout"
    snout.data.materials.append(body_mat)
    parts.append(snout)

    # Ears
    ear_mat = create_material("DeerEars", (0.5, 0.35, 0.25, 1.0))
    for z_off in [0.1, -0.1]:
        bpy.ops.mesh.primitive_cone_add(
            radius1=0.06,
            radius2=0.02,
            depth=0.15,
            location=(0.65, z_off, 1.5),
            rotation=(0.3, 0, 0 if z_off > 0 else 0)
        )
        ear = bpy.context.active_object
        ear.name = f"Ear_{z_off}"
        ear.data.materials.append(ear_mat)
        parts.append(ear)

    # Legs (4)
    leg_mat = create_material("DeerLegs", (0.45, 0.32, 0.22, 1.0))
    leg_positions = [
        (0.35, 0.15, 0.35),
        (0.35, -0.15, 0.35),
        (-0.35, 0.15, 0.35),
        (-0.35, -0.15, 0.35),
    ]
    for i, pos in enumerate(leg_positions):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.05,
            depth=0.7,
            location=pos
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{i}"
        leg.data.materials.append(leg_mat)
        parts.append(leg)

    # Tail (small)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.08,
        location=(-0.7, 0, 0.9)
    )
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail_mat = create_material("DeerTail", (1, 1, 0.9, 1.0))
    tail.data.materials.append(tail_mat)
    parts.append(tail)

    model = join_objects(parts, "Deer")
    set_origin_to_bottom(model)
    return model


def create_bird():
    """Create a small bird model."""
    clear_scene()
    parts = []

    # Body
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.1,
        location=(0, 0, 0.1),
        scale=(1.2, 0.8, 0.8)
    )
    body = bpy.context.active_object
    body.name = "Body"
    bpy.ops.object.shade_smooth()
    parts.append(body)

    body_mat = create_material("BirdBody", (0.4, 0.45, 0.5, 1.0))
    body.data.materials.append(body_mat)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.06,
        location=(0.1, 0, 0.15)
    )
    head = bpy.context.active_object
    head.name = "Head"
    bpy.ops.object.shade_smooth()
    head.data.materials.append(body_mat)
    parts.append(head)

    # Beak
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.02,
        radius2=0.005,
        depth=0.06,
        location=(0.16, 0, 0.14),
        rotation=(0, 1.57, 0)
    )
    beak = bpy.context.active_object
    beak.name = "Beak"
    beak_mat = create_material("BirdBeak", (0.9, 0.7, 0.3, 1.0))
    beak.data.materials.append(beak_mat)
    parts.append(beak)

    # Wings
    wing_mat = create_material("BirdWings", (0.35, 0.4, 0.45, 1.0))
    for z_off in [0.05, -0.05]:
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, z_off * 2, 0.12),
            scale=(0.08, 0.12, 0.02)
        )
        wing = bpy.context.active_object
        wing.name = f"Wing_{z_off}"
        wing.data.materials.append(wing_mat)
        parts.append(wing)

    # Tail feathers
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(-0.12, 0, 0.1),
        scale=(0.06, 0.04, 0.01)
    )
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail.data.materials.append(body_mat)
    parts.append(tail)

    model = join_objects(parts, "Bird")
    set_origin_to_bottom(model)
    return model


def create_rabbit():
    """Create a rabbit model."""
    clear_scene()
    parts = []

    # Body
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.15,
        location=(0, 0, 0.15),
        scale=(1.3, 0.9, 0.9)
    )
    body = bpy.context.active_object
    body.name = "Body"
    bpy.ops.object.shade_smooth()
    parts.append(body)

    body_mat = create_material("RabbitBody", (0.7, 0.65, 0.55, 1.0))
    body.data.materials.append(body_mat)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.1,
        location=(0.18, 0, 0.2)
    )
    head = bpy.context.active_object
    head.name = "Head"
    bpy.ops.object.shade_smooth()
    head.data.materials.append(body_mat)
    parts.append(head)

    # Ears (long)
    ear_mat = create_material("RabbitEars", (0.75, 0.6, 0.5, 1.0))
    for z_off in [0.04, -0.04]:
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.02,
            depth=0.15,
            location=(0.15, z_off, 0.35),
            rotation=(0.2, 0, 0 if z_off > 0 else 0)
        )
        ear = bpy.context.active_object
        ear.name = f"Ear_{z_off}"
        ear.data.materials.append(ear_mat)
        parts.append(ear)

    # Nose
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.02,
        location=(0.27, 0, 0.2)
    )
    nose = bpy.context.active_object
    nose.name = "Nose"
    nose_mat = create_material("RabbitNose", (0.9, 0.6, 0.6, 1.0))
    nose.data.materials.append(nose_mat)
    parts.append(nose)

    # Tail (fluffy ball)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.05,
        location=(-0.18, 0, 0.15)
    )
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail_mat = create_material("RabbitTail", (0.95, 0.95, 0.9, 1.0))
    tail.data.materials.append(tail_mat)
    parts.append(tail)

    # Legs
    for i, pos in enumerate([(0.08, 0.05, 0.05), (0.08, -0.05, 0.05),
                              (-0.08, 0.06, 0.06), (-0.08, -0.06, 0.06)]):
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.04 if i < 2 else 0.05,
            location=pos
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{i}"
        leg.data.materials.append(body_mat)
        parts.append(leg)

    model = join_objects(parts, "Rabbit")
    set_origin_to_bottom(model)
    return model


def create_fish():
    """Create a simple fish model."""
    clear_scene()
    parts = []

    # Body
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.1,
        location=(0, 0, 0),
        scale=(2, 0.5, 0.8)
    )
    body = bpy.context.active_object
    body.name = "Body"
    bpy.ops.object.shade_smooth()
    parts.append(body)

    body_mat = create_material("FishBody", (0.4, 0.6, 0.7, 1.0))
    body.data.materials.append(body_mat)

    # Tail fin
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.08,
        radius2=0.01,
        depth=0.1,
        location=(-0.2, 0, 0),
        rotation=(0, -1.57, 0)
    )
    tail = bpy.context.active_object
    tail.name = "Tail"
    fin_mat = create_material("FishFin", (0.35, 0.55, 0.65, 1.0))
    tail.data.materials.append(fin_mat)
    parts.append(tail)

    # Dorsal fin
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.04,
        radius2=0.01,
        depth=0.06,
        location=(0, 0, 0.08),
        rotation=(0, 0, 0)
    )
    dorsal = bpy.context.active_object
    dorsal.name = "Dorsal"
    dorsal.data.materials.append(fin_mat)
    parts.append(dorsal)

    # Eye
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.015,
        location=(0.12, 0.04, 0.02)
    )
    eye = bpy.context.active_object
    eye.name = "Eye"
    eye_mat = create_material("FishEye", (0.1, 0.1, 0.1, 1.0))
    eye.data.materials.append(eye_mat)
    parts.append(eye)

    model = join_objects(parts, "Fish")
    set_origin_to_bottom(model)
    return model


def create_wolf():
    """Create a wolf model - aggressive predator."""
    clear_scene()
    parts = []

    # Body
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.4,
        location=(0, 0, 0.5),
        scale=(1.6, 0.6, 0.8)
    )
    body = bpy.context.active_object
    body.name = "Body"
    bpy.ops.object.shade_smooth()
    parts.append(body)

    body_mat = create_material("WolfBody", (0.3, 0.3, 0.35, 1.0))
    body.data.materials.append(body_mat)

    # Neck/Chest
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.25,
        location=(0.4, 0, 0.55),
        scale=(0.8, 0.8, 1)
    )
    chest = bpy.context.active_object
    chest.name = "Chest"
    bpy.ops.object.shade_smooth()
    chest.data.materials.append(body_mat)
    parts.append(chest)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.18,
        location=(0.6, 0, 0.65),
        scale=(1.2, 0.8, 0.9)
    )
    head = bpy.context.active_object
    head.name = "Head"
    bpy.ops.object.shade_smooth()
    head.data.materials.append(body_mat)
    parts.append(head)

    # Snout
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.1,
        radius2=0.04,
        depth=0.2,
        location=(0.78, 0, 0.6),
        rotation=(0, 1.57, 0)
    )
    snout = bpy.context.active_object
    snout.name = "Snout"
    snout.data.materials.append(body_mat)
    parts.append(snout)

    # Ears
    ear_mat = create_material("WolfEars", (0.25, 0.25, 0.3, 1.0))
    for z_off in [0.1, -0.1]:
        bpy.ops.mesh.primitive_cone_add(
            radius1=0.05,
            radius2=0.02,
            depth=0.12,
            location=(0.55, z_off, 0.8),
            rotation=(0.2, 0, 0.2 if z_off > 0 else -0.2)
        )
        ear = bpy.context.active_object
        ear.name = f"Ear_{z_off}"
        ear.data.materials.append(ear_mat)
        parts.append(ear)

    # Legs
    leg_mat = create_material("WolfLegs", (0.28, 0.28, 0.32, 1.0))
    leg_positions = [
        (0.3, 0.12, 0.25),
        (0.3, -0.12, 0.25),
        (-0.3, 0.12, 0.25),
        (-0.3, -0.12, 0.25),
    ]
    for i, pos in enumerate(leg_positions):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.05,
            depth=0.5,
            location=pos
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{i}"
        leg.data.materials.append(leg_mat)
        parts.append(leg)

    # Tail (bushy)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.06,
        depth=0.4,
        location=(-0.55, 0, 0.45),
        rotation=(0, 0.8, 0)
    )
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail.data.materials.append(body_mat)
    parts.append(tail)

    model = join_objects(parts, "Wolf")
    set_origin_to_bottom(model)
    return model


def create_coyote():
    """Create a coyote model - smaller, faster than wolf."""
    clear_scene()
    parts = []

    # Body (slimmer than wolf)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.3,
        location=(0, 0, 0.4),
        scale=(1.5, 0.5, 0.7)
    )
    body = bpy.context.active_object
    body.name = "Body"
    bpy.ops.object.shade_smooth()
    parts.append(body)

    body_mat = create_material("CoyoteBody", (0.6, 0.45, 0.35, 1.0))
    body.data.materials.append(body_mat)

    # Chest
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.18,
        location=(0.3, 0, 0.45),
        scale=(0.8, 0.8, 1)
    )
    chest = bpy.context.active_object
    chest.name = "Chest"
    bpy.ops.object.shade_smooth()
    chest.data.materials.append(body_mat)
    parts.append(chest)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.12,
        location=(0.45, 0, 0.52),
        scale=(1.3, 0.8, 0.9)
    )
    head = bpy.context.active_object
    head.name = "Head"
    bpy.ops.object.shade_smooth()
    head.data.materials.append(body_mat)
    parts.append(head)

    # Snout (longer, thinner)
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.06,
        radius2=0.02,
        depth=0.18,
        location=(0.58, 0, 0.48),
        rotation=(0, 1.57, 0)
    )
    snout = bpy.context.active_object
    snout.name = "Snout"
    snout.data.materials.append(body_mat)
    parts.append(snout)

    # Large ears
    ear_mat = create_material("CoyoteEars", (0.55, 0.4, 0.32, 1.0))
    for z_off in [0.08, -0.08]:
        bpy.ops.mesh.primitive_cone_add(
            radius1=0.05,
            radius2=0.01,
            depth=0.14,
            location=(0.4, z_off, 0.68),
            rotation=(0.15, 0, 0.25 if z_off > 0 else -0.25)
        )
        ear = bpy.context.active_object
        ear.name = f"Ear_{z_off}"
        ear.data.materials.append(ear_mat)
        parts.append(ear)

    # Legs (thin)
    leg_positions = [
        (0.2, 0.1, 0.2),
        (0.2, -0.1, 0.2),
        (-0.2, 0.1, 0.2),
        (-0.2, -0.1, 0.2),
    ]
    for i, pos in enumerate(leg_positions):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.035,
            depth=0.4,
            location=pos
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{i}"
        leg.data.materials.append(body_mat)
        parts.append(leg)

    # Bushy tail
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.045,
        depth=0.35,
        location=(-0.4, 0, 0.35),
        rotation=(0, 0.6, 0)
    )
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail.data.materials.append(body_mat)
    parts.append(tail)

    model = join_objects(parts, "Coyote")
    set_origin_to_bottom(model)
    return model


def create_mountain_lion():
    """Create a mountain lion model - large, powerful predator."""
    clear_scene()
    parts = []

    # Body (muscular)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.45,
        location=(0, 0, 0.55),
        scale=(1.8, 0.65, 0.8)
    )
    body = bpy.context.active_object
    body.name = "Body"
    bpy.ops.object.shade_smooth()
    parts.append(body)

    body_mat = create_material("LionBody", (0.7, 0.55, 0.4, 1.0))
    body.data.materials.append(body_mat)

    # Chest
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.3,
        location=(0.45, 0, 0.6),
        scale=(0.9, 0.85, 1)
    )
    chest = bpy.context.active_object
    chest.name = "Chest"
    bpy.ops.object.shade_smooth()
    chest.data.materials.append(body_mat)
    parts.append(chest)

    # Head (rounded)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.2,
        location=(0.65, 0, 0.7)
    )
    head = bpy.context.active_object
    head.name = "Head"
    bpy.ops.object.shade_smooth()
    head.data.materials.append(body_mat)
    parts.append(head)

    # Snout
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.1,
        location=(0.8, 0, 0.65),
        scale=(1.2, 0.9, 0.8)
    )
    snout = bpy.context.active_object
    snout.name = "Snout"
    bpy.ops.object.shade_smooth()
    snout.data.materials.append(body_mat)
    parts.append(snout)

    # Small ears
    ear_mat = create_material("LionEars", (0.65, 0.5, 0.38, 1.0))
    for z_off in [0.1, -0.1]:
        bpy.ops.mesh.primitive_cone_add(
            radius1=0.04,
            radius2=0.02,
            depth=0.08,
            location=(0.6, z_off, 0.88),
            rotation=(0.1, 0, 0)
        )
        ear = bpy.context.active_object
        ear.name = f"Ear_{z_off}"
        ear.data.materials.append(ear_mat)
        parts.append(ear)

    # Powerful legs
    leg_mat = create_material("LionLegs", (0.65, 0.5, 0.38, 1.0))
    leg_positions = [
        (0.35, 0.15, 0.28),
        (0.35, -0.15, 0.28),
        (-0.35, 0.15, 0.28),
        (-0.35, -0.15, 0.28),
    ]
    for i, pos in enumerate(leg_positions):
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.06,
            depth=0.55,
            location=pos
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{i}"
        leg.data.materials.append(leg_mat)
        parts.append(leg)

    # Long tail
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.04,
        depth=0.6,
        location=(-0.65, 0, 0.45),
        rotation=(0, 0.4, 0)
    )
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail.data.materials.append(body_mat)
    parts.append(tail)

    # Tail tip (darker)
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.05,
        location=(-0.9, 0, 0.35)
    )
    tail_tip = bpy.context.active_object
    tail_tip.name = "TailTip"
    tip_mat = create_material("LionTailTip", (0.3, 0.25, 0.2, 1.0))
    tail_tip.data.materials.append(tip_mat)
    parts.append(tail_tip)

    model = join_objects(parts, "MountainLion")
    set_origin_to_bottom(model)
    return model


def main():
    """Generate all animal models."""
    print("=" * 50)
    print("Faultline Fear: Animal Model Generator")
    print("=" * 50)

    output_dir = create_export_directory("assets/models/animals")
    setup_fbx_export()

    # Generate models
    models = [
        # Day animals
        ("Deer", create_deer),
        ("Bird", create_bird),
        ("Rabbit", create_rabbit),
        ("Fish", create_fish),

        # Night predators
        ("Wolf", create_wolf),
        ("Coyote", create_coyote),
        ("MountainLion", create_mountain_lion),
    ]

    for name, create_func in models:
        print(f"\nCreating {name}...")
        model = create_func()

        filepath = os.path.join(output_dir, f"{name}.fbx")
        export_model(model, filepath)
        print(f"  Exported: {filepath}")

    print("\n" + "=" * 50)
    print(f"Generated {len(models)} animal models")
    print("=" * 50)


if __name__ == "__main__":
    main()
