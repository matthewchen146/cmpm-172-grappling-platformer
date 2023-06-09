extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	
	%backButton.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://scenes/main_scenes/title/title.tscn")
		)
	
	var level_container = %LevelContainer
	
	# add levels
	
	var level_metas = [
		{"path": "res://scenes/main_scenes/Levels/Level1.tscn", "name": "Level 1"},
		{"path": "res://scenes/main_scenes/Levels/Level2.tscn", "name": "Level 2"},
		{"path": "res://scenes/main_scenes/Levels/Level3.tscn", "name": "Level 3"},
		{"path": "res://scenes/main_scenes/Levels/Level4.tscn", "name": "Level 4"},
		{"path": "res://scenes/main_scenes/Levels/Level5.tscn", "name": "Level 5"},
		{"path": "res://scenes/main_scenes/Levels/Level6.tscn", "name": "Level 6"},
		{"path": "res://scenes/main_scenes/Levels/Level7.tscn", "name": "Level 7"},
		{"path": "res://scenes/main_scenes/Levels/Level8.tscn", "name": "Level 8"},
		{"path": "res://scenes/main_scenes/Levels/Level9.tscn", "name": "Level 9"},
		{"path": "res://scenes/main_scenes/Levels/Level10.tscn", "name": "Level 10"}
	]
	
	
	var level_number = 1
	for level_meta in level_metas:
		var button := Button.new()
		button.custom_minimum_size = Vector2(100, 100)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
		button.text = "Level " + str(level_number) + (
			"\n(" + level_meta.name + ")" if level_meta.has("name") else ""
		)
		level_container.add_child(button)
		
		button.pressed.connect(func():
			get_tree().change_scene_to_file(level_meta.path)
		)
		
		level_number += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
