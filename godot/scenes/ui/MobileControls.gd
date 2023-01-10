extends Control

func _ready():
	if not OS.get_name() in ["Android", "BlackBerry 10", "iOS"]:
		queue_free()
