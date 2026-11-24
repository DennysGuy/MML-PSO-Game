class_name PlayerRun extends State

@export var idle_state : State

var deceleration : float = 10.0

func enter() -> void:
	parent.play_animation(&"Run")

func exit() -> void:
	pass

func process_input(_event: InputEvent) -> State:
	return null

func process_frame(_delta: float) -> State:
	return null


func process_physics(_delta: float) -> State:
	var raw_input := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backwards"
	)

	# Camera-relative movement
	var forward = parent.camera.global_basis.z
	var right = parent.camera.global_basis.x

	var move_direction = forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	# Direct horizontal velocity control
	parent.velocity.x = move_direction.x * parent.move_speed * _delta
	parent.velocity.z = move_direction.z * parent.move_speed * _delta

	parent.move_and_slide()

	# Remember last movement direction
	if raw_input != Vector2.ZERO:
		parent.last_movement_direction = move_direction

	# Smoothly rotate character toward movement direction
	var target_angle := Vector3.BACK.signed_angle_to(
		parent.last_movement_direction,
		Vector3.UP
	)

	parent.model.global_rotation.y = lerp_angle(
		parent.model.rotation.y,
		target_angle,
		parent.rotation_speed * _delta
	)

	# Transition to idle
	if raw_input == Vector2.ZERO:
		return idle_state

	return null
