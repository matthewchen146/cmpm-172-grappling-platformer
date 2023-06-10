extends RigidBody2D

var max_length : float = 200
var grapple_reach: float = 400
var move_speed: float = 420
var swing_speed: float = 50
var jump_strength:float = 500

#Tweaking of the Grappling hook!
var min_corner_distance: float = 1 # Corners must be this distance apart to be formed
var AddCornerExtensionLength : float = 0.1 # When creating a corner, extend it from it's root by this much
var AddedAngle: float = 0.000 # When scanning angles, after finding the open angle add more to it
var CheckExtend : float = 0.1 # when raycast gets a hit, push it forward for the sweep
var corner_adjustment : float = 0 # This is used to remove corners, if they get stuck in walls

var anchor_position : Vector2 = Vector2()
var anchorNode: Node2D = Node2D.new()

@export var max_tension_force : float = 50000

var _debug_tangent : Vector2 = Vector2()
var _debug_tension : Vector2 = Vector2()
var _debug_net : Vector2 = Vector2()

@onready var _debug_control : Control = Control.new()
@onready var _debug_control_holo : Control = Control.new()

var gravity_magnitude : float = 0
var gravity : Vector2 = Vector2()

var slacking : bool = false

@onready var grappleHookSFX = $GrappleHookSFX
@onready var bgm1 = $BGM1
@onready var bgm2 = $BGM2
@onready var bgm3 = $BGM3
@onready var bgm4 = $BGM4


class Corner extends RefCounted:
	var position : Vector2 = Vector2()
	var length : float = 0
	func _init(_position, _length):
		position = _position
		length = _length

var corners = []
signal release

var rect_half_size

func _ready():
	#BGM
	var rng = RandomNumberGenerator.new()
	var val = rng.randi_range(0,4)#how do i do a switch statement in gdscript? who cares:
	if val == 0:
		bgm1.play()
	else: if val == 1:
		bgm2.play()
	else: if val == 2:
		bgm3.play()
	else:
		bgm4.play()
	
	var animationPlayer = $AnimationPlayer
	animationPlayer.play("Idle")
	anchorNode.position = Vector2() # Peyton edit
	var canvas_layer = CanvasLayer.new()
	
	add_child(canvas_layer)
	canvas_layer.add_child(_debug_control)
	add_child.call_deferred(canvas_layer)
	_debug_control.connect("draw", func():
		rect_half_size = get_viewport_rect().size * .5
		var camera = get_viewport().get_camera_2d()
		#canvas_layer.scale.x = camera.zoom.x / 2
		#canvas_layer.scale.y = camera.zoom.y / 2
		var hanger_local_position = position - position + rect_half_size
		var anchor_local_position = anchor_position - position + rect_half_size
		var prev_corner_local_position = corners[0].position - position + rect_half_size
		for i in range(0, corners.size() - 1):
			var corner_local_position = corners[i + 1].position - position + rect_half_size
			_debug_control.draw_line(prev_corner_local_position, corner_local_position, Color.ANTIQUE_WHITE, 2)
			prev_corner_local_position = corner_local_position
		for corner in corners:
			var corner_local_position = corner.position - position + rect_half_size
			_debug_control.draw_circle(corner_local_position, 3, Color.GREEN)
		_debug_control.draw_line(prev_corner_local_position, hanger_local_position, Color.ANTIQUE_WHITE, 2)
		_debug_control.draw_circle(anchor_local_position, 5, Color.BLUE)
		_debug_control.draw_circle(hanger_local_position, 5, Color.RED)
#		_debug_control.draw_line(hanger_position, hanger_position + _debug_tangent, Color.MAGENTA, 2)
#		_debug_control.draw_line(hanger_position, hanger_position + gravity, Color.GREEN, 2)
		#_debug_control.draw_line(hanger_local_position, hanger_local_position + _debug_tension, Color.ORANGE if slacking else Color.RED, 2)
		#_debug_control.draw_line(hanger_local_position, hanger_local_position + _debug_net, Color.MAGENTA, 2)
	)
	_debug_control.hide()
	var gravity_vector : Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	gravity_magnitude = ProjectSettings.get_setting("physics/2d/default_gravity")
	gravity = gravity_vector * gravity_magnitude
	
	corners.append(Corner.new(anchor_position, max_length))
	
	var canvas_layer_holo = CanvasLayer.new()
	add_child(canvas_layer_holo)
	canvas_layer_holo.add_child(_debug_control_holo)
	add_child.call_deferred(canvas_layer_holo)
	_debug_control_holo.connect("draw", func():
		var space_state = get_world_2d().direct_space_state
		var camera : Camera2D = get_viewport().get_camera_2d()
		var mouse_world_pos : Vector2 = camera.get_global_mouse_position()
		var mouseDir = mouse_world_pos - position
		var grapplePosition := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position, position + mouseDir.normalized() * grapple_reach, 0xFFFFFFFF, [self]))
		#if grapplePosition.has("collider"):
			#_debug_control_holo.draw_circle(grapplePosition.collider.position, 1, Color.LIGHT_BLUE)
	)

