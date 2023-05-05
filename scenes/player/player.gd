extends CharacterBody2D

@export var move_speed : float = 200
@export var jump_strength : float = 400
@export var grapple_pull_speed : float = 300

var gravity := Vector2()

var is_firing_grapple := false

var is_grappled := false

var current_grappling_hook : Node2D = null

func _ready():
	var gravity_vector : Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	var gravity_magnitude : int = ProjectSettings.get_setting("physics/2d/default_gravity")
	gravity = gravity_vector * gravity_magnitude

func _physics_process(delta):
	
	var movement := Vector2()
	
	# movement.x becomes a value between -1 and 1. -1 meaning moving left and 1 meaning moving right
	movement.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	
	if Input.is_action_pressed("fire_grapple"):
		if not is_firing_grapple:
			is_firing_grapple = true
			
			if current_grappling_hook:
				current_grappling_hook.get_parent().remove_child(current_grappling_hook)
				current_grappling_hook.free()
			
			var hook : Node2D = preload("res://scenes/player/grappling_hook.tscn").instantiate()
			
			var camera : Camera2D = get_viewport().get_camera_2d()
			var mouse_world_pos : Vector2 = camera.get_global_mouse_position()
			var direction = (mouse_world_pos - position).normalized()
			
			hook.ignored_bodies[self] = true
			
			hook.attached.connect(
				func(body : PhysicsBody2D):
					is_grappled = true
					hook.rope.position = position
					hook.rope.set_length((position - hook.position).length())
			)
			
			hook.fire(position, direction)
			
			get_parent().add_child(hook)
			
			current_grappling_hook = hook
			
	else:
		if is_firing_grapple:
			is_firing_grapple = false
			if current_grappling_hook:
				current_grappling_hook.get_parent().remove_child(current_grappling_hook)
				current_grappling_hook.free()
				current_grappling_hook = null
		if is_grappled:
			is_grappled = false
	
	if is_grappled:
		
		var direction := (current_grappling_hook.position - position).normalized()
		velocity = direction * grapple_pull_speed
		
	else:
		velocity.x = movement.x * move_speed
		
		if not is_on_floor():
			velocity.y += gravity.y * delta
		else:
			velocity.y = 0
			
			if Input.is_action_just_pressed("jump"):
				velocity.y = -jump_strength
	
	# this moves the player based on the velocity that is set
	# this will handle the collision automatically and slide
	move_and_slide()
