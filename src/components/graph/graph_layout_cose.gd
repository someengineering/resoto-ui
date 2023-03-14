extends Node
class_name GraphLayoutAlgorithmCose

# The original CoSE layout was written by Gerardo Huck.
# https:#www.linkedin.com/in/gerardohuck/
# Modified for GDScript

# Based on the following article:
# http://dl.acm.org/citation.cfm?id=1498047

const GraphLayoutNodeScene = preload("res://components/graph/Elements/GraphNode.tscn")
const GraphLayoutEdgeScene = preload("res://components/graph/Elements/GraphEdge.tscn")

var graph_parent:Node			= null
var graph_navigator:Node		= null
var parent:Node					= null
var animate:bool				= false
var fit_to_view:bool			= false
var fit_to_view_padding:float	= 30.0
var node_padding:float			= 10.0
var randomize_initial_pos:bool	= false
var node_repulsion:float		= 450.0
var node_overlap:float			= 800.0
var max_iterations:int			= 1000
var total_offset:float			= 10000.0
var stopped:bool				= false

var main_node_id:String			= ""

var edges:Array
var nodes:Dictionary
var layout_info:Dictionary

var graph_base:Node2D = Node2D.new()

var options:Dictionary = {
	"gravity" : 0.0,
	"initialTemp" : 100,
	"bounding_box" : Vector2(400,400),
	"idealEdgeLength" : 200.0,
	"edgeElasticity" : 1.1,
	"nestingFactor" : 0.1,
	"coolingFactor" : 0.99,
	"minTemp" : 1.0
	}


class GraphLayoutInfo:
	var temparature:float
	var client_size:Vector2
	var bounding_box:Rect2
	var node_size:int
	var edge_size:int
	var layout_nodes:Array		= []
	var id_to_index:Dictionary	= {}
	var graph_set:Array			= []


func layout_loop():
	step(layout_info, options)
	layout_info.temperature = layout_info.temperature * options.coolingFactor
	if layout_info.temperature < options.minTemp or total_offset < 10000:
		return false
	return true


func end():
	# Update edge lines
	update_edge_lines(layout_info)


func create_graph_nodes(_parent:Node, _nodes, _edges):
	parent = _parent
	graph_base.name = "GraphBase"
	parent.add_child(graph_base)
	layout_info = create_layout_info(_nodes, _edges)
	if randomize_initial_pos:
		randomize_positions(layout_info)
		update_positions(layout_info, options)
		# Update edge lines
		update_edge_lines(layout_info)


func remove_all():
	graph_base.queue_free()
	queue_free()


