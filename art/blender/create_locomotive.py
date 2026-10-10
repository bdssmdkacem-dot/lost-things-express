import bpy
import math
import os
from mathutils import Vector, Matrix

"""
Production locomotive for The Lost Things Express.
Authored as a reusable Blender scene; exports a GLB and a review render.
Local origin is at rail level, centered on the track; the engine nose faces -Z.
"""
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODEL_DIR = os.path.join(ROOT, "assets", "models")
BLEND_DIR = os.path.join(ROOT, "assets", "blender")
os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(BLEND_DIR, exist_ok=True)

# Clear the default scene while preserving no dependency on the carriage generator.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for data in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
    for item in list(data):
        if item.users == 0:
            data.remove(item)

def mat(name, color, metallic=0.0, roughness=0.4, emission=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1.0)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0:
        socket = "Emission Color" if "Emission Color" in bsdf.inputs else "Emission"
        bsdf.inputs[socket].default_value = (*color, 1.0)
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emission
    return m

GREEN = mat("Locomotive | deep bottle-green enamel", (0.025, 0.19, 0.105), 0.48, 0.26)
GREEN_DARK = mat("Locomotive | shadow green", (0.012, 0.065, 0.045), 0.38, 0.32)
BRASS = mat("Locomotive | aged polished brass", (0.56, 0.30, 0.075), 0.82, 0.23)
BRASS_LIGHT = mat("Locomotive | bright brass edges", (0.78, 0.49, 0.16), 0.78, 0.2)
IRON = mat("Locomotive | forged black iron", (0.025, 0.032, 0.035), 0.72, 0.3)
STEEL = mat("Locomotive | brushed steel", (0.22, 0.25, 0.27), 0.82, 0.28)
RED = mat("Locomotive | oxblood buffer beam", (0.25, 0.025, 0.02), 0.22, 0.35)
GLASS = mat("Locomotive | midnight blue glass", (0.025, 0.10, 0.16), 0.28, 0.18, 0.18)
LAMP = mat("Locomotive | warm headlamp glass", (1.0, 0.42, 0.09), 0.12, 0.18, 3.0)
RUBBER = mat("Locomotive | wheel tyre", (0.018, 0.021, 0.024), 0.48, 0.34)

def assign(obj, material):
    obj.data.materials.append(material)
    return obj

def bevel(obj, width=0.035, segments=3):
    if width > 0:
        mod = obj.modifiers.new("Soft machined edges", "BEVEL")
        mod.width = width
        mod.segments = segments
        normal = obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
        normal.keep_sharp = True
    return obj

