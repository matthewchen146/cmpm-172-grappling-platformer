extends Camera2D

@export_node_path("Node2D") var target_node_path
@onready var target_node : Node2D = get_node_or_null(target_node_path) if target_node_path else null

@export var follow_target := true

@export var target_offset := Vector2()

func _process(delta):
	if target_node != null and follow_target == true:
		var target_position : Vector2 = target_node.global_position + target_offset
		var cam_to_target : Vector2 = target_position - position
		position += cam_to_target.length() * cam_to_target.normalized() * Engine.get_physics_interpolation_fraction()

func follow_node(node : Node2D):
	target_node = node

