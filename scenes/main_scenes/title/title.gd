extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/HBoxContainer/VBoxContainer/PlayButton.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_scenes/level_select/level_select.tscn")
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass