"""
Experiment: Measure actual dimensions of our structure FBX files.

Re-imports each structure FBX and reports the bounding box dimensions.
"""

import bpy
import os

STRUCTURES_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "models", "structures")

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)

def import_fbx(filepath):
    """Import FBX and return all imported objects."""
    bpy.ops.import_scene.fbx(filepath=filepath)
    return list(bpy.context.selected_objects)

def get_scene_bounds():
    """Calculate bounding box of all objects in scene."""
    min_co = [float('inf')] * 3
    max_co = [float('-inf')] * 3

    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            # Get world-space bounding box
            for corner in obj.bound_box:
                world_corner = obj.matrix_world @ bpy.mathutils.Vector(corner)
                for i in range(3):
                    min_co[i] = min(min_co[i], world_corner[i])
                    max_co[i] = max(max_co[i], world_corner[i])

    if min_co[0] == float('inf'):
        return None

    return {
        'min': tuple(min_co),
        'max': tuple(max_co),
        'size': tuple(max_co[i] - min_co[i] for i in range(3))
    }

def main():
    print("=" * 70)
    print("STRUCTURE FBX MEASUREMENT EXPERIMENT")
    print("=" * 70)

    if not os.path.exists(STRUCTURES_DIR):
        print(f"ERROR: {STRUCTURES_DIR} not found")
        return

    # Expected sizes from code comments (at scale=100)
    expected_original = {
        'water_tower.fbx': 35,    # "~35 studs tall"
        'radio_tower.fbx': 60,    # "~60 studs tall"
        'ferris_wheel.fbx': 45,   # "~40-45 studs tall"
        'lighthouse.fbx': 30,     # "~30 studs tall"
        'bridge.fbx': 80,         # "~80 studs long"
        'abandoned_house.fbx': 25, # "~25 studs tall"
    }

    results = []

    for filename in sorted(os.listdir(STRUCTURES_DIR)):
        if not filename.endswith('.fbx'):
            continue

        filepath = os.path.join(STRUCTURES_DIR, filename)

        print(f"\n{'='*70}")
        print(f"File: {filename}")
        print(f"{'='*70}")

        clear_scene()

        try:
            objects = import_fbx(filepath)
            print(f"  Imported {len(objects)} objects")

            bounds = get_scene_bounds()
            if bounds:
                size = bounds['size']
                max_dim = max(size)

                print(f"  Bounding box size: {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f}")
                print(f"  Max dimension: {max_dim:.1f}")

                expected = expected_original.get(filename, None)
                if expected:
                    # We changed scale from 100 to 10000, but experiment showed cap at 1000
                    # So expected new size = original * (1000/100) = original * 10
                    expected_new = expected * 10
                    ratio = max_dim / expected if expected else 0
                    print(f"  Expected (original scale=100): ~{expected}")
                    print(f"  Expected (new scale=10000, capped to 1000): ~{expected_new}")
                    print(f"  Actual vs original expected: {ratio:.1f}x")

                results.append({
                    'file': filename,
                    'size': size,
                    'max_dim': max_dim,
                    'expected_original': expected,
                })
            else:
                print("  ERROR: No mesh objects found")

        except Exception as e:
            print(f"  ERROR: {e}")

    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY TABLE")
    print("=" * 70)
    print(f"{'File':<25} {'Max Dim':<12} {'Expected':<12} {'Ratio'}")
    print("-" * 70)

    for r in results:
        expected = r.get('expected_original', 0) or 0
        ratio = r['max_dim'] / expected if expected else 0
        print(f"{r['file']:<25} {r['max_dim']:<12.1f} {expected:<12} {ratio:.1f}x")

    print("\n" + "=" * 70)
    print("ANALYSIS")
    print("=" * 70)

    # Check if results match our expectations
    if results:
        avg_ratio = sum(r['max_dim'] / (r.get('expected_original') or r['max_dim']) for r in results) / len(results)
        print(f"Average ratio vs original expected: {avg_ratio:.1f}x")

        if avg_ratio > 8:
            print("CONCLUSION: Scale increase IS working (roughly 10x as expected from 100->1000 cap)")
            print("The models ARE larger in the FBX files.")
            print("Problem must be in how Roblox imports them!")
        elif avg_ratio > 0.8:
            print("CONCLUSION: Scale is approximately 1x - FBX export scale may not be working")
        else:
            print("CONCLUSION: Models are smaller than expected")

if __name__ == "__main__":
    # Need mathutils for vector operations
    import mathutils
    bpy.mathutils = mathutils
    main()
