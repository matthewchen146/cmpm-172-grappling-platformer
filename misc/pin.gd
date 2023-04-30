extends DampedSpringJoint2D

func _process(delta):
	if node_b != null:
		var body = get_node(node_b) as RigidBody2D
		if Input.is_action_pressed("move_right"):
			body.apply_force(Vector2.RIGHT * 1000)
