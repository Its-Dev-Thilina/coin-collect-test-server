extends Node2D

@export var webhook_url : String
var socket : WebSocketPeer
@export var spawn_point: Node2D
@export var player_scene: PackedScene
var players = {}
var player_objects = {}
var player_count = 0
var local_player_id = ""
var is_local_player: bool = true
@onready var coins: Node = $coins

func _ready() -> void:
	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(webhook_url)
	
	if err == OK:
		print('connecting to the server ...')
		await get_tree().create_timer(2).timeout
		
		print("Sending Packet ...")
		socket.send_text(JSON.stringify({
			"action" : "login"
		}))
	else:
		set_process(false)

func _process(delta: float) -> void:
	socket.poll()
	
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	
	while socket.get_available_packet_count():
		var packet = socket.get_packet().get_string_from_utf8()
		var json = JSON.new()
		if json.parse(packet) != OK or not json.data is Dictionary:
			continue
		var data: Dictionary = json.data
		
		match data.get("action", ""):
			"login":
				local_player_id = data["uuid"]
				for p in data["players"]:          # p IS the player object now
					_spawn_player(p["id"], p, p["id"] == local_player_id)
				for coin_id in data.get("coins", []):
					coins.all[int(coin_id)].queue_free()
			"move":
				var pid = str(data["id"])
				if player_objects.has(pid) and not player_objects[pid].is_local_player:
					player_objects[pid].set_target(Vector2(data["x"], data["y"]))
			"player_joined":
				_spawn_player(data["id"], { "id": data["id"], "x": data["x"], "y": data["y"] }, false)
			"player_left":
				var pid = str(data["id"])
				if player_objects.has(pid):
					player_objects[pid].queue_free()
					player_objects.erase(pid)
			"coin_success":
				coins.all[int(data["id"])].queue_free()

func _spawn_player(pid, pdata, local: bool):
	var player = player_scene.instantiate()
	spawn_point.add_child(player)
	player.set_socket(socket)
	player.set_player_id_and_data(pid, pdata, local)
	player.position = Vector2(pdata["x"], pdata["y"])
	player_objects[str(pid)] = player
