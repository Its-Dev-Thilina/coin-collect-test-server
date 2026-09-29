extends CharacterBody2D

var socket : WebSocketPeer
const SPEED = 300.0
var player_ID
var player_DATA
var is_local_player: bool = true
var send_rate := 60.0
var _accum := 0.0

func set_socket(_socket):
	socket = _socket

func set_player_id_and_data(_player_id,_player_data,_is_local_player):
	player_ID = _player_id
	player_DATA = _player_data
	is_local_player = _is_local_player

func _physics_process(delta: float) -> void:
	if not is_local_player : return
	
	var direction_x := Input.get_axis("ui_left", "ui_right")
	var direction_y := Input.get_axis("ui_up", "ui_down")
	
	if direction_x || direction_y:
		velocity.x = direction_x * SPEED
		velocity.y = direction_y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	_accum += delta
	if _accum >= 1.0 / send_rate:
		_accum = 0.0
		socket.send_text(JSON.stringify({
			"action" : "move",
			"x" : position.x,
			"y" : position.y,
		}))
	
	move_and_slide()
