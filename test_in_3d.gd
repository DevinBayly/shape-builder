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
		print()
		limiter = limiter_restart
		#print("collision is ",col)
		intersector.position = col_pos
	

		# if we have a
		# NOTE need to come up with a check to make sure motion has occurred

var prev: Node3D = null
var corners = []
var edges = []
var dist_threshold = 5
var last_intersections = []
# helps us figure out the uvs of the border points created at intersections
var last_intersections_uvs =[]
var all_vertx: Array[Vector3] = []
var triangle_vertices=[]
var hovered_element
var center = Vector3(0,0,0)
func calc_center():
	var total = Vector3(0,0,0)
	for v in all_vertx:
		total +=v
	center.x = total.x/all_vertx.size()
	center.y = total.y/all_vertx.size()
	center.z = total.z/all_vertx.size()
func uv_edges():
	for pair in edges:		
		var start = pair[0]
		var end = pair[1]
		var dif = end.position - start.position
		# dir from center
		var centerdif = center - start.position
		# figure out if the horizontal dif is bigger than the vertical
		if abs(dif.x) > abs(dif.y):
			# we have a horizontal edge
			# figure out our v coordinate to hold steady
			var v = 0
			if centerdif.y > 0:
				# center point is above our starting vector so we are a horizontal "top" line with a 0 as v
				v = 1
			# keep in mind that we might need to figure out if we are a top or bottom horizontal
			if dif.x >0:
				start.uv = Vector2(0,v)
				end.uv = Vector2(1,v)
			else:
				start.uv = Vector2(1,v)
				end.uv = Vector2(0,v)
			# figure out which one needs to have the 0 vs 1 in the u coordinate
		else:
			# we have a vertical edge
			# figure out our u coordinate to hold steady
			var u =1
			if centerdif.x >0:
				#means center point is to the right of our spot so we are a vertical line with 0 as our u
				u =0
			if dif.y>0:
				start.uv = Vector2(u,1)
				end.uv = Vector2(u,0)
			else:
				start.uv = Vector2(u,0)
				end.uv = Vector2(u,1)

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
	var ind =0
	for v in vpos:
		var vert3d =verts[ind]
		vertices.push_back(v)
		uvs.push_back(vert3d.uv)
		ind+=1
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
	
	
	# use the min and max values to help us establish uv coordinates
	for m in meshes:
		if m is MeshInstance3D:
			var mesh:ArrayMesh = m.mesh
			# iterate over the vertices in the triangle
			var mesh_array = mesh.surface_get_arrays(0)
			var vertices = mesh_array[Mesh.ARRAY_VERTEX]
			var uvs = mesh_array[Mesh.ARRAY_TEX_UV]
			
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
			
			


func _on_button_pressed() -> void:
	uv_edges()
	pass # Replace with function body.
