class_name TestArea extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !GameManager.player_ids.is_empty():
		
		if !multiplayer.is_server():
			return
		
		for id in GameManager.player_ids:
			create_player(id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func create_player(id:int) -> void:
	var player : Player = preload("uid://8jr05jbtgoba").instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	%Players.add_child(player)
