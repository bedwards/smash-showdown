"""
Faultline Fear: Structure Model Generator

Creates iconic California-inspired structures for the game.
Run with: blender --background --python tools/blender/create_structures.py

SCALE: All models built at 1:1 stud scale (1 Blender unit = 1 Roblox stud)
       Export with scale=1 so Roblox imports at correct size.

Structures and Target Sizes (in studs):
1. Ferris Wheel - 40x45x10 (Beach landmark)
2. Radio Tower - 15x60x15 (Mountain summit)
3. Abandoned House - 25x20x20 (Town building)
4. Bridge - 80x5x15 (Fault line crossing)
5. Water Tower - 15x35x15 (Town landmark)
6. Lighthouse - 10x30x10 (Coastal beacon)
"""

import bpy
import sys
import os
import math

# Add tools directory to path for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

from blender_utils import (
    clear_scene,
    create_material,
    apply_material,
    group_objects,
    export_fbx,
    smooth_shade,
)

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "..", "assets", "models", "structures")

# Export scale: 1.0 for 1:1 stud mapping
EXPORT_SCALE = 1.0


def create_ferris_wheel():
    """
    Create a Ferris Wheel - beach landmark.
    Target size: 40x45x10 studs (Width x Height x Depth)

    Part naming for AssetColors pattern matching:
    - "Gondola_N" -> Red gondola color
    - "Light_N" -> Yellow glow
    - "Rust_N" -> Rusty support color
    - Others -> Metal primary color
    """
    clear_scene()
    parts = []

    # Materials
    metal_mat = create_material("Metal", (0.3, 0.3, 0.35))
    rust_mat = create_material("Rust", (0.4, 0.25, 0.15))
    gondola_mat = create_material("Gondola", (0.8, 0.2, 0.2))
    light_mat = create_material("Light", (1.0, 0.9, 0.7), emission=3.0)

    # Build at actual stud scale
    # Target: 40 wide, 45 tall, 10 deep
    wheel_radius = 18  # 36 stud diameter, ~45 with support structure
    wheel_center_z = 24  # Center of wheel above ground
    num_spokes = 8
    num_gondolas = 6

    # Main wheel rim (torus) - LOW POLY for Roblox import
    bpy.ops.mesh.primitive_torus_add(
        major_radius=wheel_radius,
        minor_radius=0.8,
        major_segments=16,
        minor_segments=6,
        location=(0, 0, wheel_center_z)
    )
    rim = bpy.context.active_object
    rim.name = "Rim"
    apply_material(rim, metal_mat)
    parts.append(rim)

    # Inner rim - LOW POLY
    bpy.ops.mesh.primitive_torus_add(
        major_radius=wheel_radius * 0.7,
        minor_radius=0.5,
        major_segments=16,
        minor_segments=6,
        location=(0, 0, wheel_center_z)
    )
    inner_rim = bpy.context.active_object
    inner_rim.name = "InnerRim"
    apply_material(inner_rim, metal_mat)
    parts.append(inner_rim)

    # Hub - LOW POLY
    bpy.ops.mesh.primitive_cylinder_add(
        radius=2.5,
        depth=4,
        vertices=8,
        location=(0, 0, wheel_center_z)
    )
    hub = bpy.context.active_object
    hub.name = "Hub"
    hub.rotation_euler = (math.radians(90), 0, 0)
    apply_material(hub, metal_mat)
    parts.append(hub)

    # Spokes - LOW POLY
    for i in range(num_spokes):
        angle = (2 * math.pi * i) / num_spokes

        # Outer spoke
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.4,
            depth=wheel_radius,
            vertices=6,
            location=(0, 0, wheel_center_z)
        )
        spoke = bpy.context.active_object
        spoke.name = f"Spoke_{i}"
        spoke.rotation_euler = (0, math.radians(90), angle)
        spoke.location = (
            math.cos(angle) * wheel_radius / 2,
            0,
            wheel_center_z + math.sin(angle) * wheel_radius / 2
        )
        apply_material(spoke, metal_mat)
        parts.append(spoke)

    # Gondolas
    for i in range(num_gondolas):
        angle = (2 * math.pi * i) / num_gondolas
        x = math.cos(angle) * wheel_radius
        z = wheel_center_z + math.sin(angle) * wheel_radius

        # Gondola body
        bpy.ops.mesh.primitive_cube_add(
            size=4,
            location=(x, 0, z - 3)
        )
        gondola = bpy.context.active_object
        gondola.name = f"Gondola_{i}"
        gondola.scale = (1, 0.6, 1.2)
        bpy.ops.object.transform_apply(scale=True)
        apply_material(gondola, gondola_mat)
        parts.append(gondola)

        # Light on gondola
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.6,
            segments=8,
            ring_count=4,
            location=(x, 0, z - 1)
        )
        light = bpy.context.active_object
        light.name = f"Light_{i}"
        apply_material(light, light_mat)
        parts.append(light)

    # Support structure - A-frame
    support_height = wheel_center_z - wheel_radius + 2  # From ground to bottom of wheel
    for idx, side in enumerate([-1, 1]):
        # Main support leg
        bpy.ops.mesh.primitive_cylinder_add(
            radius=1.2,
            depth=support_height + 10,
            vertices=8,
            location=(side * 12, 0, (support_height + 10) / 2)
        )
        leg = bpy.context.active_object
        leg.name = f"Rust_Leg_{idx}"
        leg.rotation_euler = (0, math.radians(side * 12), 0)
        apply_material(leg, rust_mat)
        parts.append(leg)

        # Cross brace
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.6,
            depth=25,
            vertices=6,
            location=(side * 6, 0, 10)
        )
        brace = bpy.context.active_object
        brace.name = f"Rust_Brace_{idx}"
        brace.rotation_euler = (0, math.radians(-side * 50), 0)
        apply_material(brace, rust_mat)
        parts.append(brace)

    # Base platform
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 1)
    )
    base = bpy.context.active_object
    base.name = "Base"
    base.scale = (35, 8, 2)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(base, metal_mat)
    parts.append(base)

    # Smooth all parts
    for part in parts:
        smooth_shade(part)

    # Group (NOT join!) - preserves individual part names for color matching
    structure = group_objects(parts, "FerrisWheel")

    # Export at 1:1 scale
    filepath = os.path.join(OUTPUT_DIR, "ferris_wheel.fbx")
    export_fbx(filepath, scale=EXPORT_SCALE)

    print("Created Ferris Wheel (40x45x10 studs)")
    return structure


