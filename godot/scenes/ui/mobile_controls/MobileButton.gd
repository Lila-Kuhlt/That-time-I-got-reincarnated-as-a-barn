tool
extends "MobileControl.gd"

#############################################################
# CUSTOMIZATION
export var action = "game_jump"

#############################################################
# HANDLERS

func _on_touch():
	Input.call_deferred("action_press", action)
	$Pressed.visible = true
	$Normal.visible = false

func _on_untouch():
	Input.call_deferred("action_release", action)
	$Normal.visible = true
	$Pressed.visible = false
