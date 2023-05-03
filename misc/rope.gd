extends RigidBody2D

@export var max_length : float = 200

@export var anchor_position : Vector2 = Vector2()

@export var max_tension_force : float = 50000

var _debug_tangent : Vector2 = Vector2()
var _debug_tension : Vector2 = Vector2()
var _debug_net : Vector2 = Vector2()

@onready var _debug_control : Control = Control.new()

var gravity_magnitude : float = 0
var gravity : Vector2 = Vector2()

var slacking : bool = false

class Corner extends RefCounted:
	var position : Vector2 = Vector2()
	var length : float = 0
	func _init(_position, _length):
		position = _position
		length = _length

var corners = []

func _ready():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(_debug_control)
	add_child.call_deferred(canvas_layer)
	_debug_control.connect("draw", func():
		var rect_half_size = get_viewport_rect().size * .5
		var camera = get_viewport().get_camera_2d()
		var hanger_local_position = position - camera.position + rect_half_size
		var anchor_local_position = anchor_position - camera.position + rect_half_size
		var prev_corner_local_position = corners[0].position - camera.position + rect_half_size
		for i in range(0, corners.size() - 1):
			var corner_local_position = corners[i + 1].position - camera.position + rect_half_size
			_debug_control.draw_line(prev_corner_local_position, corner_local_position, Color.ANTIQUE_WHITE, 2)
			prev_corner_local_position = corner_local_position
		for corner in corners:
			var corner_local_position = corner.position - camera.position + rect_half_size
			_debug_control.draw_circle(corner_local_position, 3, Color.GREEN)
		_debug_control.draw_line(prev_corner_local_position, hanger_local_position, Color.ANTIQUE_WHITE, 2)
		_debug_control.draw_circle(anchor_local_position, 5, Color.BLUE)
		_debug_control.draw_circle(hanger_local_position, 5, Color.RED)
#		_debug_control.draw_line(hanger_position, hanger_position + _debug_tangent, Color.MAGENTA, 2)
#		_debug_control.draw_line(hanger_position, hanger_position + gravity, Color.GREEN, 2)
		_debug_control.draw_line(hanger_local_position, hanger_local_position + _debug_tension, Color.ORANGE if slacking else Color.RED, 2)
		_debug_control.draw_line(hanger_local_position, hanger_local_position + _debug_net, Color.MAGENTA, 2)
	)
	
	var gravity_vector : Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	gravity_magnitude = ProjectSettings.get_setting("physics/2d/default_gravity")
	gravity = gravity_vector * gravity_magnitude
	
	corners.append(Corner.new(anchor_position, max_length))

#var first_supposed_length = 0

func _physics_process(delta):
	
	corners[0].position = anchor_position
	
	if corners.size() > 1:
		var diff : Vector2 = corners[1].position - corners[0].position
		var length := diff.length()
		if length != corners[0].length:
			var change : float = corners[0].length - length
			corners[corners.size() - 1].length += change
			corners[0].length = length
	
	var space_state = get_world_2d().direct_space_state
	
#	print(corners.size())
	
	var i = 0
	while true:
		if i >= corners.size():
			break
		var current_corner = corners[i]
		var next_corner = corners[i + 1] if i + 1 < corners.size() else null
		var next_corner_is_hanger := next_corner == null
		var next_corner_position : Vector2 = next_corner.position if not next_corner_is_hanger else position
		# result is from current corner to the next corner. ex is anchor to the hanger
		var result := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(next_corner_position, current_corner.position, 0xFFFFFFFF, [self]))
		if result.has("collider") and current_corner.length > 1:
				
			# create corner
			var sign = -1
			var angle = .01
			var rotated = Vector2()
			var found = false
			# tests multiple rays with different angles from the next corner to find a non-colliding spot
			# convert this into some binary search for faster calculation
			for j in range(100):
				rotated = (current_corner.position - next_corner_position).rotated(angle * sign)
				var test = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(next_corner_position, next_corner_position + rotated, 0xFFFFFFFF, [self]))
				if not test.has("collider"):
					found = true
