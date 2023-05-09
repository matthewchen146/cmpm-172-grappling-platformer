extends Interactable

var open = false;
@export var LevelNumToEnter: int = 2
# Called when the node enters the scene tree for the first time.
func _ready():
	#$AnimationPlayer.play("Door_Close")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func activate():
	print_debug("Door Activated")
	if (!open):
		#$Sprite2D.visible = false
		$AnimationPlayer.play("Door_Open")
		open = true
	else:
		#$Sprite2D.visible = true
		$AnimationPlayer.play("Door_Close")
		open = false
	


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		print_debug("Player Entered Door")
		get_tree().change_scene_to_file("Level%d" % [LevelNumToEnter])
