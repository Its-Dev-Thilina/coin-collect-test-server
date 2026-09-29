extends StaticBody2D

var id
var is_collected := false      # local guard against double-fire

func _get_socket() -> WebSocketPeer:
	var peers = get_tree().get_nodes_in_group('peer')
	return peers[0].socket if not peers.is_empty() else null

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group('player') and body.get("is_local_player") == true:
		collect_coin()

func collect_coin() -> void:
	var socket = _get_socket()
	if socket == null:
		return          # network not ready yet — coin stays, try again next touch
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return          # not connected yet — don't send

	is_collected = true     # local hide so we don't spam the server
	visible = false
	$Area2D/CollisionShape2D.set_deferred("disabled", true)

	socket.send_text(JSON.stringify({
		"action": "collect_coin",
		"id": id
	}))
	# actual queue_free happens when server confirms "coin_success"