func create_layout_info(_nodes:Dictionary, _edges:Array):
	edges = _edges
	nodes = _nodes
	
	var new_layout_info:Dictionary = {
	"is_compound": false,
	"layout_nodes": [],
	"id_to_index": {},
	"node_size": nodes.size(),
	"graph_set": [],
	"index_to_graph": [],
	"layout_edges": [],
	"edge_size": edges.size(),
	"temperature": options.initialTemp,
	"client_size": Vector2(400,400),
	"boundingBox": Rect2(0, 0, 400, 400)
	}
	
	new_layout_info.bounding_box = Rect2(Vector2.ZERO, Vector2(400,400))
	new_layout_info.temparature = options.initialTemp
	new_layout_info.client_size = Vector2(1000, 600)
	new_layout_info.node_size = nodes.size()
	new_layout_info.edge_size = edges.size()
	
	var g:int = 0
	for node_id in nodes.keys():
		var temp_node = GraphLayoutNodeScene.instance()
		temp_node.id = node_id
		temp_node.node_id = nodes[node_id].id
		if temp_node.node_id == main_node_id:
			temp_node.node_display_mode = temp_node.Mode.ROOT
		temp_node.parent_id = ""
		if node_id=="root":
			temp_node.is_locked = true
		temp_node.metadata = nodes[node_id]
		temp_node.padding = Vector2(node_padding, node_padding)
		temp_node.node_repulsion = node_repulsion
		temp_node.connect("node_clicked", graph_parent, "on_node_clicked")
		graph_navigator.connect("change_zoom", temp_node, "on_change_zoom")
		
		
		graph_base.add_child(temp_node)
		new_layout_info.id_to_index[node_id] = g
		new_layout_info.layout_nodes.append(temp_node)
		g += 1

	# Inline implementation of a queue, used for traversing the graph in BFS order
	var queue:Array = []
	var start = 0   # Points to the start the queue
	var end   = -1  # Points to the end of the queue
	var tempGraph = []

	# Second pass to add child information and
	# initialize queue for hierarchical traversal
	for i in new_layout_info.node_size:
		var n = new_layout_info.layout_nodes[ i ]
		var p_id = n.parent_id
		# Check if node n has a parent node
		if p_id != "":
			# Add node Id to parent's list of children
			new_layout_info.layout_nodes[ new_layout_info.id_to_index[ p_id ] ].children.append( n.id )
		else:
			# If a node doesn't have a parent, then it's in the root graph
			end += 1
			if queue.size() >= end+1:
				queue[ end ] = n.id
			else:
				queue.append(n.id)
			tempGraph.append( n.id )
	
	 # Add root graph to graphSet
	new_layout_info.graph_set.append( tempGraph )

	# Traverse the graph, level by level,
	while start <= end:
		# Get the node to visit and remove it from queue
		var node_id  = queue[ start ]
		start += 1
		var node_ix  = new_layout_info.id_to_index[ node_id ]
		var node     = new_layout_info.layout_nodes[ node_ix ]
		var children = node.children
		if not children.empty():	
			# Add children nodes as a new graph to graph set
			new_layout_info.graph_set.append( children )
			# Add children to que queue to be visited
			for i in children.size():
				end += 1
				queue[ end ] = children[ i ]


	# Create indexToGraph map
	for i in new_layout_info.graph_set.size():
		var graph = new_layout_info.graph_set[ i ]
		for j in graph.size():
			var index = new_layout_info.id_to_index[ graph[ j ] ]
			if new_layout_info.index_to_graph.size() >= index+1:
				new_layout_info.index_to_graph[ index ] = i
			else:
				new_layout_info.index_to_graph.append(i)


	# Iterate over all edges, creating Layout Edges
	for i in new_layout_info.edge_size:
		var e = edges[ i ];
		var tempEdge = GraphLayoutEdgeScene.instance()
		tempEdge.id = e.from+"##to##"+e.to
		tempEdge.source_id = e.from
		if tempEdge.source_id == main_node_id:
			tempEdge.edge_display_mode = tempEdge.Mode.OUTBOUND
		tempEdge.target_id = e.to
		graph_base.add_child(tempEdge)

		# Compute ideal length
		var idealLength = options.idealEdgeLength
		var elasticity = options.edgeElasticity

		# Check if it's an inter graph edge
		var sourceIx    = new_layout_info.id_to_index[ tempEdge.source_id ]
		var targetIx    = new_layout_info.id_to_index[ tempEdge.target_id ]
		var sourceGraph = new_layout_info.index_to_graph[ sourceIx ]
		var targetGraph = new_layout_info.index_to_graph[ targetIx ]

		if sourceGraph != targetGraph:
			# Find lowest common graph ancestor
			var lca = find_lca( tempEdge.source_id, tempEdge.target_id, new_layout_info )

			# Compute sum of node depths, relative to lca graph
			var lcaGraph = new_layout_info.graph_set[ lca ]
			var depth    = 0

			# Source depth
			var tempNode = new_layout_info.layout_nodes[ sourceIx ]
			while lcaGraph.find( tempNode.id ) == -1:
				tempNode = new_layout_info.layout_nodes[ new_layout_info.id_to_index[ tempNode.parent_id ] ]
				depth += 1

			# Target depth
			tempNode = new_layout_info.layout_nodes[ targetIx ]
			while( lcaGraph.find( tempNode.id ) == -1 ):
				tempNode = new_layout_info.layout_nodes[ new_layout_info.id_to_index[ tempNode.parent_id ] ]
				depth += 1

			# Update idealLength
			
			idealLength *= depth * options.nestingFactor
		tempEdge.ideal_length = idealLength
		tempEdge.elasticity = elasticity

		new_layout_info.layout_edges.append( tempEdge )
	
	return new_layout_info


