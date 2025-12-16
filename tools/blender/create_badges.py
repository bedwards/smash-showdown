"""
Faultline Fear: Badge Image Generator

Creates badge images for Roblox using Blender headless.
Badge size: 150x150 pixels (Roblox standard)

Usage:
    blender --background --python tools/blender/create_badges.py
"""

import bpy
import math
import os

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "assets", "badges")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Badge size (Roblox standard)
BADGE_SIZE = 150


def clear_scene():
    """Remove all objects from scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # Clear materials
    for material in bpy.data.materials:
        bpy.data.materials.remove(material)


def setup_render():
    """Configure render settings for badge output."""
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 64
    scene.render.resolution_x = BADGE_SIZE
    scene.render.resolution_y = BADGE_SIZE
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'


def setup_camera():
    """Create orthographic camera for badge render."""
    bpy.ops.object.camera_add(location=(0, -5, 0))
    camera = bpy.context.object
    camera.rotation_euler = (math.radians(90), 0, 0)
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = 2.5
    bpy.context.scene.camera = camera
    return camera


def setup_lighting():
    """Create lighting for badge render."""
    # Key light
    bpy.ops.object.light_add(type='SUN', location=(2, -2, 3))
    sun = bpy.context.object
    sun.data.energy = 3
    sun.rotation_euler = (math.radians(45), math.radians(30), 0)

    # Fill light
    bpy.ops.object.light_add(type='AREA', location=(-2, -2, 2))
    fill = bpy.context.object
    fill.data.energy = 100
    fill.data.size = 3


def create_material(name, color, metallic=0.0, roughness=0.5, emission=0.0):
    """Create a PBR material."""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()

    # Principled BSDF
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Emission Strength'].default_value = emission
    if emission > 0:
        bsdf.inputs['Emission Color'].default_value = (*color, 1.0)

    # Output
    output = nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])

    return mat


def create_survivor_badge():
    """Create Survivor badge - earthquake/crack theme with star."""
    clear_scene()
    setup_render()
    setup_camera()
    setup_lighting()

    # Background circle (gold/bronze)
    bpy.ops.mesh.primitive_cylinder_add(radius=1.0, depth=0.1, location=(0, 0, 0))
    bg = bpy.context.object
    bg.rotation_euler = (math.radians(90), 0, 0)
    gold_mat = create_material("Gold", (0.83, 0.69, 0.22), metallic=0.9, roughness=0.3)
    bg.data.materials.append(gold_mat)

    # Inner circle (dark)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.85, depth=0.12, location=(0, -0.02, 0))
    inner = bpy.context.object
    inner.rotation_euler = (math.radians(90), 0, 0)
    dark_mat = create_material("Dark", (0.15, 0.12, 0.1), roughness=0.8)
    inner.data.materials.append(dark_mat)

    # Crack/fault line (red glow)
    bpy.ops.mesh.primitive_cube_add(size=0.1, location=(0, -0.05, 0))
    crack = bpy.context.object
    crack.scale = (0.08, 0.05, 0.7)
    crack.rotation_euler = (math.radians(90), 0, math.radians(15))
    crack_mat = create_material("Crack", (1.0, 0.3, 0.1), emission=5.0)
    crack.data.materials.append(crack_mat)

    # Star (survivor symbol)
    bpy.ops.mesh.primitive_circle_add(vertices=5, radius=0.35, fill_type='NGON', location=(0, -0.08, 0.3))
    star = bpy.context.object
    star.rotation_euler = (math.radians(90), 0, math.radians(18))
    # Make it a star shape by scaling alternate vertices
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='DESELECT')
    bpy.ops.object.mode_set(mode='OBJECT')
    star_mat = create_material("Star", (1.0, 0.85, 0.0), metallic=0.8, roughness=0.2, emission=1.0)
    star.data.materials.append(star_mat)

    # Render
    bpy.context.scene.render.filepath = os.path.join(OUTPUT_DIR, "survivor_badge.png")
    bpy.ops.render.render(write_still=True)
    print(f"Created: {bpy.context.scene.render.filepath}")


def create_explorer_badge():
    """Create Explorer badge - compass theme."""
    clear_scene()
    setup_render()
    setup_camera()
    setup_lighting()

    # Background circle (blue/teal)
    bpy.ops.mesh.primitive_cylinder_add(radius=1.0, depth=0.1, location=(0, 0, 0))
    bg = bpy.context.object
    bg.rotation_euler = (math.radians(90), 0, 0)
    teal_mat = create_material("Teal", (0.2, 0.6, 0.7), metallic=0.7, roughness=0.3)
    bg.data.materials.append(teal_mat)

    # Inner circle (darker)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.85, depth=0.12, location=(0, -0.02, 0))
    inner = bpy.context.object
    inner.rotation_euler = (math.radians(90), 0, 0)
    dark_mat = create_material("DarkBlue", (0.1, 0.2, 0.3), roughness=0.6)
    inner.data.materials.append(dark_mat)

    # Compass rose - N arrow (white)
    bpy.ops.mesh.primitive_cone_add(radius1=0.15, depth=0.5, location=(0, -0.05, 0.25))
    n_arrow = bpy.context.object
    n_arrow.rotation_euler = (math.radians(90), 0, 0)
    white_mat = create_material("White", (0.95, 0.95, 0.95), roughness=0.3)
    n_arrow.data.materials.append(white_mat)

    # S arrow (red)
    bpy.ops.mesh.primitive_cone_add(radius1=0.12, depth=0.4, location=(0, -0.05, -0.2))
    s_arrow = bpy.context.object
    s_arrow.rotation_euler = (math.radians(-90), 0, 0)
    red_mat = create_material("Red", (0.8, 0.2, 0.2), roughness=0.3)
    s_arrow.data.materials.append(red_mat)

    # E/W markers
    for angle, offset in [(90, (0.35, -0.05, 0)), (-90, (-0.35, -0.05, 0))]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.08, location=offset)
        marker = bpy.context.object
        marker.data.materials.append(white_mat)

    # Render
    bpy.context.scene.render.filepath = os.path.join(OUTPUT_DIR, "explorer_badge.png")
    bpy.ops.render.render(write_still=True)
    print(f"Created: {bpy.context.scene.render.filepath}")


def create_rescuer_badge():
    """Create Rescuer badge - helping hand/heart theme."""
    clear_scene()
    setup_render()
    setup_camera()
    setup_lighting()

    # Background circle (warm red/orange)
    bpy.ops.mesh.primitive_cylinder_add(radius=1.0, depth=0.1, location=(0, 0, 0))
    bg = bpy.context.object
    bg.rotation_euler = (math.radians(90), 0, 0)
    red_mat = create_material("WarmRed", (0.8, 0.3, 0.2), metallic=0.6, roughness=0.3)
    bg.data.materials.append(red_mat)

    # Inner circle
    bpy.ops.mesh.primitive_cylinder_add(radius=0.85, depth=0.12, location=(0, -0.02, 0))
    inner = bpy.context.object
    inner.rotation_euler = (math.radians(90), 0, 0)
    dark_mat = create_material("DarkRed", (0.2, 0.1, 0.1), roughness=0.7)
    inner.data.materials.append(dark_mat)

    # Heart shape (two spheres + cone)
    heart_mat = create_material("Heart", (1.0, 0.4, 0.5), emission=1.0)

    # Left lobe
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.25, location=(-0.15, -0.06, 0.15))
    lobe1 = bpy.context.object
    lobe1.data.materials.append(heart_mat)

    # Right lobe
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.25, location=(0.15, -0.06, 0.15))
    lobe2 = bpy.context.object
    lobe2.data.materials.append(heart_mat)

    # Bottom point
    bpy.ops.mesh.primitive_cone_add(radius1=0.35, depth=0.5, location=(0, -0.06, -0.1))
    point = bpy.context.object
    point.rotation_euler = (math.radians(180), 0, 0)
    point.data.materials.append(heart_mat)

    # Hands reaching up (simplified as cylinders)
    hand_mat = create_material("Hand", (0.9, 0.75, 0.6), roughness=0.6)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.4, location=(-0.4, -0.05, -0.2))
    hand1 = bpy.context.object
    hand1.rotation_euler = (math.radians(90), 0, math.radians(-30))
    hand1.data.materials.append(hand_mat)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.4, location=(0.4, -0.05, -0.2))
    hand2 = bpy.context.object
    hand2.rotation_euler = (math.radians(90), 0, math.radians(30))
    hand2.data.materials.append(hand_mat)

    # Render
    bpy.context.scene.render.filepath = os.path.join(OUTPUT_DIR, "rescuer_badge.png")
    bpy.ops.render.render(write_still=True)
    print(f"Created: {bpy.context.scene.render.filepath}")


def main():
    print("=" * 50)
    print("FAULTLINE FEAR BADGE GENERATOR")
    print("=" * 50)

    create_survivor_badge()
    create_explorer_badge()
    create_rescuer_badge()

    print("=" * 50)
    print(f"All badges created in: {OUTPUT_DIR}")
    print("=" * 50)


if __name__ == "__main__":
    main()
