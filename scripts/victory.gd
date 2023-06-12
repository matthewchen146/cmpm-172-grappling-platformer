extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	%MenuButton.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_scenes/title/title.tscn")
	)