###
# @brief :	This function finds the index of the lowest common
# 			graph ancestor between 2 nodes in the subtree
#			(from the graph hierarchy induced tree) whose
#			root is graphIx
###
func find_lca(node1, node2, _layout_info):
	# Find their common ancester, starting from the root graph
	var res = find_lca_aux( node1, node2, 0, _layout_info )
	if 2 > res.count:
		# If aux function couldn't find the common ancester,
		# then it is the root graph
		return 0
	else:
		return res.graph


###
# @brief          : Auxiliary function used for LCA computation
#
# @arg node1      : node1's ID
# @arg node2      : node2's ID
# @arg graphIx    : subgraph index
# @arg layoutInfo : layoutInfo object
#
# @return         : object of the form {count: X, graph: Y}, where:
#                   X is the number of ancesters (max: 2) found in
#                   graphIx (and it's subgraphs),
#                   Y is the graph index of the lowest graph containing
#                   all X nodes
###
func find_lca_aux( node1, node2, graphIx, _layout_info ):
	var graph = _layout_info.graph_set[ graphIx ]
	# If both nodes belongs to graphIx
	if( -1 < graph.find( node1 ) and -1 < graph.find( node2 ) ):
		return {"count": 2, "graph": graphIx}

  # Make recursive calls for all subgraphs
	var c = 0
	for i in graph.size():
		var nodeId   = graph[ i ];
		var nodeIx   = _layout_info.id_to_index[ nodeId ]
		var children = _layout_info.layout_nodes[ nodeIx ].children

		# If the node has no child, skip it
		if children.empty():
			continue

		var childGraphIx = _layout_info.index_to_graph[ _layout_info.id_to_index[ children[0] ] ]
		var result = find_lca_aux( node1, node2, childGraphIx, _layout_info )
		if( 0 == result.count ):
			# Neither node1 nor node2 are present in this subgraph
			continue
		elif( 1 == result.count ):
			# One of (node1, node2) is present in this subgraph
			c += 1
			if( 2 == c ):
				# We've already found both nodes, no need to keep searching
				break
		else:
			# Both nodes are present in this subgraph
			return result

  return {"count": c, "graph": graphIx}


###
# @brief          : Performs one iteration of the physical simulation
# @arg layoutInfo : LayoutInfo object already initialized
# @arg cy         : Cytoscape object
# @arg options    : Layout options
###
func step(_layout_info, _options):
	# Calculate node repulsions
	calculate_node_forces(_layout_info, _options)
	# Calculate edge forces
	calculate_edge_forces(_layout_info, _options)
	# Calculate gravity forces
	calculate_gravity_forces(_layout_info, _options)
	# Propagate forces from parent to child
	propagate_forces(_layout_info, _options)
	# Update positions based on calculated forces
	quick_update_positions(_layout_info)


###
# @brief : Computes the node repulsion forces
###
func calculate_node_forces(_layout_info, _options):
	# Go through each of the graphs in graphSet
	# Nodes only repel each other if they belong to the same graph
	for i in _layout_info.graph_set.size():
		var graph = _layout_info.graph_set[i]
		var num_nodes = graph.size()
		
		# Now get all the pairs of nodes
		# Only get each pair once, (A, B) = (B, A)
		for j in num_nodes:
			var node1 = _layout_info.layout_nodes[_layout_info.id_to_index[graph[j]]]
			var _k = j + 1
			while _k < num_nodes:
				var node2 = _layout_info.layout_nodes[_layout_info.id_to_index[graph[_k]]]
				node_repulsion(node1, node2, _layout_info, _options)
				_k += 1


