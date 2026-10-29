extends CharacterBody3D

const SPEED := 4.2
const SENSITIVITY := 0.0025
var test_direction := Vector3.ZERO
var test_mode := false
@onready var eyes: Camera3D = $Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		eyes.rotation.x = clampf(eyes.rotation.x - event.relative.y * SENSITIVITY, -1.35, 1.35)

func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	if test_mode:
		direction = test_direction
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var axis := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		direction = (basis * Vector3(axis.x, 0, axis.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
	if position.y < -6:
		position = Vector3(0, 0.1, 7)
