extends Node2D

@onready var poly = $Polygon2D
signal vertexclicked
var included_in_tri = false
func tri_clicked():
	included_in_tri = true
	turn_on()
func tri_cleared():
	included_in_tri = false
	turn_off()
func turn_on():
	poly.color = Color("red")
func turn_off():
	poly.color = Color("white")

func _on_area_2d_mouse_entered() -> void:
	if not included_in_tri:
		turn_on()
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	if not included_in_tri:
		turn_off()
	pass # Replace with function body.


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed :
		
		vertexclicked.emit(self)
		
		pass
	pass # Replace with function body.
