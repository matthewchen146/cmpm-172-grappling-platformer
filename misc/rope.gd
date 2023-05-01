extends Node2D

@export var max_length : float = 200

@export var hanger_position : Vector2 = Vector2()

var hanger_acceleration : Vector2 = Vector2()
var hanger_velocity : Vector2 = Vector2()
var angular_velocity : float = 0
var swing_angle : float = 0
var swing_start_vector : Vector2 = Vector2()

var _debug_tangent : Vector2 = Vector2()
var _debug_tension : Vector2 = Vector2()
var _debug_net : Vector2 = Vector2()

@onready var _debug_control : Control = Control.new()

@export var rigid_body : RigidBody2D

var gravity_magnitude : float = 0
var gravity : Vector2 = Vector2()

var energy : float = 1

var slacking : bool = false

func _ready():
	add_child.call_deferred(_debug_control)
	_debug_control.connect("draw", func():
		var hanger_local_position = rigid_body.position - position
		_debug_control.draw_line(Vector2.ZERO, hanger_local_position, Color.ANTIQUE_WHITE, 2)
		_debug_control.draw_circle(Vector2.ZERO, 5, Color.BLUE)
		_debug_control.draw_circle(hanger_local_position, 5, Color.RED)
#		_debug_control.draw_line(hanger_position, hanger_position + _debug_tangent, Color.MAGENTA, 2)
#		_debug_control.draw_line(hanger_position, hanger_position + gravity, Color.GREEN, 2)
		_debug_control.draw_line(hanger_local_position, hanger_local_position + _debug_tension, Color.ORANGE if slacking else Color.RED, 2)
		_debug_control.draw_line(hanger_local_position, hanger_local_position + _debug_net, Color.MAGENTA, 2)
	)
	
	var gravity_vector : Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	gravity_magnitude = ProjectSettings.get_setting("physics/2d/default_gravity")
	gravity = gravity_vector * gravity_magnitude
	
	var diff = hanger_position - position
#	hanger_position = position + diff.normalized() * max_length
	swing_start_vector = hanger_position - position
#	swing_angle = atan(diff.x / diff.y)
	print(swing_start_vector.length())

func _physics_process(delta):
#	hanger_acceleration = gravity + (position - hanger_position).normalized()
#	hanger_acceleration *= delta
#	var tension_vector := position - hanger_position
#	var angle = PI * .5 - tension_vector.angle_to(Vector2.UP)#Vector2.RIGHT if tension_vector.x > 0 else Vector2.LEFT)
#	var net = sin(angle) - gravity_magnitude * 5
#	var net := 10 * tension_vector + gravity
	hanger_position = rigid_body.position
#	var distance := tension_vector.length()
	# calculate pendulum acceleration
	var diff = hanger_position - position#vec(this.pos).sub(this.tongueTipPos)
	var length := diff.length()
#	var radius = length#max(length, 6);
	var pendulum_angle = atan(diff.x / diff.y)
#	var angular_force = gravity.y * (sin(pendulum_angle) / radius) * (-1 if sign(diff.y) > 0 else 1)
#	angular_velocity += angular_force
#
#	# change swing angle
#	swing_angle -= angular_velocity * delta * .01
#
#	var rotated_pos = swing_start_vector.rotated(swing_angle * energy)

	# calculate tangent for velocity
	var tangent = Vector2(diff.y, -diff.x).normalized()#Vector2(rotated_pos.y, -rotated_pos.x).normalized()
	var tangent_angle = atan(tangent.x / tangent.y) * (1 if diff.x < 0 else -1)
#	var tension_force = gravity.y * sin(tangent_angle) * (1 if sign(diff.y) > 0 else -1) * (max(0, length - max_length) ** 2) * .01
	var tension_force = gravity.y * cos(pendulum_angle) + 1 * (rigid_body.linear_velocity.length_squared()) / length
#	tension_force *= max(0, length - max_length) * .01
#	print(tension_force)
	slacking = length < max_length
	
	var tension_vector = position - hanger_position
	var tension = tension_vector.normalized() * (tension_force if not slacking else 0)
	_debug_tension = tension
	
	var magnitude = angular_velocity * max_length
	
	_debug_tangent = tangent * 100
	
	var movement = Vector2(float(Input.is_action_pressed("move_right")) - float(Input.is_action_pressed("move_left")), 0)
	
	var applied = Vector2()
	
	applied += movement * 300# * tangent * 10000
	applied += Vector2.UP * 500 if Input.is_action_just_pressed("jump") else Vector2()
	
	var net = gravity + tension + applied# + tangent
	_debug_net = net
	if rigid_body != null:
		rigid_body.apply_force(net)
	if length > max_length:
#		print("applyin")
		rigid_body.move_and_collide(-diff.normalized() * (length - max_length))
		rigid_body.apply_impulse(-diff.normalized() * (length - max_length) * 10)
#		applied += tension_vector.normalized() * (length - max_length) ** 2
#	hanger_velocity = tangent
#	hanger_position += hanger_velocity * delta
#	hanger_position = position + rotated_pos
	
	if Input.is_key_pressed(KEY_SHIFT):
		max_length -= 200 * delta
	if Input.is_key_pressed(KEY_CTRL):
		max_length += 200 * delta
	
	if Input.is_key_pressed(KEY_J):
		position += Vector2.LEFT * 100 * delta
	if Input.is_key_pressed(KEY_L):
		position += Vector2.RIGHT * 100 * delta
	if Input.is_key_pressed(KEY_I):
		position += Vector2.UP * 100 * delta
	if Input.is_key_pressed(KEY_K):
		position += Vector2.DOWN * 100 * delta
		
#	position = get_viewport().get_camera_2d().get_local_mouse_position()
	
	_debug_control.queue_redraw()