#var first_supposed_length = 0
var grappling = false
var pulling = false
var pressed_mouse = false
var auto_retracting = false
var auto_retract_length : float = 50
var auto_retract_speed : float = 5
var auto_retract_max_length: float = 0
var onGround = false
func _physics_process(delta):
	#start with checking if player is on the ground
	var bodies = $Area2D.get_overlapping_bodies()
	for body in bodies:
		if body.name != "Player":
			onGround = true
			break
	
	#show where grapple will land
	var space_state = get_world_2d().direct_space_state
	var camera : Camera2D = get_viewport().get_camera_2d()
	var mouse_world_pos : Vector2 = camera.get_global_mouse_position()
	if Input.is_action_just_pressed("fire_grapple"):
		#print("Shot The Grapple")
		pressed_mouse = true
		var direction : Vector2
		if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_F)):
			direction = mouse_world_pos - position
		else: if (Input.is_key_pressed(KEY_UP)):
			direction = Vector2(0,-1)
		else: if (Input.is_key_pressed(KEY_DOWN)):
			direction = Vector2(0,1)
		else: if (Input.is_key_pressed(KEY_LEFT)):
			direction = Vector2(-1,0)
		else: if (Input.is_key_pressed(KEY_RIGHT)):
			direction = Vector2(1,0)
		var anchorobject := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position, position + direction.normalized() * grapple_reach, 0xFFFFFFFF, [self]))
		if anchorobject.has("collider"):
			print_debug("Grapple Landed")
			var obj_to_pull = anchorobject.collider as RigidBody2D
			grappling = true
			grappleHookSFX.play()
			if obj_to_pull != null:
				pulling = true
				print(obj_to_pull.name)
				anchorNode.position = anchorobject.collider.position
				max_length = (anchorNode.position - position).length()
				corners.clear()
				corners.append(Corner.new(anchorNode.position, max_length))
				obj_to_pull.ConnectToPlayer()
				print("Connecting To Player")
			else:
				pulling = false
				emit_signal("release")
				_debug_control.show()
				#anchorobject.collider.add_child(anchorNode) #  this doesn't work but it would be nice to solve
				anchorNode.position = anchorobject.position
				max_length = (anchorobject.position - position).length()
				corners.clear()
				corners.append(Corner.new(anchorNode.position, max_length))
				if onGround:
					auto_retracting = true
					auto_retract_length = 70
					auto_retract_speed = 250#default
					auto_retract_max_length = max_length
				var TM = anchorobject.collider as TileMap
				if TM != null:
					#there is a tilemap
					var location0 : Vector2 = TM.local_to_map(anchorNode.position + (direction.normalized() * 0.1))
					if TM.get_cell_tile_data(0, location0).get_custom_data("FastGrapple"):
						#FastGrapple
						auto_retracting = true
						auto_retract_length = max_length
						auto_retract_speed = 320#default
						auto_retract_max_length = max_length
						apply_impulse(direction.normalized() * 1500)
				
	if Input.is_action_just_pressed("jump"):
		if grappling:
			#jump off of the rope instead of disconnect it
			#apply_impulse(jump_strength * Vector2(0,-1)) # removing grapple jump, OP
			grappling = false
			_debug_control.hide()
			pulling = false
		else:
			if onGround:
				if not (linear_velocity.x > 1 or linear_velocity.x < -1):
					$AnimationPlayer.play("Jump-Idle")
				apply_impulse(jump_strength * Vector2(0,-1))
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		grappling = false
		_debug_control.hide()
		pulling = false
		emit_signal("release")
	if not grappling or pulling:
		return
	anchor_position = anchorNode.position
	
	corners[0].position = anchor_position
	
	if corners.size() > 1:
		var diff : Vector2 = corners[1].position - corners[0].position
		var length := diff.length()
		if length != corners[0].length:
			var change : float = corners[0].length - length
			corners[corners.size() - 1].length += change
			corners[0].length = length
	
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
		if result.has("collider") and current_corner.length > min_corner_distance and ((result.position - current_corner.position).length() > min_corner_distance):
			#var corner_position = result.position
			# create corner
			var sign = -1
			var angle = .01
			var rotated = Vector2()
			var found = false
			var corner_position = result.position
			var farthestPositive : float = (current_corner.position - result.position).length()
			var farthestNegative : float = (current_corner.position - result.position).length()
			# tests multiple rays with different angles from the next corner to find a non-colliding spot
			# convert this into some binary search for faster calculation
			for j in range(1000):
				rotated = (result.position - current_corner.position).rotated(angle * sign)
				rotated += rotated.normalized() * CheckExtend # extend the rotating scan slightly
				var test = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(current_corner.position,current_corner.position + rotated, 0xFFFFFFFF, [self]))
				if not test.has("collider"):
					found = true # found a spot where it isn't colliding
					rotated = (result.position - current_corner.position).rotated((angle + AddedAngle) * sign)
					if sign == 1:
						var dir = (rotated.normalized() * farthestPositive)
						dir += dir.normalized() * AddCornerExtensionLength
						corner_position = current_corner.position + dir
						
					else:
						var dir = (rotated.normalized() * farthestNegative)
						dir += dir.normalized() * AddCornerExtensionLength
						corner_position = current_corner.position + dir
