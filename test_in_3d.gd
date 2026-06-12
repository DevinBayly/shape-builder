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
		print()
		limiter = limiter_restart
		#print("collision is ",col)
		intersector.position = col_pos
	

		# if we have a
		# NOTE need to come up with a check to make sure motion has occurred
		if innerButton.is_pressed():
			last_intersections=[]
			last_intersections_uvs = []
			if edges.size() > 1:
				var edges_2d= []
				var cam = get_viewport().get_camera_3d()
				var col_pos_2d = cam.unproject_position(col_pos)
				for e in edges:
					var start = e[0]
					var end = e[1]
					start.unprojectedPosition = cam.unproject_position(start.position)
					end.unprojectedPosition = cam.unproject_position(end.position)
				# check intersections of all the edges in cardinal directions from the point on the screen
				# make a vector at this current position,
				var directions = [[200,0.01],[0.01,200],[-200,0.01],[0.01,-200]]
				#var directions = [[0.01,200]]
				var closed =  edges + [
					[edges[-1][1],edges[0][0]]
				]
				# NOTE I'm adding in a part that stops searching edge for more intersections after one passes
				# this will have the pairs of intersections that help us figure out what the uv coords should be for the point added in
				# structure will be [[vertical],[horizontal]] 
				# horizontal will be left to right
				# vertical top to bottom 
				for edge in closed:
					print(edge)
					for dir in directions: 
						var e2 = col_pos_2d +Vector2(randf()/100,randf()/100)
						var e1 = Vector2(e2.x + dir[0],e2.y +dir[1]) +  Vector2(randf()/100,randf()/100)
						# note that for some of these values the denominator will be 0
						var em = (e2.y - e1.y)/(e2.x - e1.x)
						# go over the other edges_2d and see if
						# include the final edge of last to first
						
					
						var i1 = edge[0].unprojectedPosition + Vector2(randf()/100,randf()/100)
						var i2 = edge[1].unprojectedPosition + Vector2(randf()/100,randf()/100)
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
								print(edge,dir)
								# use start and end points of edge to figure out in normalized coords how far along the intersection the new point is
								var start = edge[0].unprojectedPosition
								var end = edge[1].unprojectedPosition
								var edgeDelta = end-start
								var partial_delta = intercept - start
								var ratio = partial_delta.length()/edgeDelta.length()
								# work out the mixture between start and end uv to assign
								var new_uv = edge[0].uv + ratio * (edge[1].uv - edge[0].uv)  
								last_intersections_uvs.push_back(new_uv)
								break
						else:
							#print("this edge is too parallel to one of the cardinal directions")
							continue
			print(last_intersections,last_intersections_uvs)

var prev: Node3D = null
var corners = []
var edges = []
var dist_threshold = 1
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
				calc_center()
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
					var i = 0
					var horizontal_intersections = []
					var vertical_intersections = []
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
						new_intersect_vert.uv = last_intersections_uvs[i]
						new_intersect_vert.vertexhovered.connect(vert_was_hovered)
						new_intersect_vert.position = intersect_3d
						new_intersect_vert.unprojectedPosition = intersect
						add_child(new_intersect_vert)
						all_vertx.push_back(intersect_3d)
						i+=1
						# compare with new vert to help give it the right UV coords
						var dif =  new_intersect_vert.position -  new_vert.position 
						if abs(dif.x ) > abs(dif.y):
							# point is located horizontally out from the inner new vert
							if dif.x >0:
								# point is to the right
								horizontal_intersections.push_back(new_intersect_vert)
							else:
								# point is to the left
								horizontal_intersections.push_front(new_intersect_vert)
						else:
							if dif.y>0:
								# point is below
								vertical_intersections.push_back(new_intersect_vert)
							else:
								# point is above
								vertical_intersections.push_front(new_intersect_vert)
							# means intersection is below 
					# now we can interpolate a uv for the new vert in the middle
					# we do have to use 2d projections of the points though
					new_vert.unprojectedPosition = cam.unproject_position(new_vert.position)
					var horizontal_delta = horizontal_intersections[1].unprojectedPosition-horizontal_intersections[0].unprojectedPosition
					var partial_horizontal = new_vert.unprojectedPosition - horizontal_intersections[0].unprojectedPosition
					var horizontal_ratio = partial_horizontal.length()/horizontal_delta.length()
					# calculate amount of u coordinate to give to new vert
					var v = horizontal_intersections[0].uv.y + horizontal_ratio*(horizontal_intersections[1].uv.y - horizontal_intersections[0].uv.y)
					
					
					var vertical_delta = vertical_intersections[1].unprojectedPosition-vertical_intersections[0].unprojectedPosition
					var partial_vertical = new_vert.unprojectedPosition - vertical_intersections[0].unprojectedPosition
					var vertical_ratio = partial_vertical.length()/vertical_delta.length()
					# calculate amount of u coordinate to give to new vert
					var u = vertical_intersections[0].uv.x + vertical_ratio*(vertical_intersections[1].uv.x - vertical_intersections[0].uv.x)
					new_vert.uv = Vector2(u,v)
					
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
