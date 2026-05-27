extends Node3D
@onready  var ray = %RayCast3D
@onready var intersector = $intersector
var vert3d = preload("res://vert_3d.tscn")
var limiter=0
@export var limiter_restart =3
func _ready() -> void:
	pass

var col
var col_pos
func _physics_process(delta: float) -> void:
	col = ray.get_collider()
	col_pos = ray.get_collision_point()
	limiter-=delta
	if col and limiter<0:
		limiter = limiter_restart
		print("collision is ",col)
		intersector.position = col_pos

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.double_click:
			print("yes double clicked")
			if col:
				print("position",col_pos)
				# maek a vertex there
				var new_vert = vert3d.instantiate()
				new_vert.position = col_pos
				add_child(new_vert)
