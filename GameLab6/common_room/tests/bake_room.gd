extends SceneTree

func _initialize() -> void:
	call_deferred("bake")

func own_children(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.scene_file_path = ''
		child.owner=scene_root
		own_children(child,scene_root)

func bake() -> void:
	var scene: Node3D=load("res://common_room/scenes/common_room_source.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	own_children(scene,scene)
	var packed:=PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://common_room/scenes/common_room.tscn")==OK)
	print("BAKED editable room with ",scene.get_child_count()," root nodes")
	quit()

