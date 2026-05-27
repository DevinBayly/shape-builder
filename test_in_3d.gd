extends Node3D
@onready  var ray = %RayCast3D
var vert3d = preload("res://vert_3d.tscn")
func _physics_process(delta: float) -> void:
	var col = ray.get_collider()
	
	if col :
		col
		print("collision is ",col)
