extends CharacterBody2D

var socket : WebSocketPeer
const SPEED = 300.0
var player_ID
var player_DATA
var is_local_player: bool = true
var target_pos: Vector2
@export var send_rate := 15.0
var _accum := 0.0

func set_target(pos: Vector2) -> void:
	target_pos = pos   # NEVER set position directly

func _process(delta: float) -> void:
	if is_local_player: return
	position = position.lerp(target_pos, clampf(delta * 12.0, 0.0, 1.0))

func set_socket(_socket):
	socket = _socket

func set_player_id_and_data(_player_id,_player_data,_is_local_player):
	player_ID = _player_id
	player_DATA = _player_data
	is_local_player = _is_local_player

func _physics_process(delta: float) -> void:
	if not is_local_player: return
	
	var dx := Input.get_axis("ui_left", "ui_right")
	var dy := Input.get_axis("ui_up", "ui_down")
	velocity = Vector2(dx, dy).normalized() * SPEED if (dx or dy) else velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()   # move FIRST
	
	_accum += delta
	if _accum >= 1.0 / send_rate:
		_accum = 0.0
		socket.send_text(JSON.stringify({
			"action": "move",
			"x": position.x,
			"y": position.y
		}))