###
# @brief : Calculates all edge forces
###
func calculate_edge_forces(_layout_info, _options):
	# Iterate over all edges
	for i in _layout_info.edge_size:
		# Get edge, source & target nodes
		var edge     = _layout_info.layout_edges[ i ]
		var sourceIx = _layout_info.id_to_index[ edge.source_id ]
		var source   = _layout_info.layout_nodes[ sourceIx ]
		var targetIx = _layout_info.id_to_index[ edge.target_id ]
		var target   = _layout_info.layout_nodes[ targetIx ]

		# Get direction of line connecting both node centers
		var direction = target.position - source.position

		# If both centers are the same, do nothing.
		# A random force has already been applied as node repulsion
		if direction.length() == 0:
			continue

		# Get clipping points for both nodes
		var point1 = find_clipping_point( source, direction )
		var point2 = find_clipping_point( target, -direction )
		
		var l_v = point2 - point1
		var l = point2.distance_to(point1)
		var force  = pow( edge.ideal_length - l, 2 ) / edge.elasticity
		var force_vector:Vector2 = Vector2.ZERO
		
		if l != 0:
			force_vector = force * l_v / l
		
		# Add this force to target and source nodes
		if not source.is_locked:
			source.offset += force_vector

		if not target.is_locked:
			target.offset -= force_vector

###
# @brief : Computes gravity forces for all nodes
###
func calculate_gravity_forces(_layout_info, _options):
	if _options.gravity == 0:
		return
	
	var dist_threshold = 1.0

	for i in _layout_info.graph_set.size():
		var graph = _layout_info.graph_set[i]
		var num_nodes = graph.size()
		
		var center:Vector2 = Vector2.ZERO
		# Compute graph center
		if i == 0:
			center = _layout_info.client_size / 2.0
		else:
		  # Get Parent node for this graph, and use its position as center
		  var temp = _layout_info.layout_nodes[ _layout_info.id_to_index[ graph[0] ] ]
		  var parent = _layout_info.layout_nodes[ _layout_info.id_to_index[ temp.parent_id ] ]
		  center = parent.position

		# Apply force to all nodes in graph
		for j in num_nodes:
			var node = _layout_info.layout_nodes[ _layout_info.id_to_index[ graph[j] ] ]

			if node.is_locked:
				continue

			var dir_vector:Vector2 = center - node.position
			var d  = dir_vector.length()
			if d > dist_threshold:
				var f = _options.gravity * dir_vector / d
				node.offset += f

###
# @brief          : This function propagates the existing offsets from parent nodes to its descendents.
# @arg layoutInfo : layoutInfo Object
# @arg cy         : cytoscape Object
# @arg options    : Layout options
###
func propagate_forces(_layout_info, _options):
	# Inline implementation of a queue, used for traversing the graph in BFS order
	var queue:Array = _layout_info.graph_set[0]
	var start:int = 0 # Points to the start the queue
	var end:int = -1 # Points to the end of the queue

	# Start by visiting the nodes in the root graph
	end += _layout_info.graph_set[0].size()

	# Traverse the graph, level by level,
	while start <= end:
		# Get the node to visit and remove it from queue
		var nodeId    = queue[ start ]
		start += 1
		var nodeIndex = _layout_info.id_to_index[ nodeId ]
		var node      = _layout_info.layout_nodes[ nodeIndex ]
		var children  = node.children
		
		# We only need to process the node if it's compound
		if 0 < children.size() and not node.is_locked:
			var off = node.offset

			for i in children.size():
				var child_node = _layout_info.layoutNodes[ _layout_info.idToIndex[ children[ i ] ] ];
				# Propagate offset
				child_node.offset += off
				# Add children to queue to be visited
				end += 1
				queue[end] = children[i]

			# Reset parent offsets
			node.offset = Vector2.ZERO


