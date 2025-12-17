"""
Faultline Fear: Creature Model Generator

Creates hostile night creature models for the game.
Run with: blender --background --python tools/blender/create_creatures.py

Creature Types:
1. Shadow Stalker - Fast quadruped, hunts in packs
2. Fissure Dweller - Emerges from fault line cracks
3. Night Bird - Aerial threat with glowing eyes
"""

import bpy
import sys
import os
import math

# Add tools directory to path for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

from blender_utils import (
    clear_scene,
    create_material,
    apply_material,
    join_objects,
    export_fbx,
    create_primitive,
    smooth_shade,
    subdivide,
)

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "..", "assets", "models", "creatures")


def create_shadow_stalker():
    """
    Create a Shadow Stalker - fast quadruped creature.

    Design: Low, sleek body with four legs, glowing eyes.
    Aesthetic: Dark and shadowy with subtle glow.
    """
    clear_scene()
    parts = []

    # Body (elongated ellipsoid)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.5, location=(0, 0, 0.6))
    body = bpy.context.active_object
    body.name = "Body"
    body.scale = (1.5, 0.6, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(body)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.25, location=(1.2, 0, 0.7))
    head = bpy.context.active_object
    head.name = "Head"
    head.scale = (1.2, 0.8, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    parts.append(head)

    # Snout
    bpy.ops.mesh.primitive_cone_add(radius1=0.12, depth=0.3, location=(1.5, 0, 0.65))
    snout = bpy.context.active_object
    snout.name = "Snout"
    snout.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.transform_apply(rotation=True)
    parts.append(snout)

    # Eyes (glowing)
    eye_mat = create_material("EyeGlow", (1.0, 0.3, 0.1), emission=5.0)

    for side in [-1, 1]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.06, location=(1.3, side * 0.12, 0.8))
        eye = bpy.context.active_object
        eye.name = f"Eye_{['L', 'R'][side > 0]}"
        apply_material(eye, eye_mat)
        parts.append(eye)

    # Legs (4 legs)
    leg_positions = [
        (0.6, 0.3, 0),   # Front right
        (0.6, -0.3, 0),  # Front left
        (-0.6, 0.3, 0),  # Back right
        (-0.6, -0.3, 0), # Back left
    ]

    for i, pos in enumerate(leg_positions):
        # Upper leg
        bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.4, location=(pos[0], pos[1], 0.35))
        upper = bpy.context.active_object
        upper.rotation_euler = (math.radians(15 if i < 2 else -15), 0, 0)
        parts.append(upper)

        # Lower leg
        bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.35, location=(pos[0], pos[1], 0.1))
        lower = bpy.context.active_object
        parts.append(lower)

    # Tail
    bpy.ops.mesh.primitive_cone_add(radius1=0.1, depth=0.8, location=(-1.0, 0, 0.5))
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail.rotation_euler = (0, math.radians(-70), 0)
    bpy.ops.object.transform_apply(rotation=True)
    parts.append(tail)

    # Apply dark material to body parts
    dark_mat = create_material("ShadowBody", (0.05, 0.05, 0.08), emission=0.1)
    for part in parts:
        if "Eye" not in part.name:
            apply_material(part, dark_mat)
            smooth_shade(part)

    # Join all parts
    creature = join_objects(parts)
    creature.name = "ShadowStalker"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "shadow_stalker.fbx")
    export_fbx(filepath, scale=100)  # Scale up for Roblox

    print("Created Shadow Stalker")
    return creature


