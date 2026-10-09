import bpy
import math
import os
from mathutils import Vector

"""
The Lost Things Express — first production Blender asset.
Run inside Blender 4.x: blender --background --python art/blender/create_train_carriage.py
Creates a polished, modular carriage interior and exports:
  assets/models/train_carriage.glb
  assets/blender/train_carriage.blend
Dimensions intentionally match the Godot prototype: approx. 5.8m x 12m x 3.5m.
"""

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODEL_DIR = os.path.join(ROOT, "assets", "models")
BLEND_DIR = os.path.join(ROOT, "assets", "blender")
os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(BLEND_DIR, exist_ok=True)

# Locked project palette.
COLORS = {
    "mahogany": (0.18, 0.055, 0.028, 1),
    "dark_wood": (0.075, 0.026, 0.016, 1),
    "wood_light": (0.30, 0.105, 0.045, 1),
    "brass": (0.55, 0.27, 0.065, 1),
    "brass_highlight": (0.78, 0.48, 0.16, 1),
    "velvet": (0.24, 0.035, 0.045, 1),
    "velvet_dark": (0.12, 0.018, 0.026, 1),
    "glass": (0.018, 0.095, 0.13, 0.38),
    "iron": (0.035, 0.045, 0.05, 1),
    "parchment": (0.72, 0.59, 0.37, 1),
    "lantern": (1.0, 0.39, 0.075, 1),
}

