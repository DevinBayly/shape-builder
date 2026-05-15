extends Node2D
var vert = preload("res://vertex.tscn")
@onready var poly: Polygon2D = $Polygon2D
@onready var innerButton: Button = $Button
var viewsize
func _ready() -> void:
	print(poly.texture.get_size())
	viewsize = get_viewport_rect().size
	
	
	
var prev: Node2D = null
var edges = []

var last_intersections = []
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			# create a vertex
			var new_vert = vert.instantiate()
			new_vert.position = event.position
			add_child(new_vert)
			if prev:
				edges.push_back([prev,new_vert])
				prev = new_vert
			else:
				prev = new_vert
			if innerButton.is_pressed():
				# how can we make sure the right point relations get made?
				for intersect in last_intersections:
					var new_intersect_vert = vert.instantiate()
					new_intersect_vert.position = intersect
					add_child(new_intersect_vert)
					
	if event is InputEventMouseMotion and innerButton.is_pressed():
		last_intersections=[]
		if edges.size() > 1:
			print()
			# check intersections of all the edges in cardinal directions from the point on the screen
			# make a vector at this current position,
			var directions = [[200,0.01],[0.01,200],[-200,0.01],[0.01,-200]]
			#var directions = [[0.01,200]]
			var closed =  edges + [
				[edges[-1][1],edges[0][0]]
			]
			for edge in closed:
				for dir in directions: 
					var e2 = event.position +Vector2(randf()/100,randf()/100)
					var e1 = Vector2(e2.x + dir[0],e2.y +dir[1]) +  Vector2(randf()/100,randf()/100)
					# note that for some of these values the denominator will be 0
					var em = (e2.y - e1.y)/(e2.x - e1.x)
					# go over the other edges and see if
					# include the final edge of last to first
					
					#var closed_edges = edges + [edges[-1],edges[0]]
				
					var i1 = edge[0].position + Vector2(randf()/100,randf()/100)
					var i2 = edge[1].position + Vector2(randf()/100,randf()/100)
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
					
		