func quick_update_positions(_layout_info):
	total_offset = 0.0
	for i in _layout_info.node_size:
		var n = _layout_info.layout_nodes[ i ]
		if 0 < n.children.size() or n.is_locked:
			continue
		# Limit displacement in order to improve stability
		var temp_force:Vector2 = n.offset.limit_length(_layout_info.temperature)
		n.position += temp_force
		total_offset += n.offset.length()
		n.offset = Vector2.ZERO


###
# @brief : Updates the layout model positions, based on the accumulated forces
###
func update_positions(_layout_info, _options):
	# Reset boundaries for compound nodes
	for i in _layout_info.node_size:
		var n = _layout_info.layout_nodes[ i ]
		if 0 < n.children.size():
			n.max_x = null
			n.min_x = null
			n.max_y = null
			n.min_y = null

	for i in _layout_info.node_size:
		var n = _layout_info.layout_nodes[ i ]
		if 0 < n.children.size() or n.is_locked:
			continue
		
		# Limit displacement in order to improve stability
		var temp_force:Vector2 = n.offset.limit_length(_layout_info.temperature)
		n.position += temp_force
		n.offset = Vector2.ZERO
		n.min_x    = n.position.x - n.size.x
		n.max_x    = n.position.x + n.size.x
		n.min_y    = n.position.y - n.size.y
		n.max_y    = n.position.y + n.size.y

		# Update ancestry boudaries
		update_ancestry_boundaries( n, _layout_info );

	# Update size, position of compund nodes
	for i in _layout_info.node_size:
		var n = _layout_info.layout_nodes[ i ]
		if 0 < n.children.size() and not n.is_locked:
			n.position.x = (n.max_x + n.min_x) / 2.0
			n.position.y = (n.max_y + n.min_y) / 2.0
			n.size = Vector2(n.max_x - n.min_x, n.max_y - n.min_y)


func update_edge_lines(_layout_info):
	for layout_edge in _layout_info.layout_edges:
		var from = _layout_info.layout_nodes[_layout_info.id_to_index[layout_edge.source_id]]
		var to = _layout_info.layout_nodes[_layout_info.id_to_index[layout_edge.target_id]]
		layout_edge.update_line(from.position, to.position)

###
# @brief : Function used for keeping track of compound node sizes, since they should bound all their subnodes.
###
func update_ancestry_boundaries(_node, _layout_info):
	var parentId = _node.parent_id
	if parentId == null or parentId == "":
		return

	# Get Parent Node
	var p = _layout_info.layout_nodes[ _layout_info.id_to_index[ parentId ] ]
	var flag = false

	# MaxX
#	if( null == p.maxX || _node.maxX + p.padRight > p.maxX ){
	if p.max_x == null or _node.max_x + p.padding.x > p.max_x:
		p.max.x = _node.max_x + p.padding.x
		flag = true

	# MinX
	if p.min_x == null or _node.min_x - p.padding.x < p.min_x:
		p.min_x = _node.min_x - p.padding.x
		flag = true

	# MaxY
	if p.max_y == null or _node.max_y + p.padding.y > p.max_y:
		p.max_y = _node.max_y + p.padding.y
		flag = true

	# MinY
	if p.min_y == null or _node.min_y - p.padding.y < p.min_y:
		p.min_y = _node.min_y - p.padding.y
		flag = true

	# If updated boundaries, propagate changes upward
	if flag:
		return update_ancestry_boundaries( p, _layout_info )

	return


