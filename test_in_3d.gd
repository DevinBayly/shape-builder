extends Node3D
@onready  var ray = %RayCast3D
@onready var intersector = $intersector
var vert3d = preload("res://vert_3d.tscn")
var limiter=0
@onready var innerButton: Button = $Button
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
		if innerButton.is_pressed():
			last_intersections=[]
			if edges.size() > 1:
				var edges_2d= []
				var cam = get_viewport().get_camera_3d()
				var col_pos_2d = cam.unproject_position(col_pos)
				for e in edges:
					var start = e[0]
					var end = e[1]
					edges_2d.push_back([cam.unproject_position(start.position),
					cam.unproject_position(end.position)
					])
				# check intersections of all the edges in cardinal directions from the point on the screen
				# make a vector at this current position,
				var directions = [[200,0.01],[0.01,200],[-200,0.01],[0.01,-200]]
				#var directions = [[0.01,200]]
				var closed =  edges_2d + [
					[edges_2d[-1][1],edges_2d[0][0]]
				]
				for edge in closed:
					for dir in directions: 
						var e2 = col_pos_2d +Vector2(randf()/100,randf()/100)
						var e1 = Vector2(e2.x + dir[0],e2.y +dir[1]) +  Vector2(randf()/100,randf()/100)
						# note that for some of these values the denominator will be 0
						var em = (e2.y - e1.y)/(e2.x - e1.x)
						# go over the other edges_2d and see if
						# include the final edge of last to first
						
						#var closed_edges = edges_2d + [edges_2d[-1],edges_2d[0]]
					
						var i1 = edge[0] + Vector2(randf()/100,randf()/100)
						var i2 = edge[1] + Vector2(randf()/100,randf()/100)
						var im = (i2.y - i1.y)/(i2.x - i1.x)
						if abs(em - im) >.001:
							var intersection_x = (-i1.y + e1.y -e1.x*em + i1.x*im)/(im - em)
							#print("intersection x is",intersection_x)
							var intersection_y = im*(intersection_x - i1.x) + i1.y
							#print("intersection y is ",intersection_y)
							var intercept = Vector2(intersection_x,intersection_y)
							
							
							if (i1.x < intercept.x and intercept.x < i2.x) or (i2.x < intercept.x and intercept.x < i1.x):
								# check for ccw because that will only happen if the intersection is between 
								# using algorithm from bryce boe
								
								var mark = ColorRect.new()
								mark.size = Vector2(5,5)
								mark.color = Color("green")
								mark.position = intercept
								add_child(mark)
								# add intercepts to lastPoint_positions
								last_intersections.push_back(intercept)
								
						else:
							#print("this edge is too parallel to one of the cardinal directions")
							continue

var prev: Node3D = null
var edges = []
var dist_threshold = 1
var last_intersections = []
var all_vertx: Array[Vector3] = []
var triangle_vertices=[]
var hovered_element


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
				new_vert.vertexhovered.connect(vert_was_hovered)
				add_child(new_vert)

				# this just makes sure we have a list of the edges
				all_vertx.push_back(col_pos)
				if not innerButton.is_pressed():
					if prev:
						edges.push_back([prev,new_vert])
						prev = new_vert
					else:
						prev = new_vert
				if innerButton.is_pressed():
					# how can we make sure the right point relations get made?
					# intersections will all be 2d so we need to add a third value
					var cam: Camera3D = get_viewport().get_camera_3d()
					var depth=20
					for intersect in last_intersections:
					   
						# do a physics calculation of intersection of new ray 
						var space_state = get_world_3d().direct_space_state
						   # use global coordinates, not local to node
						var from = cam.project_ray_origin(intersect)
						var rect = get_viewport().get_visible_rect()
						var to = cam.project_ray_normal(intersect)*depth + from
						#var to = Vector3(0,0,-20)
						var query = PhysicsRayQueryParameters3D.create(from,to)
						query.collide_with_areas =true
						query.collide_with_bodies=false
						var result = space_state.intersect_ray(query)
						var intersect_3d = result["position"]
					   
						var too_close = false
						# check whether or not the intersection is too close to a pre-existing point
						for overt in all_vertx:
							if overt.distance_to(intersect_3d) < dist_threshold:
								too_close = true
								break
						if too_close:
							continue
						var new_intersect_vert = vert3d.instantiate()
						new_intersect_vert.vertexhovered.connect(vert_was_hovered)
						new_intersect_vert.position = intersect_3d
						add_child(new_intersect_vert)
						all_vertx.push_back(intersect_3d)
						
		elif e.pressed and hovered_element and tri_button.is_pressed():
			# turn the hovered_element on for it's triangle 
			hovered_element.tri_clicked()
			triangle_vertices.push_back(hovered_element)
			print("tri verts are ", triangle_vertices)
			if triangle_vertices.size()==3:
				create_colored_geometry(triangle_vertices)
				_on_clear_pressed()
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


func _on_clear_pressed() -> void:
	#clear the triangle list
	for v in triangle_vertices:
		# turn off their selection colors
		v.tri_cleared()
	triangle_vertices = []
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
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh.surface_set_material(0,mat)
			m.mesh = mesh
			
			
