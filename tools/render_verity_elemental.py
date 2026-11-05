"""Offline Blender render of the exported GLB approval assets, not a Studio capture."""
import bpy,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/verity-elemental'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(OUT/'Verity_Elemental_Gallery.glb'))
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=24
scene.render.resolution_x=1536;scene.render.resolution_y=1024;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
scene.world=bpy.data.worlds.new('SoftStudio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.72,.67,.85,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
scene.view_settings.view_transform='Standard'
scene.view_settings.look='Medium High Contrast' if 'Medium High Contrast' in [] else 'None'
def material(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.8
 return m
paper=material('LavenderPaper',(.89,.84,.98))
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,-1.6,2.2),rotation=(math.pi/2,0,0));bpy.context.object.data.materials.append(paper)
for name,loc,power,size in [('Key',(-3,5,7),600,5),('Fill',(4,4,3),280,4)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size
 o.rotation_euler=(Vector((0,0,2.3))-o.location).to_track_quat('-Z','Y').to_euler()
ink=material('CaptionInk',(.15,.025,.29))
labels=[('AQUA  /  10',-2.6,2.59),('FROST  /  25',0,2.59),('MAGMA  /  50',2.6,2.59),('CYBER  /  75',-2.6,-.21),('COSMIC  /  75 ALT',0,-.21),('RAINBOW  /  100',2.6,-.21)]
for text,x,z in labels:
 bpy.ops.object.text_add(location=(x,1,z),rotation=(math.pi/2,0,math.pi))
 o=bpy.context.object;o.data.body=text;o.data.align_x='CENTER';o.data.size=.16;o.data.extrude=0;o.data.materials.append(ink)
 # local text normal points toward camera (+Y), local X must remain screen-readable.
 o.rotation_euler=(math.pi/2,0,math.pi)
# Use camera +Y with camera local X oriented -X; flipping both text/world left is avoided by camera up tracking.
bpy.ops.object.camera_add(location=(0,14,2.2))
cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,2.2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=5.6;cam.data.lens=50
scene.camera=cam
scene.render.filepath=str(OUT/'preview-render.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Verity_Elemental_Approval.blend'))
bpy.ops.render.render(write_still=True)
print('Rendered actual GLB geometry/materials offline; no Studio Play.')
