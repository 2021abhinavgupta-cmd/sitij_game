class_name BattleEncounter
extends CanvasLayer
## Native port of the "Rare Encounter" web battle minigame (originally built as a
## Next.js/React prototype) into this project's GDScript/TileMap game. Same
## mechanics, flavor text and jokes; UI sized for this project's 240x160 GBA
## viewport instead of a browser card.

signal finished(won: bool)

enum Phase { DIALOG, ACTION, WIN, LOSE }
enum Action { CONFRONT, ATTACK, OVERTHINK, RUN }

const MAX_HP := 5
const CRUSH_MAX_HP := 20
const ATTACK_DAMAGE := 4 # ceil(MAX_HP * 0.75)
const APPEAR := "A experienced Kshitij appeared"
const CHAR_DELAY := 0.046

const RUN_SETS := [
	["YOUNG KSHITIJ: maybe I should just leave?", "OLD KSHITIJ: no.", "...ok fine."],
	["YOUNG KSHITIJ looked for an exit..", "OLD KSHITIJ is everywhere.", "Nice try."],
	["YOUNG KSHITIJ tried to run.", "But OLD KSHITIJ blocked the way!", "There is no escape."],
]

const CONFRONT_CORRECT_DAMAGE := 7 # to crush_hp, out of CRUSH_MAX_HP -- 3 correct answers empty it
const CONFRONT_WRONG_DAMAGE := 2 # to player_hp, out of MAX_HP
const QUESTIONS := [
	{
		"q": "What does Kshitij love\nthe most?",
		"options": ["AI", "Food", "His team", "Work"],
		"correct": 0,
	},
	{
		"q": "Who is Kshitij's\nfav employee?",
		"options": ["Vidit", "Abhinav", "Noobpur", "Happy"],
		"correct": 1,
	},
	{
		"q": "Who is Kshitij's\nbest client?",
		"options": ["Mellow", "Agrius", "Omo", "All 3"],
		"correct": 3,
	},
	{
		"q": "What does Kshitij\nthink over problems?",
		"options": ["Good", "None", "Few", "A lot"],
		"correct": 0,
	},
	{
		"q": "Who troubles Kshitij\na lot?",
		"options": ["Vidit", "Abhinav", "Mohit", "Noorish"],
		"correct": 3,
	},
	{
		"q": "What does Kshitij\nenjoy a lot?",
		"options": ["Founder", "Artist", "Sleeping", "Coding"],
		"correct": 0,
	},
]

@onready var enemy_bar_fill: ColorRect = $Root/EnemyHUD/EnemyHPBox/BarFill
@onready var enemy_bar_back: ColorRect = $Root/EnemyHUD/EnemyHPBox/BarBack
@onready var enemy_level_label: Label = $Root/EnemyHUD/EnemyHPBox/LevelLabel
@onready var enemy_sprite: TextureRect = $Root/EnemySprite

@onready var player_bar_fill: ColorRect = $Root/PlayerHUD/PlayerHPBox/BarFill
@onready var player_bar_back: ColorRect = $Root/PlayerHUD/PlayerHPBox/BarBack
@onready var player_level_label: Label = $Root/PlayerHUD/PlayerHPBox/LevelLabel
@onready var player_sprite: TextureRect = $Root/PlayerSprite

@onready var dialog_panel: Panel = $Root/DialogPanel
@onready var dialog_label: Label = $Root/DialogPanel/DialogLabel
@onready var advance_hint: Label = $Root/DialogPanel/AdvanceHint

@onready var action_menu: Control = $Root/ActionMenu
@onready var btn_confront: Button = $Root/ActionMenu/BtnConfront
@onready var btn_attack: Button = $Root/ActionMenu/BtnAttack
@onready var btn_overthink: Button = $Root/ActionMenu/BtnOverthink
@onready var btn_run: Button = $Root/ActionMenu/BtnRun

@onready var win_panel: Control = $Root/WinPanel
@onready var win_label: Label = $Root/WinPanel/WinLabel
@onready var win_replay_btn: Button = $Root/WinPanel/ReplayButton

@onready var lose_panel: Control = $Root/LosePanel
@onready var lose_label: Label = $Root/LosePanel/LoseLabel
@onready var retry_btn: Button = $Root/LosePanel/RetryButton
@onready var quit_btn: Button = $Root/LosePanel/QuitButton

@onready var type_timer: Timer = $TypeTimer

var player_hp := MAX_HP
var crush_hp := CRUSH_MAX_HP
var courage_stat := 5
var phase: Phase = Phase.DIALOG
var message := ""
var queue: Array = []
var run_count := 0
var overthink_count := 0
var pending_damage := 0
var pending_lose := false
var pending_win := false

