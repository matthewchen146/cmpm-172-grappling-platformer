extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var level_container = $VBoxContainer/GridContainer
	
	# add levels
	
	var level_metas = [
		{"path": "res://misc/test_scene.tscn", "name": "Test"},
		{"path": "res://misc/rope_test.tscn", "name": "Rope"}
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
