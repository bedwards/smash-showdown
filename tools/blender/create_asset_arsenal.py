"""
Faultline Fear: Comprehensive Asset Arsenal Generator

Creates eye-popping 3D assets for:
- Earthquake destruction
- 1960s retro California
- Beach/coastal
- Mountains/terrain
- Fault line features
- Horror/liminal spaces
- Survival props

Run: blender --background --python tools/blender/create_asset_arsenal.py
"""

import bpy
import math
import os
import sys

# Add tools directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from blender_utils import (
    clear_scene, create_material, apply_material,
    export_fbx, create_primitive, smooth_shade,
    group_objects, set_origin_to_bottom
)

OUTPUT_DIR = "assets/models/arsenal"
EXPORT_SCALE = 1.0  # 1:1 stud scale

# ===========================================
# COLOR PALETTES
# ===========================================

COLORS = {
    # Retro 60s California
    "turquoise": (0.25, 0.88, 0.82),
    "coral": (1.0, 0.5, 0.31),
    "mustard": (1.0, 0.86, 0.35),
    "pink": (1.0, 0.71, 0.76),
    "cream": (1.0, 0.99, 0.82),
    "teal": (0.0, 0.5, 0.5),
    "orange": (1.0, 0.55, 0.0),

    # Neon signs
    "neon_pink": (1.0, 0.08, 0.58),
    "neon_blue": (0.0, 0.75, 1.0),
    "neon_green": (0.22, 1.0, 0.08),
    "neon_orange": (1.0, 0.4, 0.0),

    # Horror/liminal
    "sickly_yellow": (0.9, 0.9, 0.5),
    "concrete_gray": (0.5, 0.5, 0.5),
    "rust": (0.72, 0.26, 0.06),
    "dried_blood": (0.4, 0.1, 0.1),
    "mold_green": (0.3, 0.4, 0.2),

    # Natural
    "sand": (0.76, 0.70, 0.50),
    "palm_green": (0.13, 0.55, 0.13),
    "ocean_blue": (0.0, 0.47, 0.75),
    "rock_brown": (0.4, 0.3, 0.2),
    "lava_red": (1.0, 0.2, 0.0),
    "steam_white": (0.95, 0.95, 0.95),

    # Metal/industrial
    "chrome": (0.77, 0.77, 0.77),
    "copper": (0.72, 0.45, 0.20),
    "steel": (0.5, 0.5, 0.55),

    # Wood
    "wood_light": (0.76, 0.60, 0.42),
    "wood_dark": (0.4, 0.26, 0.13),
    "driftwood": (0.6, 0.55, 0.5),
}

def ensure_output_dir():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

def export_asset(name):
    filepath = os.path.join(OUTPUT_DIR, f"{name}.fbx")
    export_fbx(filepath, EXPORT_SCALE)
    print(f"Exported: {name}")

# ===========================================
# 1. RETRO 60s CALIFORNIA
# ===========================================

def create_vintage_diner():
    """Classic 1960s roadside diner with chrome and neon"""
    clear_scene()
    parts = []

    # Main building - streamlined design
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 6))
    body = bpy.context.active_object
    body.name = "DinerBody"
    body.scale = (20, 12, 6)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("DinerTurquoise", COLORS["turquoise"])
    apply_material(body, mat)
    parts.append(body)

    # Chrome trim band
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 10))
    trim = bpy.context.active_object
    trim.name = "ChromeTrim"
    trim.scale = (20.5, 12.5, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("Chrome", COLORS["chrome"])
    apply_material(trim, mat)
    parts.append(trim)

    # Roof with slight angle
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 11.5))
    roof = bpy.context.active_object
    roof.name = "Roof"
    roof.scale = (21, 13, 1)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("RoofCream", COLORS["cream"])
    apply_material(roof, mat)
    parts.append(roof)

    # Large windows
    for x in [-8, 0, 8]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 6.1, 5))
        window = bpy.context.active_object
        window.name = f"Window_{x}"
        window.scale = (5, 0.2, 4)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material("Glass", (0.6, 0.8, 0.9, 0.5))
        apply_material(window, mat)
        parts.append(window)

    # Neon sign on roof "EATS"
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 14))
    sign = bpy.context.active_object
    sign.name = "NeonSign"
    sign.scale = (8, 0.5, 3)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("NeonPink", COLORS["neon_pink"], emission=2.0)
    apply_material(sign, mat)
    parts.append(sign)

    # Counter stools visible through window
    for x in [-6, -3, 0, 3, 6]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.8, depth=0.3, location=(x, 4, 2.5))
        seat = bpy.context.active_object
        seat.name = f"Stool_{x}"
        mat = create_material("CoralSeat", COLORS["coral"])
        apply_material(seat, mat)
        parts.append(seat)

        bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=2.5, location=(x, 4, 1))
        pole = bpy.context.active_object
        pole.name = f"StoolPole_{x}"
        mat = create_material("ChromePole", COLORS["chrome"])
        apply_material(pole, mat)
        parts.append(pole)

    group_objects(parts, "VintageDiner")
    export_asset("vintage_diner")

def create_retro_gas_station():
    """1960s Googie-style gas station with dramatic canopy"""
    clear_scene()
    parts = []

    # Office building
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-12, 0, 5))
    office = bpy.context.active_object
    office.name = "Office"
    office.scale = (8, 10, 5)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("OfficeCream", COLORS["cream"])
    apply_material(office, mat)
    parts.append(office)

    # Dramatic angular canopy (Googie style)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(5, 0, 12))
    canopy = bpy.context.active_object
    canopy.name = "Canopy"
    canopy.scale = (25, 15, 0.5)
    canopy.rotation_euler = (0.1, 0, 0)  # Slight tilt
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    mat = create_material("CanopyOrange", COLORS["orange"])
    apply_material(canopy, mat)
    parts.append(canopy)

    # Canopy support columns
    for pos in [(-8, -6), (-8, 6), (18, -6), (18, 6)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=12, location=(pos[0], pos[1], 6))
        col = bpy.context.active_object
        col.name = f"Column_{pos[0]}_{pos[1]}"
        mat = create_material("SteelColumn", COLORS["steel"])
        apply_material(col, mat)
        parts.append(col)

    # Gas pumps (vintage style)
    for x in [0, 8]:
        # Pump body
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0, 3))
        pump = bpy.context.active_object
        pump.name = f"Pump_{x}"
        pump.scale = (2, 1.5, 6)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material("PumpRed", (0.8, 0.1, 0.1))
        apply_material(pump, mat)
        parts.append(pump)

        # Pump globe on top
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1, location=(x, 0, 7))
        globe = bpy.context.active_object
        globe.name = f"Globe_{x}"
        mat = create_material("GlobeWhite", COLORS["cream"], emission=0.5)
        apply_material(globe, mat)
        smooth_shade(globe)
        parts.append(globe)

    # Tall sign pole with rotating sign
    bpy.ops.mesh.primitive_cylinder_add(radius=0.4, depth=25, location=(20, 0, 12.5))
    pole = bpy.context.active_object
    pole.name = "SignPole"
    mat = create_material("PoleSteel", COLORS["steel"])
    apply_material(pole, mat)
    parts.append(pole)

    # Sign at top
    bpy.ops.mesh.primitive_cylinder_add(radius=5, depth=1, location=(20, 0, 26))
    sign = bpy.context.active_object
    sign.name = "RotatingSign"
    mat = create_material("SignTeal", COLORS["teal"], emission=1.0)
    apply_material(sign, mat)
    parts.append(sign)

    group_objects(parts, "RetroGasStation")
    export_asset("retro_gas_station")

