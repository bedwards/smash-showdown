"""
Blender Utilities for Faultline Fear Asset Creation

Common functions for creating game assets in headless Blender.
Usage: blender --background --python script.py

Exports to FBX format for Roblox import.
"""

import bpy
import os
import math
from mathutils import Vector


def clear_scene():
    """Remove all objects from the scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # Clear orphan data
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)


def create_material(name: str, color: tuple, emission: float = 0.0) -> bpy.types.Material:
    """
    Create a simple material with color and optional emission.

    Args:
        name: Material name
        color: RGB or RGBA tuple (0-1 range)
        emission: Emission strength (0 = no glow)
    """
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True

    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    # Clear default nodes
    nodes.clear()

    # Create nodes
    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (300, 0)

    principled = nodes.new('ShaderNodeBsdfPrincipled')
    principled.location = (0, 0)

    # Handle both RGB (3 values) and RGBA (4 values)
    if len(color) == 3:
        rgba = (*color, 1.0)
    else:
        rgba = color[:4]  # Take first 4 values

    principled.inputs['Base Color'].default_value = rgba

    if emission > 0:
        principled.inputs['Emission Color'].default_value = rgba
        principled.inputs['Emission Strength'].default_value = emission

    links.new(principled.outputs['BSDF'], output.inputs['Surface'])

    return mat


def apply_material(obj: bpy.types.Object, material: bpy.types.Material):
    """Apply a material to an object."""
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)


def join_objects(objects: list, name: str = None) -> bpy.types.Object:
    """Join multiple objects into one, optionally renaming the result."""
    if not objects:
        return None

    bpy.ops.object.select_all(action='DESELECT')

    for obj in objects:
        obj.select_set(True)

    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()

    result = bpy.context.active_object
    if name:
        result.name = name

    return result


def export_fbx(filepath: str, scale: float = 1.0):
    """
    Export scene to FBX for Roblox.

    Args:
        filepath: Output path (should end in .fbx)
        scale: Scale multiplier (Roblox uses different units)
    """
    # Ensure directory exists
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=False,
        global_scale=scale,
        apply_unit_scale=True,
        apply_scale_options='FBX_SCALE_ALL',
        axis_forward='-Z',
        axis_up='Y',
        use_mesh_modifiers=True,
        mesh_smooth_type='OFF',
        use_armature_deform_only=True,
        bake_anim=False,
        embed_textures=False,
    )
    print(f"Exported: {filepath}")


def export_obj(filepath: str, scale: float = 1.0):
    """
    Export scene to OBJ format (alternative to FBX).
    """
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    bpy.ops.wm.obj_export(
        filepath=filepath,
        global_scale=scale,
        forward_axis='NEGATIVE_Z',
        up_axis='Y',
        apply_modifiers=True,
    )
    print(f"Exported: {filepath}")


def create_primitive(ptype: str, size: float = 1.0, location: tuple = (0, 0, 0)) -> bpy.types.Object:
    """
    Create a primitive shape.

    Args:
        ptype: 'cube', 'sphere', 'cylinder', 'cone', 'torus'
        size: Base size
        location: Position tuple
    """
    if ptype == 'cube':
        bpy.ops.mesh.primitive_cube_add(size=size, location=location)
    elif ptype == 'sphere':
        bpy.ops.mesh.primitive_uv_sphere_add(radius=size/2, location=location)
    elif ptype == 'cylinder':
        bpy.ops.mesh.primitive_cylinder_add(radius=size/2, depth=size, location=location)
    elif ptype == 'cone':
        bpy.ops.mesh.primitive_cone_add(radius1=size/2, depth=size, location=location)
    elif ptype == 'torus':
        bpy.ops.mesh.primitive_torus_add(major_radius=size/2, minor_radius=size/6, location=location)
    else:
        raise ValueError(f"Unknown primitive type: {ptype}")

    return bpy.context.active_object


def smooth_shade(obj: bpy.types.Object):
    """Apply smooth shading to an object."""
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()


def subdivide(obj: bpy.types.Object, levels: int = 1):
    """Add subdivision surface modifier."""
    mod = obj.modifiers.new(name='Subdivision', type='SUBSURF')
    mod.levels = levels
    mod.render_levels = levels


def setup_fbx_export():
    """Setup FBX export settings. Called once at start of script."""
    # No-op - settings are passed directly to export_fbx
    pass


def create_export_directory(path: str):
    """Create export directory if it doesn't exist."""
    os.makedirs(path, exist_ok=True)
    return path


def export_model(model_or_filepath, filepath: str = None, scale: float = 0.01):
    """
    Export current scene to FBX (wrapper for export_fbx).
    Default scale 0.01 for Roblox.

    Args:
        model_or_filepath: Either a model object (ignored) or filepath string
        filepath: If model_or_filepath is an object, this is the filepath
        scale: Export scale (default 0.01 for Roblox)
    """
    # Handle both call styles: export_model(filepath) and export_model(model, filepath)
    if filepath is None:
        # Called as export_model(filepath)
        actual_filepath = model_or_filepath
    else:
        # Called as export_model(model, filepath)
        actual_filepath = filepath

    export_fbx(actual_filepath, scale)


def set_origin_to_bottom(obj: bpy.types.Object):
    """Set object origin to the bottom center of its bounding box."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    # Get bounding box in world coordinates
    bbox = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    min_z = min(v.z for v in bbox)
    center_x = sum(v.x for v in bbox) / 8
    center_y = sum(v.y for v in bbox) / 8

    # Set 3D cursor to bottom center
    bpy.context.scene.cursor.location = (center_x, center_y, min_z)

    # Set origin to cursor
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')

    # Reset cursor
    bpy.context.scene.cursor.location = (0, 0, 0)


if __name__ == "__main__":
    print("Blender utilities loaded successfully")
    print(f"Blender version: {bpy.app.version_string}")
