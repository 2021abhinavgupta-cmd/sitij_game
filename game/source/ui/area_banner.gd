extends CanvasLayer
## Global "AT <PLACE>" dropdown banner. Shown whenever the player's map_root
## changes to a new area (see player.gd _ready and warper.gd warp_player).

const AREA_NAMES := {
	"PlayerHouse1F": "AT HOME",
	"PlayerHouse2F": "AT HOME",
	"PalletTown": "AT CHEMBUR",
	"Ghatkopar": "AT GHATKOPAR",
	"RCityMall": "AT R-CITY MALL",
	"Office": "AT MMGA",
}

const HIDDEN_Y := -24.0
const SHOWN_Y := 4.0
const HOLD_TIME := 1.6
const SLIDE_TIME := 0.25

@onready var box: Control = $Root/Box
@onready var label: Label = $Root/Box/Text

var _tween: Tween
var _last_area_name: String = ""


func _ready() -> void:
	box.position.y = HIDDEN_Y


func show_area_for_node(area: Node) -> void:
	if not area or area.name == _last_area_name:
		return
	var text: String = AREA_NAMES.get(area.name, "")
	if text == "":
		return
	_last_area_name = area.name
	show_area(text)


func show_area(text: String) -> void:
	label.text = text
	if _tween:
		_tween.kill()
	box.position.y = HIDDEN_Y
	_tween = create_tween()
	_tween.tween_property(box, "position:y", SHOWN_Y, SLIDE_TIME)
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(box, "position:y", HIDDEN_Y, SLIDE_TIME)
