import bpy
bpy.ops.wm.open_mainfile(filepath=r'<PROJECT_PATH>')
for o in bpy.context.scene.objects:
 if o.name in ['Head','HairCap','UpperBody','Skirt'] or o.name.startswith('LongHair'):
  print(o.name,tuple(round(x,2) for x in o.location),tuple(round(x,2) for x in o.dimensions),[m.name for m in o.data.materials] if hasattr(o.data,'materials') else '')