def create_fissure_dweller():
    """
    Create a Fissure Dweller - creature that emerges from cracks.

    Design: Worm-like segmented body, emerges vertically.
    Aesthetic: Rocky texture, glowing cracks.
    LOW POLY version for Roblox import (<10k triangles).
    """
    clear_scene()
    parts = []

    # Segmented body - REDUCED segments
    num_segments = 5  # Reduced from 8
    segment_height = 0.4  # Slightly taller to compensate

    rock_mat = create_material("RockBody", (0.2, 0.18, 0.15))
    crack_mat = create_material("CrackGlow", (1.0, 0.5, 0.1), emission=3.0)

    for i in range(num_segments):
        radius = 0.3 - (i * 0.03)  # Taper toward top
        z = i * segment_height

        # LOW POLY cylinder
        bpy.ops.mesh.primitive_cylinder_add(
            radius=radius,
            depth=segment_height,
            vertices=8,  # Reduced from default 32
            location=(0, 0, z)
        )
        segment = bpy.context.active_object
        segment.name = f"Segment_{i}"
        apply_material(segment, rock_mat)
        smooth_shade(segment)
        parts.append(segment)

        # Add glowing cracks between segments - LOW POLY torus
        if i > 0:
            bpy.ops.mesh.primitive_torus_add(
                major_radius=radius + 0.02,
                minor_radius=0.02,
                major_segments=12,  # Reduced from default 48
                minor_segments=4,   # Reduced from default 12
                location=(0, 0, z - segment_height/2)
            )
            crack = bpy.context.active_object
            crack.name = f"Crack_{i}"
            apply_material(crack, crack_mat)
            parts.append(crack)

    # Head - LOW POLY sphere
    head_z = num_segments * segment_height
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.25,
        segments=12,  # Reduced from default 32
        ring_count=6,  # Reduced from default 16
        location=(0, 0, head_z)
    )
    head = bpy.context.active_object
    head.name = "Head"
    head.scale = (1, 1, 0.6)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(head, rock_mat)
    smooth_shade(head)
    parts.append(head)

    # Eyes - REDUCED count and LOW POLY
    eye_mat = create_material("DwellerEyes", (0.8, 1.0, 0.3), emission=4.0)
    for angle in [0, 120, 240]:  # Reduced from 5 to 3 eyes
        rad = math.radians(angle)
        x = math.cos(rad) * 0.2
        y = math.sin(rad) * 0.2
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.04,
            segments=6,  # Minimal
            ring_count=4,
            location=(x, y, head_z + 0.1)
        )
        eye = bpy.context.active_object
        apply_material(eye, eye_mat)
        parts.append(eye)

    # Join
    creature = join_objects(parts)
    creature.name = "FissureDweller"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "fissure_dweller.fbx")
    export_fbx(filepath, scale=100)

    print("Created Fissure Dweller")
    return creature


def create_night_bird():
    """
    Create a Night Bird - aerial threat.

    Design: Large wingspan, sharp talons, glowing eyes.
    Aesthetic: Dark feathers, predatory silhouette.
    """
    clear_scene()
    parts = []

    dark_mat = create_material("DarkFeathers", (0.03, 0.03, 0.05))
    eye_mat = create_material("BirdEyes", (1.0, 0.8, 0.2), emission=6.0)

    # Body
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.3, location=(0, 0, 0))
    body = bpy.context.active_object
    body.name = "Body"
    body.scale = (1.5, 0.7, 0.7)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(body, dark_mat)
    smooth_shade(body)
    parts.append(body)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.15, location=(0.4, 0, 0.15))
    head = bpy.context.active_object
    head.name = "Head"
    apply_material(head, dark_mat)
    smooth_shade(head)
    parts.append(head)

    # Beak
    bpy.ops.mesh.primitive_cone_add(radius1=0.06, depth=0.2, location=(0.6, 0, 0.1))
    beak = bpy.context.active_object
    beak.name = "Beak"
    beak.rotation_euler = (0, math.radians(90), 0)
    bpy.ops.object.transform_apply(rotation=True)
    apply_material(beak, create_material("Beak", (0.1, 0.1, 0.1)))
    parts.append(beak)

    # Eyes
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.04, location=(0.5, side * 0.08, 0.2))
        eye = bpy.context.active_object
        apply_material(eye, eye_mat)
        parts.append(eye)

    # Wings (simplified as flat shapes)
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_plane_add(size=1.5, location=(0, side * 0.8, 0.1))
        wing = bpy.context.active_object
        wing.name = f"Wing_{['L', 'R'][side > 0]}"
        wing.scale = (1.2, 0.5, 1)
        wing.rotation_euler = (0, 0, side * math.radians(10))
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        apply_material(wing, dark_mat)
        parts.append(wing)

    # Tail feathers
    bpy.ops.mesh.primitive_cone_add(radius1=0.15, depth=0.5, location=(-0.5, 0, -0.05))
    tail = bpy.context.active_object
    tail.name = "Tail"
    tail.rotation_euler = (0, math.radians(-90), 0)
    tail.scale = (1, 0.3, 1)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    apply_material(tail, dark_mat)
    parts.append(tail)

    # Talons
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_cone_add(radius1=0.03, depth=0.15, location=(0, side * 0.1, -0.25))
        talon = bpy.context.active_object
        talon.rotation_euler = (math.radians(180), 0, 0)
        apply_material(talon, create_material("Talon", (0.08, 0.08, 0.08)))
        parts.append(talon)

    # Join
    creature = join_objects(parts)
    creature.name = "NightBird"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "night_bird.fbx")
    export_fbx(filepath, scale=100)

    print("Created Night Bird")
    return creature


def main():
    """Generate all creature models."""
    print("=" * 50)
    print("Faultline Fear: Creature Generator")
    print("=" * 50)

    # Ensure output directory exists
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Create all creatures
    create_shadow_stalker()
    create_fissure_dweller()
    create_night_bird()

    print("=" * 50)
    print(f"All creatures exported to: {OUTPUT_DIR}")
    print("=" * 50)


if __name__ == "__main__":
    main()
