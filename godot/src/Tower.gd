extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const Projectile = preload("res://scenes/Projectile.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):


func _on_Area2D_body_entered(body: Node2D):
	var projectile := Projectile.instance()
	var target_pos := body.global_position
	add_child(projectile)
	projectile.shoot_target(target_pos)
	

func _on_Area2D_body_exited(body: Node2D):
	remove_child(body)
