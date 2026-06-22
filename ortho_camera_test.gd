extends Node3D
@onready var cam = $Camera3D
func custom_sort(a,b):
	if a[1]>b[1]:
		return a
func _ready() -> void:
	# get the min and max of all the verts
	var verts = get_tree().get_nodes_in_group("verts")
	
		
	# calculate the center, move the camera to this spot
	var centroid = Vector3(0,0,0)
	# get the corners by finding the 4 verts that are furthest from the center
	var distances = []
	
	for v in verts:
		centroid +=v.position
	centroid/=verts.size()
	for v in verts:
		var dif = v.position - centroid
		distances.push_back([v,dif.length()])
	distances.sort_custom(custom_sort)
	# get 3 of the verts and get 2 vectors (center, get vectors going out to each frmo center) 
	var corners = []
	for c in distances.slice(0,4):
		corners.push_back(c[0])
	
	# go through the corner options and figure out which combo gives biggest
	var c1
	var c2
	var max = 0
	for v in corners:
		for vo in corners:
			if v == vo:
				continue
			if (v.position - vo.position).length() > max:
				c1 = v
				c2 = vo
				max = (v.position - vo.position).length()
	var center = (c2.position - c1.position)/2 + c1.position
	var v1 = corners[0].position - center
	var v2 =  corners[1].position - center
	
	
	# get normal from cross product
	var v3 = v1.cross(v2)
	#v3.z*=-1
	#if v3.z<0:
		#v3.z*=-1
	#v3*=-1
	print(v1,v2,v3)
		 
	
	
	# LATER use normal to move the camera out in the direction of the player
	cam.position = center + v3
	# figure out the vector that goes in the min to max direction, use the length of this to determine the size of the camera view
	# get the furthest distance point, and set it as the size
	cam.size = distances[0][1]
	cam.look_at(center)
	
	
