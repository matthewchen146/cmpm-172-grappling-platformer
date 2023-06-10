extends StaticBody2D

var pressed = false
var presscount = 0

signal button_pressed
signal button_depressed

@onready var ButtonSFX = $ButtonSFX

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_area_2d_body_entered(body):
	if body.is_in_group("Presser"):
		presscount += 1
		if presscount == 1:
			$AnimationPlayer.play("Button_Down")
			ButtonSFX.play()
			print_debug("Button Pressed")
			button_pressed.emit()
	
	


func _on_area_2d_body_exited(body):
	if body.is_in_group("Presser"):
		presscount -= 1
		if presscount == 0:
			$AnimationPlayer.play("Button_Up")
			button_depressed.emit()
	pass # Replace with function body.
