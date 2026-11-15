class_name Player extends CharacterBody3D

@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity : float = 0.25
@export_range(1.0,2.0) var joy_stick_sensivity : float = 1.5
@export_group("Stats")
@export var move_speed : float = 8.0
@export var acceleration : float = 20.0
@export var rotation_speed : float = 12.0
@export var jump_impulse : float = 12.0
@onready var camera_pivot : Node3D = %CameraPivot
@onready var camera : Camera3D = %Camera3D
@onready var model: Node3D = $Model

var camera_input_direction : Vector2 = Vector2.ZERO
var last_movement_direction : Vector3 = Vector3.BACK
var gravity : float = -30.0
@export_group("Animation")
@export var animation_player : AnimationPlayer

var locked_on_enemy : TestEnemy = null

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

	if is_camera_motion and !locked_on_enemy:
		camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("lock_on"):
		if !locked_on_enemy:
			choose_lock_on_target()
		else:
			locked_on_enemy = null
			print("This is Enemy Locked on %s" % locked_on_enemy)

	if locked_on_enemy:
		
		if Input.is_action_just_pressed("lock_on_left") and Input.is_action_just_pressed("lock_on_right"):
			print("Can't press both")
		
		if Input.is_action_just_pressed("lock_on_left"):
			switch_lock_on_target(-1)
		
		if Input.is_action_just_pressed("lock_on_right"):
			switch_lock_on_target(1)
		

	camera_pivot.rotation.x += camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/6.0, PI/3.0)
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	
	camera_input_direction = Vector2.ZERO
	
	if locked_on_enemy:
		set_lock_on_camera(delta)

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
	
	#var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
	#if is_starting_jump:
		#velocity.y += jump_impulse
	
	move_and_slide()
	
	if move_direction.length() > 0.2:
		last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(last_movement_direction, Vector3.UP)
	model.global_rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)
	
	var ground_speed := velocity.length()
	
	if is_on_floor():
		if ground_speed > 0.0:
			animation_player.play("Run")
		else:
			animation_player.play("Idle")
	else:
		if velocity.y > 0:
			animation_player.play("Jump")
		else:
			animation_player.play("Fall")
			
	var raw_camera_input := Input.get_vector("rotate_camera_left","rotate_camera_right","rotate_camera_up","rotate_camera_down")
	
	camera_input_direction = raw_camera_input * joy_stick_sensivity
	
func set_lock_on_camera(delta: float) -> void:
	if !is_instance_valid(locked_on_enemy):
		locked_on_enemy = null
		return

	var player_location = global_position
	var enemy_location = locked_on_enemy.global_position

	# Direction from player to enemy
	var direction = enemy_location - player_location

	# Calculate horizontal angle
	var target_angle = atan2(direction.x, direction.z)

	# Smoothly rotate camera pivot horizontally
	camera_pivot.rotation.y = lerp_angle(
	camera_pivot.rotation.y,
	target_angle,
	5.0 * delta
	)

func choose_lock_on_target() -> void:
	
	if get_tree().get_nodes_in_group("Enemies").is_empty():
		return
	
	var closest_target : TestEnemy = null
	for child in get_tree().get_nodes_in_group("Enemies"):
		if camera.is_position_behind(child.global_position):
			continue	
		if !closest_target:
			closest_target = child
		else:
			var next_target := child as TestEnemy
			if next_target.global_position.distance_to(global_position) < closest_target.global_position.distance_to(global_position):
				closest_target = next_target
				
	locked_on_enemy = closest_target

func switch_lock_on_target(direction : int) -> void:
	if !is_instance_valid(locked_on_enemy):
		return
	
	var current_screen_position = camera.unproject_position(locked_on_enemy.global_position)
	
	var best_enemy : TestEnemy = null
	var best_score = INF
	
	var enemies = get_tree().get_nodes_in_group("Enemies")
	
	for enemy in enemies:
		if enemy == locked_on_enemy:
			continue
		
		if !is_instance_valid(enemy):
			continue
		
		if camera.is_position_behind(enemy.global_position):
			continue
		
		var screen_pos = camera.unproject_position(enemy.global_position)
		var horizontal_difference = screen_pos.x - current_screen_position.x
		
		if direction == -1 and horizontal_difference >= 0:
			continue
		
		if direction == 1 and horizontal_difference <= 0:
			continue
		
		var vertical_difference = abs(screen_pos.y - current_screen_position.y)
		var score = abs(horizontal_difference) + vertical_difference * 1.5
		
		if score < best_score:
			best_score = score
			best_enemy = enemy
	
	if best_enemy:
		locked_on_enemy = best_enemy
		print("Switched target to: ", locked_on_enemy)
