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
        color: RGB tuple (0-1 range)
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
    principled.inputs['Base Color'].default_value = (*color, 1.0)

    if emission > 0:
        principled.inputs['Emission Color'].default_value = (*color, 1.0)
        principled.inputs['Emission Strength'].default_value = emission

    links.new(principled.outputs['BSDF'], output.inputs['Surface'])

    return mat


def apply_material(obj: bpy.types.Object, material: bpy.types.Material):
    """Apply a material to an object."""
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)


def join_objects(objects: list) -> bpy.types.Object:
    """Join multiple objects into one."""
    if not objects:
        return None

    bpy.ops.object.select_all(action='DESELECT')

    for obj in objects:
        obj.select_set(True)

    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()

    return bpy.context.active_object


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


if __name__ == "__main__":
    print("Blender utilities loaded successfully")
    print(f"Blender version: {bpy.app.version_string}")
