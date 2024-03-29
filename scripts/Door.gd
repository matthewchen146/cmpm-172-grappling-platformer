extends Interactable

@onready var DoorSFX = $DoorSFX

var open = false;
@export var LevelNumToEnter: int = 3
@export var toVictory = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Door_Close")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func activate():
	print_debug("Door Activated")
	if (!open):
		#$Sprite2D.visible = false
		$AnimationPlayer.play("Door_Open")
		DoorSFX.play()
		open = true
	#else:
		#$Sprite2D.visible = true
		#$AnimationPlayer.play("Door_Close")
		#open = false
	


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		print_debug("Player Entered Door")
		if (open):
			if not toVictory:
				get_tree().change_scene_to_file("res://scenes/main_scenes/Levels/Level%d.tscn" % [LevelNumToEnter])
			else:
				get_tree().change_scene_to_file("res://scenes/main_scenes/Levels/Victory.tscn")
