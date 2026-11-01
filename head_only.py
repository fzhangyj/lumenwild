import bpy
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=r'<PROJECT_PATH>')
for o in bpy.context.scene.objects:
 if not (o.name.startswith('Head') or o.name.startswith('Eye') or o.name.startswith('Eyelash') or o.name=='Mouth'): o.hide_render=True
scene=bpy.context.scene; scene.render.engine='BLENDER_EEVEE_NEXT'; scene.render.resolution_x=700; scene.render.resolution_y=900; scene.render.resolution_percentage=100; scene.render.filepath=r'<PROJECT_PATH>'
cam=bpy.data.cameras.new('Cam'); co=bpy.data.objects.new('Cam',cam); bpy.context.collection.objects.link(co); scene.camera=co; co.location=(0,2.3,-5); co.rotation_euler=(Vector((0,2.3,0))-co.location).to_track_quat('-Z','Y').to_euler()
ld=bpy.data.lights.new('L','AREA'); lo=bpy.data.objects.new('L',ld); bpy.context.collection.objects.link(lo); lo.location=(2,4,-3); ld.energy=900; lo.rotation_euler=(Vector((0,2.3,0))-lo.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.render.render(write_still=True)