#					print("found at ", j)
					break
				else:
					if (sign == 1):
						farthestPositive = (current_corner.position - test.position).length()
						#_debug_control.draw_circle(farthestPositive - position + rect_half_size, 5, Color.BLACK)
					else:
						farthestNegative = (current_corner.position - test.position).length()
						#_debug_control.draw_circle(farthestNegative - position + rect_half_size, 5, Color.BLACK)
				sign *= -1
				angle += .01
			if found:#found
				var length = (corner_position - next_corner_position).length()
				#var corner_position = next_corner_position + rotated.normalized() * length
				#Peyton Edit: made it so can't make new corners close to previous ones.
				if (corner_position - current_corner.position).length() >= min_corner_distance:
					#print("Added Corner")
					corners.insert(i + 1, Corner.new(corner_position, length))
					#print("adding corner from corner ", i, " to corner ", i+1)
					#print("Corner Count: ", corners.size())
					current_corner.length -= length
					i += 1
		else:
			# check if current corner and prev corner can see next corner
			if corners.size() > 1 and not next_corner_is_hanger:
				var next_next_corner = corners[i + 2] if i + 2 < corners.size() else null
				var next_next_corner_pos : Vector2 = next_next_corner.position if next_next_corner != null else position
				var adjusted_current_direction : Vector2 = (next_next_corner_pos - current_corner.position).normalized() * corner_adjustment
				var adjusted_next_direction : Vector2 = (next_next_corner_pos - next_corner.position).normalized() * corner_adjustment
				var test := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(current_corner.position , next_next_corner_pos, 0xFFFFFFFF, [self]))
				var test2 := space_state.intersect_ray(PhysicsRayQueryParameters2D.create(next_corner.position, next_next_corner_pos, 0xFFFFFFFF, [self]))
				if not test.has("collider"):
					if not test2.has("collider"):
						current_corner.length += next_corner.length
						corners.remove_at(i + 1)
						#print("Removed Corner")
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
	slacking = length < current_max_length
	
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
	
	if length > current_max_length and grappling:
