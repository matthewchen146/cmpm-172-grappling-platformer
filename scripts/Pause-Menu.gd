extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	$CenterContainer/VBoxContainer/Resume.pressed.connect(func(): 
		get_tree().paused = false
		$CenterContainer.hide()
		)
	$"CenterContainer/VBoxContainer/Main Menu".pressed.connect(func(): 
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_scenes/title/title.tscn")
		)
	
	$CenterContainer.hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		on_pause_button_pressed()

func on_pause_button_pressed():
	get_tree().paused = true
	$CenterContainer.show()

func on_pause_leave():
	get_tree().paused = false
	$CenterContainer.hide()

func quit_to_main():
	get_tree().change_scene_to_file("res://scenes/main_scenes/title/title.tscn")