def create_classic_car_57():
    """1957-style classic car with fins"""
    clear_scene()
    parts = []

    # Main body
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2))
    body = bpy.context.active_object
    body.name = "CarBody"
    body.scale = (8, 3, 1.5)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("CarTurquoise", COLORS["turquoise"])
    apply_material(body, mat)
    parts.append(body)

    # Cabin
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 3.5))
    cabin = bpy.context.active_object
    cabin.name = "Cabin"
    cabin.scale = (4, 2.8, 1.2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("CabinCream", COLORS["cream"])
    apply_material(cabin, mat)
    parts.append(cabin)

    # Tail fins
    for y in [-1.5, 1.5]:
        bpy.ops.mesh.primitive_cone_add(radius1=0.8, radius2=0, depth=2, location=(-4, y, 3))
        fin = bpy.context.active_object
        fin.name = f"Fin_{y}"
        fin.rotation_euler = (1.57, 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material("FinChrome", COLORS["chrome"])
        apply_material(fin, mat)
        parts.append(fin)

    # Wheels
    for pos in [(-2.5, -1.6), (-2.5, 1.6), (2.5, -1.6), (2.5, 1.6)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=1, depth=0.6, location=(pos[0], pos[1], 1))
        wheel = bpy.context.active_object
        wheel.name = f"Wheel_{pos[0]}_{pos[1]}"
        wheel.rotation_euler = (1.57, 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material("Tire", (0.1, 0.1, 0.1))
        apply_material(wheel, mat)
        parts.append(wheel)

        # Hubcap
        bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=0.1, location=(pos[0], pos[1] + (0.35 if pos[1] > 0 else -0.35), 1))
        hub = bpy.context.active_object
        hub.name = f"Hubcap_{pos[0]}_{pos[1]}"
        hub.rotation_euler = (1.57, 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material("HubChrome", COLORS["chrome"])
        apply_material(hub, mat)
        parts.append(hub)

    # Chrome bumpers
    for x in [-4.2, 4.2]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0, 1.5))
        bumper = bpy.context.active_object
        bumper.name = f"Bumper_{x}"
        bumper.scale = (0.3, 3, 0.4)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material("BumperChrome", COLORS["chrome"])
        apply_material(bumper, mat)
        parts.append(bumper)

    # Headlights
    for y in [-1, 1]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.4, location=(4.1, y, 2))
        light = bpy.context.active_object
        light.name = f"Headlight_{y}"
        mat = create_material("HeadlightGlow", COLORS["cream"], emission=1.0)
        apply_material(light, mat)
        smooth_shade(light)
        parts.append(light)

    group_objects(parts, "ClassicCar57")
    export_asset("classic_car_57")

def create_motel_sign():
    """Iconic retro motel sign with arrow"""
    clear_scene()
    parts = []

    # Main pole
    bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=30, location=(0, 0, 15))
    pole = bpy.context.active_object
    pole.name = "Pole"
    mat = create_material("PoleSteel", COLORS["steel"])
    apply_material(pole, mat)
    parts.append(pole)

    # Sign board
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 28))
    board = bpy.context.active_object
    board.name = "SignBoard"
    board.scale = (12, 1, 8)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("SignPink", COLORS["pink"])
    apply_material(board, mat)
    parts.append(board)

    # "MOTEL" letters (simplified as blocks)
    for i, x in enumerate([-4, -2, 0, 2, 4]):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0.6, 28))
        letter = bpy.context.active_object
        letter.name = f"Letter_{i}"
        letter.scale = (1.5, 0.2, 3)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material("NeonLetters", COLORS["neon_pink"], emission=3.0)
        apply_material(letter, mat)
        parts.append(letter)

    # Arrow pointing down
    bpy.ops.mesh.primitive_cone_add(radius1=3, radius2=0, depth=5, location=(0, 0.6, 20))
    arrow = bpy.context.active_object
    arrow.name = "Arrow"
    arrow.rotation_euler = (0, 0, 3.14)  # Point down
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("ArrowNeon", COLORS["neon_orange"], emission=2.0)
    apply_material(arrow, mat)
    parts.append(arrow)

    # "VACANCY" sign below
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.6, 14))
    vacancy = bpy.context.active_object
    vacancy.name = "VacancySign"
    vacancy.scale = (8, 0.2, 2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("VacancyNeon", COLORS["neon_green"], emission=2.0)
    apply_material(vacancy, mat)
    parts.append(vacancy)

    group_objects(parts, "MotelSign")
    export_asset("motel_sign")

def create_drive_in_screen():
    """Drive-in movie theater screen"""
    clear_scene()
    parts = []

    # Main screen
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 25))
    screen = bpy.context.active_object
    screen.name = "Screen"
    screen.scale = (50, 1, 30)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("ScreenWhite", (0.95, 0.95, 0.95))
    apply_material(screen, mat)
    parts.append(screen)

    # Support structure (back)
    for x in [-20, 0, 20]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -2, 20))
        support = bpy.context.active_object
        support.name = f"Support_{x}"
        support.scale = (2, 3, 40)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material("SupportSteel", COLORS["steel"])
        apply_material(support, mat)
        parts.append(support)

    # Cross braces
    for z in [10, 30]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -2, z))
        brace = bpy.context.active_object
        brace.name = f"Brace_{z}"
        brace.scale = (45, 1, 1)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material("BraceSteel", COLORS["steel"])
        apply_material(brace, mat)
        parts.append(brace)

    # Speaker posts (a few in front)
    for x in [-30, -15, 0, 15, 30]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=5, location=(x, 20, 2.5))
        post = bpy.context.active_object
        post.name = f"SpeakerPost_{x}"
        mat = create_material("PostMetal", COLORS["steel"])
        apply_material(post, mat)
        parts.append(post)

    group_objects(parts, "DriveInScreen")
    export_asset("drive_in_screen")

def create_tiki_bar():
    """Beach tiki bar with thatched roof"""
    clear_scene()
    parts = []

    # Counter
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2))
    counter = bpy.context.active_object
    counter.name = "Counter"
    counter.scale = (12, 4, 2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("BambooCounter", COLORS["wood_light"])
    apply_material(counter, mat)
    parts.append(counter)

    # Bamboo posts
    for pos in [(-5, -2), (-5, 2), (5, -2), (5, 2)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.4, depth=10, location=(pos[0], pos[1], 5))
        post = bpy.context.active_object
        post.name = f"Post_{pos[0]}_{pos[1]}"
        mat = create_material("Bamboo", COLORS["mustard"])
        apply_material(post, mat)
        parts.append(post)

    # Thatched roof (cone shape)
    bpy.ops.mesh.primitive_cone_add(radius1=8, radius2=1, depth=5, location=(0, 0, 12))
    roof = bpy.context.active_object
    roof.name = "ThatchedRoof"
    mat = create_material("Thatch", COLORS["sand"])
    apply_material(roof, mat)
    parts.append(roof)

    # Bar stools
    for x in [-4, -2, 0, 2, 4]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.6, depth=0.3, location=(x, -3, 2))
        seat = bpy.context.active_object
        seat.name = f"Stool_{x}"
        mat = create_material("StoolSeat", COLORS["coral"])
        apply_material(seat, mat)
        parts.append(seat)

        bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=2, location=(x, -3, 1))
        leg = bpy.context.active_object
        leg.name = f"StoolLeg_{x}"
        mat = create_material("BambooLeg", COLORS["wood_light"])
        apply_material(leg, mat)
        parts.append(leg)

    # Tiki torches on sides
    for x in [-7, 7]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=8, location=(x, 0, 4))
        torch = bpy.context.active_object
        torch.name = f"Torch_{x}"
        mat = create_material("TorchBamboo", COLORS["wood_dark"])
        apply_material(torch, mat)
        parts.append(torch)

        # Flame
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.5, location=(x, 0, 8.5))
        flame = bpy.context.active_object
        flame.name = f"Flame_{x}"
        mat = create_material("Flame", COLORS["orange"], emission=3.0)
        apply_material(flame, mat)
        smooth_shade(flame)
        parts.append(flame)

    group_objects(parts, "TikiBar")
    export_asset("tiki_bar")

