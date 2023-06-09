extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	%PlayButton.pressed.connect(func():
		#get_tree().change_scene_to_file("res://scenes/main_scenes/level_select/level_select.tscn")
		var scene_trs = load("res://scenes/main_scenes/level_select/level_select.tscn")
		var scene = scene_trs.instantiate()
		add_child(scene)
	)
	%SettingsButton.pressed.connect(func():
		#get_tree().change_scene_to_file("res://scenes/main_scenes/settings/settings.tscn")
		var scene_trs = load("res://scenes/main_scenes/settings/settings.tscn")
		var scene = scene_trs.instantiate()
		add_child(scene)
	)
	%CreditsButton.pressed.connect(func():
		#get_tree().change_scene_to_file("res://scenes/main_scenes/credits/credits.tscn")
		var scene_trs = load("res://scenes/main_scenes/credits/credits.tscn")
		var scene = scene_trs.instantiate()
		add_child(scene)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
