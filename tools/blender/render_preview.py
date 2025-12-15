"""
Render terrain preview images for Claude to see
Run with: blender --background --python render_preview.py
"""

import bpy
import os
import math
from mathutils import Vector

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
RENDER_DIR = os.path.join(OUTPUT_DIR, "renders")

# Create render directory
os.makedirs(RENDER_DIR, exist_ok=True)

def setup_scene():
    """Setup scene for rendering"""

    # Clear scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    # Import combined terrain
    terrain_file = os.path.join(OUTPUT_DIR, "mertin_terrain.fbx")
    if os.path.exists(terrain_file):
        bpy.ops.import_scene.fbx(filepath=terrain_file)
        print(f"Imported terrain from {terrain_file}")
    else:
        print(f"ERROR: {terrain_file} not found!")
        return False

    return True

def setup_lighting():
    """Add lighting for the render"""

    # Sun light
    bpy.ops.object.light_add(type='SUN', location=(100, -100, 500))
    sun = bpy.context.object
    sun.name = "Sun"
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(45), math.radians(15), math.radians(45))

    # Ambient light (hemisphere)
    bpy.ops.object.light_add(type='SUN', location=(-100, 100, 300))
    ambient = bpy.context.object
    ambient.name = "Ambient"
    ambient.data.energy = 1.0
    ambient.data.color = (0.8, 0.9, 1.0)
    ambient.rotation_euler = (math.radians(120), 0, 0)

def setup_camera(position, target, name="Camera"):
    """Setup camera for rendering"""

    bpy.ops.object.camera_add(location=position)
    camera = bpy.context.object
    camera.name = name

    # Point at target
    direction = Vector(target) - Vector(position)
    rot_quat = direction.to_track_quat('-Z', 'Y')
    camera.rotation_euler = rot_quat.to_euler()

    # Set as active camera
    bpy.context.scene.camera = camera

    return camera

def setup_render_settings():
    """Configure render settings"""

    scene = bpy.context.scene

    # Use EEVEE for fast preview
    scene.render.engine = 'BLENDER_EEVEE'

    # Resolution
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 50  # 50% for faster preview

    # Output format
    scene.render.image_settings.file_format = 'PNG'

    # Background color
    world = bpy.data.worlds.get("World")
    if world is None:
        world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs["Color"].default_value = (0.5, 0.7, 1.0, 1.0)  # Sky blue

def render_view(camera_pos, target_pos, filename, description):
    """Render a single view"""

    print(f"Rendering: {description}")

    # Setup camera
    camera = setup_camera(camera_pos, target_pos, f"Camera_{filename}")

    # Set output path
    filepath = os.path.join(RENDER_DIR, filename)
    bpy.context.scene.render.filepath = filepath

    # Render
    bpy.ops.render.render(write_still=True)

    print(f"  Saved to: {filepath}.png")

    # Cleanup camera
    bpy.data.objects.remove(camera, do_unlink=True)

def render_all_views():
    """Render multiple views of the terrain"""

    views = [
        # Overview from above
        {
            "camera": (0, -800, 600),
            "target": (0, 0, 100),
            "filename": "overview_south",
            "description": "Overview from south (looking north)",
        },
        {
            "camera": (0, 800, 600),
            "target": (0, 0, 100),
            "filename": "overview_north",
            "description": "Overview from north (looking south)",
        },
        # Spawn area view
        {
            "camera": (50, -150, 80),
            "target": (0, 0, 20),
            "filename": "spawn_area",
            "description": "View from spawn area",
        },
        # Frozen Peaks close-up
        {
            "camera": (200, -500, 200),
            "target": (300, -400, 150),
            "filename": "frozen_peaks",
            "description": "Frozen Peaks mountain range",
        },
        # The Giants
        {
            "camera": (200, 200, 200),
            "target": (350, 350, 150),
            "filename": "the_giants",
            "description": "The Giants mountain range",
        },
        # Top-down map view
        {
            "camera": (0, 0, 1000),
            "target": (0, 0, 0),
            "filename": "topdown_map",
            "description": "Top-down map view",
        },
    ]

    for view in views:
        render_view(
            view["camera"],
            view["target"],
            view["filename"],
            view["description"],
        )

def main():
    print("\n" + "=" * 50)
    print("TERRAIN PREVIEW RENDERER")
    print("=" * 50 + "\n")

    if not setup_scene():
        return

    setup_lighting()
    setup_render_settings()
    render_all_views()

    print("\n" + "=" * 50)
    print(f"RENDERS COMPLETE! Check {RENDER_DIR}/")
    print("=" * 50 + "\n")

if __name__ == "__main__":
    main()
