import bpy,os,json
from mathutils import Vector
base=r'C:\Users\User MSI\Downloads\GameDev\Game6'
meta={}
for f in os.listdir(os.path.join(base,'Movement')):
 if not f.endswith('.fbx'):continue
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.fbx(filepath=os.path.join(base,'Movement',f))
 arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 action=arm.animation_data.action
 if f[:-4]=='Running':
  for l in action.layers:
   for st in l.strips:
    for bag in st.channelbags:
     for fc in bag.fcurves:
      first=fc.evaluate(1)
      for index in range(len(fc.keyframe_points)-1,-1,-1):
       if fc.keyframe_points[index].co.x>18:fc.keyframe_points.remove(fc.keyframe_points[index],fast=True)
      fc.keyframe_points.insert(24,first)
      fc.update()
 # Local hip Z is forward; keep vertical Y motion for jumping and footwork.
 for l in action.layers:
  for st in l.strips:
   for bag in st.channelbags:
    for fc in bag.fcurves:
     if fc.data_path=='pose.bones["mixamorig:Hips"].location' and fc.array_index in (0,2):
      for k in fc.keyframe_points:k.co.y=0;k.handle_left.y=0;k.handle_right.y=0
 mins=[]
 for frame in range(int(action.frame_range[0]),int(action.frame_range[1])+1):
  bpy.context.scene.frame_set(frame); dg=bpy.context.evaluated_depsgraph_get()
  low=1e9
  for o in bpy.context.scene.objects:
   if o.type!='MESH':continue
   eo=o.evaluated_get(dg); mesh=eo.to_mesh()
   low=min(low,min((eo.matrix_world@v.co).z for v in mesh.vertices)); eo.to_mesh_clear()
  mins.append(low)
 if f[:-4] != 'Jumping':
  hip=arm.pose.bones['mixamorig:Hips']
  direction=arm.matrix_world.to_3x3() @ hip.bone.matrix_local.to_3x3().col[1]
  for l in action.layers:
   for st in l.strips:
    for bag in st.channelbags:
     for fc in bag.fcurves:
      if fc.data_path=='pose.bones["mixamorig:Hips"].location' and fc.array_index==1:
       for k in fc.keyframe_points:
        index=int(round(k.co.x))-int(action.frame_range[0])
        correction=(mins[index]-min(mins))/direction.z
        k.co.y-=correction;k.handle_left.y-=correction;k.handle_right.y-=correction
 action.update_tag()
 bpy.context.scene.frame_set(0)
 bpy.context.view_layer.update()
 corrected=[]
 for frame in range(int(action.frame_range[0]),int(action.frame_range[1])+1):
  bpy.context.scene.frame_set(frame);dg=bpy.context.evaluated_depsgraph_get();low=1e9
  for o in bpy.context.scene.objects:
   if o.type!='MESH':continue
   eo=o.evaluated_get(dg);mesh=eo.to_mesh()
   low=min(low,min((eo.matrix_world@v.co).z for v in mesh.vertices));eo.to_mesh_clear()
  corrected.append(low)
 print('FOOT_AUDIT',f,min(corrected),max(corrected),'offset',-min(mins)*.52)
 # A constant floor correction preserves jumps; never pins an airborne foot.
 meta[f[:-4]]={'floor_offset':-min(corrected)*.52,'min_foot':min(mins),'max_foot':max(mins),'frames':len(mins),'bones':len(arm.data.bones)}
 bpy.context.scene.frame_set(1)
 bpy.ops.export_scene.gltf(filepath=os.path.join(base,'Lab6Build','characters',f[:-4]+'.glb'),export_format='GLB',export_animation_mode='ACTIONS')
with open(os.path.join(base,'Lab6Build','characters','metadata.json'),'w') as out:json.dump(meta,out,indent=2)






