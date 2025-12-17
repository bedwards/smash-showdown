#!/usr/bin/env python3
"""
Faultline Fear: Master Asset Generator

Generates ALL game assets and combines them into ONE FBX file for easy Roblox import.

Usage:
    python tools/generate-all-assets.py

Output:
    assets/models/combined_all_assets.fbx  - Single FBX with all meshes named Category_AssetName

After running:
    1. In Roblox Studio: File → Import 3D → select combined_all_assets.fbx
    2. All meshes appear in Workspace as separate MeshParts
    3. AssetManifest automatically finds and hides templates

No plugins needed. No manual organization required.
"""

import subprocess
import os
import shutil
import sys
from pathlib import Path

# Project root
PROJECT_ROOT = Path(__file__).parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets" / "models"
IMPORT_DIR = ASSETS_DIR / "for-import"  # Intermediate folder for combine script
COMBINED_FBX = ASSETS_DIR / "combined_all_assets.fbx"

# Blender scripts to run (in order)
BLENDER_SCRIPTS = [
    "tools/blender/create_creatures.py",
    "tools/blender/create_animals.py",
    "tools/blender/create_npcs.py",
    "tools/blender/create_structures.py",
    "tools/blender/create_terrain_assets.py",
    "tools/blender/create_caves.py",
    "tools/blender/create_liminal_spaces.py",
    "tools/blender/create_signs.py",
]

# Mapping from folder names to AssetManifest category names
FOLDER_TO_CATEGORY = {
    "creatures": "Creatures",
    "animals": "Animals",
    "npcs": "NPCs",
    "structures": "Structures",
    "terrain": "Terrain",
    "caves": "Caves",
    "liminal": "Liminal",
    "signs": "Signs",
}

# Snake_case to PascalCase asset name mappings
SNAKE_TO_PASCAL = {
    "shadow_stalker": "ShadowStalker",
    "fissure_dweller": "FissureDweller",
    "night_bird": "NightBird",
    "abandoned_house": "AbandonedHouse",
    "ferris_wheel": "FerrisWheel",
    "radio_tower": "RadioTower",
    "water_tower": "WaterTower",
    "bridge": "Bridge",
    "lighthouse": "Lighthouse",
}


def run_blender_script(script_path: str) -> bool:
    """Run a Blender script and return success status."""
    full_path = PROJECT_ROOT / script_path
    if not full_path.exists():
        print(f"  WARNING: Script not found: {script_path}")
        return False

    print(f"  Running {script_path}...")
    result = subprocess.run(
        ["blender", "--background", "--python", str(full_path)],
        capture_output=True,
        text=True,
        cwd=PROJECT_ROOT,
    )

    if result.returncode != 0:
        print(f"  FAILED: {script_path}")
        print(f"    Error: {result.stderr[-500:] if result.stderr else 'Unknown'}")
        return False

    # Count exported files from output
    exports = result.stdout.count("Exported:")
    print(f"  OK: {script_path} ({exports} models)")
    return True


def normalize_asset_name(filename: str) -> str:
    """Convert filename to asset name matching AssetManifest."""
    name = Path(filename).stem

    # Check explicit mapping first
    lower_name = name.lower()
    if lower_name in SNAKE_TO_PASCAL:
        return SNAKE_TO_PASCAL[lower_name]

    # Snake_case to PascalCase
    if name.islower() and "_" in name:
        return "".join(word.capitalize() for word in name.split("_"))

    # Lowercase to Capitalized
    if name.islower():
        return name.capitalize()

    # Already proper format (Boulder_Small, etc.)
    return name