# ===========================================
# 2. BEACH / COASTAL
# ===========================================

def create_lifeguard_tower():
    """Classic California lifeguard tower"""
    clear_scene()
    parts = []

    # Platform
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 8))
    platform = bpy.context.active_object
    platform.name = "Platform"
    platform.scale = (6, 6, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("PlatformWood", COLORS["wood_light"])
    apply_material(platform, mat)
    parts.append(platform)

    # Cabin
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 11))
    cabin = bpy.context.active_object
    cabin.name = "Cabin"
    cabin.scale = (5, 5, 5)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("CabinCoral", COLORS["coral"])
    apply_material(cabin, mat)
    parts.append(cabin)

    # Roof
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 14.5))
    roof = bpy.context.active_object
    roof.name = "Roof"
    roof.scale = (6, 6, 1)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("RoofWhite", COLORS["cream"])
    apply_material(roof, mat)
    parts.append(roof)

    # Support legs
    for pos in [(-2.5, -2.5), (-2.5, 2.5), (2.5, -2.5), (2.5, 2.5)]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(pos[0], pos[1], 4))
        leg = bpy.context.active_object
        leg.name = f"Leg_{pos[0]}_{pos[1]}"
        leg.scale = (0.4, 0.4, 8)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material("LegWood", COLORS["wood_light"])
        apply_material(leg, mat)
        parts.append(leg)

    # Ramp
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -6, 4))
    ramp = bpy.context.active_object
    ramp.name = "Ramp"
    ramp.scale = (2, 6, 0.3)
    ramp.rotation_euler = (0.3, 0, 0)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    mat = create_material("RampWood", COLORS["wood_light"])
    apply_material(ramp, mat)
    parts.append(ramp)

    # Rescue buoy
    bpy.ops.mesh.primitive_torus_add(major_radius=0.8, minor_radius=0.2, location=(3, 0, 9))
    buoy = bpy.context.active_object
    buoy.name = "RescueBuoy"
    mat = create_material("BuoyOrange", COLORS["orange"])
    apply_material(buoy, mat)
    parts.append(buoy)

    group_objects(parts, "LifeguardTower")
    export_asset("lifeguard_tower")

def create_surfboard():
    """Vintage longboard surfboard"""
    clear_scene()
    parts = []

    # Board body (elongated ellipsoid)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1, location=(0, 0, 0.15))
    board = bpy.context.active_object
    board.name = "SurfboardBody"
    board.scale = (0.8, 4, 0.1)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("BoardTurquoise", COLORS["turquoise"])
    apply_material(board, mat)
    smooth_shade(board)
    parts.append(board)

    # Racing stripe
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.2))
    stripe = bpy.context.active_object
    stripe.name = "Stripe"
    stripe.scale = (0.15, 3.5, 0.02)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("StripeOrange", COLORS["orange"])
    apply_material(stripe, mat)
    parts.append(stripe)

    # Fin
    bpy.ops.mesh.primitive_cone_add(radius1=0.3, radius2=0, depth=0.4, location=(0, -1.5, 0))
    fin = bpy.context.active_object
    fin.name = "Fin"
    fin.rotation_euler = (1.57, 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("FinDark", COLORS["wood_dark"])
    apply_material(fin, mat)
    parts.append(fin)

    group_objects(parts, "Surfboard")
    export_asset("surfboard")

def create_beach_umbrella():
    """Colorful beach umbrella"""
    clear_scene()
    parts = []

    # Pole
    bpy.ops.mesh.primitive_cylinder_add(radius=0.1, depth=8, location=(0, 0, 4))
    pole = bpy.context.active_object
    pole.name = "Pole"
    mat = create_material("PoleWood", COLORS["wood_light"])
    apply_material(pole, mat)
    parts.append(pole)

    # Umbrella top (cone)
    bpy.ops.mesh.primitive_cone_add(radius1=4, radius2=0.3, depth=2, location=(0, 0, 8.5))
    umbrella = bpy.context.active_object
    umbrella.name = "UmbrellaTop"
    mat = create_material("UmbrellaPink", COLORS["pink"])
    apply_material(umbrella, mat)
    parts.append(umbrella)

    # Stripes (alternating colored sections)
    for i, angle in enumerate([0, 1.57, 3.14, 4.71]):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(2 * math.cos(angle), 2 * math.sin(angle), 8))
        stripe = bpy.context.active_object
        stripe.name = f"Stripe_{i}"
        stripe.scale = (0.5, 2, 0.1)
        stripe.rotation_euler = (0.5, 0, angle)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        mat = create_material(f"StripeWhite_{i}", COLORS["cream"])
        apply_material(stripe, mat)
        parts.append(stripe)

    group_objects(parts, "BeachUmbrella")
    export_asset("beach_umbrella")

def create_pier_section():
    """Wooden pier section"""
    clear_scene()
    parts = []

    # Main deck
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 5))
    deck = bpy.context.active_object
    deck.name = "Deck"
    deck.scale = (10, 30, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("DeckWood", COLORS["driftwood"])
    apply_material(deck, mat)
    parts.append(deck)

    # Support pilings
    for pos in [(-4, -12), (-4, 0), (-4, 12), (4, -12), (4, 0), (4, 12)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=10, location=(pos[0], pos[1], 0))
        piling = bpy.context.active_object
        piling.name = f"Piling_{pos[0]}_{pos[1]}"
        mat = create_material("PilingWood", COLORS["wood_dark"])
        apply_material(piling, mat)
        parts.append(piling)

    # Railings
    for x in [-5, 5]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0, 6.5))
        rail = bpy.context.active_object
        rail.name = f"Rail_{x}"
        rail.scale = (0.2, 30, 0.2)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material("RailWood", COLORS["wood_light"])
        apply_material(rail, mat)
        parts.append(rail)

        # Rail posts
        for y in range(-12, 15, 6):
            bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, 5.75))
            post = bpy.context.active_object
            post.name = f"Post_{x}_{y}"
            post.scale = (0.2, 0.2, 1.5)
            bpy.ops.object.transform_apply(scale=True)
            mat = create_material("PostWood", COLORS["wood_light"])
            apply_material(post, mat)
            parts.append(post)

    group_objects(parts, "PierSection")
    export_asset("pier_section")

def create_palm_tree():
    """California palm tree"""
    clear_scene()
    parts = []

    # Trunk (slightly curved cylinder segments)
    for i in range(5):
        bpy.ops.mesh.primitive_cylinder_add(radius=1.2 - i*0.15, depth=8, location=(i*0.3, 0, 4 + i*8))
        segment = bpy.context.active_object
        segment.name = f"Trunk_{i}"
        segment.rotation_euler = (0.05 * i, 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material("TrunkBrown", COLORS["wood_dark"])
        apply_material(segment, mat)
        parts.append(segment)

    # Palm fronds
    for i in range(8):
        angle = i * (2 * math.pi / 8)
        x = 2 * math.cos(angle)
        y = 2 * math.sin(angle)

        bpy.ops.mesh.primitive_cube_add(size=1, location=(x + 1.5, y, 42))
        frond = bpy.context.active_object
        frond.name = f"Frond_{i}"
        frond.scale = (8, 0.5, 0.1)
        frond.rotation_euler = (-0.5, 0, angle)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        mat = create_material("FrondGreen", COLORS["palm_green"])
        apply_material(frond, mat)
        parts.append(frond)

    # Coconuts
    for i in range(3):
        angle = i * (2 * math.pi / 3)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.5, location=(0.5 * math.cos(angle) + 1.5, 0.5 * math.sin(angle), 40))
        coconut = bpy.context.active_object
        coconut.name = f"Coconut_{i}"
        mat = create_material("CoconutBrown", COLORS["wood_dark"])
        apply_material(coconut, mat)
        smooth_shade(coconut)
        parts.append(coconut)

    group_objects(parts, "PalmTree")
    export_asset("palm_tree")

