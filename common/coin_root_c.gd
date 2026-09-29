extends Node

var all = {}

func _ready() -> void:
	for i in get_child_count():
		get_child(i).id = i
		all[i] = get_child(i)
