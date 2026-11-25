class_name PlayerDash extends State

var dash_duration : float = 3.0
var dash_timer : float = 3.0
var dash_direction : Vector3

@export var idle_state : State

func enter() -> void:
	dash_timer = 3.0
	dash_direction = parent.model.transform.basis.z
	dash_timer = dash_duration
	parent.play_animation(&"Dash")

func exit() -> void:
	pass

func process_input(_event: InputEvent) -> State:
	return null

func process_frame(_delta: float) -> State:
	return null

func process_physics(_delta: float) -> State:
	dash_timer -= 10*_delta
	
	if dash_timer > 0:
		parent.velocity.x = dash_direction.x * parent.dash_speed 
		parent.velocity.z = dash_direction.z * parent.dash_speed
	else:
		return idle_state
	
	parent.move_and_slide()
	
	return null
