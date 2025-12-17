"""
Combine All FBX Files into One Master FBX

This script:
1. Imports all individual FBX files from assets/models/for-import/
2. Names each mesh as Category_AssetName (matching the filename)
3. Exports ONE combined FBX file

Usage:
    blender --background --python tools/blender/combine_all_fbx.py

Then in Roblox Studio:
    File → Import 3D → select combined_all_assets.fbx
    All meshes appear as separate MeshParts in Workspace!
"""

import bpy
import os
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
IMPORT_DIR = PROJECT_ROOT / "assets" / "models" / "for-import"
OUTPUT_FILE = PROJECT_ROOT / "assets" / "models" / "combined_all_assets.fbx"

def clear_scene():
    """Remove all objects from scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # Also clear orphan data
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)

def import_and_combine():
    """Import all FBX files and combine into one scene."""
    clear_scene()

    fbx_files = list(IMPORT_DIR.glob("*.fbx"))

    if not fbx_files:
        print(f"ERROR: No FBX files found in {IMPORT_DIR}")
        return False

    print(f"Found {len(fbx_files)} FBX files to combine")
    print("=" * 50)

    imported_count = 0

    for fbx_path in sorted(fbx_files):
        # Get the asset name from filename (e.g., "Creatures_ShadowStalker.fbx" → "Creatures_ShadowStalker")
        asset_name = fbx_path.stem

        print(f"Importing: {asset_name}")

        # Remember what objects exist before import
        existing_objects = set(bpy.data.objects.keys())

        # Import the FBX
        try:
            bpy.ops.import_scene.fbx(filepath=str(fbx_path))
        except Exception as e:
            print(f"  ERROR importing {fbx_path}: {e}")
            continue

        # Find newly imported objects
        new_objects = [obj for obj in bpy.data.objects if obj.name not in existing_objects]

        if not new_objects:
            print(f"  WARNING: No objects imported from {fbx_path}")
            continue

        # If multiple objects were imported, they might be in a hierarchy
        # Find the root(s) and rename appropriately
        for i, obj in enumerate(new_objects):
            if obj.type == 'MESH':
                # Name the mesh with the asset name
                if len([o for o in new_objects if o.type == 'MESH']) == 1:
                    obj.name = asset_name
                else:
                    obj.name = f"{asset_name}_part{i}"

                # Position slightly offset so they don't all stack at origin
                # (Roblox will use the positions from the FBX)
                row = imported_count // 10
                col = imported_count % 10
                obj.location = (col * 5, row * 5, 0)

        imported_count += 1
        print(f"  OK: {asset_name}")

    print("=" * 50)
    print(f"Imported {imported_count} assets")

    return imported_count > 0

def export_combined():
    """Export all objects as one FBX file."""
    # Select all mesh objects
    bpy.ops.object.select_all(action='DESELECT')
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            obj.select_set(True)

    # Ensure output directory exists
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    # Export
    bpy.ops.export_scene.fbx(
        filepath=str(OUTPUT_FILE),
        use_selection=True,
        apply_scale_options='FBX_SCALE_ALL',
        bake_space_transform=True,
        mesh_smooth_type='FACE',
    )

    print(f"Exported combined FBX to: {OUTPUT_FILE}")

def main():
    print("=" * 50)
    print("COMBINE ALL FBX FILES")
    print("=" * 50)

    if not IMPORT_DIR.exists():
        print(f"ERROR: Import directory not found: {IMPORT_DIR}")
        print("Run 'python tools/generate-all-assets.py' first")
        return

    if import_and_combine():
        export_combined()
        print("")
        print("=" * 50)
        print("DONE!")
        print("=" * 50)
        print(f"""
In Roblox Studio:
  1. File → Import 3D
  2. Select: {OUTPUT_FILE}
  3. All meshes appear as separate MeshParts in Workspace.Meshes!

No need to use Asset Manager or insert one by one.
""")
    else:
        print("ERROR: No files were imported")

if __name__ == "__main__":
    main()