#		print("applyin")
		move_and_collide(-diff.normalized() * (length - current_max_length))
		apply_impulse(-diff.normalized() * (length - current_max_length) * 100)
	
	#Auto-retraction and normal retraction
	if Input.is_action_pressed("raise") or auto_retracting:
		#use 250 as speed if not auto-retracting, else use it's speed
		var retractSpeed = 250 if not auto_retracting else auto_retract_speed
		current_corner.length -= retractSpeed * delta
		auto_retract_length -= retractSpeed * delta
		if auto_retract_length <= 0:
			auto_retracting = false
		if current_corner.length < 30: #and (corners.size() - 1) == 0: # make it so you can't go below 30 on anchor
			current_corner.length = 30
		if auto_retracting:
			if current_corner.length < auto_retract_max_length:
				auto_retract_max_length = current_corner.length
			if current_corner.length > auto_retract_max_length:
				current_corner.length = auto_retract_max_length
	if Input.is_action_pressed("lower"):
		current_corner.length += 250 * delta
	
	if Input.is_key_pressed(KEY_J):
		anchor_position += Vector2.LEFT * 100 * delta
	if Input.is_key_pressed(KEY_L):
		anchor_position += Vector2.RIGHT * 100 * delta
	if Input.is_key_pressed(KEY_I):
		anchor_position += Vector2.UP * 100 * delta
	if Input.is_key_pressed(KEY_K):
		anchor_position += Vector2.DOWN * 100 * delta
		
	#anchor_position = get_viewport().get_camera_2d().get_local_mouse_position()
	
#	_debug_control.rotation = -rotation
	_debug_control.queue_redraw()
	_debug_control_holo.queue_redraw()

func _process(delta):
	#start with checking if player is on the ground
	onGround = false
	var bodies = $Area2D.get_overlapping_bodies()
	for body in bodies:
		if body.name != "Player":
			onGround = true
			break
	if (linear_velocity.x > 1 or linear_velocity.x < -1 or linear_velocity.y > 1 or linear_velocity.y < -1) and onGround:
		#print("Playing Running")
		$AnimationPlayer.play("Running")
	else: if not onGround:
		if not $AnimationPlayer.current_animation == "Jump-Idle":
			$AnimationPlayer.play("Jump-Airborn")
	else:
		#print("Playing Idle")
		$AnimationPlayer.play("Idle")
	if linear_velocity.x < -1:
		$Sprite2D.scale.x = -$Sprite2D.scale.y
	if linear_velocity.x > 1:
		$Sprite2D.scale.x = $Sprite2D.scale.y
	var speed_limit = 300
	var movement:= Vector2()
	if linear_velocity.x < speed_limit or (grappling and not pulling):
		movement.x += int(Input.is_action_pressed("move_right"))
	if linear_velocity.x > -speed_limit or (grappling and not pulling):
		movement.x -= int(Input.is_action_pressed("move_left"))
	if onGround:
		if not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
			linear_damp = 6
		else:
			linear_damp = 0.05
	else:
		linear_damp = 0.05
	if grappling and not pulling:
		if onGround:
			apply_force(movement * move_speed)
		else:
			apply_force(movement * swing_speed)
	else:
		apply_force(movement * move_speed)
	
	
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
	


func _on_area_2d_body_entered(body): # 
	var body_tilemap = body as TileMap
	if body_tilemap != null:
		var tileLocation = body_tilemap.local_to_map(position + Vector2(0, 32))
		var tiledata: TileData = body_tilemap.get_cell_tile_data(0, tileLocation)
		if tiledata != null:
			if tiledata.get_custom_data("Lethal") == true:
				Player_Death()
		tileLocation = body_tilemap.local_to_map(position)
		tiledata = body_tilemap.get_cell_tile_data(0, tileLocation)
		if tiledata != null:
			if tiledata.get_custom_data("Lethal") == true:
				Player_Death()

func Player_Death():
	get_tree().reload_current_scene()