def organize_for_combine():
    """Collect all FBX files into for-import/ with Category_AssetName naming."""
    print("\n" + "=" * 50)
    print("Organizing files for combine...")
    print("=" * 50)

    # Clean and create import directory
    if IMPORT_DIR.exists():
        shutil.rmtree(IMPORT_DIR)
    IMPORT_DIR.mkdir(parents=True)

    total_files = 0

    # Walk through all category folders
    for folder in ASSETS_DIR.iterdir():
        if not folder.is_dir() or folder.name == "for-import":
            continue

        category = FOLDER_TO_CATEGORY.get(folder.name, folder.name.capitalize())

        for fbx_file in folder.glob("*.fbx"):
            asset_name = normalize_asset_name(fbx_file.name)
            new_name = f"{category}_{asset_name}.fbx"
            dest = IMPORT_DIR / new_name

            shutil.copy2(fbx_file, dest)
            print(f"  {folder.name}/{fbx_file.name} -> {new_name}")
            total_files += 1

    print(f"\nOrganized {total_files} files into {IMPORT_DIR}")
    return total_files


def combine_all_fbx():
    """Run the Blender script to combine all FBX into one."""
    print("\n" + "=" * 50)
    print("Combining into single FBX...")
    print("=" * 50)

    combine_script = PROJECT_ROOT / "tools" / "blender" / "combine_all_fbx.py"
    if not combine_script.exists():
        print(f"ERROR: Combine script not found: {combine_script}")
        return False

    result = subprocess.run(
        ["blender", "--background", "--python", str(combine_script)],
        capture_output=True,
        text=True,
        cwd=PROJECT_ROOT,
    )

    if result.returncode != 0:
        print("FAILED: Could not combine FBX files")
        print(f"Error: {result.stderr[-500:] if result.stderr else 'Unknown'}")
        return False

    if COMBINED_FBX.exists():
        size_mb = COMBINED_FBX.stat().st_size / (1024 * 1024)
        print(f"OK: Created {COMBINED_FBX.name} ({size_mb:.1f} MB)")
        return True
    else:
        print("ERROR: Combined FBX file was not created")
        return False


def main():
    print("=" * 50)
    print("FAULTLINE FEAR: ASSET GENERATOR")
    print("=" * 50)

    # Check blender is available
    result = subprocess.run(["blender", "--version"], capture_output=True, text=True)
    if result.returncode != 0:
        print("ERROR: Blender not found. Install Blender first.")
        sys.exit(1)
    print(f"Using {result.stdout.split()[0]} {result.stdout.split()[1]}")

    # Run all Blender scripts
    print("\n" + "=" * 50)
    print("Generating 3D models...")
    print("=" * 50)

    success = 0
    failed = 0
    for script in BLENDER_SCRIPTS:
        if run_blender_script(script):
            success += 1
        else:
            failed += 1

    print(f"\nGeneration: {success} succeeded, {failed} failed")

    if failed > 0:
        print("WARNING: Some scripts failed. Check output above.")

    # Organize files with Category_AssetName naming
    total_files = organize_for_combine()

    if total_files == 0:
        print("ERROR: No FBX files to combine")
        sys.exit(1)

    # Combine all into one FBX
    if not combine_all_fbx():
        print("ERROR: Failed to create combined FBX")
        sys.exit(1)

    # Open folder containing combined FBX
    import platform
    print("\n" + "=" * 50)
    print("Opening output folder...")
    print("=" * 50)

    try:
        if platform.system() == "Darwin":
            subprocess.run(["open", str(ASSETS_DIR)])
        elif platform.system() == "Windows":
            subprocess.run(["explorer", str(ASSETS_DIR)])
        else:
            subprocess.run(["xdg-open", str(ASSETS_DIR)])
    except Exception as e:
        print(f"Could not open folder: {e}")

    # Final summary
    print("\n" + "=" * 50)
    print("DONE!")
    print("=" * 50)
    print(f"""
OUTPUT: {COMBINED_FBX}
MESHES: {total_files} assets combined into one FBX

IN ROBLOX STUDIO:
  1. File -> Import 3D
  2. Select: combined_all_assets.fbx
  3. Click Import
  4. Done! Meshes appear in Workspace

AssetManifest automatically:
  - Finds meshes by Category_AssetName pattern
  - Hides templates so they don't block players
  - Provides CloneAsset() for spawning

No plugins needed. No manual organization.
""")


if __name__ == "__main__":
    main()
