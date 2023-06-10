extends Node

@onready var LaunchPadSFX = $"Launch-PadSFX"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not $AnimationPlayer.is_playing() and $AnimationPlayer.get_animation("Active"):
		$AnimationPlayer.play("Idle")


func Body_Entered_Jump_Region(body):
	$AnimationPlayer.play("Active")
	if body is RigidBody2D:
		body.linear_velocity.y = 0
		body.apply_impulse(Vector2(0, -1000))
		body.linear_damp = 0.05
		LaunchPadSFX.play()
	pass # Replace with function body.
