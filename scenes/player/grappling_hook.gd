extends Area2D

signal attached(body : PhysicsBody2D)

enum State {
	READY,
	FIRING,
	ATTACHED
}

var state : State = State.READY

var initial_direction := Vector2()

var speed : float = 50

var last_position : Vector2 = Vector2()

var ignored_bodies := {}

@onready var rope := $Node/Rope

func fire(start_pos : Vector2, direction : Vector2):
	if state == State.READY:
		initial_direction = direction
		position = start_pos
		state = State.FIRING

func _physics_process(delta):
	match state:
		State.FIRING:
			position += initial_direction * speed
		State.ATTACHED:
			pass
		_:
			pass
	
	last_position = position

func _on_body_entered(body):
	if not ignored_bodies.has(body):
		state = State.ATTACHED
		
		var space_state = get_world_2d().direct_space_state
		
		var shape_rid = PhysicsServer2D.circle_shape_create()
		var radius = 20
		PhysicsServer2D.shape_set_data(shape_rid, radius)
		
		var params = PhysicsShapeQueryParameters2D.new()
		params.shape_rid = shape_rid
		for ignored_body in ignored_bodies.keys():
			params.exclude.append(ignored_body.get_rid())
		var t : float = 0
		var diff := position - last_position
		var k := diff.length() * .5
		var dxn := diff.normalized()
		params.transform.origin = last_position + dxn * k
		
		for i in 30:
			var half = k * .5
			print(half)
			var result = space_state.collide_shape(params, 1)
			if result.is_empty():
				# no collision
				k += half
				params.transform.origin = last_position + dxn * k
			else:
				# collision
				k -= half
				params.transform.origin = last_position + dxn * k
			if half < .1:
				break
		
		PhysicsServer2D.free_rid(shape_rid)
		
		rope.anchor_position = last_position + dxn * k
		rope.active = true
		
		attached.emit(body)
