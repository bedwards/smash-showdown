"""
Faultline Fear: Structure Model Generator

Creates iconic California-inspired structures for the game.
Run with: blender --background --python tools/blender/create_structures.py

Structures:
1. Ferris Wheel - Beach landmark, rotating beacon
2. Radio Tower - Mountain summit rescue beacon
3. Abandoned House - Modular town building
4. Bridge - Fault line crossing
5. Water Tower - Town landmark
6. Lighthouse - Coastal beacon
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
    join_objects,
    export_fbx,
    smooth_shade,
)

# Output directory
OUTPUT_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "..", "assets", "models", "structures")


def create_ferris_wheel():
    """
    Create a Ferris Wheel - beach landmark.

    Design: Large wheel with gondolas, support structure.
    Scale: ~40 studs tall when imported.
    """
    clear_scene()
    parts = []

    # Materials
    metal_mat = create_material("Metal", (0.3, 0.3, 0.35))
    rust_mat = create_material("Rust", (0.4, 0.25, 0.15))
    gondola_mat = create_material("Gondola", (0.8, 0.2, 0.2))
    light_mat = create_material("Light", (1.0, 0.9, 0.7), emission=3.0)

    wheel_radius = 1.8
    num_spokes = 12
    num_gondolas = 8

    # Main wheel rim (torus)
    bpy.ops.mesh.primitive_torus_add(
        major_radius=wheel_radius,
        minor_radius=0.05,
        location=(0, 0, 2.2)
    )
    rim = bpy.context.active_object
    rim.name = "Rim"
    apply_material(rim, metal_mat)
    parts.append(rim)

    # Inner rim
    bpy.ops.mesh.primitive_torus_add(
        major_radius=wheel_radius * 0.7,
        minor_radius=0.03,
        location=(0, 0, 2.2)
    )
    inner_rim = bpy.context.active_object
    apply_material(inner_rim, metal_mat)
    parts.append(inner_rim)

    # Hub
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.15,
        depth=0.3,
        location=(0, 0, 2.2)
    )
    hub = bpy.context.active_object
    hub.rotation_euler = (math.radians(90), 0, 0)
    apply_material(hub, metal_mat)
    parts.append(hub)

    # Spokes
    for i in range(num_spokes):
        angle = (2 * math.pi * i) / num_spokes

        # Outer spoke
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.02,
            depth=wheel_radius,
            location=(0, 0, 2.2)
        )
        spoke = bpy.context.active_object
        spoke.rotation_euler = (0, math.radians(90), angle)
        # Move to correct position
        spoke.location = (
            math.cos(angle) * wheel_radius / 2,
            0,
            2.2 + math.sin(angle) * wheel_radius / 2
        )
        apply_material(spoke, metal_mat)
        parts.append(spoke)

    # Gondolas
    for i in range(num_gondolas):
        angle = (2 * math.pi * i) / num_gondolas
        x = math.cos(angle) * wheel_radius
        z = 2.2 + math.sin(angle) * wheel_radius

        # Gondola body
        bpy.ops.mesh.primitive_cube_add(
            size=0.3,
            location=(x, 0, z - 0.2)
        )
        gondola = bpy.context.active_object
        gondola.scale = (1, 0.6, 1.2)
        bpy.ops.object.transform_apply(scale=True)
        apply_material(gondola, gondola_mat)
        parts.append(gondola)

        # Light on gondola
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.04,
            location=(x, 0, z - 0.05)
        )
        light = bpy.context.active_object
        apply_material(light, light_mat)
        parts.append(light)

    # Support structure - A-frame
    for side in [-1, 1]:
        # Main support leg
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.08,
            depth=3.0,
            location=(side * 0.8, 0, 1.1)
        )
        leg = bpy.context.active_object
        leg.rotation_euler = (0, math.radians(side * 15), 0)
        apply_material(leg, rust_mat)
        parts.append(leg)

        # Cross brace
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.04,
            depth=1.8,
            location=(side * 0.4, 0, 0.8)
        )
        brace = bpy.context.active_object
        brace.rotation_euler = (0, math.radians(-side * 45), 0)
        apply_material(brace, rust_mat)
        parts.append(brace)

    # Base platform
    bpy.ops.mesh.primitive_cube_add(
        size=0.5,
        location=(0, 0, -0.1)
    )
    base = bpy.context.active_object
    base.scale = (4, 2, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(base, metal_mat)
    parts.append(base)

    # Smooth all parts
    for part in parts:
        smooth_shade(part)

    # Join
    structure = join_objects(parts)
    structure.name = "FerrisWheel"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "ferris_wheel.fbx")
    export_fbx(filepath, scale=100)

    print("Created Ferris Wheel")
    return structure


def create_radio_tower():
    """
    Create a Radio Tower - mountain summit rescue beacon.

    Design: Tall lattice tower with antenna and blinking light.
    Scale: ~60 studs tall when imported.
    """
    clear_scene()
    parts = []

    # Materials
    metal_mat = create_material("TowerMetal", (0.5, 0.5, 0.55))
    red_mat = create_material("TowerRed", (0.8, 0.1, 0.1))
    light_mat = create_material("BeaconLight", (1.0, 0.2, 0.1), emission=8.0)

    tower_height = 3.0
    base_width = 0.6
    top_width = 0.15
    num_sections = 6

    # Tower legs (4 corners)
    for corner in [(-1, -1), (-1, 1), (1, -1), (1, 1)]:
        # Tapered leg
        bpy.ops.mesh.primitive_cone_add(
            vertices=4,
            radius1=0.04,
            radius2=0.02,
            depth=tower_height,
            location=(corner[0] * base_width/2, corner[1] * base_width/2, tower_height/2)
        )
        leg = bpy.context.active_object
        apply_material(leg, metal_mat)
        parts.append(leg)

    # Horizontal braces at each section
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
                radius=0.015,
                depth=length,
                location=((x1+x2)/2, (y1+y2)/2, height)
            )
            brace = bpy.context.active_object
            brace.rotation_euler = (0, 0, angle + math.radians(90))
            # Alternate red and white for visibility
            if section % 2 == 0:
                apply_material(brace, metal_mat)
            else:
                apply_material(brace, red_mat)
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
                    radius=0.01,
                    depth=length,
                    location=((x1+x2)/2, (y1+y2)/2, (height + next_height)/2)
                )
                diag = bpy.context.active_object
                # Calculate rotation
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
        radius=0.03,
        depth=0.5,
        location=(0, 0, tower_height + 0.25)
    )
    mast = bpy.context.active_object
    apply_material(mast, metal_mat)
    parts.append(mast)

    # Beacon light
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.08,
        location=(0, 0, tower_height + 0.55)
    )
    beacon = bpy.context.active_object
    beacon.name = "Beacon"
    apply_material(beacon, light_mat)
    parts.append(beacon)

    # Guy wires (visual only)
    for angle in [0, 120, 240]:
        rad = math.radians(angle)
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.005,
            depth=tower_height * 1.2,
            location=(math.cos(rad) * 0.4, math.sin(rad) * 0.4, tower_height * 0.5)
        )
        wire = bpy.context.active_object
        wire.rotation_euler = (math.radians(60), 0, rad)
        apply_material(wire, metal_mat)
        parts.append(wire)

    # Join
    structure = join_objects(parts)
    structure.name = "RadioTower"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "radio_tower.fbx")
    export_fbx(filepath, scale=100)

    print("Created Radio Tower")
    return structure


def create_abandoned_house():
    """
    Create an Abandoned House - modular town building.

    Design: Simple two-story house with broken windows, weathered look.
    Scale: ~25 studs tall when imported.
    """
    clear_scene()
    parts = []

    # Materials
    wall_mat = create_material("WornWall", (0.6, 0.55, 0.5))
    roof_mat = create_material("Shingles", (0.25, 0.2, 0.18))
    window_mat = create_material("BrokenGlass", (0.3, 0.35, 0.4))
    wood_mat = create_material("WornWood", (0.35, 0.25, 0.15))

    # Main structure
    house_width = 1.2
    house_depth = 1.0
    house_height = 1.0

    # Walls (hollow box)
    wall_thickness = 0.05

    # Front wall
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -house_depth/2 + wall_thickness/2, house_height/2))
    front = bpy.context.active_object
    front.scale = (house_width, wall_thickness, house_height)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(front, wall_mat)
    parts.append(front)

    # Back wall
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, house_depth/2 - wall_thickness/2, house_height/2))
    back = bpy.context.active_object
    back.scale = (house_width, wall_thickness, house_height)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(back, wall_mat)
    parts.append(back)

    # Side walls
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(side * (house_width/2 - wall_thickness/2), 0, house_height/2)
        )
        wall = bpy.context.active_object
        wall.scale = (wall_thickness, house_depth, house_height)
        bpy.ops.object.transform_apply(scale=True)
        apply_material(wall, wall_mat)
        parts.append(wall)

    # Roof (triangular prism)
    roof_height = 0.4
    bpy.ops.mesh.primitive_cone_add(
        vertices=4,
        radius1=house_width * 0.75,
        depth=roof_height,
        location=(0, 0, house_height + roof_height/2)
    )
    roof = bpy.context.active_object
    roof.scale = (1, house_depth/house_width * 0.8, 1)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(roof, roof_mat)
    parts.append(roof)

    # Door
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0.2, -house_depth/2 + 0.01, 0.25)
    )
    door = bpy.context.active_object
    door.scale = (0.25, 0.02, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(door, wood_mat)
    parts.append(door)

    # Windows (broken - just frames)
    window_positions = [
        (-0.35, -house_depth/2, 0.6),  # Front left
        (0.35, -house_depth/2, 0.6),   # Front right (missing)
        (-0.35, house_depth/2, 0.6),   # Back
    ]

    for i, pos in enumerate(window_positions):
        if i == 1:  # Skip one window (broken out)
            continue
        bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
        window = bpy.context.active_object
        window.scale = (0.2, 0.02, 0.25)
        bpy.ops.object.transform_apply(scale=True)
        apply_material(window, window_mat)
        parts.append(window)

    # Porch
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, -house_depth/2 - 0.15, 0.05)
    )
    porch = bpy.context.active_object
    porch.scale = (0.6, 0.3, 0.1)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(porch, wood_mat)
    parts.append(porch)

    # Chimney
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0.4, 0.2, house_height + 0.3)
    )
    chimney = bpy.context.active_object
    chimney.scale = (0.15, 0.15, 0.4)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(chimney, wall_mat)
    parts.append(chimney)

    # Smooth and join
    for part in parts:
        smooth_shade(part)

    structure = join_objects(parts)
    structure.name = "AbandonedHouse"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "abandoned_house.fbx")
    export_fbx(filepath, scale=100)

    print("Created Abandoned House")
    return structure


def create_bridge():
    """
    Create a Bridge - fault line crossing.

    Design: Suspension bridge segment, partially damaged.
    Scale: ~80 studs long when imported.
    """
    clear_scene()
    parts = []

    # Materials
    steel_mat = create_material("BridgeSteel", (0.4, 0.4, 0.45))
    concrete_mat = create_material("Concrete", (0.5, 0.5, 0.48))
    cable_mat = create_material("Cable", (0.2, 0.2, 0.22))
    rust_mat = create_material("BridgeRust", (0.5, 0.3, 0.2))

    bridge_length = 4.0
    bridge_width = 0.8
    tower_height = 1.5

    # Road deck
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, 0, 0)
    )
    deck = bpy.context.active_object
    deck.scale = (bridge_length, bridge_width, 0.1)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(deck, concrete_mat)
    parts.append(deck)

    # Support towers (2)
    for x_pos in [-bridge_length/3, bridge_length/3]:
        for side in [-1, 1]:
            # Vertical tower
            bpy.ops.mesh.primitive_cube_add(
                size=1,
                location=(x_pos, side * bridge_width/2 * 0.8, tower_height/2)
            )
            tower = bpy.context.active_object
            tower.scale = (0.1, 0.1, tower_height)
            bpy.ops.object.transform_apply(scale=True)
            apply_material(tower, steel_mat)
            parts.append(tower)

        # Cross beam at top
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(x_pos, 0, tower_height)
        )
        beam = bpy.context.active_object
        beam.scale = (0.1, bridge_width * 0.8, 0.08)
        bpy.ops.object.transform_apply(scale=True)
        apply_material(beam, steel_mat)
        parts.append(beam)

    # Main cables (catenary shape approximation)
    cable_points = 20
    for side in [-1, 1]:
        for i in range(cable_points - 1):
            t1 = i / (cable_points - 1)
            t2 = (i + 1) / (cable_points - 1)

            x1 = -bridge_length/2 + t1 * bridge_length
            x2 = -bridge_length/2 + t2 * bridge_length

            # Parabolic sag
            sag1 = tower_height - 0.3 * (4 * (t1 - 0.5) ** 2)
            sag2 = tower_height - 0.3 * (4 * (t2 - 0.5) ** 2)

            y = side * bridge_width/2 * 0.7

            # Cable segment
            length = math.sqrt((x2-x1)**2 + (sag2-sag1)**2)
            angle = math.atan2(sag2-sag1, x2-x1)

            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.015,
                depth=length,
                location=((x1+x2)/2, y, (sag1+sag2)/2)
            )
            cable = bpy.context.active_object
            cable.rotation_euler = (0, -angle, 0)
            apply_material(cable, cable_mat)
            parts.append(cable)

    # Vertical suspenders
    num_suspenders = 10
    for i in range(num_suspenders):
        t = i / (num_suspenders - 1)
        x = -bridge_length/2 + t * bridge_length
        sag = tower_height - 0.3 * (4 * (t - 0.5) ** 2)

        for side in [-1, 1]:
            height = sag - 0.05  # From cable to deck

            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.008,
                depth=height,
                location=(x, side * bridge_width/2 * 0.7, height/2 + 0.05)
            )
            suspender = bpy.context.active_object
            apply_material(suspender, cable_mat)
            parts.append(suspender)

    # Railings
    for side in [-1, 1]:
        # Horizontal rail
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.02,
            depth=bridge_length,
            location=(0, side * bridge_width/2 * 0.95, 0.15)
        )
        rail = bpy.context.active_object
        rail.rotation_euler = (0, math.radians(90), 0)
        apply_material(rail, rust_mat)
        parts.append(rail)

        # Vertical posts
        for i in range(12):
            x = -bridge_length/2 + 0.2 + i * (bridge_length - 0.4) / 11
            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.015,
                depth=0.2,
                location=(x, side * bridge_width/2 * 0.95, 0.1)
            )
            post = bpy.context.active_object
            apply_material(post, rust_mat)
            parts.append(post)

    # Add some damage - broken railing section
    # (Already looks weathered with rust material)

    # Join
    structure = join_objects(parts)
    structure.name = "Bridge"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "bridge.fbx")
    export_fbx(filepath, scale=100)

    print("Created Bridge")
    return structure


def create_water_tower():
    """
    Create a Water Tower - town landmark.

    Design: Classic elevated water tank on steel frame.
    Scale: ~35 studs tall when imported.
    """
    clear_scene()
    parts = []

    # Materials
    tank_mat = create_material("TankMetal", (0.5, 0.5, 0.55))
    rust_mat = create_material("TowerRust", (0.45, 0.3, 0.2))

    tank_height = 0.8
    tank_radius = 0.5
    leg_height = 1.5

    # Tank (cylinder with dome top)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=tank_radius,
        depth=tank_height,
        location=(0, 0, leg_height + tank_height/2)
    )
    tank = bpy.context.active_object
    apply_material(tank, tank_mat)
    smooth_shade(tank)
    parts.append(tank)

    # Dome top
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=tank_radius,
        location=(0, 0, leg_height + tank_height)
    )
    dome = bpy.context.active_object
    dome.scale = (1, 1, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(dome, tank_mat)
    smooth_shade(dome)
    parts.append(dome)

    # Support legs (4)
    for angle in [45, 135, 225, 315]:
        rad = math.radians(angle)
        x = math.cos(rad) * tank_radius * 0.7
        y = math.sin(rad) * tank_radius * 0.7

        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.05,
            depth=leg_height,
            location=(x, y, leg_height/2)
        )
        leg = bpy.context.active_object
        apply_material(leg, rust_mat)
        parts.append(leg)

    # Cross braces
    for height in [0.3, 0.8, 1.2]:
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
                radius=0.025,
                depth=length,
                location=((x1+x2)/2, (y1+y2)/2, height)
            )
            brace = bpy.context.active_object
            brace.rotation_euler = (math.radians(90), 0, angle)
            apply_material(brace, rust_mat)
            parts.append(brace)

    # Ladder
    for i in range(15):
        z = 0.1 + i * 0.12
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.01,
            depth=0.15,
            location=(tank_radius * 0.7, 0, z)
        )
        rung = bpy.context.active_object
        rung.rotation_euler = (0, math.radians(90), 0)
        apply_material(rung, rust_mat)
        parts.append(rung)

    # Join
    structure = join_objects(parts)
    structure.name = "WaterTower"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "water_tower.fbx")
    export_fbx(filepath, scale=100)

    print("Created Water Tower")
    return structure


def create_lighthouse():
    """
    Create a Lighthouse - coastal beacon.

    Design: Classic white lighthouse with light housing.
    Scale: ~30 studs tall when imported.
    """
    clear_scene()
    parts = []

    # Materials
    white_mat = create_material("LighthouseWhite", (0.9, 0.9, 0.88))
    red_mat = create_material("LighthouseRed", (0.7, 0.15, 0.1))
    glass_mat = create_material("LighthouseGlass", (0.4, 0.5, 0.6))
    light_mat = create_material("LighthouseLight", (1.0, 0.95, 0.8), emission=10.0)

    base_radius = 0.4
    top_radius = 0.25
    tower_height = 1.5

    # Main tower (tapered cylinder)
    bpy.ops.mesh.primitive_cone_add(
        vertices=32,
        radius1=base_radius,
        radius2=top_radius,
        depth=tower_height,
        location=(0, 0, tower_height/2)
    )
    tower = bpy.context.active_object
    apply_material(tower, white_mat)
    smooth_shade(tower)
    parts.append(tower)

    # Red stripe bands
    for height in [0.4, 0.8, 1.2]:
        t = height / tower_height
        radius = base_radius - (base_radius - top_radius) * t

        bpy.ops.mesh.primitive_torus_add(
            major_radius=radius,
            minor_radius=0.03,
            location=(0, 0, height)
        )
        band = bpy.context.active_object
        apply_material(band, red_mat)
        parts.append(band)

    # Observation deck
    bpy.ops.mesh.primitive_cylinder_add(
        radius=top_radius + 0.1,
        depth=0.05,
        location=(0, 0, tower_height)
    )
    deck = bpy.context.active_object
    apply_material(deck, white_mat)
    parts.append(deck)

    # Railing
    bpy.ops.mesh.primitive_torus_add(
        major_radius=top_radius + 0.08,
        minor_radius=0.015,
        location=(0, 0, tower_height + 0.08)
    )
    railing = bpy.context.active_object
    apply_material(railing, red_mat)
    parts.append(railing)

    # Light housing
    bpy.ops.mesh.primitive_cylinder_add(
        radius=top_radius * 0.8,
        depth=0.25,
        location=(0, 0, tower_height + 0.15)
    )
    housing = bpy.context.active_object
    apply_material(housing, glass_mat)
    smooth_shade(housing)
    parts.append(housing)

    # Light source
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=0.1,
        location=(0, 0, tower_height + 0.15)
    )
    light = bpy.context.active_object
    light.name = "Light"
    apply_material(light, light_mat)
    parts.append(light)

    # Dome top
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=top_radius * 0.8,
        location=(0, 0, tower_height + 0.32)
    )
    dome = bpy.context.active_object
    dome.scale = (1, 1, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(dome, red_mat)
    smooth_shade(dome)
    parts.append(dome)

    # Door
    bpy.ops.mesh.primitive_cube_add(
        size=1,
        location=(0, -base_radius + 0.02, 0.2)
    )
    door = bpy.context.active_object
    door.scale = (0.15, 0.02, 0.35)
    bpy.ops.object.transform_apply(scale=True)
    apply_material(door, red_mat)
    parts.append(door)

    # Join
    structure = join_objects(parts)
    structure.name = "Lighthouse"

    # Export
    filepath = os.path.join(OUTPUT_DIR, "lighthouse.fbx")
    export_fbx(filepath, scale=100)

    print("Created Lighthouse")
    return structure


def main():
    """Generate all structure models."""
    print("=" * 50)
    print("Faultline Fear: Structure Generator")
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
    print("=" * 50)


if __name__ == "__main__":
    main()
