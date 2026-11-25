class_name MultiplayerMenu extends Control

const IP_ADDRESS = "LocalHost"
const PORT = 7777
const MAX_CLIENTS = 4
signal server_disconnected
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connected_to_server.connect(on_connected)
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.connection_failed.connect(on_connected_fail)
	multiplayer.server_disconnected.connect(on_server_disconnected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_client() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func create_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer

func on_connected() -> void:
	print("Connect Successfully!")

func _on_create_server_button_up() -> void:
	create_server()

func _on_join_server_button_up() -> void:
	create_client()

func on_peer_connected(id : int) -> void:
	print("Player connected successfully %s" % str(id))
	GameManager.player_ids.append(id)
	
func on_peer_disconnected(id : int) -> void:
	print("Player disconnected %s" % str(id))

func remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func on_connected_fail() -> void:
	remove_multiplayer_peer()

func on_server_disconnected() -> void:
	remove_multiplayer_peer()
	server_disconnected.emit()

@rpc("any_peer")
func pong() -> void:
	print("Pong (Called by client on server)")

@rpc
func ping() -> void:
	print("Ping (Called by server on my client )")
	pong.rpc_id(1)

func _on_send_information_button_up() -> void:
	go_to_test_area.rpc()

@rpc("authority", "call_local", "reliable")
func go_to_test_area() -> void:
	get_tree().change_scene_to_file("uid://bqo3wua7y4bkr")
