extends Control

func _ready():
	%returnButton.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_scenes/title/title.tscn")
)


func _process(delta):
	pass


