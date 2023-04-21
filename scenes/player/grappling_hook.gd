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

var ignored_bodies := {}

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

func _on_body_entered(body):
	if not ignored_bodies.has(body):
		state = State.ATTACHED
		attached.emit(body)
