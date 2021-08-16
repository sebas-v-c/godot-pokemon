extends KinematicBody2D


export var walk_speed = 4.0
const TILE_SIZE = 16

onready var anim_tree = $AnimationTree
onready var anim_state = anim_tree.get("parameters/playback")

var initial_position = Vector2(0, 0)
var input_direction = Vector2(0, 0)
var is_moving = false
# This variable is more like a product between two numbers that results in less
# tan one. So it is used to multiply by the tile size and produce movement.
var percent_moved_to_next_tile = 0.0


func _ready():
	initial_position = position


func _physics_process(delta):
	if not is_moving:
		process_player_input()
	elif input_direction != Vector2.ZERO:
		move(delta)
		anim_state.travel("Walk")
	else:
		anim_state.travel("Idle")
		is_moving = false


func process_player_input() -> void:
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		
	if input_direction != Vector2.ZERO:
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Walk/blend_position", input_direction)
		initial_position = position
		is_moving = true
	else:
		anim_state.travel("Idle")


func move(delta) -> void:
	percent_moved_to_next_tile += walk_speed * delta
	if percent_moved_to_next_tile >= 1.0:
		position = initial_position + (TILE_SIZE * input_direction)
		percent_moved_to_next_tile = 0
		is_moving = false
	else:
		position = initial_position + (TILE_SIZE * input_direction * percent_moved_to_next_tile)
