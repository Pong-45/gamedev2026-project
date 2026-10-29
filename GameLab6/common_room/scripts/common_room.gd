extends Node3D

const ASSETS := "res://common_room/dungeon/"
const PLAYER = preload("res://common_room/scripts/player.gd")
var actors: Array[Node3D] = []
var players: Array[AnimationPlayer] = []
var player: CharacterBody3D
var zone_label: Label
var zones := [[Vector3(-6,0,-5), "01  /  RECEPTION"], [Vector3(-6,0,3), "02  /  LOUNGE"], [Vector3(5.5,0,-5), "03  /  TRAINING"], [Vector3(5.5,0,2), "04  /  WARM-UP"], [Vector3(4,0,7), "05  /  ENTRANCE"]]

func _ready() -> void:
	if get_child_count() == 0:
		build_room()
	else:
		player = get_node('Player')
		zone_label = get_node('CanvasLayer/ZoneLabel')
		for holder in get_tree().get_nodes_in_group('room_actor'):
			actors.append(holder)
			var ap: AnimationPlayer = holder.find_child('AnimationPlayer', true, false)
			players.append(ap)
			for key in ap.get_animation_list():
				if key != 'RESET':
					ap.play(key)
					break
	if "--verify-room" in OS.get_cmdline_user_args():
		verify_room()

