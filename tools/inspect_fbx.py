#!/usr/bin/env python3
"""
Experiment: Directly inspect FBX file to see actual vertex coordinates.

This bypasses Blender's re-import and looks at raw FBX data.
"""

import struct
import os
import sys

def read_fbx_header(f):
    """Read FBX header to determine if binary or ASCII."""
    magic = f.read(23)
    if magic.startswith(b'Kaydara FBX Binary'):
        return 'binary'
    else:
        return 'ascii'

def analyze_fbx_simple(filepath):
    """
    Simple FBX analysis - look for vertex data patterns.
    FBX files store vertices as arrays of floats.
    """
    print(f"\n{'='*60}")
    print(f"Analyzing: {os.path.basename(filepath)}")
    print(f"{'='*60}")

    file_size = os.path.getsize(filepath)
    print(f"File size: {file_size} bytes")

    with open(filepath, 'rb') as f:
        # Check format
        fmt = read_fbx_header(f)
        print(f"Format: {fmt}")

        # Read entire file
        f.seek(0)
        data = f.read()

    # Look for "Vertices" property (common FBX pattern)
    vertices_marker = b'Vertices'
    positions = []

    idx = 0
    while True:
        idx = data.find(vertices_marker, idx)
        if idx == -1:
            break

        print(f"Found 'Vertices' at offset {idx}")

        # Try to find float array after marker
        # FBX binary stores arrays with type markers
        # Look for a sequence of floats after the marker

        search_start = idx + len(vertices_marker)
        search_end = min(search_start + 500, len(data))

        # Look for what might be coordinate data
        # Try to extract some floats
        for offset in range(search_start, search_end - 12, 4):
            try:
                # Read 3 floats (x, y, z)
                x = struct.unpack('<f', data[offset:offset+4])[0]
                y = struct.unpack('<f', data[offset+4:offset+8])[0]
                z = struct.unpack('<f', data[offset+8:offset+12])[0]

                # Check if these look like reasonable coordinates
                # (not NaN, not huge, not tiny denormals)
                if all(-100000 < v < 100000 and abs(v) > 1e-10 or v == 0 for v in [x, y, z]):
                    if abs(x) > 0.01 or abs(y) > 0.01 or abs(z) > 0.01:
                        positions.append((x, y, z))
                        if len(positions) <= 5:
                            print(f"  Possible vertex at +{offset-search_start}: ({x:.2f}, {y:.2f}, {z:.2f})")
            except:
                pass

        idx += 1

    if positions:
        # Calculate bounds
        min_x = min(p[0] for p in positions)
        max_x = max(p[0] for p in positions)
        min_y = min(p[1] for p in positions)
        max_y = max(p[1] for p in positions)
        min_z = min(p[2] for p in positions)
        max_z = max(p[2] for p in positions)

        width = max_x - min_x
        height = max_y - min_y
        depth = max_z - min_z

        print(f"\nEstimated bounds from {len(positions)} candidate vertices:")
        print(f"  X: {min_x:.2f} to {max_x:.2f} (width: {width:.2f})")
        print(f"  Y: {min_y:.2f} to {max_y:.2f} (height: {height:.2f})")
        print(f"  Z: {min_z:.2f} to {max_z:.2f} (depth: {depth:.2f})")
        print(f"  Max dimension: {max(width, height, depth):.2f}")

        return max(width, height, depth)

    print("Could not find vertex data")
    return None


def main():
    print("FBX INSPECTION EXPERIMENT")
    print("Checking actual vertex coordinates in exported FBX files")

    # Check our structure FBX files
    structures_dir = "assets/models/structures"

    if not os.path.exists(structures_dir):
        print(f"ERROR: {structures_dir} not found")
        sys.exit(1)

    # Also check the test cubes from experiment 1
    test_files = [
        "/tmp/scale_experiment/cube_scale_1.fbx",
        "/tmp/scale_experiment/cube_scale_100.fbx",
        "/tmp/scale_experiment/cube_scale_1000.fbx",
        "/tmp/scale_experiment/cube_scale_10000.fbx",
    ]

    print("\n" + "="*60)
    print("TEST CUBES (known 1x1x1 cubes at different export scales)")
    print("="*60)

    for filepath in test_files:
        if os.path.exists(filepath):
            size = analyze_fbx_simple(filepath)
            scale = os.path.basename(filepath).split('_')[-1].replace('.fbx', '')
            print(f"  -> Scale {scale}: actual max dimension = {size:.1f}" if size else "")

    print("\n" + "="*60)
    print("STRUCTURE FBX FILES")
    print("="*60)

    for filename in sorted(os.listdir(structures_dir)):
        if filename.endswith('.fbx'):
            filepath = os.path.join(structures_dir, filename)
            analyze_fbx_simple(filepath)


if __name__ == "__main__":
    main()