# ===========================================
# 3. EARTHQUAKE / DESTRUCTION
# ===========================================

def create_cracked_earth():
    """Ground with earthquake cracks"""
    clear_scene()
    parts = []

    # Base ground
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -0.5))
    ground = bpy.context.active_object
    ground.name = "Ground"
    ground.scale = (20, 20, 1)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("GroundBrown", COLORS["rock_brown"])
    apply_material(ground, mat)
    parts.append(ground)

    # Crack fissures (dark gaps)
    crack_positions = [
        (0, 0, 0, 15, 1.5),
        (-5, 3, 0.5, 8, 1),
        (4, -4, -0.3, 10, 0.8),
        (-3, -6, 0.2, 7, 0.6),
    ]

    for i, (x, y, rot, length, width) in enumerate(crack_positions):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, 0.1))
        crack = bpy.context.active_object
        crack.name = f"Crack_{i}"
        crack.scale = (length, width, 0.3)
        crack.rotation_euler = (0, 0, rot)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        mat = create_material(f"CrackDark_{i}", (0.05, 0.05, 0.05))
        apply_material(crack, mat)
        parts.append(crack)

    # Uplifted chunks along cracks
    for i in range(6):
        x = (i - 3) * 3 + (i % 2) * 0.5
        y = i * 0.3 - 1
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, 0.8))
        chunk = bpy.context.active_object
        chunk.name = f"Chunk_{i}"
        chunk.scale = (2, 1.5, 1.2)
        chunk.rotation_euler = (0.1 * (i % 3 - 1), 0.1 * (i % 2), 0.2 * (i % 4 - 2))
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        mat = create_material(f"ChunkRock_{i}", COLORS["rock_brown"])
        apply_material(chunk, mat)
        parts.append(chunk)

    group_objects(parts, "CrackedEarth")
    export_asset("cracked_earth")

def create_steam_vent():
    """Volcanic steam vent from fault line"""
    clear_scene()
    parts = []

    # Vent opening (cone depression)
    bpy.ops.mesh.primitive_cone_add(radius1=3, radius2=1, depth=2, location=(0, 0, -1))
    vent = bpy.context.active_object
    vent.name = "VentOpening"
    vent.rotation_euler = (3.14, 0, 0)  # Flip upside down
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("VentRock", COLORS["rock_brown"])
    apply_material(vent, mat)
    parts.append(vent)

    # Inner glow
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.8, location=(0, 0, -0.5))
    glow = bpy.context.active_object
    glow.name = "InnerGlow"
    mat = create_material("LavaGlow", COLORS["lava_red"], emission=5.0)
    apply_material(glow, mat)
    smooth_shade(glow)
    parts.append(glow)

    # Steam clouds (spheres)
    steam_positions = [
        (0, 0, 2), (0.5, 0.3, 4), (-0.3, 0.5, 6),
        (0.2, -0.4, 8), (-0.5, 0.2, 10), (0.3, 0.3, 12)
    ]
    for i, pos in enumerate(steam_positions):
        size = 1.5 - i * 0.15
        bpy.ops.mesh.primitive_uv_sphere_add(radius=size, location=pos)
        steam = bpy.context.active_object
        steam.name = f"Steam_{i}"
        mat = create_material(f"Steam_{i}", (*COLORS["steam_white"], 0.6), emission=0.3)
        apply_material(steam, mat)
        smooth_shade(steam)
        parts.append(steam)

    # Surrounding rocks
    for i in range(6):
        angle = i * (2 * math.pi / 6)
        x = 4 * math.cos(angle)
        y = 4 * math.sin(angle)
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, 0.5))
        rock = bpy.context.active_object
        rock.name = f"Rock_{i}"
        rock.scale = (1.5, 1, 1)
        rock.rotation_euler = (0.2, 0.1, angle)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        mat = create_material(f"SurroundRock_{i}", COLORS["rock_brown"])
        apply_material(rock, mat)
        parts.append(rock)

    group_objects(parts, "SteamVent")
    export_asset("steam_vent")

def create_rubble_pile():
    """Pile of building rubble and debris"""
    clear_scene()
    parts = []

    # Various sized chunks
    chunks = [
        (0, 0, 1, 3, 2, 2, 0.1, 0.2, 0.3),
        (2, 1, 0.8, 2, 1.5, 1.5, -0.2, 0.1, 0.1),
        (-1.5, 0.5, 0.6, 1.5, 2, 1, 0.3, -0.1, 0.2),
        (0.5, -1.5, 0.5, 2.5, 1, 1.2, 0.1, 0.3, -0.1),
        (-2, -1, 0.4, 1, 1.5, 0.8, -0.1, 0.2, 0.4),
        (1, 2, 0.3, 1.2, 0.8, 0.6, 0.2, 0.1, 0.15),
    ]

    for i, (x, y, z, sx, sy, sz, rx, ry, rz) in enumerate(chunks):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z))
        chunk = bpy.context.active_object
        chunk.name = f"RubbleChunk_{i}"
        chunk.scale = (sx, sy, sz)
        chunk.rotation_euler = (rx, ry, rz)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        # Alternate between concrete gray and brick red
        color = COLORS["concrete_gray"] if i % 2 == 0 else (0.6, 0.3, 0.2)
        mat = create_material(f"RubbleMat_{i}", color)
        apply_material(chunk, mat)
        parts.append(chunk)

    # Rebar sticking out
    for i in range(4):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=3, location=(i - 1.5, i * 0.3 - 0.5, 1.5 + i * 0.2))
        rebar = bpy.context.active_object
        rebar.name = f"Rebar_{i}"
        rebar.rotation_euler = (0.3 + i * 0.1, 0.2, i * 0.2)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material("RebarRust", COLORS["rust"])
        apply_material(rebar, mat)
        parts.append(rebar)

    group_objects(parts, "RubblePile")
    export_asset("rubble_pile")

def create_damaged_car():
    """Earthquake-damaged abandoned car"""
    clear_scene()
    parts = []

    # Crushed body
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.5))
    body = bpy.context.active_object
    body.name = "CrushedBody"
    body.scale = (7, 3, 1.2)
    body.rotation_euler = (0.1, 0.05, 0.02)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    mat = create_material("RustedBody", COLORS["rust"])
    apply_material(body, mat)
    parts.append(body)

    # Smashed roof
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.8))
    roof = bpy.context.active_object
    roof.name = "SmashedRoof"
    roof.scale = (3.5, 2.5, 0.6)
    roof.rotation_euler = (-0.15, 0.1, 0.05)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    mat = create_material("RustedRoof", COLORS["rust"])
    apply_material(roof, mat)
    parts.append(roof)

    # Flat/missing wheels
    wheel_data = [
        (-2, -1.5, 0.4, True),   # Flat
        (-2, 1.5, 0.4, True),
        (2, -1.5, 0.3, False),  # Missing (just axle)
        (2, 1.5, 0.4, True),
    ]

    for i, (x, y, z, has_wheel) in enumerate(wheel_data):
        if has_wheel:
            bpy.ops.mesh.primitive_cylinder_add(radius=0.6, depth=0.4, location=(x, y, z))
            wheel = bpy.context.active_object
            wheel.name = f"FlatWheel_{i}"
            wheel.rotation_euler = (1.57, 0, 0)
            bpy.ops.object.transform_apply(rotation=True)
            mat = create_material("FlatTire", (0.1, 0.1, 0.1))
            apply_material(wheel, mat)
            parts.append(wheel)

    # Broken window glass on ground
    for i in range(5):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(i - 2, 2 + i * 0.2, 0.05))
        glass = bpy.context.active_object
        glass.name = f"BrokenGlass_{i}"
        glass.scale = (0.3, 0.2, 0.02)
        glass.rotation_euler = (0, 0, i * 0.5)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        mat = create_material(f"Glass_{i}", (0.7, 0.8, 0.85, 0.7))
        apply_material(glass, mat)
        parts.append(glass)

    group_objects(parts, "DamagedCar")
    export_asset("damaged_car")