func collider(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	return body

func prop(file: String, at: Vector3, yaw := 0.0, size := Vector3.ONE, solid := true) -> Node3D:
	var model: Node3D = load(ASSETS + file + ".glb").instantiate()
	add_child(model)
	model.name = file.replace(" ", "_")
	model.position = at
	model.rotation.y = deg_to_rad(yaw)
	model.scale = size
	if solid:
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			mesh.create_trimesh_collision()
	return model

func text3d(words: String, at: Vector3, size := 48) -> void:
	var label := Label3D.new()
	label.text = words
	label.font_size = size
	label.pixel_size = 0.007
	label.modulate = Color("f4d6a0")
	label.outline_modulate = Color("241c1b")
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func lamp(at: Vector3, energy := 2.0, radius := 8.0) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color("ffce8c")
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = true
	add_child(light)

func actor(animation: String, at: Vector3, yaw: float, title: String) -> void:
	var holder := Node3D.new()
	holder.add_to_group('room_actor', true)
	holder.name = title.replace(" ", "_")
	add_child(holder)
	holder.position = at
	holder.rotation.y = deg_to_rad(yaw)
	var model: Node3D = load("res://common_room/characters/" + animation + ".glb").instantiate()
	holder.add_child(model)
	model.scale = Vector3.ONE * 0.52
	var metadata = JSON.parse_string(FileAccess.get_file_as_string("res://common_room/characters/metadata.json"))
	model.position.y = metadata[animation]["floor_offset"] + 0.015
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	assert(ap != null, "AnimationPlayer missing: " + animation)
	for key in ap.get_animation_list():
		if key == "RESET": continue
		var clip := ap.get_animation(key)
		clip.loop_mode = Animation.LOOP_LINEAR
		ap.play(key)
		ap.seek(0.0, true)
		break
	actors.append(holder)
	players.append(ap)
	# Protect the character's activity area while leaving wide circulation lanes.
	collider(holder, Vector3(0,0.9,0), Vector3(1.35,1.8,1.35))
	text3d(title + "\n" + animation, at + Vector3(0,3.05,0), 32)

func build_room() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("292b36")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("aabbd1")
	env.environment.ambient_light_energy = 0.55
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-65,-25,0)
	sun.light_color = Color("ffe8c5")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)
	var ceiling := MeshInstance3D.new()
	ceiling.name = "StoneCeiling"
	var slab := BoxMesh.new()
	slab.size = Vector3(20,0.25,20)
	ceiling.mesh = slab
	ceiling.position = Vector3(0,6.15,0)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("38323a")
	stone.roughness = 1.0
	ceiling.material_override = stone
	add_child(ceiling)
	# 20 x 20 m hall; tile tops exactly at y=0.
	for x in range(-9,10,2):
		for z in range(-9,10,2):
			prop("Floor Tile", Vector3(x,-0.125,z), 0, Vector3.ONE, false)
	collider(self, Vector3(0,-0.25,0), Vector3(20,0.5,20))
	for x in range(-9,10,2):
		for y in [1.0,3.0,5.0]:
			prop("Wall Modular", Vector3(x,y,-10), 0, Vector3.ONE, false)
			if abs(x)>2:
				prop("Wall Modular", Vector3(x,y,10), 0, Vector3.ONE, false)
	for z in range(-9,10,2):
		for y in [1.0,3.0,5.0]:
			prop("Wall Modular", Vector3(-10,y,z),90,Vector3.ONE,false)
			prop("Wall Modular", Vector3(10,y,z),90,Vector3.ONE,false)
	collider(self,Vector3(0,3,-10),Vector3(20,6,0.5))
	collider(self,Vector3(-10,3,0),Vector3(0.5,6,20))
	collider(self,Vector3(10,3,0),Vector3(0.5,6,20))
	for x in [-6.5,6.5]: collider(self,Vector3(x,3,10),Vector3(7,6,.5))
	prop("Arch",Vector3(0,0,10),0,Vector3(1.5,1.45,1),false)
	# Walkable entrance vestibule, closed at its far end.
	for x in [-1,1]:
		for z in [11,13]: prop("Floor Tile",Vector3(x,-.125,z),0,Vector3.ONE,false)
	collider(self,Vector3(0,-.25,12),Vector3(4,.5,4))
	for x in [-2.1,2.1]:
		collider(self,Vector3(x,2,12),Vector3(.3,4,4))
		for z in [11,13]: prop("Wall Modular",Vector3(x,2,z),90,Vector3(1,2,1),false)
	prop("Arch Door",Vector3(0,0,14),0,Vector3(1.55,1.4,1),true)
	collider(self,Vector3(0,2,14),Vector3(4,4,.4))
	for x in [-8.7,8.7]:
		for z in [-8.7,0,8.7]: prop("Column",Vector3(x,0,z),0,Vector3(1,1.45,1))
	# Reception and communal dining / rest area.
	prop("Table Big",Vector3(-6,0,-7),90,Vector3(1.2,1.2,1.2))
	prop("Coin Bag",Vector3(-6,1.03,-7),0,Vector3(2,2,2),false)
	prop("Chest with Gold",Vector3(-8.3,0,-7),0)
	prop("Banner",Vector3(-8.5,0,-4),0)
	prop("Table Big",Vector3(-6,0,.5),0)
	for p in [Vector3(-7.4,0,.1),Vector3(-7.4,0,1.3),Vector3(-4.6,0,.1),Vector3(-4.6,0,1.3)]:
		prop("Chair",p,90 if p.x < -6 else -90)
	prop("Small Table",Vector3(-7.5,0,5.5),0)
	prop("Bucket",Vector3(-7.4,.86,5.5),0,Vector3.ONE,false)
	prop("Chair",Vector3(-6,0,5.5),-90)
	for p in [Vector3(-8.5,0,7.5),Vector3(-7.3,0,7.8),Vector3(8,0,7.8)]: prop("Barrel",p)
	for p in [Vector3(8,0,-8),Vector3(6.4,0,-8),Vector3(8,0,5.8)]: prop("Crate",p)
	prop("Sword Wall Mount",Vector3(5,2,-9.65),0,Vector3(2,2,2),false)
	prop("Banner Wall",Vector3(-3.6,5.4,-9.65),0,Vector3.ONE,false)
	prop("Banner Wall",Vector3(3.6,5.4,-9.65),0,Vector3.ONE,false)
	prop("Pedestal",Vector3(0,0,-8.3),0,Vector3(.7,.55,.7))
	prop("Skull",Vector3(0,1.30,-8.3),180,Vector3(1.7,1.7,1.7),false)
	for x in [-8.8,8.8]:
		for z in [-6,4]:
			prop("Torch",Vector3(x,2.8,z),90 if x<0 else -90,Vector3.ONE,false)
			lamp(Vector3(x*.88,3.6,z),2.2,8)
	for z in [-6,2,9]: lamp(Vector3(0,4.8,z),1.6,10)
	text3d("THE EMBER HALL\nAdventurers' common room",Vector3(0,4.5,-9.5),56)
	actor("Walk",Vector3(-5.8,0,-4.6),0,"01  RECEPTION")
	actor("Silly Dancing",Vector3(-5.8,0,3.3),20,"02  LOUNGE")
	actor("Hurricane Kick",Vector3(5.4,0,-4.6),-35,"03  TRAINING")
	actor("Jumping",Vector3(5.4,0,1.5),-45,"04  WARM-UP")
	actor("Running",Vector3(4,0,7),-70,"05  ENTRANCE")
	player = CharacterBody3D.new()
	player.name="Player"
	player.set_script(PLAYER)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=.32
	capsule.height=1.8
	collision.shape=capsule
	collision.position.y=.9
	player.add_child(collision)
	var camera := Camera3D.new()
	camera.name="Camera3D"
	camera.position.y=1.65
	camera.fov=78
	camera.current=true
	player.add_child(camera)
	player.position=Vector3(0,.1,8)
	add_child(player)
	build_hud()

