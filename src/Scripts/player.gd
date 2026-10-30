class_name Player extends CharacterBody3D

@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity : float = 0.25
@export_range(1.0,2.0) var joy_stick_sensivity : float = 1.5
@export var move_speed : float = 8.0
@export var acceleration : float = 20.0
@export var rotation_speed : float = 12.0
@export var jump_impulse : float = 12.0
@onready var camera_pivot : Node3D = %CameraPivot
@onready var camera : Camera3D = %Camera3D
@onready var skin : SophiaSkin = %SophiaSkin

var camera_input_direction : Vector2 = Vector2.ZERO
var last_movement_direction : Vector3 = Vector3.BACK
var gravity : float = -30.0

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)

	if is_camera_motion:
		camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	camera_pivot.rotation.x += camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/6.0, PI/3.0)
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	camera_input_direction = Vector2.ZERO
	
	var raw_input := Input.get_vector("move_left","move_right","move_forward","move_backwards")
	var forward := camera.global_basis.z
	var right := camera.global_basis.x

	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + gravity * delta
	
	var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_starting_jump:
		velocity.y += jump_impulse
	
	
	move_and_slide()
	
	if move_direction.length() > 0.2:
		last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(last_movement_direction, Vector3.UP)
	skin.global_rotation.y = lerp_angle(skin.rotation.y, target_angle, rotation_speed * delta)
	
	var ground_speed := velocity.length()
	
	if is_on_floor():
		if ground_speed > 0.0:
			skin.move()
		else:
			skin.idle()
	else:
		if velocity.y > 0:
			skin.jump()
		else:
			skin.fall()
			
	var raw_camera_input := Input.get_vector("rotate_camera_left","rotate_camera_right","rotate_camera_up","rotate_camera_down")
	
	camera_input_direction = raw_camera_input * joy_stick_sensivity
	
	
