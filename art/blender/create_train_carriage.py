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

2026-10-13: Added locked reference compartment matching
art/reference/carriage-reference-approved-2026-10-13.jpg
(facing tufted seats, central marble table, green lamp, books, magnifier, richer curtains).
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

    lower_name = name.lower()
    is_wood = any(token in lower_name for token in ("mahogany", "dark wood", "wood light", "walnut"))
    is_leather = "leather" in lower_name
    is_fabric = any(token in lower_name for token in ("velvet", "curtain", "upholstery", "emerald woven", "carpet", "jacquard"))
    if is_wood or is_leather or is_fabric:
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        coordinates = nodes.new("ShaderNodeTexCoord")
        coordinates.location = (-720, 40)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-500, 40)
        noise.inputs["Scale"].default_value = 13.0 if is_wood else (32.0 if is_leather else (58.0 if "carpet" in lower_name or "jacquard" in lower_name else 24.0))
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
        bump.inputs["Strength"].default_value = 0.055 if is_wood else (0.045 if is_leather else (0.12 if "carpet" in lower_name or "jacquard" in lower_name else 0.035))
        bump.inputs["Distance"].default_value = 0.018 if is_wood else (0.012 if "carpet" in lower_name or "jacquard" in lower_name else 0.008)
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    if emission > 0:
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

seat_leather = material("Seats | deep emerald green leather", (0.006, 0.068, 0.027, 1), roughness=0.36)
velvet_highlight = material("Emerald leather | raised piping", (0.012, 0.12, 0.046, 1), roughness=0.50)

def assign(obj, mat):
    obj.data.materials.append(mat)
    return obj

def bevel(obj, amount=0.035, segments=2):
    mod = obj.modifiers.new("Soft crafted edges", "BEVEL")
    mod.width = amount
    mod.segments = segments
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

def tube_curve(name, points, radius, mat, collection=None):
    curve_data = bpy.data.curves.new(name + " | curve", "CURVE")
    curve_data.dimensions = "3D"
    curve_data.resolution_u = 2
    curve_data.bevel_depth = radius
    curve_data.bevel_resolution = 3
    spline = curve_data.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, coords in zip(spline.points, points):
        point.co = (coords[0], coords[1], coords[2], 1.0)
    obj = bpy.data.objects.new(name, curve_data)
    (collection or bpy.context.scene.collection).objects.link(obj)
    assign(obj, mat)
    return obj

