class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var previous_state: State
var initialized := false


# -------------------------------------------------
# INITIALIZATION
# -------------------------------------------------
func init(parent) -> void:
	# Bind parent to all child states
	for child in get_children():
		child.parent = parent

	# Delay state entry until the node is fully ready (export-safe)
	call_deferred("_enter_initial_state")


func _enter_initial_state() -> void:
	assert(initial_state != null, "StateMachine: initial_state is null")
	current_state = initial_state
	current_state.enter()
	initialized = true


# -------------------------------------------------
# STATE TRANSITIONS
# -------------------------------------------------
func change_state(new_state: State) -> void:
	assert(new_state != null, "StateMachine: change_state called with null")
	#assert(initialized, "StateMachine: change_state called before initialization")

	if current_state:
		current_state.exit()

	previous_state = current_state
	current_state = new_state
	current_state.enter()


func return_to_previous_state() -> void:
	if previous_state != null:
		change_state(previous_state)


# -------------------------------------------------
# PROCESSING
# -------------------------------------------------
func process_physics(delta: float) -> void:
	if !initialized:
		return

	assert(current_state != null, "StateMachine: current_state null in process_physics")

	var next_state := current_state.process_physics(delta)

	# Gravity handling (unchanged logic, just clarified)
	var parent := get_parent()
	#if parent is CharacterBody2D:
		#if parent.is_on_floor() or !parent.apply_gravity:
			#parent.velocity.y = 0
		#else:
		#
			#parent.velocity.y += parent.gravity * delta

	if next_state != null:
		change_state(next_state)


func process_input(event: InputEvent) -> void:
	if !initialized:
		return

	assert(current_state != null, "StateMachine: current_state null in process_input")

	var next_state := current_state.process_input(event)
	if next_state != null:
		change_state(next_state)


func process_frame(delta: float) -> void:
	if !initialized:
		return

	assert(current_state != null, "StateMachine: current_state null in process_frame")

	var next_state := current_state.process_frame(delta)
	if next_state != null:
		change_state(next_state)
