extends Node2D

var next_scene
var player_location = Vector2(0, 0)
var player_direction = Vector2(0, 0)

func _ready():
	pass # Replace with function body.


func transition_to_scene(new_scene: String, spawn_location, spawn_direction):
	next_scene = new_scene
	player_location = spawn_location
	player_direction = spawn_direction
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")


func finished_fading():
	$CurrentScene.get_child(0).queue_free()
	$CurrentScene.add_child(load(next_scene).instance())
	
	var player = $CurrentScene.get_children().back().find_node("Player")
	player.set_spawn(player_location, player_direction)
	
	$ScreenTransition/AnimationPlayer.play("FadeToNormal")
