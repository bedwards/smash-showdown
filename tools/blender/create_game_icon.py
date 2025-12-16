"""
Faultline Fear: Game Icon Generator

Creates a 512x512 game icon for Roblox.

Usage:
    blender --background --python tools/blender/create_game_icon.py
"""

import bpy
import math
import os

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "assets", "marketing")
os.makedirs(OUTPUT_DIR, exist_ok=True)

ICON_SIZE = 512


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for material in bpy.data.materials:
        bpy.data.materials.remove(material)


def setup_render():
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 128
    scene.render.resolution_x = ICON_SIZE
    scene.render.resolution_y = ICON_SIZE
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'

    # Set world background to dark sky gradient
    world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    nodes = world.node_tree.nodes
    nodes.clear()

    # Gradient background
    bg = nodes.new('ShaderNodeBackground')
    bg.inputs['Color'].default_value = (0.05, 0.08, 0.15, 1.0)  # Dark blue
    bg.inputs['Strength'].default_value = 1.0

    output = nodes.new('ShaderNodeOutputWorld')
    world.node_tree.links.new(bg.outputs['Background'], output.inputs['Surface'])


def setup_camera():
    bpy.ops.object.camera_add(location=(0, -8, 2))
    camera = bpy.context.object
    camera.rotation_euler = (math.radians(80), 0, 0)
    camera.data.type = 'PERSP'
    camera.data.lens = 35
    bpy.context.scene.camera = camera
    return camera


def setup_lighting():
    # Dramatic rim light from behind
    bpy.ops.object.light_add(type='AREA', location=(0, 5, 5))
    rim = bpy.context.object
    rim.data.energy = 500
    rim.data.color = (1.0, 0.6, 0.3)  # Orange
    rim.data.size = 5
    rim.rotation_euler = (math.radians(-45), 0, 0)

    # Cool fill from front
    bpy.ops.object.light_add(type='AREA', location=(0, -5, 3))
    fill = bpy.context.object
    fill.data.energy = 200
    fill.data.color = (0.6, 0.8, 1.0)  # Blue
    fill.data.size = 8

    # Ground glow (fault line)
    bpy.ops.object.light_add(type='AREA', location=(0, 0, -0.5))
    glow = bpy.context.object
    glow.data.energy = 300
    glow.data.color = (1.0, 0.3, 0.1)  # Red/orange
    glow.data.size = 2
    glow.rotation_euler = (math.radians(180), 0, 0)


def create_material(name, color, metallic=0.0, roughness=0.5, emission=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()

    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Emission Strength'].default_value = emission
    if emission > 0:
        bsdf.inputs['Emission Color'].default_value = (*color, 1.0)

    output = nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    return mat


def create_game_icon():
    """Create dramatic fault line icon."""
    clear_scene()
    setup_render()
    setup_camera()
    setup_lighting()

    # Ground plane (cracked earth)
    rock_mat = create_material("Rock", (0.3, 0.25, 0.2), roughness=0.9)

    # Left ground
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-1.5, 0, 0))
    left = bpy.context.object
    left.scale = (3, 5, 0.5)
    left.rotation_euler = (0, math.radians(-5), 0)
    left.data.materials.append(rock_mat)

    # Right ground (slightly lower - fault offset)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(1.5, 0, -0.3))
    right = bpy.context.object
    right.scale = (3, 5, 0.5)
    right.rotation_euler = (0, math.radians(5), 0)
    right.data.materials.append(rock_mat)

    # Fault line crack (glowing)
    crack_mat = create_material("Crack", (1.0, 0.4, 0.1), emission=15.0)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -0.8))
    crack = bpy.context.object
    crack.scale = (0.3, 6, 1)
    crack.data.materials.append(crack_mat)

    # Jagged rocks along fault
    debris_mat = create_material("Debris", (0.2, 0.18, 0.15), roughness=1.0)

    for i in range(-3, 4):
        for side in [-0.4, 0.4]:
            bpy.ops.mesh.primitive_cone_add(
                radius1=0.2 + (i % 2) * 0.1,
                depth=0.4 + (i % 3) * 0.2,
                location=(side, i * 1.2, 0.1)
            )
            rock = bpy.context.object
            rock.rotation_euler = (
                math.radians(10 * (i % 3)),
                math.radians(15 * side),
                math.radians(30 * i)
            )
            rock.data.materials.append(debris_mat)

    # Dust/smoke particles (spheres with emission)
    smoke_mat = create_material("Smoke", (0.8, 0.5, 0.3), emission=2.0)

    import random
    random.seed(42)
    for _ in range(15):
        x = random.uniform(-0.8, 0.8)
        y = random.uniform(-2, 2)
        z = random.uniform(0.5, 2)
        size = random.uniform(0.1, 0.3)

        bpy.ops.mesh.primitive_uv_sphere_add(radius=size, location=(x, y, z))
        smoke = bpy.context.object
        smoke.data.materials.append(smoke_mat)

    # Render
    bpy.context.scene.render.filepath = os.path.join(OUTPUT_DIR, "game_icon.png")
    bpy.ops.render.render(write_still=True)
    print(f"Created: {bpy.context.scene.render.filepath}")


def main():
    print("=" * 50)
    print("FAULTLINE FEAR GAME ICON GENERATOR")
    print("=" * 50)

    create_game_icon()

    print("=" * 50)
    print(f"Icon created in: {OUTPUT_DIR}")
    print("=" * 50)


if __name__ == "__main__":
    main()