var in_quiz := false
var quiz_index := 0
var quiz_awaiting_answer := false

var _shown_chars := 0
var _dialog_done := false


func _ready() -> void:
	btn_confront.pressed.connect(func(): _on_slot_pressed(0))
	btn_attack.pressed.connect(func(): _on_slot_pressed(1))
	btn_overthink.pressed.connect(func(): _on_slot_pressed(2))
	btn_run.pressed.connect(func(): _on_slot_pressed(3))
	dialog_panel.gui_input.connect(_on_dialog_input)
	type_timer.timeout.connect(_on_type_tick)
	win_replay_btn.pressed.connect(_on_replay)
	retry_btn.pressed.connect(_on_replay)
	quit_btn.mouse_entered.connect(_flee_quit)

	player_bar_back.color = Color("#3a3a2e")
	enemy_bar_back.color = Color("#3a3a2e")

	start_encounter()


func start_encounter() -> void:
	player_hp = MAX_HP
	crush_hp = CRUSH_MAX_HP
	courage_stat = 5
	run_count = 0
	overthink_count = 0
	pending_damage = 0
	pending_lose = false
	pending_win = false
	in_quiz = false
	quiz_index = 0
	quiz_awaiting_answer = false
	btn_confront.text = "CONFRONT"
	btn_attack.text = "ATTACK"
	btn_overthink.text = "OVERTHINK"
	btn_run.text = "RUN"
	win_panel.hide()
	lose_panel.hide()
	action_menu.hide()
	dialog_panel.show()
	set_phase_dialog(APPEAR, [])
	update_hp_ui()


func set_phase_dialog(msg: String, q: Array) -> void:
	phase = Phase.DIALOG
	message = msg
	queue = q.duplicate()
	_start_typing()


func _start_typing() -> void:
	_shown_chars = 0
	_dialog_done = false
	dialog_label.text = ""
	advance_hint.hide()
	type_timer.start(CHAR_DELAY)


func _on_type_tick() -> void:
	_shown_chars += 1
	dialog_label.text = message.substr(0, _shown_chars)
	if _shown_chars >= message.length():
		type_timer.stop()
		_dialog_done = true
		advance_hint.show()


func _on_dialog_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		advance_dialog()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and phase == Phase.DIALOG and _dialog_done:
		advance_dialog()
	elif event.is_action_pressed("ui_cancel") and (phase == Phase.WIN or phase == Phase.LOSE):
		finished.emit(phase == Phase.WIN)


func advance_dialog() -> void:
	if phase != Phase.DIALOG or not _dialog_done:
		return

	if queue.size() > 0:
		var next_msg: String = queue[0]
		var next_queue: Array = queue.slice(1)

		if pending_damage > 0 and next_queue.is_empty():
			var new_hp: int = max(0, player_hp - pending_damage)
			pending_damage = 0
			player_hp = new_hp
			update_hp_ui()
			_shake(player_sprite)
			if new_hp <= 0:
				message = next_msg
				queue = ["YOUNG KSHITIJ fainted..."]
				pending_lose = true
				_start_typing()
				return
			message = next_msg
			queue = []
			_start_typing()
			return

		if pending_win and next_queue.is_empty():
			message = next_msg
			queue = []
			_start_typing()
			return

		message = next_msg
		queue = next_queue
		_start_typing()
		return

	if pending_lose:
		pending_lose = false
		show_lose()
		return
	if pending_win:
		pending_win = false
		show_win()
		return

	if in_quiz:
		if quiz_awaiting_answer:
			quiz_awaiting_answer = false
			ask_current_question()
		else:
			quiz_awaiting_answer = true
			show_quiz_options()
		return

	phase = Phase.ACTION
	dialog_label.text = "What will\nYOUNG KSHITIJ do?"
	advance_hint.hide()
	action_menu.show()


func _on_slot_pressed(slot: int) -> void:
	if in_quiz:
		answer_question(slot)
		return
	match slot:
		0: do_action(Action.CONFRONT)
		1: do_action(Action.ATTACK)
		2: do_action(Action.OVERTHINK)
		3: do_action(Action.RUN)


func ask_current_question() -> void:
	if quiz_index >= QUESTIONS.size():
		in_quiz = false
		phase = Phase.ACTION
		dialog_label.text = "What will\nYOUNG KSHITIJ do?"
		advance_hint.hide()
		action_menu.show()
		return
	set_phase_dialog(QUESTIONS[quiz_index]["q"], [])


