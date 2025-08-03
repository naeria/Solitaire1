extends Node2D

@onready var outline = $DropArea/ColorRect

func _on_drop_area_mouse_entered():
	outline.visible = true

func _on_drop_area_mouse_exited():
	outline.visible = false
