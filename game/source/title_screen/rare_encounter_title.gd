extends CanvasLayer

@onready var start_button: Button = $Root/StartButton


func _ready() -> void:
	start_button.pressed.connect(_start)


func _start() -> void:
	get_tree().change_scene_to_file("res://source/maps/overworld/overworld.tscn")