def create_radio_tower():
    """
    Create a Radio Tower - mountain summit rescue beacon.
    Target size: 15x60x15 studs (Width x Height x Depth)

    Part naming for AssetColors pattern matching:
    - "Red_N" -> Red brace color
    - "Beacon" -> Glowing red beacon
    - Others -> Metal primary color
    """
    clear_scene()
    parts = []

    # Materials
    metal_mat = create_material("TowerMetal", (0.5, 0.5, 0.55))
    red_mat = create_material("TowerRed", (0.8, 0.1, 0.1))
    light_mat = create_material("BeaconLight", (1.0, 0.2, 0.1), emission=8.0)

    # Target: 15 wide, 60 tall, 15 deep
    tower_height = 55  # Main tower, plus antenna
    base_width = 12
    top_width = 4
    num_sections = 6

    # Tower legs (4 corners)
    for idx, corner in enumerate([(-1, -1), (-1, 1), (1, -1), (1, 1)]):
        # Tapered leg
        bpy.ops.mesh.primitive_cone_add(
            vertices=4,
            radius1=1.0,
            radius2=0.4,
            depth=tower_height,
            location=(corner[0] * base_width/2, corner[1] * base_width/2, tower_height/2)
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{idx}"
        apply_material(leg, metal_mat)
        parts.append(leg)

    # Horizontal braces at each section
    brace_idx = 0
    for section in range(num_sections + 1):
        height = section * (tower_height / num_sections)
        width = base_width - (base_width - top_width) * (section / num_sections)

        # Square brace
        for start, end in [((-1,-1), (-1,1)), ((-1,1), (1,1)), ((1,1), (1,-1)), ((1,-1), (-1,-1))]:
            x1, y1 = start[0] * width/2, start[1] * width/2
            x2, y2 = end[0] * width/2, end[1] * width/2

            length = math.sqrt((x2-x1)**2 + (y2-y1)**2)
            angle = math.atan2(y2-y1, x2-x1)

            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.3,
                depth=length,
                vertices=6,
                location=((x1+x2)/2, (y1+y2)/2, height)
            )
            brace = bpy.context.active_object
            brace.rotation_euler = (0, 0, angle + math.radians(90))
            # Alternate red and white for visibility
            if section % 2 == 0:
                brace.name = f"Brace_{brace_idx}"
                apply_material(brace, metal_mat)
            else:
                brace.name = f"Red_Brace_{brace_idx}"
                apply_material(brace, red_mat)
            brace_idx += 1
            parts.append(brace)

        # Diagonal braces (X pattern)
        if section < num_sections:
            next_height = (section + 1) * (tower_height / num_sections)
            next_width = base_width - (base_width - top_width) * ((section + 1) / num_sections)

            for side in [((-1,-1), (1,1)), ((-1,1), (1,-1))]:
                x1, y1 = side[0][0] * width/2, side[0][1] * width/2
                x2, y2 = side[1][0] * next_width/2, side[1][1] * next_width/2

                length = math.sqrt((x2-x1)**2 + (y2-y1)**2 + (tower_height/num_sections)**2)

                bpy.ops.mesh.primitive_cylinder_add(
                    radius=0.2,
                    depth=length,
                    vertices=4,
                    location=((x1+x2)/2, (y1+y2)/2, (height + next_height)/2)
                )
                diag = bpy.context.active_object
                diag.name = f"Diag_{brace_idx}"
                brace_idx += 1
                dx, dy, dz = x2-x1, y2-y1, tower_height/num_sections
                diag.rotation_euler = (
                    math.atan2(math.sqrt(dx**2 + dy**2), dz),
                    0,
                    math.atan2(dy, dx)
                )
                apply_material(diag, metal_mat)
                parts.append(diag)

    # Antenna mast
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.5,
        depth=8,
        vertices=6,
        location=(0, 0, tower_height + 4)
    )
    mast = bpy.context.active_object
    mast.name = "Mast"
    apply_material(mast, metal_mat)
    parts.append(mast)

    # Beacon light
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=1.5,
        segments=12,
        ring_count=8,
        location=(0, 0, tower_height + 9)
    )
    beacon = bpy.context.active_object
    beacon.name = "Beacon"
    apply_material(beacon, light_mat)
    parts.append(beacon)

    # Guy wires (visual only)
    for idx, angle in enumerate([0, 120, 240]):
        rad = math.radians(angle)
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.1,
            depth=tower_height * 1.2,
            vertices=4,
            location=(math.cos(rad) * 8, math.sin(rad) * 8, tower_height * 0.5)
        )
        wire = bpy.context.active_object
        wire.name = f"Wire_{idx}"
        wire.rotation_euler = (math.radians(60), 0, rad)
        apply_material(wire, metal_mat)
        parts.append(wire)

    # Group
    structure = group_objects(parts, "RadioTower")

    # Export
    filepath = os.path.join(OUTPUT_DIR, "radio_tower.fbx")
    export_fbx(filepath, scale=EXPORT_SCALE)

    print("Created Radio Tower (15x60x15 studs)")
    return structure


