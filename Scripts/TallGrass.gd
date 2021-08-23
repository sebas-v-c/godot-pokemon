extends Node2D

onready var anim_player = $AnimationPlayer

const grass_overlay_texture = preload("res://Assets/Grass/stepped_tall_grass.png")
const GrassStepEffect = preload("res://Scenes/GrassStepEffect.tscn")

# Variable to store the texture
var grass_overlay: TextureRect  = null
# Is just a flag to say if the player is inside de grass or not
var player_inside: bool = false



func _ready():
	var player = find_parent("CurrentScene").get_children().back().find_node("Player")
	player.connect("player_moving_signal", self, "player_exiting_grass")
	player.connect("player_stopped_signal", self, "player_in_grass")
#	get_tree().current_scene.find_node("Player").connect("player_jumping_signal", self, "player_jumping_grass")


func player_exiting_grass():
	player_inside = false
	if is_instance_valid(grass_overlay):
		grass_overlay.queue_free()


func player_in_grass():
	if player_inside:
		var grass_step_efect = GrassStepEffect.instance()
		grass_step_efect.position = position
		get_tree().current_scene.add_child(grass_step_efect)

		grass_overlay = TextureRect.new()
		grass_overlay.texture = grass_overlay_texture
		grass_overlay.rect_position = position

		get_tree().current_scene.add_child(grass_overlay)


#func player_jumping_grass():
#	if is_instance_valid(grass_overlay):
#		grass_overlay.queue_free()


func _on_Area2D_body_entered(_body):
	player_inside = true
	anim_player.play("Stepped")
