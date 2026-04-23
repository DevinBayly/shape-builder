extends Node2D

@onready var poly = $Polygon2D

func _on_area_2d_mouse_entered() -> void:
	poly.color = Color("red")
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	poly.color = Color("white")
	pass # Replace with function body.