def create_abandoned_house():
    """
    Create an Abandoned House - modular town building.
    Target size: 25x20x20 studs (Width x Height x Depth)

    Part naming for AssetColors pattern matching:
    - "Roof_*" / "Shingle*" -> Dark roof color
    - "Door" -> Wood color
    - "Porch" -> Wood color
    - "Wood_*" -> Wood color
    - "Window_*" -> Glass color
    - Others -> Wall primary color
    """
    clear_scene()
    parts = []

    # Materials
    wall_mat = create_material("WornWall", (0.6, 0.55, 0.5))
    roof_mat = create_material("Shingles", (0.25, 0.2, 0.18))
    window_mat = create_material("BrokenGlass", (0.3, 0.35, 0.4))
    wood_mat = create_material("WornWood", (0.35, 0.25, 0.15))

    # Target: 25 wide, 20 tall, 20 deep
    house_width = 24
    house_depth = 18
    house_height = 14
    wall_thickness = 1

    # Front wall
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -house_depth/2 + wall_thickness/2, house_height/2))
    front = bpy.context.active_object
    front.name = "Wall_Front"
    front.scale = (house_width, wall_thickness, house_height)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(front, wall_mat)
    parts.append(front)

    # Back wall
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, house_depth/2 - wall_thickness/2, house_height/2))
    back = bpy.context.active_object
    back.name = "Wall_Back"
    back.scale = (house_width, wall_thickness, house_height)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(back, wall_mat)
    parts.append(back)

    # Side walls
    for idx, side in enumerate([-1, 1]):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(side * (house_width/2 - wall_thickness/2), 0, house_height/2)
        )
        wall = bpy.context.active_object
        wall.name = f"Wall_Side_{idx}"
        wall.scale = (wall_thickness, house_depth, house_height)
        bpy.ops.object.transform_apply(scale=True)
        apply_material(wall, wall_mat)
        parts.append(wall)

    # Roof (triangular prism shape)
    roof_height = 6
    bpy.ops.mesh.primitive_cone_add(
        vertices=4,
        radius1=house_width * 0.58,
        depth=roof_height,
        location=(0, 0, house_height + roof_height/2)
    )
    roof = bpy.context.active_object
    roof.name = "Roof"
    roof.scale = (1, house_depth/house_width * 0.75, 1)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(roof, roof_mat)
    parts.append(roof)

    # Door
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(4, -house_depth/2 + 0.1, 3.5)
    )
    door = bpy.context.active_object
    door.name = "Door"
    door.scale = (4, 0.3, 7)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(door, wood_mat)
    parts.append(door)

    # Windows
    window_positions = [
        (-6, -house_depth/2, 9),   # Front left upper
        (6, -house_depth/2, 9),    # Front right upper (broken)
        (-6, house_depth/2, 9),    # Back left
    ]

    window_idx = 0
    for i, pos in enumerate(window_positions):
        if i == 1:  # Skip one window (broken out)
            continue
        bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
        window = bpy.context.active_object
        window.name = f"Window_{window_idx}"
        window_idx += 1
        window.scale = (3, 0.3, 4)
        bpy.ops.object.transform_apply(scale=True)
        apply_material(window, window_mat)
        parts.append(window)

    # Porch
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, -house_depth/2 - 3, 0.75)
    )
    porch = bpy.context.active_object
    porch.name = "Porch"
    porch.scale = (12, 6, 1.5)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(porch, wood_mat)
    parts.append(porch)

    # Chimney
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(8, 4, house_height + 3)
    )
    chimney = bpy.context.active_object
    chimney.name = "Chimney"
    chimney.scale = (3, 3, 8)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(chimney, wall_mat)
    parts.append(chimney)

    # Smooth and group
    for part in parts:
        smooth_shade(part)

    structure = group_objects(parts, "AbandonedHouse")

    # Export
    filepath = os.path.join(OUTPUT_DIR, "abandoned_house.fbx")
    export_fbx(filepath, scale=EXPORT_SCALE)

    print("Created Abandoned House (25x20x20 studs)")
    return structure


