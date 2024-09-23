extends Node2D

@export var speed = 0
@export var keep_child_rotation = true
@export var angle_total = 2*PI
@export var angle_decal = 0
@export var iterations = -1
@export_enum("LoopFromStart", "GoBack") var when_end_reached:String = "LoopFromStart"

@export_group("Flipping")
@export_flags("H", "V") var use_flipping = 00
@export var flipping_angles:Vector2
@export var use_flip_when_possible = true

@export_group("Children Options")
@export var remote_children:Array[NodePath]
@export var allow_adding:bool = false
@export var disabled_children:Array[NodePath]
@export var allow_removing:bool = false

@export_group("Tweening")
enum EASING{None, TRANS_LINEAR,TRANS_SINE,TRANS_QUINT,TRANS_QUART,TRANS_QUAD,TRANS_EXPO,TRANS_ELASTIC,TRANS_CUBIC, \
			TRANS_CIRC,TRANS_BOUNCE,TRANS_BACK}
@export var easing:EASING = EASING.None


## TODO add
# add save pos and reset

## var init
@onready var tween
var init_pos:Dictionary = {}
var init_rot:Dictionary = {}
var remote_nodes:Array[Node]
var disabled_nodes:Array[Node]
var valid_children:Array[Node]
var all_children:Array

## state variables
var start_angle:float
var end_angle:float
var dir = 1
var iter_left = -1


func _ready():
	start_angle = angle_decal
	end_angle = start_angle + angle_total
	iter_left = iterations
	
	for node in remote_children:
		remote_nodes.append(get_node(node))
	for node in disabled_children:
		disabled_nodes.append(get_node(node))
	compute_valid_children()
	all_children = remote_nodes+valid_children
	for node in all_children+disabled_nodes:
		init_pos[node] = node.global_position
		init_rot[node] = node.rotation

func compute_valid_children():
	valid_children.clear()
	for node in get_children():
		if node in disabled_nodes: continue
		valid_children.append(node)

func _physics_process(delta):
	if speed == 0: return
	
	if easing == EASING.None: rotate(speed*delta*dir)
	else: setup_tween()
	
	for node in remote_nodes:
		node.global_position = global_position + (global_position-init_pos[node]).rotated(rotation)
	for node in disabled_nodes:
		node.global_position = init_pos[node]
		node.rotation = -(rotation + init_rot[node])
	if allow_removing: compute_valid_children()
	if allow_adding: all_children = valid_children+remote_nodes
	
	if keep_child_rotation:
		for node in valid_children:
			node.rotation = -(rotation + init_rot[node])
	else:
		for node in remote_nodes:
			node.rotation = (rotation + init_rot[node])
	
	if use_flipping > 0:
		var vect:float
		for node in all_children:
			vect = global_position.angle_to_point(node.global_position)
			match use_flipping:
				1: flip_node(node, vect > flipping_angles.x and vect < flipping_angles.x+PI, false)
				2: flip_node(node, false, vect > flipping_angles.x and vect < flipping_angles.x+PI)
				3: flip_node(node, vect > flipping_angles.x and vect < flipping_angles.x+PI,
									vect > flipping_angles.y and vect < flipping_angles.y+PI)
	
	if rotation > end_angle: reached_end()
	if rotation < start_angle and dir == -1: reached_end()


func reached_end():
	iter_left -= 1
	if iterations == 0: return

	match when_end_reached:
		"LoopFromStart": rotation = start_angle
		"GoBack": dir *= -1
#		"GobackOnce":
#			dir *= -1
#			when_end_reached = "LoopFromStart"
#			start_angle = end_angle
#			end_angle = angle_decal

func setup_tween():
	if tween == null:
		tween = create_tween()
		tween.tween_property(self, "rotation", end_angle, (end_angle-rotation)/speed).set_trans(easing)
	if tween != null and not tween.is_running():
		tween.stop()
		tween.tween_property(self, "rotation", end_angle, (end_angle-rotation)/speed).set_trans(easing)
		tween.play()

func flip_node(node, flip_h, flip_v):
	if use_flip_when_possible and node.get("flip_h") != null:
		node.flip_h = flip_h
		node.flip_v = flip_v
	else:
		node.scale.x = abs(node.scale.x)*[1,-1][int(flip_h)]
		node.scale.y = abs(node.scale.y)*[1,-1][int(flip_v)]

