extends Node2D

onready var progress_bar: ProgressBar = $ProgressBarLayer/CenterContainer/ProgressBar

func _ready():
	progress_bar.hide()
	
func _on_screen_loader_progress(progress: float) -> void:
	progress_bar.show()
	progress_bar.value = progress * 100