def create_fallen_power_lines():
    """Downed power lines and pole"""
    clear_scene()
    parts = []

    # Fallen pole
    bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=15, location=(0, 0, 0.5))
    pole = bpy.context.active_object
    pole.name = "FallenPole"
    pole.rotation_euler = (0, 1.4, 0.2)
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("WoodPole", COLORS["wood_dark"])
    apply_material(pole, mat)
    parts.append(pole)

    # Cross beam
    bpy.ops.mesh.primitive_cube_add(size=1, location=(5, 0, 3))
    beam = bpy.context.active_object
    beam.name = "CrossBeam"
    beam.scale = (0.2, 4, 0.2)
    beam.rotation_euler = (0, 0.3, 0)
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    mat = create_material("BeamWood", COLORS["wood_dark"])
    apply_material(beam, mat)
    parts.append(beam)

    # Tangled wires on ground
    for i in range(4):
        # Simulate wire as a series of small cylinders
        for j in range(8):
            bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=2,
                location=(j - 4 + i, i * 0.5 - 1, 0.2 + j * 0.1))
            wire = bpy.context.active_object
            wire.name = f"Wire_{i}_{j}"
            wire.rotation_euler = (0.1 * j, 0.2 * i, 0.3 + j * 0.1)
            bpy.ops.object.transform_apply(rotation=True)
            mat = create_material("WireBlack", (0.05, 0.05, 0.05))
            apply_material(wire, mat)
            parts.append(wire)

    # Sparking end (glowing)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.3, location=(-3, 0, 0.5))
    spark = bpy.context.active_object
    spark.name = "SparkingEnd"
    mat = create_material("Spark", (1, 0.9, 0.3), emission=5.0)
    apply_material(spark, mat)
    smooth_shade(spark)
    parts.append(spark)

    group_objects(parts, "FallenPowerLines")
    export_asset("fallen_power_lines")

# ===========================================
# 4. HORROR / LIMINAL
# ===========================================

def create_mannequin():
    """Creepy store mannequin"""
    clear_scene()
    parts = []

    # Body
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 4))
    torso = bpy.context.active_object
    torso.name = "Torso"
    torso.scale = (1.2, 0.6, 2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("MannequinSkin", (0.9, 0.8, 0.75))
    apply_material(torso, mat)
    parts.append(torso)

    # Head
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.6, location=(0, 0, 5.8))
    head = bpy.context.active_object
    head.name = "Head"
    mat = create_material("HeadSkin", (0.9, 0.8, 0.75))
    apply_material(head, mat)
    smooth_shade(head)
    parts.append(head)

    # Featureless face (slightly darker area)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.55, location=(0, 0.2, 5.8))
    face = bpy.context.active_object
    face.name = "Face"
    face.scale = (0.9, 0.5, 0.9)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("FaceSkin", (0.85, 0.75, 0.7))
    apply_material(face, mat)
    smooth_shade(face)
    parts.append(face)

    # Arms (slightly posed)
    for side, y_offset, rot in [(-1, -0.8, 0.3), (1, 0.8, -0.3)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=2.5, location=(0, y_offset, 3.5))
        arm = bpy.context.active_object
        arm.name = f"Arm_{side}"
        arm.rotation_euler = (0, rot, side * 0.2)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material(f"ArmSkin_{side}", (0.9, 0.8, 0.75))
        apply_material(arm, mat)
        parts.append(arm)

    # Legs
    for y_offset in [-0.3, 0.3]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=3, location=(0, y_offset, 1.5))
        leg = bpy.context.active_object
        leg.name = f"Leg_{y_offset}"
        mat = create_material(f"LegSkin_{y_offset}", (0.9, 0.8, 0.75))
        apply_material(leg, mat)
        parts.append(leg)

    # Base stand
    bpy.ops.mesh.primitive_cylinder_add(radius=0.8, depth=0.2, location=(0, 0, 0.1))
    base = bpy.context.active_object
    base.name = "Base"
    mat = create_material("BaseBlack", (0.1, 0.1, 0.1))
    apply_material(base, mat)
    parts.append(base)

    group_objects(parts, "Mannequin")
    export_asset("mannequin")

def create_empty_pool():
    """Drained swimming pool - liminal space"""
    clear_scene()
    parts = []

    # Pool walls
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -3))
    pool = bpy.context.active_object
    pool.name = "PoolBasin"
    pool.scale = (15, 25, 6)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("PoolBlue", (0.6, 0.8, 0.9))
    apply_material(pool, mat)
    parts.append(pool)

    # Pool floor (darker, stained)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -5.9))
    floor = bpy.context.active_object
    floor.name = "PoolFloor"
    floor.scale = (14.5, 24.5, 0.2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("StainedFloor", COLORS["mold_green"])
    apply_material(floor, mat)
    parts.append(floor)

    # Drain
    bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=0.1, location=(0, 8, -5.8))
    drain = bpy.context.active_object
    drain.name = "Drain"
    mat = create_material("DrainMetal", COLORS["steel"])
    apply_material(drain, mat)
    parts.append(drain)

    # Ladder
    for y in [0.3, -0.3]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.1, depth=8, location=(-7, y, -2))
        rail = bpy.context.active_object
        rail.name = f"LadderRail_{y}"
        mat = create_material("ChromeRail", COLORS["chrome"])
        apply_material(rail, mat)
        parts.append(rail)

    # Ladder rungs
    for z in range(-5, 2, 1):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.6, location=(-7, 0, z))
        rung = bpy.context.active_object
        rung.name = f"Rung_{z}"
        rung.rotation_euler = (1.57, 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material(f"ChromeRung_{z}", COLORS["chrome"])
        apply_material(rung, mat)
        parts.append(rung)

    # Abandoned pool toys
    bpy.ops.mesh.primitive_torus_add(major_radius=1.5, minor_radius=0.3, location=(5, -5, -5.5))
    floatie = bpy.context.active_object
    floatie.name = "Floatie"
    floatie.rotation_euler = (0.2, 0.1, 0)
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("FloatiePink", COLORS["pink"])
    apply_material(floatie, mat)
    parts.append(floatie)

    # Beach ball (deflated)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.8, location=(-3, 3, -5.5))
    ball = bpy.context.active_object
    ball.name = "DeflatedBall"
    ball.scale = (1, 1, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("BeachBall", COLORS["coral"])
    apply_material(ball, mat)
    smooth_shade(ball)
    parts.append(ball)

    group_objects(parts, "EmptyPool")
    export_asset("empty_pool")

def create_old_tv():
    """Vintage TV with static"""
    clear_scene()
    parts = []

    # Cabinet
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 3))
    cabinet = bpy.context.active_object
    cabinet.name = "Cabinet"
    cabinet.scale = (4, 3, 3.5)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("WoodCabinet", COLORS["wood_dark"])
    apply_material(cabinet, mat)
    parts.append(cabinet)

    # Screen (glowing static)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 1.4, 3.2))
    screen = bpy.context.active_object
    screen.name = "Screen"
    screen.scale = (2.5, 0.1, 2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("StaticScreen", COLORS["sickly_yellow"], emission=0.5)
    apply_material(screen, mat)
    parts.append(screen)

    # Screen bezel
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 1.35, 3.2))
    bezel = bpy.context.active_object
    bezel.name = "Bezel"
    bezel.scale = (2.8, 0.05, 2.3)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("BezelGray", COLORS["concrete_gray"])
    apply_material(bezel, mat)
    parts.append(bezel)

    # Knobs
    for z in [2, 3, 4]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=0.3, location=(1.6, 1.5, z))
        knob = bpy.context.active_object
        knob.name = f"Knob_{z}"
        knob.rotation_euler = (1.57, 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material(f"KnobBrown_{z}", COLORS["wood_dark"])
        apply_material(knob, mat)
        parts.append(knob)

    # Antenna ears
    for x in [-1, 1]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=3, location=(x, 0, 5.5))
        antenna = bpy.context.active_object
        antenna.name = f"Antenna_{x}"
        antenna.rotation_euler = (0, x * 0.4, 0)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material(f"AntennaChrome_{x}", COLORS["chrome"])
        apply_material(antenna, mat)
        parts.append(antenna)

    # Legs
    for pos in [(-1.5, -1), (-1.5, 1), (1.5, -1), (1.5, 1)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=1.2, location=(pos[0], pos[1], 0.6))
        leg = bpy.context.active_object
        leg.name = f"Leg_{pos[0]}_{pos[1]}"
        mat = create_material("LegWood", COLORS["wood_dark"])
        apply_material(leg, mat)
        parts.append(leg)

    group_objects(parts, "OldTV")
    export_asset("old_tv")

