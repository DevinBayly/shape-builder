extends Node3D
@onready var ray = $Camera3D/RayCast3D
func _process(delta: float) -> void:
	var col = ray.get_collider()
	if col:
		print(col)
