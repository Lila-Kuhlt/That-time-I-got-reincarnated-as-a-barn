extends Particles2D

signal fertility_ray_change_tile
signal fertility_ray_next
signal fertility_ray_done

func _ready():
	$AnimationPlayer.play("start")
	
func _on_ParticlesFertilityRay_fertility_ray_done():
	queue_free()