#					print("found at ", j)
					break
				sign *= -1
				angle += .01
			if found:
				var length = (result.position - next_corner_position).length()
				var corner_position = next_corner_position + rotated.normalized() * length
				corners.insert(i + 1, Corner.new(corner_position, length))
#				print("addinng corner ", i)
				current_corner.length -= length
				i += 1
		else:
			# check if current corner and prev corner can see next corner
			if corners.size() > 1 and not next_corner_is_hanger:
				
#				var prev_corner = corners[i - 1]
#				var test_prev := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(prev_corner.position, next_corner_position, 0xFFFFFFFF, [self]))
#				if not test_prev.has("collider"):
##					print("can remove ", i)
##					print("removibing ", i)
#					prev_corner.length += current_corner.length
#					corners.remove_at(i)
#					i -= 1
#					pass
				var next_next_corner = corners[i + 2] if i + 2 < corners.size() else null
				var next_next_corner_pos = next_next_corner.position if next_next_corner != null else position
				var test := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(current_corner.position, next_next_corner_pos, 0xFFFFFFFF, [self]))
				if not test.has("collider"):
					current_corner.length += next_corner.length
					corners.remove_at(i + 1)
					i -= 1
#		current_corner = next_corner
		i += 1
	
	var current_corner = corners[corners.size() - 1]
	var current_anchor_position : Vector2 = current_corner.position
	
	var diff = position - current_anchor_position#vec(this.pos).sub(this.tongueTipPos)
	var length : float = max(1, diff.length())
	var current_max_length = current_corner.length
	var pendulum_angle = atan(diff.x / diff.y)

	# calculate tangent for velocity
	var tangent = Vector2(diff.y, -diff.x).normalized()#Vector2(rotated_pos.y, -rotated_pos.x).normalized()
	var tangent_angle = atan(tangent.x / tangent.y) * (1 if diff.x < 0 else -1)
#	var tension_force = gravity.y * sin(tangent_angle) * (1 if sign(diff.y) > 0 else -1) * (max(0, length - max_length) ** 2) * .01
	var tension_force = gravity.y * cos(pendulum_angle) + 1 * (linear_velocity.length_squared()) / length
#	tension_force *= max(0, length - max_length) * .01
#	print(tension_force)
	slacking = length < max_length
	
	var tension_vector = current_anchor_position - position
	var tension = tension_vector.normalized() * (tension_force if not slacking else 0)
	_debug_tension = tension
	
	_debug_tangent = tangent * 100
	
	var movement = Vector2(float(Input.is_action_pressed("move_right")) - float(Input.is_action_pressed("move_left")), 0)
	
	var applied = Vector2()
	
	applied += movement * 300# * tangent * 10000
	applied += Vector2.UP * 500 if Input.is_action_just_pressed("jump") else Vector2()
	
	var net = gravity + tension + applied# + tangent
	_debug_net = net
	
#	print(tension_force > 40000)
	
	apply_force(net)
	
	if length > current_max_length:
#		print("applyin")
		move_and_collide(-diff.normalized() * (length - current_max_length))
		apply_impulse(-diff.normalized() * (length - current_max_length) * 100)
	
	if Input.is_key_pressed(KEY_SHIFT):
		current_corner.length -= 200 * delta
	if Input.is_key_pressed(KEY_CTRL):
		current_corner.length += 200 * delta
	
	if Input.is_key_pressed(KEY_J):
		anchor_position += Vector2.LEFT * 100 * delta
	if Input.is_key_pressed(KEY_L):
		anchor_position += Vector2.RIGHT * 100 * delta
	if Input.is_key_pressed(KEY_I):
		anchor_position += Vector2.UP * 100 * delta
	if Input.is_key_pressed(KEY_K):
		anchor_position += Vector2.DOWN * 100 * delta
		
	anchor_position = get_viewport().get_camera_2d().get_local_mouse_position()
	
#	_debug_control.rotation = -rotation
	_debug_control.queue_redraw()
