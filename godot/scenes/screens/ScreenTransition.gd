extends CanvasLayer

onready var background: Control = $TextureRect
onready var progress_bar: ProgressBar = $CenterContainer/ProgressBar

func _ready():
	visible = false

func transitionStart(show_background = false):
	progress_bar.value = 0
	background.visible = show_background
	visible = true
func transitionEnd():
	visible = false
func transitionProgress(progress: float) -> void:
	progress_bar.value = progress * 100