def create_flickering_light():
    """Ceiling fluorescent light fixture"""
    clear_scene()
    parts = []

    # Housing
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    housing = bpy.context.active_object
    housing.name = "Housing"
    housing.scale = (6, 1.5, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("HousingWhite", COLORS["cream"])
    apply_material(housing, mat)
    parts.append(housing)

    # Tubes (glowing)
    for y in [-0.3, 0.3]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=5, location=(0, y, -0.25))
        tube = bpy.context.active_object
        tube.name = f"Tube_{y}"
        tube.rotation_euler = (0, 1.57, 0)
        bpy.ops.object.transform_apply(rotation=True)
        # One tube dimmer (flickering effect)
        emission = 3.0 if y > 0 else 1.0
        mat = create_material(f"TubeGlow_{y}", COLORS["sickly_yellow"], emission=emission)
        apply_material(tube, mat)
        parts.append(tube)

    # End caps
    for x in [-2.7, 2.7]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0, -0.15))
        cap = bpy.context.active_object
        cap.name = f"EndCap_{x}"
        cap.scale = (0.3, 1.3, 0.2)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material(f"CapGray_{x}", COLORS["concrete_gray"])
        apply_material(cap, mat)
        parts.append(cap)

    group_objects(parts, "FlickeringLight")
    export_asset("flickering_light")

def create_shopping_cart():
    """Abandoned shopping cart"""
    clear_scene()
    parts = []

    # Basket frame
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.5))
    basket = bpy.context.active_object
    basket.name = "Basket"
    basket.scale = (2, 3, 2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("WireFrame", COLORS["chrome"])
    apply_material(basket, mat)
    parts.append(basket)

    # Handle
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=2.5, location=(0, -1.8, 3.5))
    handle = bpy.context.active_object
    handle.name = "Handle"
    handle.rotation_euler = (0.3, 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("HandleChrome", COLORS["chrome"])
    apply_material(handle, mat)
    parts.append(handle)

    # Wheels
    for pos in [(-0.8, -1.2), (-0.8, 1.2), (0.8, -1.2), (0.8, 1.2)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=0.15, location=(pos[0], pos[1], 0.3))
        wheel = bpy.context.active_object
        wheel.name = f"Wheel_{pos[0]}_{pos[1]}"
        wheel.rotation_euler = (1.57, 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material("WheelBlack", (0.1, 0.1, 0.1))
        apply_material(wheel, mat)
        parts.append(wheel)

    # Child seat (folded)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 1.3, 2))
    seat = bpy.context.active_object
    seat.name = "ChildSeat"
    seat.scale = (1.8, 0.3, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("SeatPlastic", (0.3, 0.3, 0.35))
    apply_material(seat, mat)
    parts.append(seat)

    group_objects(parts, "ShoppingCart")
    export_asset("shopping_cart")

# ===========================================
# 5. SURVIVAL PROPS
# ===========================================

def create_first_aid_kit():
    """Emergency first aid kit"""
    clear_scene()
    parts = []

    # Box
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))
    box = bpy.context.active_object
    box.name = "Box"
    box.scale = (2, 1.2, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("BoxWhite", (0.95, 0.95, 0.95))
    apply_material(box, mat)
    parts.append(box)

    # Red cross
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.61, 0.5))
    cross_h = bpy.context.active_object
    cross_h.name = "CrossH"
    cross_h.scale = (0.8, 0.02, 0.2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("RedCross", (0.9, 0.1, 0.1))
    apply_material(cross_h, mat)
    parts.append(cross_h)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.61, 0.5))
    cross_v = bpy.context.active_object
    cross_v.name = "CrossV"
    cross_v.scale = (0.2, 0.02, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("RedCrossV", (0.9, 0.1, 0.1))
    apply_material(cross_v, mat)
    parts.append(cross_v)

    # Handle
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.1))
    handle = bpy.context.active_object
    handle.name = "Handle"
    handle.scale = (0.8, 0.1, 0.15)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("HandleGray", COLORS["concrete_gray"])
    apply_material(handle, mat)
    parts.append(handle)

    # Latches
    for x in [-0.7, 0.7]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0.5, 0.5))
        latch = bpy.context.active_object
        latch.name = f"Latch_{x}"
        latch.scale = (0.15, 0.15, 0.08)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material(f"LatchMetal_{x}", COLORS["chrome"])
        apply_material(latch, mat)
        parts.append(latch)

    group_objects(parts, "FirstAidKit")
    export_asset("first_aid_kit")

def create_flashlight():
    """Heavy duty flashlight"""
    clear_scene()
    parts = []

    # Body
    bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=2.5, location=(0, 0, 1.25))
    body = bpy.context.active_object
    body.name = "Body"
    mat = create_material("BodyBlack", (0.1, 0.1, 0.1))
    apply_material(body, mat)
    parts.append(body)

    # Head
    bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=0.8, location=(0, 0, 2.9))
    head = bpy.context.active_object
    head.name = "Head"
    mat = create_material("HeadBlack", (0.1, 0.1, 0.1))
    apply_material(head, mat)
    parts.append(head)

    # Lens
    bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=0.1, location=(0, 0, 3.35))
    lens = bpy.context.active_object
    lens.name = "Lens"
    mat = create_material("LensGlow", COLORS["cream"], emission=2.0)
    apply_material(lens, mat)
    parts.append(lens)

    # Grip ridges
    for z in [0.5, 0.8, 1.1, 1.4, 1.7]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.32, minor_radius=0.03, location=(0, 0, z))
        ridge = bpy.context.active_object
        ridge.name = f"Ridge_{z}"
        mat = create_material(f"RidgeGray_{z}", (0.2, 0.2, 0.2))
        apply_material(ridge, mat)
        parts.append(ridge)

    # Button
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.05, location=(0.25, 0, 2))
    button = bpy.context.active_object
    button.name = "Button"
    button.rotation_euler = (0, 1.57, 0)
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("ButtonOrange", COLORS["orange"])
    apply_material(button, mat)
    parts.append(button)

    group_objects(parts, "Flashlight")
    export_asset("flashlight")

def create_camping_tent():
    """Small survival tent"""
    clear_scene()
    parts = []

    # Main tent body (triangular prism)
    bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=4, radius2=4, depth=6, location=(0, 0, 2))
    tent = bpy.context.active_object
    tent.name = "TentBody"
    tent.rotation_euler = (1.57, 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("TentOrange", COLORS["orange"])
    apply_material(tent, mat)
    parts.append(tent)

    # Door opening (darker)
    bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=1.5, radius2=1.5, depth=0.5, location=(0, 3.1, 1.5))
    door = bpy.context.active_object
    door.name = "Door"
    door.rotation_euler = (1.57, 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("DoorDark", (0.1, 0.1, 0.1))
    apply_material(door, mat)
    parts.append(door)

    # Guy lines
    for angle in [0, 2.09, 4.18]:
        x = 5 * math.cos(angle)
        y = 5 * math.sin(angle)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=5, location=(x/2, y/2, 1.5))
        line = bpy.context.active_object
        line.name = f"GuyLine_{angle}"
        line.rotation_euler = (0, 0.5, angle)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material("RopeYellow", COLORS["mustard"])
        apply_material(line, mat)
        parts.append(line)

    group_objects(parts, "CampingTent")
    export_asset("camping_tent")