def create_bridge():
    """
    Create a Bridge - fault line crossing.
    Target size: 80x5x15 studs (Length x Height x Width)

    Part naming for AssetColors pattern matching:
    - "Steel_*" / "Tower_*" -> Steel color
    - "Cable_*" -> Cable color
    - "Rail_*" / "Rust_*" -> Rusty railing color
    - Others -> Concrete primary color
    """
    clear_scene()
    parts = []

    # Materials
    steel_mat = create_material("BridgeSteel", (0.4, 0.4, 0.45))
    concrete_mat = create_material("Concrete", (0.5, 0.5, 0.48))
    cable_mat = create_material("Cable", (0.2, 0.2, 0.22))
    rust_mat = create_material("BridgeRust", (0.5, 0.3, 0.2))

    # Target: 80 long, 5 tall deck, 15 wide
    bridge_length = 80
    bridge_width = 14
    deck_height = 2
    tower_height = 25

    # Road deck
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, deck_height/2)
    )
    deck = bpy.context.active_object
    deck.name = "Deck"
    deck.scale = (bridge_length, bridge_width, deck_height)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(deck, concrete_mat)
    parts.append(deck)

    # Support towers (2 pairs)
    tower_idx = 0
    for x_pos in [-bridge_length/3, bridge_length/3]:
        for side in [-1, 1]:
            # Vertical tower
            bpy.ops.mesh.primitive_cube_add(
                size=1,
                location=(x_pos, side * bridge_width/2 * 0.8, deck_height + tower_height/2)
            )
            tower = bpy.context.active_object
            tower.name = f"Tower_{tower_idx}"
            tower_idx += 1
            tower.scale = (2, 2, tower_height)
            bpy.ops.object.transform_apply(scale=True)
            apply_material(tower, steel_mat)
            parts.append(tower)

        # Cross beam at top
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x_pos, 0, deck_height + tower_height)
        )
        beam = bpy.context.active_object
        beam.name = f"Steel_Beam_{tower_idx}"
        beam.scale = (2, bridge_width * 0.8, 1.5)
        bpy.ops.object.transform_apply(scale=True)
        apply_material(beam, steel_mat)
        parts.append(beam)

    # Main cables (catenary shape) - LOW POLY
    cable_points = 10
    cable_idx = 0
    for side in [-1, 1]:
        for i in range(cable_points - 1):
            t1 = i / (cable_points - 1)
            t2 = (i + 1) / (cable_points - 1)

            x1 = -bridge_length/2 + t1 * bridge_length
            x2 = -bridge_length/2 + t2 * bridge_length

            # Parabolic sag
            cable_top = deck_height + tower_height
            sag1 = cable_top - 5 * (4 * (t1 - 0.5) ** 2)
            sag2 = cable_top - 5 * (4 * (t2 - 0.5) ** 2)

            y = side * bridge_width/2 * 0.7

            length = math.sqrt((x2-x1)**2 + (sag2-sag1)**2)
            angle = math.atan2(sag2-sag1, x2-x1)

            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.3,
                depth=length,
                vertices=4,
                location=((x1+x2)/2, y, (sag1+sag2)/2)
            )
            cable = bpy.context.active_object
            cable.name = f"Cable_{cable_idx}"
            cable_idx += 1
            cable.rotation_euler = (0, -angle, 0)
            apply_material(cable, cable_mat)
            parts.append(cable)

    # Vertical suspenders
    num_suspenders = 8
    suspender_idx = 0
    for i in range(num_suspenders):
        t = i / (num_suspenders - 1)
        x = -bridge_length/2 + t * bridge_length
        cable_top = deck_height + tower_height
        sag = cable_top - 5 * (4 * (t - 0.5) ** 2)

        for side in [-1, 1]:
            height = sag - deck_height - 1

            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.15,
                depth=height,
                vertices=4,
                location=(x, side * bridge_width/2 * 0.7, deck_height + 1 + height/2)
            )
            suspender = bpy.context.active_object
            suspender.name = f"Cable_Suspender_{suspender_idx}"
            suspender_idx += 1
            apply_material(suspender, cable_mat)
            parts.append(suspender)

    # Railings
    rail_idx = 0
    for side in [-1, 1]:
        # Horizontal rail
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.4,
            depth=bridge_length,
            vertices=6,
            location=(0, side * bridge_width/2 * 0.95, deck_height + 2.5)
        )
        rail = bpy.context.active_object
        rail.name = f"Rail_{rail_idx}"
        rail_idx += 1
        rail.rotation_euler = (0, math.radians(90), 0)
        apply_material(rail, rust_mat)
        parts.append(rail)

        # Vertical posts
        for i in range(10):
            x = -bridge_length/2 + 4 + i * (bridge_length - 8) / 9
            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.25,
                depth=3,
                vertices=4,
                location=(x, side * bridge_width/2 * 0.95, deck_height + 1.5)
            )
            post = bpy.context.active_object
            post.name = f"Rust_Post_{rail_idx}_{i}"
            apply_material(post, rust_mat)
            parts.append(post)

    # Group
    structure = group_objects(parts, "Bridge")

    # Export
    filepath = os.path.join(OUTPUT_DIR, "bridge.fbx")
    export_fbx(filepath, scale=EXPORT_SCALE)

    print("Created Bridge (80x5x15 studs)")
    return structure


