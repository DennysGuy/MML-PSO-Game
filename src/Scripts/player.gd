class_name Player extends Entity

@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity : float = 0.25
@export_range(1.0,2.0) var joy_stick_sensivity : float = 1.5
@onready var camera_pivot : Node3D = %CameraPivot
@onready var camera : Camera3D = %Camera3D
var camera_input_direction : Vector2 = Vector2.ZERO
var last_movement_direction : Vector3 = Vector3.BACK

var locked_on_enemy : TestEnemy = null
var current_animation : String  = &""
@export_group("Player Stats")
@export var dash_speed : float = 120.0

func _ready() -> void:
	camera.current = is_multiplayer_authority()
	animation_player.speed_scale = 1.0
	state_machine.init(self)

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)

	if is_camera_motion and !locked_on_enemy:
		camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	
	if !is_multiplayer_authority():
		return
		
	state_machine.process_physics(delta)
	
	if Input.is_action_just_pressed("lock_on"):
		if !locked_on_enemy:
			choose_lock_on_target()
		else:
			locked_on_enemy = null
			print("This is Enemy Locked on %s" % locked_on_enemy)

	if locked_on_enemy:
		
		if Input.is_action_just_pressed("lock_on_left") and Input.is_action_just_pressed("lock_on_right"):
			print("Can't press both")
		
		elif Input.is_action_just_pressed("lock_on_left"):
			switch_lock_on_target(-1)
		
		elif Input.is_action_just_pressed("lock_on_right"):
			switch_lock_on_target(1)
		

	camera_pivot.rotation.x += camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/6.0, PI/3.0)
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	
	camera_input_direction = Vector2.ZERO
	
	if locked_on_enemy:
		set_lock_on_camera(delta)

	var ground_speed := velocity.length()
	var y_velocity = velocity.y
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y = y_velocity + gravity * delta
	
	sync_pos.rpc(global_position)
	#if velocity.y > 0:
		#play_animation(&"Jump")
	#else:
		#play_animation(&"Fall")
			
	var raw_camera_input := Input.get_vector("rotate_camera_left","rotate_camera_right","rotate_camera_up","rotate_camera_down")
	camera_input_direction = raw_camera_input * joy_stick_sensivity
	
@rpc
func sync_pos(pos:Vector3) -> void:
	global_position = pos

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


func play_animation(animation_name : String) -> void:
	if current_animation == animation_name:
		return
	
	current_animation = animation_name
	
	animation_player.play(animation_name)
	sync_animation.rpc(animation_name)
	
@rpc("authority", "call_remote", "reliable")
func sync_animation(animation_name: StringName):
	animation_player.play(animation_name)