def create_campfire():
    """Campfire with logs"""
    clear_scene()
    parts = []

    # Fire pit ring (rocks)
    for i in range(8):
        angle = i * (2 * math.pi / 8)
        x = 2 * math.cos(angle)
        y = 2 * math.sin(angle)
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, 0.3))
        rock = bpy.context.active_object
        rock.name = f"Rock_{i}"
        rock.scale = (0.8, 0.6, 0.5)
        rock.rotation_euler = (0.1, 0.1, angle)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        mat = create_material(f"RockGray_{i}", COLORS["rock_brown"])
        apply_material(rock, mat)
        parts.append(rock)

    # Logs
    for i, (x, y, rot) in enumerate([(-0.5, 0, 0.5), (0.5, 0, -0.5), (0, -0.3, 1.57)]):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=2, location=(x, y, 0.5))
        log = bpy.context.active_object
        log.name = f"Log_{i}"
        log.rotation_euler = (0, 0.3, rot)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material(f"LogWood_{i}", COLORS["wood_dark"])
        apply_material(log, mat)
        parts.append(log)

    # Flames (stylized)
    flame_positions = [
        (0, 0, 1, 0.6), (-0.3, 0.2, 1.3, 0.4), (0.3, -0.2, 1.2, 0.5),
        (0, 0.3, 1.5, 0.3), (-0.2, -0.3, 1.4, 0.35)
    ]
    for i, (x, y, z, s) in enumerate(flame_positions):
        bpy.ops.mesh.primitive_cone_add(radius1=s * 0.5, radius2=0, depth=s * 2, location=(x, y, z))
        flame = bpy.context.active_object
        flame.name = f"Flame_{i}"
        mat = create_material(f"FlameOrange_{i}", COLORS["orange"], emission=5.0)
        apply_material(flame, mat)
        parts.append(flame)

    # Embers (small glowing spheres)
    for i in range(10):
        x = (i % 3 - 1) * 0.5
        y = (i // 3 - 1) * 0.4
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.08, location=(x, y, 0.15))
        ember = bpy.context.active_object
        ember.name = f"Ember_{i}"
        mat = create_material(f"EmberGlow_{i}", COLORS["lava_red"], emission=3.0)
        apply_material(ember, mat)
        smooth_shade(ember)
        parts.append(ember)

    group_objects(parts, "Campfire")
    export_asset("campfire")

def create_water_bottle():
    """Plastic water bottle"""
    clear_scene()
    parts = []

    # Bottle body
    bpy.ops.mesh.primitive_cylinder_add(radius=0.4, depth=2, location=(0, 0, 1))
    body = bpy.context.active_object
    body.name = "Bottle"
    mat = create_material("BottlePlastic", (0.7, 0.85, 0.95, 0.8))
    apply_material(body, mat)
    smooth_shade(body)
    parts.append(body)

    # Neck
    bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=0.4, location=(0, 0, 2.2))
    neck = bpy.context.active_object
    neck.name = "Neck"
    mat = create_material("NeckPlastic", (0.7, 0.85, 0.95, 0.8))
    apply_material(neck, mat)
    parts.append(neck)

    # Cap
    bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=0.25, location=(0, 0, 2.55))
    cap = bpy.context.active_object
    cap.name = "Cap"
    mat = create_material("CapBlue", COLORS["ocean_blue"])
    apply_material(cap, mat)
    parts.append(cap)

    # Water inside (visible through bottle)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.35, depth=1.2, location=(0, 0, 0.8))
    water = bpy.context.active_object
    water.name = "Water"
    mat = create_material("WaterBlue", (0.5, 0.7, 0.9, 0.6))
    apply_material(water, mat)
    parts.append(water)

    # Label
    bpy.ops.mesh.primitive_cylinder_add(radius=0.42, depth=0.8, location=(0, 0, 1))
    label = bpy.context.active_object
    label.name = "Label"
    mat = create_material("LabelWhite", COLORS["cream"])
    apply_material(label, mat)
    parts.append(label)

    group_objects(parts, "WaterBottle")
    export_asset("water_bottle")

# ===========================================
# 6. SIGNS AND MARKERS
# ===========================================

def create_warning_sign():
    """Diamond-shaped warning sign"""
    clear_scene()
    parts = []

    # Post
    bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=8, location=(0, 0, 4))
    post = bpy.context.active_object
    post.name = "Post"
    mat = create_material("PostMetal", COLORS["steel"])
    apply_material(post, mat)
    parts.append(post)

    # Diamond sign (rotated square)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.2, 7))
    sign = bpy.context.active_object
    sign.name = "Sign"
    sign.scale = (3, 0.1, 3)
    sign.rotation_euler = (0, 0, 0.785)  # 45 degrees
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    mat = create_material("SignYellow", COLORS["mustard"])
    apply_material(sign, mat)
    parts.append(sign)

    # Exclamation mark (simplified)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.25, 7.2))
    exclaim = bpy.context.active_object
    exclaim.name = "Exclaim"
    exclaim.scale = (0.3, 0.05, 1.2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("ExclaimBlack", (0.05, 0.05, 0.05))
    apply_material(exclaim, mat)
    parts.append(exclaim)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.25, 6.2))
    dot = bpy.context.active_object
    dot.name = "Dot"
    dot.scale = (0.3, 0.05, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("DotBlack", (0.05, 0.05, 0.05))
    apply_material(dot, mat)
    parts.append(dot)

    group_objects(parts, "WarningSign")
    export_asset("warning_sign")

def create_route_66_sign():
    """Classic Route 66 highway shield"""
    clear_scene()
    parts = []

    # Post
    bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=10, location=(0, 0, 5))
    post = bpy.context.active_object
    post.name = "Post"
    mat = create_material("PostWood", COLORS["wood_dark"])
    apply_material(post, mat)
    parts.append(post)

    # Shield shape (simplified as rounded cube)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.3, 9))
    shield = bpy.context.active_object
    shield.name = "Shield"
    shield.scale = (3, 0.15, 3.5)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("ShieldWhite", COLORS["cream"])
    apply_material(shield, mat)
    parts.append(shield)

    # Inner shield
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.35, 9))
    inner = bpy.context.active_object
    inner.name = "InnerShield"
    inner.scale = (2.5, 0.05, 3)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("InnerBlack", (0.1, 0.1, 0.1))
    apply_material(inner, mat)
    parts.append(inner)

    # 66 numbers (simplified blocks)
    for x in [-0.5, 0.5]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0.4, 9))
        num = bpy.context.active_object
        num.name = f"Six_{x}"
        num.scale = (0.6, 0.05, 1.2)
        bpy.ops.object.transform_apply(scale=True)
        mat = create_material(f"NumWhite_{x}", COLORS["cream"])
        apply_material(num, mat)
        parts.append(num)

    group_objects(parts, "Route66Sign")
    export_asset("route_66_sign")

