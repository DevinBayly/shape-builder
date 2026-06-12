extends Node3D
@onready  var ray = %RayCast3D
@onready var intersector = $intersector
var vert3d = preload("res://vert_3d.tscn")
var limiter=0
@onready var tri_button: Button = $tri_button
@export var limiter_restart:float =3
@onready var testicon = preload("res://icon.svg")
var cam
func _ready() -> void:
	cam = get_viewport().get_camera_3d()
	pass

var col
var col_pos
func _physics_process(delta: float) -> void:
	col = ray.get_collider()
	col_pos = ray.get_collision_point()
	limiter-=delta
	if col and limiter<0:
		limiter = limiter_restart
		#print("collision is ",col)
		intersector.position = col_pos
	

		# if we have a
		# NOTE need to come up with a check to make sure motion has occurred

var prev: Node3D = null
var edges = []
var dist_threshold = 5
var last_intersections = []
var all_vertx: Array[Vector3] = []
var triangle_vertices=[]
var hovered_element


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.double_click and not tri_button.is_pressed():
			print("yes double clicked")
			if col:
				print("position",col_pos)
				for overt in all_vertx:
					if (col_pos - overt).length() < dist_threshold:
						print("too close")
						return
				# maek a vertex there
				var new_vert = vert3d.instantiate()
				new_vert.position = col_pos
				new_vert.vertexhovered.connect(vert_was_hovered)
				add_child(new_vert)

				# this just makes sure we have a list of the edges
				all_vertx.push_back(col_pos)
				if prev:
					edges.push_back([prev,new_vert])
					prev = new_vert
				else:
					prev = new_vert
						
		elif e.pressed and hovered_element and tri_button.is_pressed():
			# turn the hovered_element on for it's triangle 
			hovered_element.tri_clicked()
			triangle_vertices.push_back(hovered_element)
			print("tri verts are ", triangle_vertices)
			if triangle_vertices.size()==3:
				create_colored_geometry(triangle_vertices)
				clear_triangles_list()
			# check if we have a 			

func create_colored_geometry(verts):
	var vpos = []
	for vert in verts:
		vpos.push_back(vert.position)
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()

	for v in vpos:
		vertices.push_back(v)
		uvs.push_back(Vector2(0, 0))

	# Initialize the ArrayMesh.
	var arr_mesh:ArrayMesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(randf(),randf(),randf())
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	arr_mesh.surface_set_material(0,mat)
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	
	# make this a random color
	add_child(m)

func vert_was_hovered(vert):
	hovered_element = vert		

func remove_meshes():
	# also remove all meshes
	var meshes = get_children()
	
	for m in meshes:
		if m is MeshInstance3D:
			m.queue_free()
func clear_triangles_list():
	#clear the triangle list
	for v in triangle_vertices:
		# turn off their selection colors
		v.tri_cleared()
	triangle_vertices = []
func _on_clear_pressed() -> void:
	clear_triangles_list()
	remove_meshes()
	
	pass # Replace with function body.

func _on_drawim_pressed() -> void:
	# go get all the other mesh2ds 
	# find the min and max of all their points
	# go back through each and update it's texture coordinates, and add a texture to the shape
	# OR
	# make one big ass mesh using all the triangles, and set all the uvs to correct values, and then at the end just assign a single texture
	var meshes = get_children()
	print("trying something different")
	var minx = get_viewport().get_visible_rect().size.x + 500
	var miny = get_viewport().get_visible_rect().size.y + 500
	var maxx = -100
	var maxy = -100
	for m in meshes:
		if m is MeshInstance3D:
			var mesh:ArrayMesh = m.mesh
			# iterate over the vertices in the triangle
			var mesh_array = mesh.surface_get_arrays(0)
			var vertices = mesh_array[Mesh.ARRAY_VERTEX]
			
			for v3d in vertices:
				# convert back to the screen coordinates
				var v = cam.unproject_position(v3d)
				if v.x >maxx:
					maxx = v.x
				if v.x < minx:
					minx= v.x
				if v.y <miny:
					miny = v.y
				if v.y > maxy:
					maxy=v.y
	print("min ",minx," ",miny," and max values ",maxx," ",maxy)
	# use the min and max values to help us establish uv coordinates
	for m in meshes:
		if m is MeshInstance3D:
			var mesh:ArrayMesh = m.mesh
			# iterate over the vertices in the triangle
			var mesh_array = mesh.surface_get_arrays(0)
			var vertices = mesh_array[Mesh.ARRAY_VERTEX]
			var uvs = mesh_array[Mesh.ARRAY_TEX_UV]
			var i=0
			for v3d in vertices:
				var v = cam.unproject_position(v3d)
				print("vertex", v)
				# normalize the v and store that as the uv coordinate
				var normv = Vector2((maxx - v.x)/(maxx - minx),(maxy - v.y)/(maxy - miny))
				# also flip the y since that's how graphics work
				normv.y = 1-normv.y
				print("normalized vertex is",normv)
				uvs[i] =  normv
				i+=1
			mesh_array[Mesh.ARRAY_TEX_UV] = uvs
			mesh.surface_remove(0)
			# re add the data so the uvs get baked in properly
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_array)
			
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_texture = testicon
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh.surface_set_material(0,mat)
			m.mesh = mesh
			
			
