class_name PlayerIdle extends State

@export var run_state : State

func enter() -> void:
	parent.play_animation(&"Idle")
	parent.velocity.z = 0
	parent.velocity.x = 0
func exit() -> void:
	pass

func process_input(_event: InputEvent) -> State:
	return null

func process_frame(_delta: float) -> State:
	return null

func process_physics(_delta: float) -> State:
	var raw_input := Input.get_vector("move_left","move_right","move_forward","move_backwards")
	print(raw_input)
	if raw_input != Vector2.ZERO:
		return run_state
	
	parent.move_and_slide()
	
	return null
