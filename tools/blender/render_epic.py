"""
Render epic terrain from multiple dramatic angles
"""

import bpy
import math
import os
from mathutils import Vector

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
RENDER_DIR = os.path.join(OUTPUT_DIR, "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def import_terrain():
    filepath = os.path.join(OUTPUT_DIR, "epic_terrain.fbx")
    if os.path.exists(filepath):
        bpy.ops.import_scene.fbx(filepath=filepath)
        print(f"Imported: {filepath}")
        return True
    return False

def setup_epic_lighting():
    """Dramatic Elder Scrolls style lighting"""

    # Golden hour sun
    bpy.ops.object.light_add(type='SUN', location=(500, -300, 800))
    sun = bpy.context.object
    sun.name = "GoldenSun"
    sun.data.energy = 4.0
    sun.data.color = (1.0, 0.9, 0.7)  # Warm golden
    sun.rotation_euler = (math.radians(35), math.radians(15), math.radians(30))

    # Rim light (cool)
    bpy.ops.object.light_add(type='SUN', location=(-400, 400, 600))
    rim = bpy.context.object
    rim.name = "RimLight"
    rim.data.energy = 1.5
    rim.data.color = (0.7, 0.8, 1.0)  # Cool blue
    rim.rotation_euler = (math.radians(60), 0, math.radians(150))

    # Ambient fill
    bpy.ops.object.light_add(type='SUN', location=(0, 0, 1000))
    ambient = bpy.context.object
    ambient.name = "Ambient"
    ambient.data.energy = 0.5
    ambient.data.color = (0.6, 0.7, 0.9)

def setup_camera(position, target, name="Camera"):
    bpy.ops.object.camera_add(location=position)
    camera = bpy.context.object
    camera.name = name

    direction = Vector(target) - Vector(position)
    rot_quat = direction.to_track_quat('-Z', 'Y')
    camera.rotation_euler = rot_quat.to_euler()

    # Cinematic settings
    camera.data.lens = 35  # Wide angle for epic shots
    camera.data.dof.use_dof = True
    camera.data.dof.focus_distance = (Vector(target) - Vector(position)).length
    camera.data.dof.aperture_fstop = 8.0

    bpy.context.scene.camera = camera
    return camera

def setup_render():
    scene = bpy.context.scene

    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 75

    scene.render.image_settings.file_format = 'PNG'

    # Epic sky
    world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        # Gradient sky (simulate with single color for now)
        bg.inputs["Color"].default_value = (0.4, 0.55, 0.8, 1.0)
        bg.inputs["Strength"].default_value = 1.0

def render_view(camera_pos, target, filename, description):
    print(f"Rendering: {description}")

    camera = setup_camera(camera_pos, target, f"Camera_{filename}")

    filepath = os.path.join(RENDER_DIR, f"epic_{filename}")
    bpy.context.scene.render.filepath = filepath

    bpy.ops.render.render(write_still=True)
    print(f"  Saved: {filepath}.png")

    bpy.data.objects.remove(camera, do_unlink=True)

def main():
    print("\n" + "=" * 60)
    print("   EPIC TERRAIN RENDERER")
    print("=" * 60 + "\n")

    clear_scene()

    if not import_terrain():
        print("ERROR: Could not import terrain!")
        return

    setup_epic_lighting()
    setup_render()

    # Epic cinematic views
    views = [
        # Hero shot - dramatic low angle looking up at mountains
        {
            "camera": (100, -800, 50),
            "target": (200, 0, 200),
            "filename": "hero_shot",
            "description": "Hero shot - dramatic mountain view",
        },
        # Aerial overview
        {
            "camera": (0, 0, 1200),
            "target": (0, 0, 0),
            "filename": "aerial",
            "description": "Aerial overview of the realm",
        },
        # Frozen Peaks dramatic
        {
            "camera": (150, -600, 100),
            "target": (300, -400, 250),
            "filename": "frozen_peaks_epic",
            "description": "Frozen Peaks - epic vista",
        },
        # Valley view
        {
            "camera": (-200, 200, 30),
            "target": (100, -100, 100),
            "filename": "valley_view",
            "description": "View from the valley floor",
        },
        # Sunset angle
        {
            "camera": (-600, -400, 150),
            "target": (0, 0, 100),
            "filename": "sunset_angle",
            "description": "Dramatic sunset angle",
        },
        # Close-up terrain detail
        {
            "camera": (50, -100, 80),
            "target": (100, 0, 50),
            "filename": "terrain_detail",
            "description": "Terrain detail close-up",
        },
    ]

    for view in views:
        render_view(
            view["camera"],
            view["target"],
            view["filename"],
            view["description"]
        )

    print("\n" + "=" * 60)
    print("   EPIC RENDERS COMPLETE!")
    print(f"   Check: {RENDER_DIR}/")
    print("=" * 60 + "\n")

if __name__ == "__main__":
    main()
