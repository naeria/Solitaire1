extends Node2D

@export var size: Vector2 = Vector2(70, 110)
@export var padding: float = 5.0
@export var color: Color = Color(1, 1, 1, 1.0)
@export var thickness: float = 1.0

@onready var collision_shape = get_parent().get_node("CollisionShape2D")

func _ready():
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var extents = collision_shape.shape.extents
		size = extents * 2 - Vector2(padding * 2, padding * 2)
	queue_redraw()


func _draw():
	print("Drawing outline at", global_position)
	var padded_size = size - Vector2(padding * 2, padding * 2)
	var rect = Rect2(-padded_size / 2, padded_size)
	draw_rect(rect, color, false, thickness)
