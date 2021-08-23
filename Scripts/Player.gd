extends KinematicBody2D

# Signals emited when there is a grass overlay with the player
signal player_moving_signal
signal player_stopped_signal
#signal player_jumping_signal

signal player_entering_door_signal
signal player_entered_door_signal

export var walk_speed = 4.0
export var jump_speed = 4.0

const TILE_SIZE = 16
const LandingDustEffect = preload("res://Scenes/LandingDustEffect.tscn")

onready var anim_tree = $AnimationTree
onready var anim_state = anim_tree.get("parameters/playback")
onready var ray = $BlockingRayCast2D
onready var ledge_ray = $LedgeRayCast2D2
onready var player_collision = $CollisionShape2D
onready var shadow = $Shadow
onready var door_ray = $DoorRayCast2D

var jumping_over_ledge: bool = false

enum PlayerState { IDLE, TURNING, WALKING }
enum FacingDirection { LEFT, RIGHT, UP, DOWN }

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

var initial_position = Vector2(0, 0)
var input_direction = Vector2(0, 1)
var is_moving = false
var stop_input: bool = false
# This variable is more like a product between two numbers that results in less
# tan one. So it is used to multiply by the tile size and produce movement.
var percent_moved_to_next_tile = 0.0


func _ready() -> void:
	# Active animation tree
	anim_tree.active = true
	initial_position = position
	shadow.visible = false
	$Sprite.visible = true
	anim_tree.set("parameters/Idle/blend_position", input_direction)
	anim_tree.set("parameters/Walk/blend_position", input_direction)
	anim_tree.set("parameters/Turn/blend_position", input_direction)


func set_spawn(location: Vector2, direction: Vector2):
	anim_tree.set("parameters/Idle/blend_position", direction)
	anim_tree.set("parameters/Walk/blend_position", direction)
	anim_tree.set("parameters/Turn/blend_position", direction)
	position = location


func _physics_process(delta) -> void:
	if player_state == PlayerState.TURNING or stop_input:
		return
	elif not is_moving:
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
		anim_tree.set("parameters/Turn/blend_position", input_direction)
		
		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("Turn")
		else:
			initial_position = position
			is_moving = true
		
	else:
		anim_state.travel("Idle")


func need_to_turn() -> bool:
	var new_facing_direction
	if input_direction.x < 0:
		new_facing_direction = FacingDirection.LEFT
	elif input_direction.x > 0:
		new_facing_direction = FacingDirection.RIGHT
	elif input_direction.y < 0:
		new_facing_direction = FacingDirection.UP
	elif input_direction.y > 0:
		new_facing_direction = FacingDirection.DOWN
	
	if facing_direction != new_facing_direction:
		facing_direction = new_facing_direction
		return true
	else:
		facing_direction = new_facing_direction
		return false


func move(delta) -> void:
	var desired_step: Vector2 = input_direction * TILE_SIZE / 2
	ray.cast_to = desired_step
	ray.force_raycast_update()
	# Also update the ledge raycast
	ledge_ray.cast_to = desired_step
	ledge_ray.force_raycast_update()

	door_ray.cast_to = desired_step
	door_ray.force_raycast_update()

	if door_ray.is_colliding():
		if percent_moved_to_next_tile == 0.0:
			emit_signal("player_entering_door_signal")

		percent_moved_to_next_tile += walk_speed * delta

		if percent_moved_to_next_tile >= 1.0:
			position = initial_position + (input_direction * TILE_SIZE)
			percent_moved_to_next_tile = 0
			is_moving = false
			stop_input = true
			# Player disapear
			$AnimationPlayer.play("Disapear")
			$Camera2D.clear_current()
		else:
			position = initial_position + (TILE_SIZE * input_direction * percent_moved_to_next_tile)


	elif (ledge_ray.is_colliding() and input_direction == Vector2(0, 1)) or jumping_over_ledge:
		percent_moved_to_next_tile += jump_speed * delta
		emit_signal("player_moving_signal")
		# Here we never multiply delta value more than one time.
		# The variable percent_moved_to_next_tile is already multiplied by this.
		if percent_moved_to_next_tile >= 2.0:
			position = initial_position + (TILE_SIZE * input_direction * 2)
			percent_moved_to_next_tile = 0
			is_moving = false
			jumping_over_ledge = false
			# Enable player collision again
			player_collision.disabled = false
			# Disable shadow while not jumping
			shadow.visible = false

			var dust_effect = LandingDustEffect.instance()
			dust_effect.position = position
			get_tree().current_scene.add_child(dust_effect)

		else:
			# Disable player collision while jumping to avoid touch grass
			player_collision.disabled = true
			# Enable shadow while jumping
			shadow.visible = true
			jumping_over_ledge = true
			var input = input_direction.y * TILE_SIZE * percent_moved_to_next_tile
			position.y = initial_position.y + (-0.96 - 0.53 * input + 0.05 * pow(input, 2))

	elif not (ray.is_colliding() or jumping_over_ledge):
		if percent_moved_to_next_tile == 0:
			emit_signal("player_moving_signal")

		percent_moved_to_next_tile += walk_speed * delta

		if percent_moved_to_next_tile >= 1.0:
			position = initial_position + (TILE_SIZE * input_direction)
			percent_moved_to_next_tile = 0
			is_moving = false
			emit_signal("player_stopped_signal")
		else:
			position = initial_position + (TILE_SIZE * input_direction * percent_moved_to_next_tile)
	else:
		is_moving = false


func finished_turning() -> void:
	player_state = PlayerState.IDLE


func entered_door() -> void:
	emit_signal("player_entered_door_signal")
