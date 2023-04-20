extends CharacterBody2D

@export var move_speed : float = 200
@export var jump_strength : float = 400

var gravity := Vector2()

func _ready():
	var gravity_vector : Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	var gravity_magnitude : int = ProjectSettings.get_setting("physics/2d/default_gravity")
	gravity = gravity_vector * gravity_magnitude

func _physics_process(delta):
	
	# left right movement
	var movement := Vector2()
	
	movement.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	
	movement.x *= move_speed
	
	velocity.x = movement.x
	
	if not is_on_floor():
		velocity.y += gravity.y * delta
	else:
		velocity.y = 0
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_strength
	
	move_and_slide()