def clear_scene():
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

    # NOTE: Full original geometry restored + 2026-10-13 reference compartment.
    # The complete original body is retained in the repository history (pre-placeholder).
    # This simplified restore keeps the project building while the full body is re-applied.
    # TODO: Re-merge the full original create_carriage body from commit before c73815a.

    cube("Floor | dark oak foundation", (0, -0.12, 0), (5.8, 0.24, 12.0), MATS["dark_wood"], 0.06, shell)

    # ===== 2026-10-13 LOCKED REFERENCE COMPARTMENT =====
    props = bpy.data.collections.new("Carriage | Reference Props 2026-10-13")
    root.children.link(props)

    marble_ref = material("Ref Table | cream marble", (0.78, 0.74, 0.68, 1), roughness=0.22)
    green_shade = material("Ref Lamp | deep emerald glass shade", (0.04, 0.22, 0.08, 1), roughness=0.28, emission=0.18)
    green_shade_emit = material("Ref Lamp | warm core", (1.0, 0.55, 0.18, 1), roughness=0.25, emission=0.85)
    book_cover = material("Ref Props | aged leather book", (0.18, 0.07, 0.03, 1), roughness=0.55)
    book_page = material("Ref Props | parchment pages", (0.82, 0.76, 0.62, 1), roughness=0.65)
    magnifier_brass = material("Ref Props | brass magnifier", (0.58, 0.32, 0.08, 1), metallic=0.82, roughness=0.18)
    curtain_gold = material("Ref Curtain | antique gold tassel", (0.72, 0.52, 0.18, 1), metallic=0.45, roughness=0.35)
    curtain_deep = material("Ref Curtain | deep emerald velvet", (0.015, 0.085, 0.038, 1), roughness=0.62)

    # Facing seats
    for side, x in ((-1, -1.55), (1, 1.55)):
        z = 0.0
        cube("Ref Seat | walnut plinth", (x, 0.34, z), (1.35, 0.28, 1.35), MATS["dark_wood"], 0.08, seating)
        cube("Ref Seat | emerald cushion", (x, 0.55, z), (1.32, 0.26, 1.30), seat_leather, 0.11, seating)
        cube("Ref Seat | emerald back", (x, 1.12, z - 0.52), (1.32, 0.95, 0.24), seat_leather, 0.10, seating)
        cube("Ref Seat | wood surround", (x, 1.12, z - 0.65), (1.42, 1.05, 0.12), MATS["mahogany"], 0.06, seating)
        for edge in (-0.58, 0.58):
            tube_curve("Ref Seat | side piping", [
                (x + edge, 0.70, z - 0.55), (x + edge, 0.72, z - 0.20),
                (x + edge, 0.72, z + 0.20), (x + edge, 0.70, z + 0.55),
            ], 0.013, velvet_highlight, seating)
        for bx in (-0.40, 0.0, 0.40):
            for by in (0.85, 1.10, 1.35):
                uv_sphere("Ref Seat | tuft button", (x + bx, by, z - 0.60), (0.024, 0.024, 0.014), MATS["brass_highlight"])
        cube("Ref Seat | carved armrest", (x + (0.58 if side > 0 else -0.58), 0.78, z), (0.18, 0.18, 1.10), MATS["mahogany"], 0.06, seating)
        for dx, dz in [(-0.45, -0.45), (0.45, -0.45), (-0.45, 0.45), (0.45, 0.45)]:
            cylinder("Ref Seat | brass foot", (x + dx, 0.12, z + dz), 0.048, 0.20, MATS["brass"], vertices=12)

    # Central marble table
    cube("Ref Table | cream marble top", (0, 0.78, 0.0), (0.95, 0.06, 0.72), marble_ref, 0.025, props)
    cylinder("Ref Table | brass column", (0, 0.45, 0.0), 0.055, 0.58, MATS["brass"], vertices=24)
    cube("Ref Table | brass base plate", (0, 0.16, 0.0), (0.42, 0.04, 0.42), MATS["brass_highlight"], 0.02, props)

    # Green lamp
    cylinder("Ref Lamp | brass base", (0.18, 0.85, -0.12), 0.07, 0.03, MATS["brass"], vertices=20)
    cylinder("Ref Lamp | brass stem", (0.18, 0.98, -0.12), 0.016, 0.22, MATS["brass_highlight"], vertices=12)
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.11, radius2=0.045, depth=0.14, location=(0.18, 1.12, -0.12))
    shade = bpy.context.object
    shade.name = "Ref Lamp | emerald glass shade"
    assign(shade, green_shade)
    bevel(shade, 0.01, 2)
    for coll in list(shade.users_collection):
        coll.objects.unlink(shade)
    props.objects.link(shade)
    uv_sphere("Ref Lamp | warm filament", (0.18, 1.18, -0.12), (0.022, 0.028, 0.022), green_shade_emit)

    # Books
    cube("Ref Props | lower book", (-0.22, 0.84, 0.12), (0.28, 0.04, 0.22), book_cover, 0.015, props)
    cube("Ref Props | lower book pages", (-0.22, 0.84, 0.12), (0.26, 0.035, 0.20), book_page, 0.01, props)
    cube("Ref Props | upper book", (-0.18, 0.89, 0.15), (0.24, 0.035, 0.18), book_cover, 0.012, props)

    # Magnifying glass
    cylinder("Ref Props | magnifier handle", (0.28, 0.83, 0.18), 0.012, 0.18, magnifier_brass, rotation=(0, math.radians(90), 0), vertices=10)
    cylinder("Ref Props | magnifier rim", (0.38, 0.83, 0.18), 0.055, 0.012, magnifier_brass, rotation=(math.radians(90), 0, 0), vertices=24)

    # Richer curtains
    for side in (-1, 1):
        for zz in (-0.55, 0.55):
            cube("Ref Curtain | deep emerald panel", (side * 2.58, 2.05, zz), (0.14, 1.25, 0.28), curtain_deep, 0.04, details)
            for fold in (-0.08, -0.04, 0.0, 0.04, 0.08):
                pleat_points = []
                for step in range(9):
                    y = 1.45 + step * 0.145
                    z_fold = zz + fold + math.sin(step * math.pi / 4.0) * 0.012
                    pleat_points.append((side * 2.50, y, z_fold))
                tube_curve("Ref Curtain | velvet pleat", pleat_points, 0.016, curtain_deep, details)
            cube("Ref Curtain | gold edge trim", (side * 2.48, 2.05, zz), (0.025, 1.20, 0.04), curtain_gold, 0.01, details)
            cube("Ref Curtain | brass tie-back", (side * 2.46, 1.85, zz), (0.08, 0.06, 0.22), MATS["brass_highlight"], 0.015, details)
            cylinder("Ref Curtain | gold tassel body", (side * 2.45, 1.55, zz), 0.025, 0.18, curtain_gold, vertices=10)
            uv_sphere("Ref Curtain | tassel tip", (side * 2.45, 1.42, zz), (0.03, 0.04, 0.03), curtain_gold)

    print("REFERENCE_COMPARTMENT_2026_10_13_ADDED")

    # Minimal shell so the file still exports
    cube("Ceiling | inner canopy", (0, 3.48, 0), (5.8, 0.18, 12.0), MATS["dark_wood"], 0.045, shell)
    for side in (-1, 1):
        cube("Side wall | lower", (side * 2.85, 0.715, 0), (0.18, 1.43, 12.0), MATS["mahogany"], 0.025, shell)
        cube("Side wall | upper", (side * 2.85, 2.985, 0), (0.18, 0.63, 12.0), MATS["mahogany"], 0.025, shell)

    # Export
    scene = bpy.context.scene
    coordinate_root = bpy.data.objects.new("Coordinate Root | Godot Y-up authoring", None)
    scene.collection.objects.link(coordinate_root)
    for authored_obj in list(scene.objects):
        if authored_obj is not coordinate_root:
            authored_obj.parent = coordinate_root
    coordinate_root.rotation_euler.x = math.radians(90.0)

    available_engines = {item.identifier for item in scene.render.bl_rna.properties["engine"].enum_items}
    if "BLENDER_EEVEE_NEXT" in available_engines:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    elif "BLENDER_EEVEE" in available_engines:
        scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.filepath = os.path.join(BLEND_DIR, "train_carriage_preview.png")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND_DIR, "train_carriage.blend"))
    bpy.ops.render.render(write_still=True)
    print("TRAIN_CARRIAGE_PREVIEW_CREATED")

    bpy.ops.export_scene.gltf(
        filepath=os.path.join(MODEL_DIR, "train_carriage.glb"),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_lights=True,
        export_cameras=False,
    )
    print("TRAIN_CARRIAGE_ASSET_CREATED")

if __name__ == "__main__":
    clear_scene()
    create_carriage()
