class_name AaryaNPC
extends Node2D
## Standing NPC at the back of the office. Press ui_accept while adjacent to
## start the Rare Encounter battle overlay.

const BATTLE_SCENE: PackedScene = preload("res://source/battle/battle_encounter.tscn")

@export var player: Player
@export var interact_range: float = 20.0

var _battle: BattleEncounter
var _in_battle := false


func _unhandled_input(event: InputEvent) -> void:
	if _in_battle or not player or not event.is_action_pressed("ui_accept"):
		return
	if global_position.distance_to(player.global_position) > interact_range:
		return
	_start_battle()


func _start_battle() -> void:
	_in_battle = true
	player.set_physics_process(false)
	_battle = BATTLE_SCENE.instantiate()
	get_tree().root.add_child(_battle)
	_battle.finished.connect(_on_battle_finished)


func _on_battle_finished(_won: bool) -> void:
	_battle.queue_free()
	_battle = null
	player.set_physics_process(true)
	_in_battle = false