def create_water_tower():
    """
    Create a Water Tower - town landmark.
    Target size: 15x35x15 studs (Width x Height x Depth)

    Part naming for AssetColors pattern matching:
    - "Tank_*" -> Tank metal color
    - "Rust_*" / "Leg_*" / "Brace_*" -> Rusty frame color
    - Others -> Tank primary color
    """
    clear_scene()
    parts = []

    # Materials
    tank_mat = create_material("TankMetal", (0.5, 0.5, 0.55))
    rust_mat = create_material("TowerRust", (0.45, 0.3, 0.2))

    # Target: 15 wide, 35 tall, 15 deep
    tank_height = 12
    tank_radius = 7
    leg_height = 22

    # Tank (cylinder)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=tank_radius,
        depth=tank_height,
        vertices=16,
        location=(0, 0, leg_height + tank_height/2)
    )
    tank = bpy.context.active_object
    tank.name = "Tank"
    apply_material(tank, tank_mat)
    smooth_shade(tank)
    parts.append(tank)

    # Dome top
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=tank_radius,
        segments=16,
        ring_count=8,
        location=(0, 0, leg_height + tank_height)
    )
    dome = bpy.context.active_object
    dome.name = "Tank_Dome"
    dome.scale = (1, 1, 0.4)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(dome, tank_mat)
    smooth_shade(dome)
    parts.append(dome)

    # Support legs (4)
    for idx, angle in enumerate([45, 135, 225, 315]):
        rad = math.radians(angle)
        x = math.cos(rad) * tank_radius * 0.7
        y = math.sin(rad) * tank_radius * 0.7

        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.8,
            depth=leg_height,
            vertices=8,
            location=(x, y, leg_height/2)
        )
        leg = bpy.context.active_object
        leg.name = f"Leg_{idx}"
        apply_material(leg, rust_mat)
        parts.append(leg)

    # Cross braces
    brace_idx = 0
    for height in [5, 12, 18]:
        for i in range(4):
            angle1 = math.radians(45 + i * 90)
            angle2 = math.radians(45 + (i + 1) * 90)

            x1 = math.cos(angle1) * tank_radius * 0.7
            y1 = math.sin(angle1) * tank_radius * 0.7
            x2 = math.cos(angle2) * tank_radius * 0.7
            y2 = math.sin(angle2) * tank_radius * 0.7

            length = math.sqrt((x2-x1)**2 + (y2-y1)**2)
            angle = math.atan2(y2-y1, x2-x1)

            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.4,
                depth=length,
                vertices=6,
                location=((x1+x2)/2, (y1+y2)/2, height)
            )
            brace = bpy.context.active_object
            brace.name = f"Brace_{brace_idx}"
            brace_idx += 1
            brace.rotation_euler = (math.radians(90), 0, angle)
            apply_material(brace, rust_mat)
            parts.append(brace)

    # Ladder
    for i in range(20):
        z = 1.5 + i * 1.1
        if z > leg_height:
            break
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.15,
            depth=2,
            vertices=4,
            location=(tank_radius * 0.7, 0, z)
        )
        rung = bpy.context.active_object
        rung.name = f"Rust_Rung_{i}"
        rung.rotation_euler = (0, math.radians(90), 0)
        apply_material(rung, rust_mat)
        parts.append(rung)

    # Group
    structure = group_objects(parts, "WaterTower")

    # Export
    filepath = os.path.join(OUTPUT_DIR, "water_tower.fbx")
    export_fbx(filepath, scale=EXPORT_SCALE)

    print("Created Water Tower (15x35x15 studs)")
    return structure