func show_quiz_options() -> void:
	phase = Phase.ACTION
	advance_hint.hide()
	var opts: Array = QUESTIONS[quiz_index]["options"]
	btn_confront.text = opts[0]
	btn_attack.text = opts[1]
	btn_overthink.text = opts[2]
	btn_run.text = opts[3]
	action_menu.show()


func answer_question(slot: int) -> void:
	action_menu.hide()
	var q: Dictionary = QUESTIONS[quiz_index]
	if slot == q["correct"]:
		quiz_index += 1
		crush_hp = max(0, crush_hp - CONFRONT_CORRECT_DAMAGE)
		update_hp_ui()
		_shake(enemy_sprite)
		if crush_hp <= 0:
			pending_win = true
		set_phase_dialog("Correct!", ["OLD KSHITIJ is shaken!\n-%d HP" % CONFRONT_CORRECT_DAMAGE])
	else:
		pending_damage = CONFRONT_WRONG_DAMAGE
		set_phase_dialog("Wrong!", ["YOUNG KSHITIJ panics!\n-%d HP" % CONFRONT_WRONG_DAMAGE])


func do_action(action: Action) -> void:
	action_menu.hide()
	match action:
		Action.RUN:
			var lines: Array = RUN_SETS[run_count % RUN_SETS.size()]
			run_count += 1
			set_phase_dialog(lines[0], lines.slice(1))

		Action.OVERTHINK:
			var n := overthink_count
			var msg: String
			var q: Array
			if n == 0:
				msg = "YOUNG KSHITIJ is thinking...\nYOUNG KSHITIJ is thinking..."
				q = ["YOUNG KSHITIJ hurt himself\nin confusion!", "-15 HP!"]
			elif n == 1:
				msg = "Still thinking..."
				q = ["YOUNG KSHITIJ hurt himself\nagain!", "-15 HP again!"]
			else:
				msg = "...YOUNG KSHITIJ, please."
				q = ["OLD KSHITIJ sighs quietly.", "-15 HP"]
			overthink_count += 1
			pending_damage = 1
			set_phase_dialog(msg, q)

		Action.ATTACK:
			crush_hp = max(0, crush_hp - 1)
			courage_stat = min(99, courage_stat + 5)
			pending_damage = ATTACK_DAMAGE
			update_hp_ui()
			_shake(enemy_sprite)
			set_phase_dialog("YOUNG KSHITIJ used ATTACK!", [
				"It did 1 damage.",
				"OLD KSHITIJ fights back!",
				"OLD KSHITIJ used AI!\n-99 HP",
			])

		Action.CONFRONT:
			in_quiz = true
			quiz_index = 0
			quiz_awaiting_answer = false
			ask_current_question()


func show_win() -> void:
	phase = Phase.WIN
	dialog_panel.hide()
	action_menu.hide()
	win_label.text = "OLD KSHITIJ joined\nyour party!\n\nCOURAGE -> MAX\nHEART -> MAX\n\n(ESC to leave, REPLAY to fight again)"
	win_panel.show()


func show_lose() -> void:
	phase = Phase.LOSE
	dialog_panel.hide()
	action_menu.hide()
	lose_label.text = "GAME OVER\n\nyou missed the opportunity...\nbut YOUNG KSHITIJ never loses hope...\n\n(ESC to leave)"
	quit_btn.position = Vector2(120, 40)
	lose_panel.show()


func _on_replay() -> void:
	start_encounter()


func _flee_quit() -> void:
	var x: float = 4 + randf() * 190
	var y: float = 30 + randf() * 40
	quit_btn.position = Vector2(x, y)


func update_hp_ui() -> void:
	var e_pct: float = float(crush_hp) / CRUSH_MAX_HP
	var p_pct: float = float(player_hp) / MAX_HP
	enemy_bar_fill.size.x = enemy_bar_back.size.x * e_pct
	player_bar_fill.size.x = player_bar_back.size.x * p_pct
	enemy_bar_fill.color = _hp_color(e_pct)
	player_bar_fill.color = _hp_color(p_pct)
	enemy_level_label.text = "Lv.200"
	player_level_label.text = "Lv.%d" % courage_stat


func _hp_color(pct: float) -> Color:
	if pct > 0.5:
		return Color("#38b838")
	elif pct > 0.25:
		return Color("#c8b030")
	return Color("#c83030")


func _shake(node: Control) -> void:
	var tween := create_tween()
	var start_pos := node.position
	for i in range(4):
		var off := 4.0 if i % 2 == 0 else -4.0
		tween.tween_property(node, "position:x", start_pos.x + off, 0.05)
	tween.tween_property(node, "position:x", start_pos.x, 0.05)
