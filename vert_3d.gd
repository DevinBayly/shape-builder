extends Node3D

@onready var mark = $mark
signal vertexclicked
var included_in_tri = false
func tri_clicked():
	included_in_tri = true
	turn_on()
func tri_cleared():
	included_in_tri = false
	turn_off()
func turn_on():
	
	mark.material.albedo_color = Color("red")
func turn_off():
	mark.material.albedo_color = Color("white")

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


func _on_mark_visibility_changed() -> void:
	pass # Replace with function body.


func _on_area_3d_area_entered(area: Area3D) -> void:
	print("entered ",area)
	turn_on()
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed :
		#
		#vertexclicked.emit(self)
		#
		#pass
	#pass # Replace with function body.
	#pass # Replace with function body.
