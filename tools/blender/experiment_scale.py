"""
Experiment: What does FBX export scale actually produce?

Creates a 1x1x1 cube in Blender, exports at various scales,
then re-imports to measure actual resulting size.
"""

import bpy
import os
import sys

OUTPUT_DIR = "/tmp/scale_experiment"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def create_unit_cube():
    """Create a 1x1x1 cube at origin."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))  # Bottom at z=0
    cube = bpy.context.active_object
    cube.name = "TestCube"
    return cube

def export_fbx(filepath, scale):
    """Export scene to FBX with given scale."""
    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=False,
        global_scale=scale,
        apply_unit_scale=True,
        apply_scale_options='FBX_SCALE_ALL',
        axis_forward='-Z',
        axis_up='Y',
    )

def import_fbx(filepath):
    """Import FBX and return the imported object."""
    bpy.ops.import_scene.fbx(filepath=filepath)
    return bpy.context.selected_objects[0] if bpy.context.selected_objects else None

def get_dimensions(obj):
    """Get object dimensions."""
    return obj.dimensions.copy()

def run_experiment():
    print("=" * 60)
    print("SCALE EXPERIMENT: What does FBX global_scale actually do?")
    print("=" * 60)

    # Test scales
    scales = [1, 10, 100, 1000, 10000]

    results = []

    for scale in scales:
        print(f"\n--- Testing scale={scale} ---")

        # Clear and create fresh cube
        clear_scene()
        cube = create_unit_cube()
        original_dims = get_dimensions(cube)
        print(f"Original cube dimensions: {original_dims.x:.4f} x {original_dims.y:.4f} x {original_dims.z:.4f}")

        # Export
        filepath = os.path.join(OUTPUT_DIR, f"cube_scale_{scale}.fbx")
        export_fbx(filepath, scale)
        file_size = os.path.getsize(filepath)
        print(f"Exported to: {filepath} ({file_size} bytes)")

        # Clear and re-import
        clear_scene()
        imported = import_fbx(filepath)

        if imported:
            imported_dims = get_dimensions(imported)
            print(f"Imported dimensions: {imported_dims.x:.4f} x {imported_dims.y:.4f} x {imported_dims.z:.4f}")

            # Calculate actual scale achieved
            actual_scale = imported_dims.x / original_dims.x
            print(f"Actual scale factor: {actual_scale:.2f}x")

            results.append({
                "target_scale": scale,
                "actual_scale": actual_scale,
                "dimensions": (imported_dims.x, imported_dims.y, imported_dims.z),
                "file_size": file_size
            })
        else:
            print("ERROR: Failed to import!")
            results.append({
                "target_scale": scale,
                "error": "Import failed"
            })

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"{'Target Scale':<15} {'Actual Scale':<15} {'Dimensions':<30} {'File Size'}")
    print("-" * 75)
    for r in results:
        if "error" in r:
            print(f"{r['target_scale']:<15} ERROR: {r['error']}")
        else:
            dims = f"{r['dimensions'][0]:.1f} x {r['dimensions'][1]:.1f} x {r['dimensions'][2]:.1f}"
            print(f"{r['target_scale']:<15} {r['actual_scale']:<15.2f} {dims:<30} {r['file_size']}")

    print("\n" + "=" * 60)
    print("CONCLUSION")
    print("=" * 60)

    # Check if scale actually works
    if len(results) >= 2 and "actual_scale" in results[0] and "actual_scale" in results[-1]:
        ratio = results[-1]["actual_scale"] / results[0]["actual_scale"]
        expected_ratio = results[-1]["target_scale"] / results[0]["target_scale"]
        print(f"Scale {results[0]['target_scale']} -> {results[-1]['target_scale']}")
        print(f"Expected size ratio: {expected_ratio}x")
        print(f"Actual size ratio: {ratio:.2f}x")

        if abs(ratio - expected_ratio) < expected_ratio * 0.1:
            print("RESULT: FBX scale IS working correctly in Blender round-trip")
        else:
            print("RESULT: FBX scale is NOT preserving expected dimensions!")

if __name__ == "__main__":
    run_experiment()
