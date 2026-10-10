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
    "mahogany": (0.052, 0.013, 0.006, 1),
    "dark_wood": (0.034, 0.009, 0.005, 1),
    "wood_light": (0.082, 0.021, 0.009, 1),
    "brass": (0.43, 0.19, 0.045, 1),
    "brass_highlight": (0.62, 0.35, 0.095, 1),
    "velvet": (0.018, 0.15, 0.072, 1),
    "velvet_dark": (0.012, 0.095, 0.052, 1),
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
    if "glass" in name.lower():
        bsdf.inputs["Alpha"].default_value = color[3]
        if "Transmission" in bsdf.inputs:
            bsdf.inputs["Transmission"].default_value = 0.06
        if hasattr(mat, "blend_method"):
            mat.blend_method = "BLEND"
        elif hasattr(mat, "surface_render_method"):
            mat.surface_render_method = "BLENDED"
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness

    # Subtle procedural breakup removes the flat plastic look from large surfaces.
    # Generated coordinates keep this dependency-free and exportable in glTF.
    lower_name = name.lower()
    is_wood = any(token in lower_name for token in ("mahogany", "dark wood", "wood light", "walnut"))
    is_leather = "leather" in lower_name
    is_fabric = any(token in lower_name for token in ("velvet", "curtain", "upholstery", "emerald woven"))
    if is_wood or is_leather or is_fabric:
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        coordinates = nodes.new("ShaderNodeTexCoord")
        coordinates.location = (-720, 40)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-500, 40)
        noise.inputs["Scale"].default_value = 13.0 if is_wood else (32.0 if is_leather else 24.0)
        noise.inputs["Detail"].default_value = 2.5
        noise.inputs["Roughness"].default_value = 0.68
        links.new(coordinates.outputs["Generated"], noise.inputs["Vector"])

        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-250, 80)
        dark_factor, light_factor = ((0.70, 1.20) if is_wood else ((0.84, 1.10) if is_leather else (0.90, 1.06)))
        ramp.color_ramp.elements[0].position = 0.16
        ramp.color_ramp.elements[0].color = tuple(max(0.0, min(1.0, channel * dark_factor)) for channel in color[:3]) + (1.0,)
        ramp.color_ramp.elements[1].position = 0.84
        ramp.color_ramp.elements[1].color = tuple(max(0.0, min(1.0, channel * light_factor)) for channel in color[:3]) + (1.0,)
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])

        bump = nodes.new("ShaderNodeBump")
        bump.location = (-20, -160)
        bump.inputs["Strength"].default_value = 0.055 if is_wood else (0.045 if is_leather else 0.035)
        bump.inputs["Distance"].default_value = 0.018 if is_wood else 0.008
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

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

# Define seat upholstery before any seat geometry references it.
seat_leather = material("Seats | deep emerald green leather", (0.006, 0.068, 0.027, 1), roughness=0.36)

def assign(obj, mat):
    obj.data.materials.append(mat)
    return obj