func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = 'CanvasLayer'
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position=Vector2(24,24)
	var style := StyleBoxFlat.new()
	style.bg_color=Color(0.055,.065,.085,.9)
	style.border_color=Color("b78b50")
	style.border_width_left=3
	style.content_margin_left=18
	style.content_margin_right=22
	style.content_margin_top=12
	style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text="THE EMBER HALL  /  LAB 6"
	title.add_theme_font_size_override("font_size",23)
	title.modulate=Color("f2ce94")
	box.add_child(title)
	var controls := Label.new()
	controls.text="WASD  Move    |    Mouse  Look\nEsc  Release mouse    |    Click  Resume"
	controls.add_theme_font_size_override("font_size",16)
	box.add_child(controls)
	zone_label=Label.new()
	zone_label.name='ZoneLabel'
	zone_label.position=Vector2(24,135)
	zone_label.add_theme_font_size_override("font_size",18)
	zone_label.modulate=Color("f2ce94")
	layer.add_child(zone_label)
	var crosshair := Label.new()
	crosshair.text="·"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.add_theme_font_size_override("font_size",30)
	layer.add_child(crosshair)

func _process(_delta: float) -> void:
	if zone_label == null: return
	var nearest := "COMMON ROOM  /  Explore 5 activity areas"
	for zone in zones:
		if player.position.distance_to(zone[0])<3.7: nearest=zone[1]
	zone_label.text=nearest

func verify_room() -> void:
	await get_tree().physics_frame
	player.test_mode=true
	await get_tree().create_timer(.8).timeout
	assert(player.is_on_floor(), "Player must stand on floor")
	for i in players.size():
		var ap := players[i]
		assert(ap.is_playing(), "NPC animation stopped")
		var skeleton: Skeleton3D = actors[i].find_children("*","Skeleton3D",true,false)[0]
		assert(skeleton.get_bone_count()==33, "Unexpected skeleton")
		var bone := skeleton.find_bone("mixamorig_LeftLeg")
		if bone<0: bone=7
		var before := skeleton.get_bone_global_pose(bone)
		await get_tree().create_timer(.25).timeout
		var after := skeleton.get_bone_global_pose(bone)
		assert(not before.is_equal_approx(after), "Skeleton is not animating")
		print("PASS NPC ",i+1," bones=",skeleton.get_bone_count()," clip=",ap.current_animation)
	if "--visual-tour" in OS.get_cmdline_user_args():
		for i in actors.size():
			player.position = actors[i].position + Vector3(0,0,-3.2) if i == 4 else actors[i].position + Vector3(0,0,3.2)
			player.eyes.look_at(actors[i].position + Vector3(0,1.3,0), Vector3.UP)
			await get_tree().create_timer(.3).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("C:/Users/User MSI/Downloads/GameDev/Game6/room_npc_" + str(i+1) + ".png")
		player.position=Vector3(0,.1,8)
		player.rotation=Vector3.ZERO
		player.eyes.rotation=Vector3.ZERO
		await get_tree().create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("C:/Users/User MSI/Downloads/GameDev/Game6/room_overview.png")
		if '--capture-only' in OS.get_cmdline_user_args():
			get_tree().quit()
			return
	# Walk to every activity point using actual CharacterBody movement.
	for target in [Vector3(0,0,-4),Vector3(-3.7,0,-4.6),Vector3(-3.7,0,3.3),Vector3(0,0,3.3),Vector3(3.3,0,1.5),Vector3(3.3,0,-4.6),Vector3(0,0,-4),Vector3(0,0,7),Vector3(2,0,7),Vector3(0,0,12)]:
		var ticks:=0
		while Vector2(player.position.x-target.x,player.position.z-target.z).length()>.15 and ticks<600:
			player.test_direction=(target-player.position)*Vector3(1,0,1)
			player.test_direction=player.test_direction.normalized()
			await get_tree().physics_frame
			ticks+=1
		assert(ticks<600,"Route blocked: "+str(target))
		print("PASS route ",target)
	player.position=Vector3(0,.1,-8)
	player.test_direction=Vector3(0,0,-1)
	await get_tree().create_timer(1).timeout
	assert(player.position.z > -9.6,"Wall collision failed")
	print("PASS wall collision ",player.position)
	player.position=Vector3(-3.8,.1,.5)
	player.test_direction=Vector3(-1,0,0)
	await get_tree().create_timer(1).timeout
	assert(player.position.x > -5.1,"Table collision failed")
	print("PASS furniture collision ",player.position)
	player.test_direction=Vector3.ZERO
	player.rotation=Vector3.ZERO
	player.eyes.rotation=Vector3.ZERO
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var motion:=InputEventMouseMotion.new()
	motion.relative=Vector2(120,-60)
	player._unhandled_input(motion)
	assert(abs(player.rotation.y)>.1 and abs(player.eyes.rotation.x)>.05,"Mouse look failed")
	var escape:=InputEventKey.new()
	escape.keycode=KEY_ESCAPE
	escape.pressed=true
	player._unhandled_input(escape)
	assert(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Esc failed")
	print("PASS camera and Escape; ALL ROOM CHECKS PASSED")
	get_tree().quit()