def create_lighthouse():
    """
    Create a Lighthouse - coastal beacon.
    Target size: 10x30x10 studs (Width x Height x Depth)

    Part naming for AssetColors pattern matching:
    - "Red_*" / "Dome" / "Door" / "Band_*" / "Railing" -> Red accent color
    - "Glass_*" / "Housing" -> Glass color
    - "Light" -> Glowing light color
    - Others -> White primary color
    """
    clear_scene()
    parts = []

    # Materials
    white_mat = create_material("LighthouseWhite", (0.9, 0.9, 0.88))
    red_mat = create_material("LighthouseRed", (0.7, 0.15, 0.1))
    glass_mat = create_material("LighthouseGlass", (0.4, 0.5, 0.6))
    light_mat = create_material("LighthouseLight", (1.0, 0.95, 0.8), emission=10.0)

    # Target: 10 wide, 30 tall, 10 deep
    base_radius = 5
    top_radius = 3
    tower_height = 24

    # Main tower (tapered cylinder)
    bpy.ops.mesh.primitive_cone_add(
        vertices=24,
        radius1=base_radius,
        radius2=top_radius,
        depth=tower_height,
        location=(0, 0, tower_height/2)
    )
    tower = bpy.context.active_object
    tower.name = "Tower"
    apply_material(tower, white_mat)
    smooth_shade(tower)
    parts.append(tower)

    # Red stripe bands
    for idx, height in enumerate([6, 12, 18]):
        t = height / tower_height
        radius = base_radius - (base_radius - top_radius) * t

        bpy.ops.mesh.primitive_torus_add(
            major_radius=radius + 0.1,
            minor_radius=0.5,
            major_segments=24,
            minor_segments=6,
            location=(0, 0, height)
        )
        band = bpy.context.active_object
        band.name = f"Band_{idx}"
        apply_material(band, red_mat)
        parts.append(band)

    # Observation deck
    bpy.ops.mesh.primitive_cylinder_add(
        radius=top_radius + 1.5,
        depth=0.8,
        vertices=16,
        location=(0, 0, tower_height)
    )
    deck = bpy.context.active_object
    deck.name = "Deck"
    apply_material(deck, white_mat)
    parts.append(deck)

    # Railing
    bpy.ops.mesh.primitive_torus_add(
        major_radius=top_radius + 1.2,
        minor_radius=0.25,
        major_segments=16,
        minor_segments=6,
        location=(0, 0, tower_height + 1.2)
    )
    railing = bpy.context.active_object
    railing.name = "Railing"
    apply_material(railing, red_mat)
    parts.append(railing)

    # Light housing
    bpy.ops.mesh.primitive_cylinder_add(
        radius=top_radius * 0.8,
        depth=4,
        vertices=16,
        location=(0, 0, tower_height + 2.5)
    )
    housing = bpy.context.active_object
    housing.name = "Housing"
    apply_material(housing, glass_mat)
    smooth_shade(housing)
    parts.append(housing)

    # Light source
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=1.5,
        segments=12,
        ring_count=8,
        location=(0, 0, tower_height + 2.5)
    )
    light = bpy.context.active_object
    light.name = "Light"
    apply_material(light, light_mat)
    parts.append(light)

    # Dome top
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=top_radius * 0.8,
        segments=16,
        ring_count=8,
        location=(0, 0, tower_height + 5)
    )
    dome = bpy.context.active_object
    dome.name = "Dome"
    dome.scale = (1, 1, 0.6)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(dome, red_mat)
    smooth_shade(dome)
    parts.append(dome)

    # Door
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, -base_radius + 0.3, 3)
    )
    door = bpy.context.active_object
    door.name = "Door"
    door.scale = (2.5, 0.4, 5)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(door, red_mat)
    parts.append(door)

    # Group
    structure = group_objects(parts, "Lighthouse")

    # Export
    filepath = os.path.join(OUTPUT_DIR, "lighthouse.fbx")
    export_fbx(filepath, scale=EXPORT_SCALE)

    print("Created Lighthouse (10x30x10 studs)")
    return structure


def main():
    """Generate all structure models."""
    print("=" * 50)
    print("Faultline Fear: Structure Generator")
    print("=" * 50)
    print("Building at 1:1 stud scale (1 unit = 1 stud)")
    print(f"Export scale: {EXPORT_SCALE}")
    print("=" * 50)

    # Ensure output directory exists
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Create all structures
    create_ferris_wheel()
    create_radio_tower()
    create_abandoned_house()
    create_bridge()
    create_water_tower()
    create_lighthouse()

    print("=" * 50)
    print(f"All structures exported to: {OUTPUT_DIR}")
    print("Next steps:")
    print("1. Upload FBX files to Roblox Creator Hub")
    print("2. Update asset IDs in AssetManifest.luau and plugin")
    print("3. Use plugin 'Clear ALL' then 'Download & Scale' to test")
    print("=" * 50)


if __name__ == "__main__":
    main()