###
# @brief : Compute the node repulsion forces between a pair of nodes
###
func node_repulsion(node1, node2, _layout_info, _options):
	# Get direction of line connecting both node centers
	var direction = node2.position - node1.position
	var dir_to = node2.position.direction_to(node1.position)
	var dist_to = node2.position.distance_to(node1.position)
	var max_rand_dist = 1.0
	
	# If nodes are too close, apply a random force
	
	if dist_to < 0.1:
		direction = Vector2(random_distance(max_rand_dist), random_distance(max_rand_dist))
	
	var overlap = nodes_overlap(node1, node2, direction)
	var force_vector = Vector2.ZERO
	
	if overlap > 0:
		# If nodes overlap, repulsion force is proportional to the overlap
		var force = node_overlap * overlap
		# Compute the module and components of the force vector
		var distance = direction.length()
		force_vector = (force * direction / distance)
	else:
		# If there's no overlap, force is inversely proportional to squared distance
		# Get clipping points for both nodes
		var point1 = find_clipping_point( node1, direction )
		var point2 = find_clipping_point( node2, -direction )
		
		# Use clipping points to compute distance
		var distance = point2.distance_to(point1)
		
		# Compute the module and components of the force vector
		var force  = ( node1.node_repulsion + node2.node_repulsion ) / point2.distance_squared_to(point1)
		force_vector = force * direction / distance
	
	# Apply force
	if not node1.is_locked:
		node1.offset -= force_vector# * direction

	if not node2.is_locked:
		node2.offset += force_vector# * direction


func random_distance(max_rand_dist:float):
	return -max_rand_dist + 2.0 * max_rand_dist * randf()


func find_clipping_point( node, dir ):
	if dir.x == 0 or dir.y == 0:
		dir += Vector2(0.1,0.1)
	var x = node.position.x
	var y = node.position.y
	var h = min(node.size.y, 1)
	var w = min(node.size.x, 1)
	var dir_slope     = dir.y / dir.x
	var node_slope    = h / w
	
	# Compute intersection
	var res:Vector2 = Vector2.ZERO
	
	# Case: Vertical direction (up)
	if dir.x == 0 and dir.y > 0:
		res.x = x
		res.y = y + h / 2.0
		return res
	
	# Case: Vertical direction (down)
	if dir.x == 0 and dir.y < 0:
		res.x = x
		res.y = y + h / 2.0
		return res
	
	# Case: Intersects the right border
	if (0 < dir.x
	and -node_slope <= dir_slope
	and dir_slope <= node_slope):
		res.x = x + w / 2
		res.y = y + (w * dir.y / 2.0 / dir.x)
		return res

	# Case: Intersects the left border
	if (0 > dir.x
	and -node_slope <= dir_slope
	and dir_slope <= node_slope ):
		res.x = x - w / 2.0
		res.y = y - (w * dir.y / 2.0 / dir.x)
		return res

  # Case: Intersects the top border
	if (0 < dir.y
	and ( dir_slope <= -1 * node_slope or dir_slope >= node_slope )):
		res.x = x + (h * dir.x / 2.0 / dir.y)
		res.y = y + h / 2.0
		return res

  # Case: Intersects the bottom border
	if( 0 > dir.y
	and ( dir_slope <= -1 * node_slope or dir_slope >= node_slope )):
		res.x = x - (h * dir.x / 2.0 / dir.y)
		res.y = y - h / 2.0
		return res
	
	return res


###
# @brief : Randomizes the position of all nodes
###
func randomize_positions(_layout_info):
	var width	= _layout_info.client_size.x;
	var height	= _layout_info.client_size.y;
	
	for i in _layout_info.node_size:
		var n = _layout_info.layout_nodes[i]
		
		# No need to randomize compound nodes or locked nodes
		if n.children.empty() and not n.is_locked:
			n.position = Vector2(rand_range(-width, width), rand_range(-height, height))


###
# @brief  : Determines whether two nodes overlap or not
# @return : Amount of overlapping (0.0 => no overlap)
###
func nodes_overlap(node1, node2, direction) -> float:
	var dist = node1.position.distance_to(node2.position)
	var safe_dist = 300.0
	if dist > safe_dist:
		return 0.0
	var overlap = abs(safe_dist-min(dist, safe_dist))
	return overlap
	