def material(name, color, metallic=0.0, roughness=0.45, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    if name == "Glass" and hasattr(mat, "blend_method"):
        mat.blend_method = "BLEND"
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0:
        # Blender 4.x renamed the Principled BSDF emission socket.
        emission_socket = "Emission Color" if "Emission Color" in bsdf.inputs else "Emission"
        bsdf.inputs[emission_socket].default_value = color
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emission
    return mat

MATS = {
    name: material(
        name.title().replace("_", " "),
        color,
        metallic=0.72 if "brass" in name else (0.55 if name == "iron" else 0.0),
        roughness=0.27 if "brass" in name else (0.32 if name == "glass" else 0.48),
        emission=2.0 if name == "lantern" else 0.0,
    )
    for name, color in COLORS.items()
}

def assign(obj, mat):
    obj.data.materials.append(mat)
    return obj

def bevel(obj, amount=0.035, segments=2):
    mod = obj.modifiers.new("Soft crafted edges", "BEVEL")
    mod.width = amount
    mod.segments = segments
    obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj

def cube(name, location, dimensions, mat, bevel_amount=0.0, collection=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(obj, mat)
    if bevel_amount:
        bevel(obj, bevel_amount)
    if collection:
        for coll in list(obj.users_collection):
            coll.objects.unlink(obj)
        collection.objects.link(obj)
    return obj

def cylinder(name, location, radius, depth, mat, rotation=None, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    if rotation:
        obj.rotation_euler = rotation
    assign(obj, mat)
    bevel(obj, min(radius * 0.12, 0.025), 2)
    return obj

def uv_sphere(name, location, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(obj, mat)
    return obj

def clear_scene():
    # Remove the default scene objects but keep the materials created above.
    # Deleting unused materials here invalidates the MATS references (RNA objects).
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)

def create_carriage():
    root = bpy.context.scene.collection
    shell = bpy.data.collections.new("Carriage | Structure")
    details = bpy.data.collections.new("Carriage | Crafted Details")
    seating = bpy.data.collections.new("Carriage | Velvet Seating")
    lighting = bpy.data.collections.new("Carriage | Lanterns")
    for coll in (shell, details, seating, lighting):
        root.children.link(coll)

    # Coordinates: X across the carriage, Y up, Z along its 12m length.
    cube("Floor | dark oak foundation", (0, -0.12, 0), (5.8, 0.24, 12.0), MATS["dark_wood"], 0.06, shell)
    # Separate inset planks give the floor readable craftsmanship.
    for i in range(24):
        z = -5.72 + i * 0.49
        cube("Floor plank %02d" % (i + 1), (0, 0.012, z), (5.55, 0.035, 0.455),
             MATS["mahogany"] if i % 3 else MATS["wood_light"], 0.012, details)
    cube("Ceiling | inner canopy", (0, 3.48, 0), (5.8, 0.18, 12.0), MATS["dark_wood"], 0.045, shell)
    # Side walls are built around real window openings; full-height solid walls
    # behind the glass made the windows look like painted teal panels.
    window_centers = (-4.0, -1.8, 0.4, 2.6, 4.7)
    for side in (-1, 1):
        x = side * 2.85
        cube("Side wall | lower mahogany", (x, 0.715, 0), (0.18, 1.43, 12.0), MATS["mahogany"], 0.025, shell)
        cube("Side wall | upper mahogany", (x, 2.985, 0), (0.18, 0.63, 12.0), MATS["mahogany"], 0.025, shell)
        cursor = -6.0
        for window_z in window_centers:
            opening_start = window_z - 0.75
            if opening_start > cursor:
                segment_length = opening_start - cursor
                cube("Side wall | window pier", (x, 1.65, (cursor + opening_start) / 2),
                     (0.18, 3.3, segment_length), MATS["mahogany"], 0.025, shell)
            cursor = window_z + 0.75
        if cursor < 6.0:
            segment_length = 6.0 - cursor
            cube("Side wall | end pier", (x, 1.65, (cursor + 6.0) / 2),
                 (0.18, 3.3, segment_length), MATS["mahogany"], 0.025, shell)

    cube("Rear wall | end panel", (0, 1.65, -5.95), (5.8, 3.3, 0.18), MATS["dark_wood"], 0.04, shell)
    cube("Front wall | end panel", (0, 1.65, 5.95), (5.8, 3.3, 0.18), MATS["dark_wood"], 0.04, shell)

    # Long brass rails and repeating inset wall panels.
    for x in (-2.70, 2.70):
        for y in (0.22, 0.42, 2.92, 3.08):
            cube("Continuous brass wall rail", (x, y, 0), (0.075, 0.045, 11.7), MATS["brass"], 0.018, details)
        for z in (-5.25, -2.8, -0.35, 2.1, 4.55):
            cube("Wall inset | mahogany panel", (x, 1.48, z), (0.055, 1.62, 1.95), MATS["dark_wood"], 0.035, details)
            for y in (0.68, 2.28):
                cube("Panel brass bead", (x + (0.035 if x > 0 else -0.035), y, z),
                     (0.025, 0.035, 1.72), MATS["brass_highlight"], 0.01, details)

    # Five tall windows on each side, dark teal glass with substantial brass frames.
    for side in (-1, 1):
        x_glass = side * 2.745
        x_frame = side * 2.68
        for index, z in enumerate((-4.0, -1.8, 0.4, 2.6, 4.7), 1):
            cube("Window %d | midnight glass" % index, (x_glass, 2.05, z),
                 (0.028, 1.03, 1.34), MATS["glass"], 0.012, details)
            for y in (1.49, 2.61):
                cube("Window brass lintel", (x_frame, y, z), (0.13, 0.075, 1.48), MATS["brass"], 0.018, details)
            for zz in (z - 0.72, z + 0.72):
                cube("Window brass stile", (x_frame, 2.05, zz), (0.13, 1.18, 0.075), MATS["brass_highlight"], 0.018, details)
            cube("Window center divider", (x_frame, 2.05, z), (0.14, 1.0, 0.035), MATS["brass"], 0.01, details)

    # A small fantasy world sits outside the windows so the carriage never reads as a sealed box.
    # These simple, low-poly silhouettes are intentionally outside the shell and visible through the glass.
    sky_mat = material("Exterior | twilight blue", (0.025, 0.085, 0.16, 1), roughness=0.95)
    island_mat = material("Exterior | floating island teal", (0.055, 0.19, 0.20, 1), roughness=0.9)
    stone_mat = material("Exterior | old stone", (0.19, 0.22, 0.27, 1), roughness=0.88)
    distant_gold = material("Exterior | clockwork gold", (0.68, 0.34, 0.09, 1), metallic=0.35, roughness=0.38, emission=0.25)
    for side in (-1, 1):
        # A continuous dusk backdrop, kept well beyond the window plane.
        cube("Exterior | endless twilight", (side * 5.35, 2.0, 0.0), (0.08, 5.8, 13.5), sky_mat, 0.0, shell)
        for idx, z in enumerate((-4.8, -2.0, 1.1, 4.3), 1):
            # Floating landforms, distant castle towers and warm clock faces.
            cube("Exterior | floating island %d" % idx, (side * (4.65 + (idx % 2) * 0.28), 0.85 + (idx % 2) * 0.22, z),
                 (0.65, 0.24, 1.25), island_mat, 0.12, details)
            cube("Exterior | castle tower %d" % idx, (side * 4.55, 1.55 + (idx % 2) * 0.24, z + 0.12),
                 (0.25, 0.95 + (idx % 2) * 0.28, 0.28), stone_mat, 0.035, details)
            cube("Exterior | tower roof %d" % idx, (side * 4.55, 2.12 + (idx % 2) * 0.24, z + 0.12),
                 (0.34, 0.12, 0.36), distant_gold, 0.035, details)
        for idx, z in enumerate((-3.0, 3.2), 1):
            uv_sphere("Exterior | distant moon %d" % idx, (side * 4.95, 2.95, z), (0.10, 0.10, 0.10), distant_gold)

    # Paired upholstered benches, with cushions, piping and brass feet.
    for z in (-3.6, -0.5, 2.8):
        for side in (-1, 1):
            x = side * 1.78
            cube("Seat | carved mahogany plinth", (x, 0.36, z), (1.30, 0.30, 1.24), MATS["dark_wood"], 0.09, seating)
            cube("Seat | deep crimson velvet cushion", (x, 0.56, z), (1.27, 0.24, 1.19), MATS["velvet"], 0.10, seating)
            cube("Seat back | velvet upholstery", (x, 1.08, z - 0.49), (1.27, 0.88, 0.22), MATS["velvet"], 0.09, seating)
            cube("Seat back | dark wood surround", (x, 1.08, z - 0.62), (1.38, 0.98, 0.12), MATS["mahogany"], 0.07, seating)
            cube("Seat back | inset upholstery", (x, 1.08, z - 0.545), (1.15, 0.72, 0.045), MATS["velvet_dark"], 0.045, seating)
            for dx in (-0.52, 0.52):
                for dz in (-0.47, 0.47):
                    cylinder("Seat | brass foot", (x + dx, 0.13, z + dz), 0.045, 0.22, MATS["brass"], vertices=12)
            for dx in (-0.34, 0.0, 0.34):
                uv_sphere("Seat | brass upholstery stud", (x + dx, 1.10, z - 0.512), (0.025, 0.025, 0.018), MATS["brass_highlight"])

    # A tailored runner makes the central aisle feel like a first-class sleeper carriage.
    rug_mat = material("Interior | midnight teal runner", (0.018, 0.075, 0.085, 1), roughness=0.92)
    rug_red = material("Interior | woven burgundy motif", (0.31, 0.045, 0.055, 1), roughness=0.88)
    cube("Aisle | tailored teal runner", (0, 0.045, 0), (0.88, 0.035, 11.25), rug_mat, 0.025, details)
    for z in [(-5.15 + i * 0.52) for i in range(20)]:
        cube("Runner | woven burgundy lozenge", (0, 0.068, z), (0.24, 0.012, 0.24), rug_red, 0.018, details)
    for x in (-0.40, 0.40):
        cube("Runner | brass woven border", (x, 0.069, 0), (0.025, 0.012, 11.05), MATS["brass_highlight"], 0.008, details)

    # Ceiling ribs and inset panels add a handcrafted, architectural silhouette.
    for z in (-5.3, -3.5, -1.7, 0.1, 1.9, 3.7, 5.35):
        cube("Ceiling | curved-look mahogany cross rib", (0, 3.345, z), (5.48, 0.11, 0.16), MATS["mahogany"], 0.045, details)
        for x in (-2.35, -1.55, -0.75, 0.75, 1.55, 2.35):
            uv_sphere("Ceiling rib | brass pin", (x, 3.275, z), (0.025, 0.018, 0.025), MATS["brass_highlight"])

    # Brass wall sconces and framed vintage travel plaques between the windows.
    for side in (-1, 1):
        x = side * 2.52
        for z in (-2.9, 1.5, 4.0):
            cube("Wall | brass sconce backplate", (x, 2.28, z), (0.09, 0.28, 0.18), MATS["brass"], 0.025, details)
            cube("Wall | amber sconce core", (x - side * 0.065, 2.28, z), (0.045, 0.16, 0.085), MATS["lantern"], 0.018, details)
            cube("Wall | framed travel plaque", (side * 2.56, 1.78, z - 0.40), (0.045, 0.30, 0.40), MATS["brass_highlight"], 0.015, details)
            cube("Wall | plaque enamel inset", (side * 2.525, 1.78, z - 0.40), (0.025, 0.24, 0.33), rug_mat, 0.01, details)

    # Small travel trunks tucked at carriage ends, clear of the central aisle.
    for side in (-1, 1):
        z = side * 5.05
        cube("Luggage | antique leather trunk", (side * 1.70, 0.34, z), (0.92, 0.55, 0.78), MATS["mahogany"], 0.07, details)
        cube("Luggage | brass lid band", (side * 1.70, 0.62, z), (0.94, 0.045, 0.80), MATS["brass"], 0.018, details)
        cube("Luggage | front clasp", (side * 1.70, 0.39, z - side * 0.405), (0.15, 0.19, 0.035), MATS["brass_highlight"], 0.02, details)
        for dx in (-0.30, 0.30):
            cylinder("Luggage | corner foot", (side * 1.70 + dx, 0.10, z), 0.04, 0.16, MATS["brass"], vertices=10)

    # Pendant lanterns with emissive cores and a warm glow when imported into Godot.
    for idx, (x, z) in enumerate(((-2.05, -3.8), (2.05, 0.0), (-2.05, 3.7)), 1):
        cylinder("Lantern %d | ceiling mount" % idx, (x, 3.26, z), 0.07, 0.24, MATS["brass"])
        cylinder("Lantern %d | hanging stem" % idx, (x, 3.08, z), 0.025, 0.22, MATS["brass_highlight"])
        cube("Lantern %d | brass housing" % idx, (x, 2.88, z), (0.28, 0.34, 0.28), MATS["brass"], 0.045, lighting)
        cube("Lantern %d | amber glass" % idx, (x, 2.88, z), (0.19, 0.25, 0.19), MATS["lantern"], 0.035, lighting)
        for dx in (-0.13, 0.13):
            for dz in (-0.13, 0.13):
                cylinder("Lantern | corner brace", (x + dx, 2.88, z + dz), 0.014, 0.30, MATS["brass_highlight"], vertices=8)

    # Repeated rivets along trim establish the locomotive's engineered feel.
    for side in (-1, 1):
        for z in [(-5.5 + i * 0.5) for i in range(23)]:
            uv_sphere("Brass rail rivet", (side * 2.655, 3.08, z), (0.025, 0.025, 0.025), MATS["brass_highlight"])

    # Production pass: layered window casings, tailored upholstery, engraved trim,
    # and focal storytelling props. Keep geometry readable at mobile camera distance.
    trim_shadow = material("Carved trim | shadow", (0.045, 0.018, 0.012, 1), roughness=0.42)
    velvet_highlight = material("Velvet | raised piping", (0.48, 0.075, 0.085, 1), roughness=0.72)
    inlay = material("Wood inlay | warm brass line", (0.82, 0.53, 0.22, 1), metallic=0.58, roughness=0.29)
    leather = material("Luggage | oxblood leather", (0.19, 0.035, 0.025, 1), roughness=0.58)

    # Multi-step window surrounds and lower sills make the windows feel architectural,
    # not like flat panes pasted onto the wall.
    for side in (-1, 1):
        for index, z in enumerate((-4.0, -1.8, 0.4, 2.6, 4.7), 1):
            xf = side * 2.655
            # Deep reveal, polished outer bead, and a broad sill with brass end caps.
            for yy, thickness, depth, mat in ((1.42, 0.055, 1.52, trim_shadow),
                                               (1.47, 0.035, 1.47, inlay),
                                               (2.66, 0.055, 1.52, trim_shadow),
                                               (2.61, 0.035, 1.47, inlay)):
                cube("Window %d | layered horizontal casing" % index, (xf, yy, z),
                     (0.095, thickness, depth), mat, 0.018, details)
            for zz in (z - 0.75, z + 0.75):
                cube("Window %d | layered vertical casing" % index,
                     (xf, 2.04, zz), (0.095, 1.25, 0.055), MATS["brass_highlight"], 0.018, details)
            cube("Window %d | deep polished sill" % index,
                 (side * 2.59, 1.405, z), (0.24, 0.075, 1.57), MATS["mahogany"], 0.035, details)
            for zz in (z - 0.64, z + 0.64):
                uv_sphere("Window %d | sill end rosette" % index,
                          (side * 2.47, 1.44, zz), (0.045, 0.035, 0.045), inlay)

    # Fine double-line inlay on every wall panel gives the woodwork a bespoke,
    # joinery-made finish instead of large uninterrupted brown surfaces.
    for side in (-1, 1):
        x = side * 2.625
        for z in (-5.25, -2.8, -0.35, 2.1, 4.55):
            for zz in (z - 0.76, z + 0.76):
                cube("Panel | fine vertical brass inlay", (x, 1.48, zz),
                     (0.026, 1.50, 0.025), inlay, 0.009, details)
            for yy in (0.73, 2.23):
                cube("Panel | fine horizontal brass inlay", (x, yy, z),
                     (0.026, 0.025, 1.52), inlay, 0.009, details)
            # A central diamond medallion in each mahogany panel.
            diamond = cube("Panel | ornamental diamond", (side * 2.605, 1.48, z),
                           (0.035, 0.25, 0.25), MATS["brass"], 0.018, details)
            diamond.rotation_euler[1] = math.radians(45)
            uv_sphere("Panel | medallion center", (side * 2.575, 1.48, z),
                      (0.026, 0.055, 0.055), MATS["brass_highlight"])

    # Tailored upholstery: inset piping, repeated tuft buttons, and softly raised
    # bolster rolls make the benches read as padded first-class seating.
    for z in (-3.6, -0.5, 2.8):
        for side in (-1, 1):
            x = side * 1.78
            # Seat cushion piping on the visible perimeter.
            for xx in (x - 0.58, x + 0.58):
                cube("Seat | cushion piping side", (xx, 0.686, z),
                     (0.025, 0.018, 1.08), velvet_highlight, 0.008, seating)
            for zz in (z - 0.54, z + 0.54):
                cube("Seat | cushion piping end", (x, 0.686, zz),
                     (1.12, 0.018, 0.025), velvet_highlight, 0.008, seating)
            # Upholstery buttons on a 3x3 grid on each seat back.
            for dx in (-0.36, 0.0, 0.36):
                for dy in (0.84, 1.08, 1.32):
                    uv_sphere("Seat back | deep button tuft",
                              (x + dx, dy, z - 0.515),
                              (0.028, 0.028, 0.022), MATS["brass"])
            # Low sculpted arm caps, with bright metal end pins.
            for dx in (-0.67, 0.67):
                cube("Seat | carved armrest", (x + dx, 0.79, z - 0.05),
                     (0.16, 0.16, 1.03), MATS["mahogany"], 0.065, seating)
                cube("Seat | armrest brass cap", (x + dx, 0.875, z - 0.05),
                     (0.17, 0.025, 0.90), inlay, 0.012, seating)

    # A signature brass carriage clock at the far end anchors the composition and
    # gives the compartment a memorable story object.
    clock_z = 5.78
    cube("End wall | clock shadow mount", (0, 2.32, 5.80), (1.22, 1.02, 0.10),
         trim_shadow, 0.08, details)
    cube("End wall | clock mahogany frame", (0, 2.32, 5.73), (1.12, 0.92, 0.12),
         MATS["mahogany"], 0.07, details)
    cylinder("End wall | brass clock bezel", (0, 2.33, 5.61), 0.34, 0.10,
             MATS["brass_highlight"], rotation=(math.radians(90), 0, 0), vertices=48)
    cylinder("End wall | clock face", (0, 2.33, 5.545), 0.285, 0.035,
             MATS["parchment"], rotation=(math.radians(90), 0, 0), vertices=48)
    cylinder("End wall | clock center pin", (0, 2.33, 5.515), 0.035, 0.025,
             MATS["brass"], rotation=(math.radians(90), 0, 0), vertices=20)
    # Clock hands are thin, raised brass bars.
    hand_minute = cube("End wall | clock minute hand", (0, 2.33, 5.495),
                       (0.018, 0.018, 0.22), MATS["brass"], 0.006, details)
    hand_minute.rotation_euler[1] = math.radians(-22)
    hand_hour = cube("End wall | clock hour hand", (0.035, 2.33, 5.49),
                     (0.018, 0.018, 0.15), MATS["brass"], 0.006, details)
    hand_hour.rotation_euler[1] = math.radians(48)
    for i in range(12):
        angle = (i / 12.0) * math.tau
        uv_sphere("End wall | clock hour marker",
                  (math.sin(angle) * 0.235, 2.33 + math.cos(angle) * 0.235, 5.57),
                  (0.018, 0.012, 0.018), MATS["brass"],)

    # Bespoke trunk hardware: corner guards, parallel straps, and visible studs.
    for side in (-1, 1):
        z = side * 5.05
        x = side * 1.70
        for dx in (-0.42, 0.42):
            cube("Luggage | leather strap", (x + dx, 0.355, z),
                 (0.065, 0.50, 0.79), leather, 0.015, details)
            for zz in (z - 0.31, z + 0.31):
                uv_sphere("Luggage | strap brass stud", (x + dx, 0.37, zz),
                          (0.026, 0.026, 0.026), inlay)
        for dx in (-0.43, 0.43):
            for zz in (z - 0.34, z + 0.34):
                cube("Luggage | brass corner protector", (x + dx, 0.52, zz),
                     (0.10, 0.12, 0.045), inlay, 0.018, details)

    # Correctly aimed, multi-temperature area lights: warm practical pools on wood
    # and velvet, with a restrained cool fill so dark materials retain their detail.
    for obj in list(bpy.data.objects):
        if obj.type == "LIGHT":
            bpy.data.objects.remove(obj, do_unlink=True)
    for idx, (pos, energy, color, size) in enumerate((
        ((-1.65, 2.85, -3.4), 260, (1.0, 0.57, 0.30), 2.0),
        ((1.65, 2.85, 0.0), 300, (1.0, 0.68, 0.42), 2.2),
        ((-1.65, 2.85, 3.4), 260, (1.0, 0.57, 0.30), 2.0),
        ((0.0, 2.55, 0.0), 120, (0.48, 0.70, 1.0), 3.5),
    ), 1):
        bpy.ops.object.light_add(type="AREA", location=pos)
        light = bpy.context.object
        light.name = "Lighting | cinematic bounce %d" % idx
        light.data.energy = energy
        light.data.color = color
        light.data.shape = "DISK"
        light.data.size = size
        target = Vector((0.0, 1.0, 0.0))
        direction = target - light.location
        light.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    # Slightly more legible physically based response in the authoring scene.
    bpy.context.scene.view_settings.view_transform = "AgX"
    bpy.context.scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.context.scene.render.resolution_x = 1600
    bpy.context.scene.render.resolution_y = 900
    bpy.context.scene.render.resolution_percentage = 100

    # Export root: keep asset origin at carriage center and floor at y=0.
    bpy.ops.object.select_all(action="SELECT")
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    bpy.context.scene.render.engine = "CYCLES"
    # Brighter warm interior illumination and an ambient fill are authored into the scene
    # for the .blend preview; Godot will still use its own runtime lights/environment.
    world = bpy.context.scene.world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.16, 0.19, 0.24, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
    for obj in list(bpy.data.objects):
        if obj.type == "LIGHT":
            bpy.data.objects.remove(obj, do_unlink=True)
    for idx, (x, z) in enumerate(((-1.8, -3.8), (1.8, -0.2), (-1.8, 3.6)), 1):
        bpy.ops.object.light_add(type="AREA", location=(x, 2.72, z))
        light = bpy.context.object
        light.name = "Lighting | warm lantern bounce %d" % idx
        light.data.energy = 170
        light.data.color = (1.0, 0.57, 0.28)
        light.data.shape = "DISK"
        light.data.size = 2.1
        light.rotation_euler = (math.radians(12), 0, 0)
    bpy.context.scene.render.resolution_x = 1280
    bpy.context.scene.render.resolution_y = 720
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.world.color = (0.018, 0.035, 0.052)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND_DIR, "train_carriage.blend"))

    # Apply transforms for stable glTF scale and export selected scene objects.
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(MODEL_DIR, "train_carriage.glb"),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_lights=True,
    )
    print("TRAIN_CARRIAGE_ASSET_CREATED: assets/models/train_carriage.glb")

if __name__ == "__main__":
    clear_scene()
    create_carriage()