def create_evacuation_sign():
    """Emergency evacuation route sign"""
    clear_scene()
    parts = []

    # Post
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 4))
    post = bpy.context.active_object
    post.name = "Post"
    post.scale = (0.3, 0.3, 8)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("PostSteel", COLORS["steel"])
    apply_material(post, mat)
    parts.append(post)

    # Sign panel
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.2, 7))
    panel = bpy.context.active_object
    panel.name = "Panel"
    panel.scale = (5, 0.1, 2)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("PanelGreen", (0.1, 0.5, 0.2))
    apply_material(panel, mat)
    parts.append(panel)

    # Arrow
    bpy.ops.mesh.primitive_cone_add(radius1=0.5, radius2=0, depth=1, location=(1.5, 0.25, 7))
    arrow = bpy.context.active_object
    arrow.name = "Arrow"
    arrow.rotation_euler = (0, 0, -1.57)
    bpy.ops.object.transform_apply(rotation=True)
    mat = create_material("ArrowWhite", COLORS["cream"])
    apply_material(arrow, mat)
    parts.append(arrow)

    # Arrow shaft
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.25, 7))
    shaft = bpy.context.active_object
    shaft.name = "Shaft"
    shaft.scale = (2, 0.05, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("ShaftWhite", COLORS["cream"])
    apply_material(shaft, mat)
    parts.append(shaft)

    # Running figure (simplified)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.3, location=(-1.5, 0.25, 7.3))
    head = bpy.context.active_object
    head.name = "FigureHead"
    mat = create_material("FigureWhite", COLORS["cream"])
    apply_material(head, mat)
    smooth_shade(head)
    parts.append(head)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(-1.5, 0.25, 6.7))
    body = bpy.context.active_object
    body.name = "FigureBody"
    body.scale = (0.3, 0.05, 0.6)
    bpy.ops.object.transform_apply(scale=True)
    mat = create_material("FigureBodyWhite", COLORS["cream"])
    apply_material(body, mat)
    parts.append(body)

    group_objects(parts, "EvacuationSign")
    export_asset("evacuation_sign")

# ===========================================
# 7. VEGETATION
# ===========================================

def create_dead_tree():
    """Dead/burnt tree"""
    clear_scene()
    parts = []

    # Trunk
    bpy.ops.mesh.primitive_cone_add(radius1=1.5, radius2=0.3, depth=15, location=(0, 0, 7.5))
    trunk = bpy.context.active_object
    trunk.name = "Trunk"
    mat = create_material("DeadWood", (0.2, 0.15, 0.1))
    apply_material(trunk, mat)
    parts.append(trunk)

    # Dead branches
    branches = [
        (0, 0, 10, 5, 0.3, 0.8, 0.3),
        (0, 0, 12, 4, -0.3, -0.5, 0.4),
        (0, 0, 8, 3.5, 0.5, 0.2, -0.3),
        (0, 0, 14, 2.5, -0.4, 0.6, 0.2),
    ]

    for i, (x, y, z, length, rx, ry, rz) in enumerate(branches):
        bpy.ops.mesh.primitive_cone_add(radius1=0.2, radius2=0.05, depth=length, location=(x, y, z))
        branch = bpy.context.active_object
        branch.name = f"Branch_{i}"
        branch.rotation_euler = (rx, ry, rz)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material(f"BranchDead_{i}", (0.2, 0.15, 0.1))
        apply_material(branch, mat)
        parts.append(branch)

    group_objects(parts, "DeadTree")
    export_asset("dead_tree")

def create_cactus():
    """Desert saguaro cactus"""
    clear_scene()
    parts = []

    # Main body
    bpy.ops.mesh.primitive_cylinder_add(radius=1, depth=12, location=(0, 0, 6))
    body = bpy.context.active_object
    body.name = "Body"
    mat = create_material("CactusGreen", (0.2, 0.5, 0.2))
    apply_material(body, mat)
    parts.append(body)

    # Arms
    arms = [
        (0, 0, 7, 1.57, 0.5, 4),   # Right arm
        (0, 0, 9, -1.57, -0.4, 3), # Left arm
    ]

    for i, (x, y, z, rot_y, rot_z, length) in enumerate(arms):
        # Horizontal section
        bpy.ops.mesh.primitive_cylinder_add(radius=0.6, depth=2, location=(0, 0, z))
        arm_h = bpy.context.active_object
        arm_h.name = f"ArmH_{i}"
        arm_h.rotation_euler = (0, rot_y, 0)
        arm_h.location = (1.5 * (1 if i == 0 else -1), 0, z)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material(f"ArmGreen_{i}", (0.2, 0.5, 0.2))
        apply_material(arm_h, mat)
        parts.append(arm_h)

        # Vertical section
        bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=length, location=(2.5 * (1 if i == 0 else -1), 0, z + length/2))
        arm_v = bpy.context.active_object
        arm_v.name = f"ArmV_{i}"
        mat = create_material(f"ArmVGreen_{i}", (0.2, 0.5, 0.2))
        apply_material(arm_v, mat)
        parts.append(arm_v)

    group_objects(parts, "Cactus")
    export_asset("cactus")

def create_tumbleweed():
    """Rolling tumbleweed"""
    clear_scene()
    parts = []

    # Core sphere (icosphere for organic look)
    bpy.ops.mesh.primitive_ico_sphere_add(radius=1.5, subdivisions=2, location=(0, 0, 1.5))
    core = bpy.context.active_object
    core.name = "Core"
    mat = create_material("TumbleCore", COLORS["sand"])
    apply_material(core, mat)
    parts.append(core)

    # Add spiky branches
    for i in range(20):
        # Random-ish positions on sphere surface
        theta = (i / 20) * 2 * math.pi
        phi = (i % 5) * 0.6 + 0.3
        x = 1.5 * math.sin(phi) * math.cos(theta)
        y = 1.5 * math.sin(phi) * math.sin(theta)
        z = 1.5 * math.cos(phi) + 1.5

        length = 0.5 + (i % 3) * 0.3
        bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=length, location=(x * 1.2, y * 1.2, z))
        stick = bpy.context.active_object
        stick.name = f"Stick_{i}"
        # Point outward
        stick.rotation_euler = (phi - 1.57, 0, theta)
        bpy.ops.object.transform_apply(rotation=True)
        mat = create_material(f"StickBrown_{i}", COLORS["sand"])
        apply_material(stick, mat)
        parts.append(stick)

    group_objects(parts, "Tumbleweed")
    export_asset("tumbleweed")

# ===========================================
# MAIN EXECUTION
# ===========================================

def main():
    print("=" * 50)
    print("FAULTLINE FEAR: ASSET ARSENAL GENERATOR")
    print("=" * 50)

    ensure_output_dir()

    # 1. RETRO 60s CALIFORNIA
    print("\n[1/7] Creating Retro 60s California assets...")
    create_vintage_diner()
    create_retro_gas_station()
    create_classic_car_57()
    create_motel_sign()
    create_drive_in_screen()
    create_tiki_bar()

    # 2. BEACH / COASTAL
    print("\n[2/7] Creating Beach/Coastal assets...")
    create_lifeguard_tower()
    create_surfboard()
    create_beach_umbrella()
    create_pier_section()
    create_palm_tree()

    # 3. EARTHQUAKE / DESTRUCTION
    print("\n[3/7] Creating Earthquake/Destruction assets...")
    create_cracked_earth()
    create_steam_vent()
    create_rubble_pile()
    create_damaged_car()
    create_fallen_power_lines()

    # 4. HORROR / LIMINAL
    print("\n[4/7] Creating Horror/Liminal assets...")
    create_mannequin()
    create_empty_pool()
    create_old_tv()
    create_flickering_light()
    create_shopping_cart()

    # 5. SURVIVAL PROPS
    print("\n[5/7] Creating Survival Props...")
    create_first_aid_kit()
    create_flashlight()
    create_camping_tent()
    create_campfire()
    create_water_bottle()

    # 6. SIGNS AND MARKERS
    print("\n[6/7] Creating Signs and Markers...")
    create_warning_sign()
    create_route_66_sign()
    create_evacuation_sign()

    # 7. VEGETATION
    print("\n[7/7] Creating Vegetation...")
    create_dead_tree()
    create_cactus()
    create_tumbleweed()

    print("\n" + "=" * 50)
    print("ASSET GENERATION COMPLETE!")
    print(f"Output directory: {OUTPUT_DIR}")
    print("=" * 50)

if __name__ == "__main__":
    main()
