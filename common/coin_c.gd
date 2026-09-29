extends StaticBody2D

var id
var socket : WebSocketPeer
signal coin_collect

func _ready() -> void:
	coin_collect.connect(collect_coin)

func _process(delta: float) -> void:
	if not socket:
		socket = get_tree().get_nodes_in_group('peer')[0].socket;

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('player') and body.is_local_player:
		coin_collect.emit()

func collect_coin() -> void:
	socket.send_text(JSON.stringify({
			"action": "collect_coin",
			"id": id
		}))