def cube(name, loc, dims, material, edge=0.025, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(o, material)
    bevel(o, edge)
    return o

def cyl(name, loc, radius, depth, material, rot=(0, 0, 0), verts=48, edge=0.012):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    assign(o, material)
    bevel(o, edge, 2)
    for p in o.data.polygons:
        p.use_smooth = True
    return o

def sphere(name, loc, scale, material, segments=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(o, material)
    for p in o.data.polygons:
        p.use_smooth = True
    return o

def torus(name, loc, major, minor, material, rot=(0, 0, 0), major_segments=64, minor_segments=12):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=major_segments, minor_segments=minor_segments, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    assign(o, material)
    for p in o.data.polygons:
        p.use_smooth = True
    return o

def tube(name, points, radius, material):
    curve = bpy.data.curves.new(name + " | formed pipe", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 16
    curve.bevel_depth = radius
    curve.bevel_resolution = 4
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bp, p in zip(spline.bezier_points, points):
        bp.co = p
        bp.handle_left_type = "AUTO"
        bp.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    assign(obj, material)
    return obj

# Main chassis, with a deep underframe and brass edge strip.
cube("Locomotive underframe", (0, 0.78, -0.05), (2.72, 0.42, 6.15), IRON, 0.11)
cube("Chassis brass side rail L", (-1.37, 0.88, -0.05), (0.055, 0.16, 6.0), BRASS, 0.018)
cube("Chassis brass side rail R", (1.37, 0.88, -0.05), (0.055, 0.16, 6.0), BRASS, 0.018)
cube("Front oxblood buffer beam", (0, 0.91, -3.15), (2.65, 0.36, 0.34), RED, 0.07)
cube("Rear coupling beam", (0, 0.86, 3.02), (2.35, 0.28, 0.28), IRON, 0.05)

# Three heavy spoked wheels on each side, with tyres, hubs, and connecting rods.
wheel_zs = [-2.25, 0.05, 2.18]
for side in (-1, 1):
    x = side * 1.32
    for wi, z in enumerate(wheel_zs):
        cyl("Wheel %s %d | tyre" % (side, wi), (x, 0.66, z), 0.51, 0.20, RUBBER, (0, math.pi / 2, 0), 64, 0.018)
        torus("Wheel %s %d | machined rim" % (side, wi), (x + side * 0.112, 0.66, z), 0.438, 0.035, STEEL, (0, math.pi / 2, 0))
        cyl("Wheel %s %d | brass hub" % (side, wi), (x + side * 0.135, 0.66, z), 0.145, 0.25, BRASS, (0, math.pi / 2, 0), 32, 0.015)
        cyl("Wheel %s %d | axle cap" % (side, wi), (x + side * 0.275, 0.66, z), 0.065, 0.035, BRASS_LIGHT, (0, math.pi / 2, 0), 24, 0.006)
        # Six steel spokes per wheel.
        for spoke in range(6):
            angle = math.tau * spoke / 6.0
            sx = x + side * 0.115
            spoke_obj = cube("Wheel spoke", (sx, 0.66 + math.sin(angle) * 0.27, z + math.cos(angle) * 0.27), (0.055, 0.055, 0.50), STEEL, 0.012)
            spoke_obj.rotation_euler.x = angle
    cube("LocomotiveConnectingRod_L" if side < 0 else "LocomotiveConnectingRod_R", (side * 1.48, 0.66, -0.035), (0.09, 0.10, 4.55), STEEL, 0.035)
    for z in wheel_zs:
        cyl("Connecting rod brass pin", (side * 1.54, 0.66, z), 0.095, 0.12, BRASS_LIGHT, (0, math.pi / 2, 0), 32, 0.01)

# Boiler barrel and four raised rolled-brass bands.
cyl("Pressure boiler | enamel barrel", (0, 1.72, -0.78), 0.72, 4.35, GREEN, (0, 0, 0), 64, 0.045)
for z in (-2.78, -1.88, -0.98, -0.08, 0.82, 1.30):
    torus("Boiler rolled brass band", (0, 1.72, z), 0.724, 0.047, BRASS, (0, 0, 0))
# Front smokebox door, raised rim, bolts and central latch.
cyl("Smokebox front door", (0, 1.72, -3.00), 0.575, 0.14, GREEN_DARK, (0, 0, 0), 64, 0.02)
torus("Smokebox door brass rim", (0, 1.72, -3.085), 0.565, 0.045, BRASS_LIGHT)
cyl("Smokebox door boss", (0, 1.72, -3.10), 0.11, 0.08, BRASS, (0, 0, 0), 32, 0.01)
cube("Smokebox door cross handle", (0, 1.72, -3.155), (0.34, 0.055, 0.05), BRASS_LIGHT, 0.018)
for i in range(12):
    a = math.tau * i / 12
    sphere("Smokebox rim bolt %02d" % i, (math.cos(a) * 0.535, 1.72 + math.sin(a) * 0.535, -3.115), (0.035, 0.035, 0.025), BRASS_LIGHT, 12, 8)

# Boiler pipes, formed handrails, couplings, and brackets.
for side in (-1, 1):
    x = side * 0.77
    tube("Boiler steam pipe", [(x, 1.24, -2.75), (x, 1.20, -1.9), (x, 1.34, -0.7), (x, 1.48, 0.65), (x, 1.5, 1.24)], 0.055, BRASS)
    tube("Boiler handrail", [(side * 0.82, 2.18, -2.25), (side * 0.91, 2.22, -1.35), (side * 0.91, 2.22, -0.2), (side * 0.83, 2.18, 0.8)], 0.028, BRASS_LIGHT)
    for z in (-1.95, -1.15, -0.35, 0.45):
        cyl("Handrail bracket", (side * 0.88, 2.06, z), 0.045, 0.16, BRASS, (math.pi / 2, 0, 0), 20, 0.008)

# Chimney, cap, whistle, and steam dome.
cyl("Smokestack base", (0, 2.36, -2.18), 0.31, 0.20, BRASS, (math.pi / 2, 0, 0), 48)
cyl("Tall black smokestack", (0, 2.72, -2.18), 0.22, 0.70, IRON, (math.pi / 2, 0, 0), 48)
cyl("Smokestack flared cap", (0, 3.09, -2.18), 0.34, 0.13, BRASS, (math.pi / 2, 0, 0), 48)
cyl("Steam dome collar", (0, 2.30, -0.82), 0.34, 0.15, BRASS, (math.pi / 2, 0, 0), 48)
sphere("Steam dome", (0, 2.48, -0.82), (0.32, 0.27, 0.42), GREEN, 32, 16)
cyl("Whistle base", (0.32, 2.42, 0.20), 0.10, 0.12, BRASS, (math.pi / 2, 0, 0), 32)
cyl("Steam whistle", (0.32, 2.60, 0.20), 0.055, 0.28, BRASS_LIGHT, (math.pi / 2, 0, 0), 24)

# Cab body and separate window frames create real recess/depth cues.
cube("Cab lower body", (0, 1.95, 2.15), (2.48, 1.92, 1.72), GREEN, 0.09)
cube("Cab waist brass moulding", (0, 1.55, 2.15), (2.53, 0.075, 1.78), BRASS, 0.018)
cube("Cab roof", (0, 3.02, 2.17), (2.78, 0.20, 2.0), GREEN_DARK, 0.08)
cube("Cab roof brass edge", (0, 2.91, 2.17), (2.80, 0.055, 2.02), BRASS, 0.018)
for side in (-1, 1):
    x = side * 1.255
    for z in (1.62, 2.55):
        cube("Cab side window glass", (x, 2.30, z), (0.035, 0.77, 0.66), GLASS, 0.006)
        for y in (1.88, 2.72):
            cube("Cab side window brass rail", (x + side * 0.025, y, z), (0.06, 0.045, 0.72), BRASS_LIGHT, 0.012)
        for zz in (z - 0.36, z + 0.36):
            cube("Cab side window upright", (x + side * 0.025, 2.30, zz), (0.06, 0.88, 0.045), BRASS_LIGHT, 0.012)
    cube("Cab side lower panel", (x, 1.34, 2.15), (0.06, 0.25, 1.5), GREEN_DARK, 0.025)
# Cab front windows face the direction of travel.
for x in (-0.64, 0.64):
    cube("Cab front glass", (x, 2.33, 1.275), (0.70, 0.78, 0.035), GLASS, 0.008)
    for xx in (x - 0.37, x + 0.37):
        cube("Cab front brass upright", (xx, 2.33, 1.245), (0.045, 0.88, 0.06), BRASS_LIGHT, 0.012)
    for y in (1.88, 2.78):
        cube("Cab front brass rail", (x, y, 1.245), (0.78, 0.045, 0.06), BRASS_LIGHT, 0.012)
cube("Cab front center pillar", (0, 2.33, 1.22), (0.07, 0.92, 0.08), BRASS, 0.015)

# Front buffer hardware, lamps, steps and coupling.
for side in (-1, 1):
    cyl("Front buffer housing", (side * 1.04, 0.94, -3.38), 0.19, 0.25, IRON, (0, 0, 0), 40, 0.02)
    cyl("Front buffer brass cap", (side * 1.04, 0.94, -3.53), 0.14, 0.08, STEEL, (0, 0, 0), 40, 0.018)
    cube("Front step", (side * 0.78, 0.50, -3.15), (0.38, 0.10, 0.38), STEEL, 0.025)
    cyl("Marker lamp brass housing", (side * 0.88, 1.22, -3.35), 0.13, 0.18, BRASS, (0, 0, 0), 40, 0.018)
    sphere("Marker lamp lens", (side * 0.88, 1.22, -3.46), (0.085, 0.085, 0.035), LAMP, 24, 12)
# Main headlamp and its hood.
cyl("Headlamp brass housing", (0, 2.05, -3.28), 0.27, 0.22, BRASS, (0, 0, 0), 48, 0.025)
sphere("Headlamp glowing lens", (0, 2.05, -3.405), (0.20, 0.20, 0.045), LAMP, 32, 16)
cube("Headlamp upper hood", (0, 2.30, -3.32), (0.58, 0.075, 0.34), BRASS, 0.03)
# Sloped pilot grate bars instead of a flat cowcatcher plate.
for i in range(9):
    x = -0.92 + i * 0.23
    bar = cube("Cowcatcher sloped steel bar", (x, 0.55, -3.50), (0.075, 0.64, 0.09), STEEL, 0.014, (0.0, 0.0, -0.35))
cube("Pilot lower crossbar", (0, 0.34, -3.53), (2.05, 0.10, 0.12), IRON, 0.025)
# Brass-edged nameplate on the front.
cube("Engine nameplate backing", (0, 1.42, -3.20), (0.94, 0.22, 0.055), BRASS, 0.025)
cube("Engine nameplate enamel inset", (0, 1.42, -3.235), (0.84, 0.14, 0.025), GREEN_DARK, 0.012)

# Rear couplings make the engine feel physically attached to a carriage.
for z in (3.18,):
    cyl("Rear coupling socket", (0, 0.70, z), 0.15, 0.24, IRON, (math.pi / 2, 0, 0), 32)
    tube("Rear coupling loop", [(-0.18, 0.68, z + 0.12), (-0.16, 0.46, z + 0.30), (0.0, 0.42, z + 0.35), (0.16, 0.46, z + 0.30), (0.18, 0.68, z + 0.12)], 0.035, STEEL)

# Grounded preview setup: the asset itself remains isolated from the studio.
bpy.ops.object.camera_add(location=(8.6, 5.4, -9.4))
camera = bpy.context.object
camera.name = "Locomotive review camera"
target = Vector((0.0, 1.55, 0.0))
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.lens = 54
bpy.context.scene.camera = camera
for name, loc, power, size, color in [
    ("Warm key", (1.5, 7.0, -5.0), 1250, 5.0, (1.0, 0.72, 0.48)),
    ("Cool fill", (-5.0, 4.0, 1.0), 900, 4.0, (0.43, 0.62, 1.0)),
    ("Brass rim", (3.0, 5.0, 4.5), 1500, 3.0, (1.0, 0.48, 0.18)),
]:
    bpy.ops.object.light_add(type="AREA", location=loc)
    light = bpy.context.object
    light.name = name
    light.data.energy = power
    light.data.shape = "DISK"
    light.data.size = size
    light.data.color = color
    light.rotation_euler = (Vector((0.0, 1.5, 0.0)) - light.location).to_track_quat("-Z", "Y").to_euler()

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
# Ubuntu Blender packages may be built without OpenImageDenoiser.
scene.cycles.use_denoising = False
scene.render.resolution_x = 1280
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = os.path.join(BLEND_DIR, "lost_things_locomotive_preview.png")
scene.world.color = (0.025, 0.035, 0.055)
scene.view_settings.view_transform = "AgX"
scene.render.image_settings.color_mode = "RGBA"
# Render first, then remove camera/lights from the exported runtime asset.
bpy.ops.render.render(write_still=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.context.scene.objects:
    if obj.type in {"CAMERA", "LIGHT"}:
        obj.select_set(True)
bpy.ops.object.delete(use_global=False)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND_DIR, "lost_things_locomotive.blend"))
bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.context.scene.objects:
    if obj.type == "MESH" or obj.type == "CURVE":
        obj.select_set(True)
bpy.context.view_layer.objects.active = next((o for o in bpy.context.scene.objects if o.select_get()), None)
# All authored dimensions above intentionally use the game's Y-up coordinates:
# X = track width, Y = vertical, Z = locomotive length. Blender's glTF exporter
# converts Blender Z-up to glTF Y-up with a +90 degree X basis conversion.
# Apply the inverse to the mesh data so the exporter cancels it, preserving the
# intended Y-up model in Godot instead of tipping the boiler/cab onto their side.
axis_fix = Matrix.Rotation(math.radians(-90.0), 4, "X")
for obj in bpy.context.scene.objects:
    if obj.type in {"MESH", "CURVE"} and obj.select_get():
        # Rotate the vertex data, not the object transform. This cancels the
        # exporter's Blender-Z-up to glTF-Y-up mesh conversion without tipping
        # the entire object node (which left the locomotive standing vertically).
        obj.data.transform(axis_fix)
bpy.ops.export_scene.gltf(filepath=os.path.join(MODEL_DIR, "lost_things_locomotive.glb"), export_format="GLB", use_selection=True, export_apply=True)
print("LOCOMOTIVE_ASSET_GENERATED: blend, GLB and preview")