def bevel(obj, amount=0.035, segments=2):
    mod = obj.modifiers.new("Soft crafted edges", "BEVEL")
    mod.width = amount
    mod.segments = segments
    # Weighted normals only work correctly when the mesh uses smooth shading.
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    if hasattr(obj.data, "use_auto_smooth"):
        obj.data.use_auto_smooth = True
        if hasattr(obj.data, "auto_smooth_angle"):
            obj.data.auto_smooth_angle = math.radians(35)
    normal_mod = obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    normal_mod.keep_sharp = True
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
    # Smoked dark-walnut floor planks: warm brown, never the pink/orange tone of pale mahogany.
    floor_wood = material("Floor | smoked dark walnut", (0.055, 0.014, 0.006, 1), roughness=0.32)
    floor_wood_alt = material("Floor | dark walnut variation", (0.078, 0.021, 0.008, 1), roughness=0.35)
    for i in range(24):
        z = -5.72 + i * 0.49
        cube("Floor plank %02d" % (i + 1), (0, 0.012, z), (5.55, 0.035, 0.455),
             floor_wood_alt if i % 4 == 0 else floor_wood, 0.012, details)
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

    cube("Rear wall | left walnut pier", (-2.32, 1.65, -5.95), (1.16, 3.3, 0.18), MATS["dark_wood"], 0.04, shell)
    cube("Rear wall | right walnut pier", (2.32, 1.65, -5.95), (1.16, 3.3, 0.18), MATS["dark_wood"], 0.04, shell)
    cube("Rear wall | doorway lintel", (0, 2.98, -5.95), (3.48, 0.64, 0.18), MATS["dark_wood"], 0.035, shell)
    cube("Doorway | left carved walnut jamb", (-1.74, 1.34, -5.80), (0.13, 2.68, 0.16), MATS["mahogany"], 0.025, details)
    cube("Doorway | right carved walnut jamb", (1.74, 1.34, -5.80), (0.13, 2.68, 0.16), MATS["mahogany"], 0.025, details)
    cube("Doorway | brass lintel inlay", (0, 2.68, -5.80), (3.42, 0.075, 0.16), MATS["brass_highlight"], 0.018, details)
    cube("Doorway | left inner brass bead", (-1.64, 1.34, -5.72), (0.035, 2.46, 0.085), MATS["brass_highlight"], 0.01, details)
    cube("Doorway | right inner brass bead", (1.64, 1.34, -5.72), (0.035, 2.46, 0.085), MATS["brass_highlight"], 0.01, details)
    cube("Doorway | brass threshold", (0, 0.075, -5.72), (3.25, 0.045, 0.22), MATS["brass"], 0.012, details)
    # A second carriage section sits beyond the open doorway to establish real depth.
    cube("Next carriage | walnut floor", (0, -0.10, -9.15), (5.56, 0.20, 6.35), MATS["dark_wood"], 0.035, shell)
    cube("Next carriage | ceiling canopy", (0, 3.38, -9.15), (5.56, 0.18, 6.35), MATS["dark_wood"], 0.035, shell)
    cube("Next carriage | left lower wall", (-2.78, 0.715, -9.15), (0.16, 1.43, 6.35), MATS["mahogany"], 0.025, shell)
    cube("Next carriage | right lower wall", (2.78, 0.715, -9.15), (0.16, 1.43, 6.35), MATS["mahogany"], 0.025, shell)
    cube("Next carriage | left upper wall", (-2.78, 2.985, -9.15), (0.16, 0.63, 6.35), MATS["mahogany"], 0.025, shell)
    cube("Next carriage | right upper wall", (2.78, 2.985, -9.15), (0.16, 0.63, 6.35), MATS["mahogany"], 0.025, shell)
    cube("Next carriage | distant end wall", (0, 1.62, -12.32), (5.56, 3.24, 0.18), MATS["dark_wood"], 0.035, shell)
    for side in (-1, 1):
        x = side * 2.78
        window_centers = (-11.15, -9.5, -7.5)
        cursor = -12.325
        for window_z in window_centers:
            opening_start = window_z - 0.59
            if opening_start > cursor:
                cube("Next carriage | window pier", (x, 2.05, (cursor + opening_start) / 2),
                     (0.16, 1.24, opening_start - cursor), MATS["mahogany"], 0.02, shell)
            cursor = window_z + 0.59
        if cursor < -5.975:
            cube("Next carriage | window end pier", (x, 2.05, (cursor - 5.975) / 2),
                 (0.16, 1.24, -5.975 - cursor), MATS["mahogany"], 0.02, shell)

        for idx, z in enumerate(window_centers, 1):
            # The next compartment also uses open window apertures; distant scenery remains visible.
            for y in (1.50, 2.60):
                cube("Next carriage | brass window rail", (side * 2.61, y, z),
                     (0.12, 0.06, 1.28), MATS["brass"], 0.015, details)
            for zz in (z - 0.64, z + 0.64):
                cube("Next carriage | brass window stile", (side * 2.61, 2.05, zz),
                     (0.12, 1.15, 0.06), MATS["brass_highlight"], 0.015, details)

    # Emerald seats beyond the portal add scale and give the second compartment a clear destination.
    for z in (-8.2, -10.35):
        for side in (-1, 1):
            x = side * 1.78
            cube("Next carriage | seat walnut plinth", (x, 0.36, z),
                 (1.24, 0.30, 1.12), MATS["dark_wood"], 0.07, seating)
            cube("Next carriage | emerald seat cushion", (x, 0.56, z),
                 (1.20, 0.24, 1.08), seat_leather, 0.08, seating)
            cube("Next carriage | emerald seat back", (x, 1.08, z - 0.45),
                 (1.20, 0.88, 0.20), seat_leather, 0.08, seating)
    cube("Front wall | end panel", (0, 1.65, 5.95), (5.8, 3.3, 0.18), MATS["dark_wood"], 0.04, shell)

    # Slim inset panels are placed only in the solid piers between windows.
    # Earlier full-width decorative panels overlapped the glazing and made windows look painted.
    for x in (-2.70, 2.70):
        for y in (0.22, 0.42, 2.92, 3.08):
            cube("Continuous brass wall rail", (x, y, 0), (0.075, 0.045, 11.7), MATS["brass"], 0.018, details)
        for panel_index, z in enumerate((-2.90, -0.70, 1.50, 3.65), 1):
            cube("Wall inset | pier panel %d" % panel_index, (x, 1.50, z),
                 (0.055, 1.48, 0.70), MATS["dark_wood"], 0.025, details)
            for y in (0.78, 2.23):
                cube("Panel brass bead | pier", (x + (0.035 if x > 0 else -0.035), y, z),
                     (0.025, 0.025, 0.58), MATS["brass_highlight"], 0.008, details)

    # Five tall windows on each side, dark teal glass with substantial brass frames.
    for side in (-1, 1):
        x_glass = side * 2.745
        x_frame = side * 2.68
        for index, z in enumerate((-4.0, -1.8, 0.4, 2.6, 4.7), 1):
            # Keep the aperture open in this first slice. A solid GL Compatibility
            # pane reads as painted blue plastic and hides the important fantasy view.
            # Brass rails and the exterior silhouettes define the glazing at gameplay scale.
            for y in (1.49, 2.61):
                cube("Window brass lintel", (x_frame, y, z), (0.13, 0.075, 1.48), MATS["brass"], 0.018, details)
            for zz in (z - 0.72, z + 0.72):
                cube("Window brass stile", (x_frame, 2.05, zz), (0.13, 1.18, 0.075), MATS["brass_highlight"], 0.018, details)
            cube("Window center divider", (x_frame, 2.05, z), (0.14, 1.0, 0.035), MATS["brass"], 0.01, details)

    # A small fantasy world sits outside the windows so the carriage never reads as a sealed box.
    # These simple, low-poly silhouettes are intentionally outside the shell and visible through the glass.
    sky_mat = material("Exterior | luminous sunset sky", (0.10, 0.22, 0.34, 1), roughness=0.95, emission=0.28)
    island_mat = material("Exterior | floating island teal", (0.10, 0.34, 0.31, 1), roughness=0.9, emission=0.08)
    stone_mat = material("Exterior | moonlit old stone", (0.43, 0.49, 0.56, 1), roughness=0.88, emission=0.08)
    distant_gold = material("Exterior | clockwork gold", (0.95, 0.58, 0.20, 1), metallic=0.22, roughness=0.38, emission=0.9)
    # Put a distinct silhouette in each window's actual first-person sightline.
    # The camera is at x=0,z=4.72; solving the projection at the window plane avoids
    # leaving the fantasy scenery hidden behind a side pier when viewed down the aisle.
    window_centers = (-4.0, -1.8, 0.4, 2.6, 4.7)
    for side in (-1, 1):
        cube("Exterior | endless twilight", (side * 5.35, 2.0, 0.0), (0.08, 5.8, 13.5), sky_mat, 0.0, shell)
        for idx, window_z in enumerate(window_centers, 1):
            tower_z = 4.72 + (window_z - 4.72) * (3.55 / 2.70)
            island_z = 4.72 + (window_z - 4.72) * (3.25 / 2.70)
            island_y = 1.56 if idx % 2 else 1.64
            # Floating island: broad horizontal silhouette along the lower pane.
            cube("Exterior | floating island %d" % idx, (side * 3.25, island_y, island_z),
                 (0.95, 0.22, 1.18), island_mat, 0.10, details)
            # Tower and roof are larger and brighter than the former distant pinpricks.
            tower_height = 0.82 + (idx % 2) * 0.18
            cube("Exterior | castle tower %d" % idx, (side * 3.55, 2.03, tower_z),
                 (0.26, tower_height, 0.34), stone_mat, 0.035, details)
            cube("Exterior | tower roof %d" % idx, (side * 3.55, 2.03 + tower_height * 0.60, tower_z),
                 (0.38, 0.13, 0.44), distant_gold, 0.035, details)
            cube("Exterior | tower window %d" % idx, (side * 3.50, 2.04, tower_z + 0.18),
                 (0.025, 0.16, 0.055), distant_gold, 0.008, details)
            if idx in (1, 3, 5):
                # A slim illuminated waterfall hangs below selected floating islands.
                cube("Exterior | luminous waterfall %d" % idx, (side * 3.18, 1.27, island_z + 0.28),
                     (0.045, 0.42, 0.10), distant_gold, 0.015, details)
        for idx, window_z in enumerate((-3.0, 3.2), 1):
            moon_z = 4.72 + (window_z - 4.72) * (4.75 / 2.70)
            uv_sphere("Exterior | distant moon %d" % idx, (side * 4.75, 2.92, moon_z),
                      (0.13, 0.13, 0.13), distant_gold)

    # Paired upholstered benches, with cushions, piping and brass feet.
    for z in (-3.6, -0.5, 2.8):
        for side in (-1, 1):
            x = side * 1.78
            cube("Seat | carved mahogany plinth", (x, 0.36, z), (1.30, 0.30, 1.24), MATS["dark_wood"], 0.09, seating)
            cube("Seat | emerald leather cushion", (x, 0.56, z), (1.27, 0.24, 1.19), seat_leather, 0.10, seating)
            cube("Seat back | velvet upholstery", (x, 1.08, z - 0.49), (1.27, 0.88, 0.22), seat_leather, 0.09, seating)
            cube("Seat back | dark wood surround", (x, 1.08, z - 0.62), (1.38, 0.98, 0.12), MATS["mahogany"], 0.07, seating)
            cube("Seat back | inset upholstery", (x, 1.08, z - 0.545), (1.15, 0.72, 0.045), MATS["velvet_dark"], 0.045, seating)
            for dx in (-0.52, 0.52):
                for dz in (-0.47, 0.47):
                    cylinder("Seat | brass foot", (x + dx, 0.13, z + dz), 0.045, 0.22, MATS["brass"], vertices=12)
            for dx in (-0.34, 0.0, 0.34):
                uv_sphere("Seat | brass upholstery stud", (x + dx, 1.10, z - 0.512), (0.025, 0.025, 0.018), MATS["brass_highlight"])

    # A tailored runner makes the central aisle feel like a first-class sleeper carriage.
    rug_mat = material("Interior | deep emerald woven runner", (0.004, 0.040, 0.017, 1), roughness=0.88)
    rug_red = material("Interior | woven antique gold motif", (0.24, 0.125, 0.028, 1), metallic=0.12, roughness=0.76)
    cube("Aisle | tailored emerald runner", (0, 0.045, 0), (0.88, 0.035, 11.25), rug_mat, 0.025, details)
    for z in [(-5.15 + i * 0.52) for i in range(20)]:
        cube("Runner | antique-gold woven lozenge", (0, 0.068, z), (0.24, 0.012, 0.24), rug_red, 0.018, details)
    for x in (-0.40, 0.40):
        cube("Runner | brass woven border", (x, 0.069, 0), (0.025, 0.012, 11.05), MATS["brass_highlight"], 0.008, details)
    cube("Next carriage | emerald runner", (0, 0.045, -9.15), (0.86, 0.035, 6.0), rug_mat, 0.02, details)
    for z in (-11.55, -10.95, -10.35, -9.75, -9.15, -8.55, -7.95, -7.35):
        cube("Next carriage | gold runner motif", (0, 0.068, z), (0.20, 0.012, 0.20), rug_red, 0.015, details)

    # Small first-class marble tables and brass reading lamps, placed between seating rows.
    marble = material("Tables | warm ivory marble", (0.66, 0.64, 0.57, 1), roughness=0.27)
    table_gold = material("Tables | polished brass", (0.64, 0.36, 0.095, 1), metallic=0.78, roughness=0.22)
    lamp_glass = material("Reading lamps | amber glass", (1.0, 0.47, 0.12, 1), roughness=0.24, emission=1.4)
    luggage_leather = material("Overhead luggage | oxblood leather", (0.22, 0.045, 0.028, 1), roughness=0.42)
    luggage_inlay = material("Overhead luggage | brass straps", (0.72, 0.43, 0.14, 1), metallic=0.68, roughness=0.26)
    for z in (-2.05, 1.15, 4.30):
        for side in (-1, 1):
            x = side * 2.08
            cube("Table | ivory marble top", (x, 0.76, z), (0.62, 0.085, 0.62), marble, 0.035, details)
            cylinder("Table | brass pedestal", (x, 0.46, z), 0.055, 0.54, table_gold, vertices=20)
            cube("Table | brass foot", (x, 0.18, z), (0.42, 0.055, 0.42), table_gold, 0.025, details)
            cylinder("Reading lamp | brass base", (x, 0.825, z), 0.105, 0.035, table_gold, vertices=24)
            cylinder("Reading lamp | brass stem", (x, 0.93, z), 0.022, 0.19, table_gold, vertices=16)
            cube("Reading lamp | amber shade", (x, 1.045, z), (0.18, 0.12, 0.18), lamp_glass, 0.045, details)

    # Overhead racks with compact leather cases; keep them above head height and out of the aisle.
    for z in (-3.6, -0.5, 2.8):
        for side in (-1, 1):
            x = side * 2.03
            cube("Luggage rack | walnut shelf", (x, 2.62, z), (0.70, 0.075, 2.18), MATS["mahogany"], 0.035, details)
            cube("Luggage rack | brass outer rail", (side * 2.34, 2.72, z), (0.045, 0.16, 2.12), MATS["brass_highlight"], 0.018, details)
            for dz in (-0.92, 0.92):
                cube("Luggage rack | brass support", (side * 2.28, 2.48, z + dz), (0.07, 0.28, 0.07), table_gold, 0.018, details)
            cube("Luggage | leather suitcase", (side * 1.90, 2.82, z), (0.56, 0.30, 0.78), luggage_leather, 0.055, details)
            for dx in (-0.12, 0.12):
                cube("Luggage | brass suitcase band", (side * 1.90 + dx * 1.25, 2.82, z), (0.045, 0.31, 0.80), luggage_inlay, 0.012, details)
            cube("Luggage | brass handle", (side * 1.90, 2.99, z), (0.17, 0.03, 0.04), table_gold, 0.012, details)

    # Emerald upholstered ceiling panels and tailored velvet curtains establish the requested signature palette.
    emerald_ceiling = material("Ceiling | emerald woven velvet", (0.012, 0.115, 0.058, 1), roughness=0.86)
    for panel_z in (-4.4, -2.6, -0.8, 1.0, 2.8, 4.6):
        cube("Ceiling | emerald upholstered inset", (0, 3.365, panel_z), (4.75, 0.035, 1.38), emerald_ceiling, 0.045, details)
    curtain_mat = material("Curtains | deep emerald velvet", (0.006, 0.105, 0.042, 1), roughness=0.86)
    curtain_fold = material("Curtains | raised emerald folds", (0.010, 0.14, 0.052, 1), roughness=0.82)
    for side in (-1, 1):
        for z in (-4.0, -1.8, 0.4, 2.6, 4.7):
            for zz in (z - 0.66, z + 0.66):
                cube("Curtain | hanging emerald panel", (side * 2.60, 2.03, zz), (0.12, 1.12, 0.20), curtain_mat, 0.045, details)
                for fold in (-0.055, 0.0, 0.055):
                    cube("Curtain | tailored fold", (side * 2.525, 2.03, zz + fold), (0.035, 1.02, 0.018), curtain_fold, 0.008, details)
                cube("Curtain | brass tie-back", (side * 2.49, 1.88, zz), (0.07, 0.055, 0.24), MATS["brass_highlight"], 0.018, details)

        for z in (-11.15, -9.5, -7.5):
            for zz in (z - 0.54, z + 0.54):
                cube("Next carriage | emerald curtain", (side * 2.58, 2.03, zz),
                     (0.10, 1.08, 0.16), curtain_mat, 0.035, details)
                for fold in (-0.045, 0.0, 0.045):
                    cube("Next carriage | curtain fold", (side * 2.52, 2.03, zz + fold),
                         (0.025, 1.00, 0.014), curtain_fold, 0.006, details)

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
    for side in (1,):
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

    # Three visible centerline ceiling fixtures echo the reference carriage and
    # remain readable from the first-person camera (the side sconces are mostly peripheral).
    for idx, z in enumerate((-3.8, 0.0, 3.7), 1):
        cylinder("Ceiling lamp %d | brass ceiling rose" % idx, (0, 3.31, z), 0.14, 0.07, MATS["brass_highlight"], vertices=24)
        cylinder("Ceiling lamp %d | brass drop stem" % idx, (0, 3.18, z), 0.035, 0.22, MATS["brass"], vertices=16)
        cube("Ceiling lamp %d | amber opal shade" % idx, (0, 3.02, z), (0.30, 0.14, 0.30), MATS["lantern"], 0.045, details)
        for dx in (-0.17, 0.17):
            cylinder("Ceiling lamp %d | brass shade rim" % idx, (dx, 3.02, z), 0.018, 0.15, MATS["brass_highlight"], vertices=10)

    # Repeated rivets along trim establish the locomotive's engineered feel.
    for side in (-1, 1):
        for z in [(-5.5 + i * 0.5) for i in range(23)]:
            uv_sphere("Brass rail rivet", (side * 2.655, 3.08, z), (0.025, 0.025, 0.025), MATS["brass_highlight"])

    # Production pass: layered window casings, tailored upholstery, engraved trim,
    # and focal storytelling props. Keep geometry readable at mobile camera distance.
    trim_shadow = material("Carved trim | shadow", (0.045, 0.018, 0.012, 1), roughness=0.42)
    velvet_highlight = material("Emerald leather | raised piping", (0.012, 0.12, 0.046, 1), roughness=0.50)
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

    # A focal carriage clock is mounted on the far wall of the second section,
    # facing down the central aisle through the open doorway.
    cube("Next carriage | clock shadow mount", (0, 2.32, -12.17), (1.22, 1.02, 0.10),
         trim_shadow, 0.08, details)
    cube("Next carriage | clock mahogany frame", (0, 2.32, -12.08), (1.12, 0.92, 0.12),
         MATS["mahogany"], 0.07, details)
    cylinder("Next carriage | brass clock bezel", (0, 2.33, -12.005), 0.34, 0.10,
             MATS["brass_highlight"], vertices=48)
    cylinder("Next carriage | clock face", (0, 2.33, -11.945), 0.285, 0.035,
             MATS["parchment"], vertices=48)
    cylinder("Next carriage | clock center pin", (0, 2.33, -11.915), 0.035, 0.025,
             MATS["brass"], vertices=20)
    minute_hand = cube("Next carriage | clock minute hand", (0, 2.44, -11.895),
                       (0.018, 0.22, 0.018), MATS["brass"], 0.006, details)
    minute_hand.rotation_euler[2] = math.radians(-22)
    hour_hand = cube("Next carriage | clock hour hand", (0.035, 2.33, -11.89),
                     (0.018, 0.15, 0.018), MATS["brass"], 0.006, details)
    hour_hand.rotation_euler[2] = math.radians(48)
    for i in range(12):
        angle = (i / 12.0) * math.tau
        uv_sphere("Next carriage | clock hour marker",
                  (math.sin(angle) * 0.235, 2.33 + math.cos(angle) * 0.235, -11.91),
                  (0.018, 0.018, 0.018), MATS["brass"])

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
        ((1.65, 2.85, 0.0), 420, (1.0, 0.68, 0.42), 2.2),
        ((-1.65, 2.85, 3.4), 360, (1.0, 0.57, 0.30), 2.0),
        ((0.0, 2.55, 0.0), 220, (0.48, 0.70, 1.0), 3.5),
        # Warm practical light spills through the open portal into the next carriage.
        ((-1.45, 2.85, -7.7), 500, (1.0, 0.52, 0.28), 2.4),
        ((1.45, 2.85, -10.25), 460, (1.0, 0.66, 0.38), 2.4),
        ((0.0, 2.55, -8.9), 190, (0.48, 0.70, 1.0), 3.0),
    ), 1):
        bpy.ops.object.light_add(type="AREA", location=pos)
        light = bpy.context.object
        light.name = "Lighting | cinematic bounce %d" % idx
        light.data.energy = energy
        light.data.color = color
        light.data.shape = "DISK"
        light.data.size = size
        target = Vector((0.0, 1.05, -9.1)) if pos[2] < -6.0 else Vector((0.0, 1.0, 0.0))
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
    # Brighter warm interior illumination and an ambient fill are authored into the scene
    # for the .blend preview; Godot will still use its own runtime lights/environment.
    scene = bpy.context.scene
    world = scene.world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.16, 0.19, 0.24, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.70
    scene.world.color = (0.018, 0.035, 0.052)

    # Match the game's eye-level opening shot so the preview checks the central aisle,
    # green upholstery, doorway depth and far clock in the same composition as play.
    bpy.ops.object.camera_add(location=(0.0, 1.58, 4.72))
    camera = bpy.context.object
    camera.name = "Preview Camera | first-person carriage view"
    camera.data.name = "Preview Camera | 16:9 mobile match"
    camera.data.lens = 16.0
    camera.data.sensor_fit = "VERTICAL"
    look_at = Vector((0.0, 1.92, -4.85))
    camera.rotation_euler = (look_at - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    # The generator's design coordinates deliberately match Godot (Y is up,
    # the aisle runs along Z). Blender itself is Z-up. Rotate the whole authored
    # scene—including preview camera and lights—into Blender's native Z-up frame
    # before rendering/exporting. The glTF Y-up conversion then restores the intended
    # Godot orientation instead of exporting a sideways carriage.
    coordinate_root = bpy.data.objects.new("Coordinate Root | Godot Y-up authoring", None)
    scene.collection.objects.link(coordinate_root)
    for authored_obj in list(scene.objects):
        if authored_obj is not coordinate_root:
            authored_obj.parent = coordinate_root
    coordinate_root.rotation_euler.x = math.radians(90.0)

    # Ubuntu runner packages may provide Blender 3.x (BLENDER_EEVEE) while
    # newer workstations provide Blender 4.x (BLENDER_EEVEE_NEXT). Choose the
    # installed renderer instead of failing the asset pipeline on a version mismatch.
    available_engines = {
        item.identifier for item in scene.render.bl_rna.properties["engine"].enum_items
    }
    if "BLENDER_EEVEE_NEXT" in available_engines:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    elif "BLENDER_EEVEE" in available_engines:
        scene.render.engine = "BLENDER_EEVEE"
    else:
        raise RuntimeError("No Eevee renderer is available for the carriage preview.")
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.color_depth = "8"
    scene.render.filepath = os.path.join(BLEND_DIR, "train_carriage_preview.png")
    scene.render.film_transparent = False
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND_DIR, "train_carriage.blend"))
    bpy.ops.render.render(write_still=True)
    print("TRAIN_CARRIAGE_PREVIEW_CREATED: assets/blender/train_carriage_preview.png")

    # Apply transforms for stable glTF scale and export selected scene objects.
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(MODEL_DIR, "train_carriage.glb"),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_lights=True,
        export_cameras=False,
    )
    print("TRAIN_CARRIAGE_ASSET_CREATED: assets/models/train_carriage.glb")

if __name__ == "__main__":
    clear_scene()
    create_carriage()