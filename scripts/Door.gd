extends Interactable

var open = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Door_Close")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func activate():
	print_debug("Door Activated")
	if (!open):
		$Sprite2D.visible = false
		$AnimationPlayer.play("Door_Open")
		open = true
	else:
		$Sprite2D.visible = true
		$AnimationPlayer.play("Door_Close")
		open = false
	
