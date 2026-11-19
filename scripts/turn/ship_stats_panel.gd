extends CanvasLayer
## Ship card. Move controls in scenes/ui/ship_card.tscn. This file only fills text and wires clicks.
## EmptyHint is the small dark "Click a ship" box. Card is the parchment. Details under the card is leftover Command/test UI.

const _SHORT_FACING := ["SE", "NE", "N", "NW", "SW", "S"]
const _TRIREME_CAPACITY := 250
const _QUADRIREME_CAPACITY := 650
const _TRIREME_ENGINEERS := 8
const _QUADRIREME_ENGINEERS := 12
const _MenuFrame := preload("res://scripts/turn/menu_frame.gd")
const _Log = preload("res://scripts/turn/game_log.gd")
const _TEX_SAIL_PIC_UP := preload("res://assets/2D/Ship Card_Sail_Up.png")
const _TEX_SAIL_PIC_DOWN := preload("res://assets/2D/Ship Card_Sail_Down.png")
const _TEX_BALLISTA := preload("res://assets/2D/Button_Reload_Ballista.png")
const _TEX_BALLISTA_GREY := preload("res://assets/2D/Button_Reload_Ballista_Greyed.png")
const _TEX_CATAPULT := preload("res://assets/2D/Button_Reload_Catapult.png")
const _TEX_CATAPULT_GREY := preload("res://assets/2D/Button_Reload_Catapult_Greyed.png")

var _ship: Ship
var _hp_max: Dictionary = {}
var _task_buttons: Array[Button] = []
var _cheat_pairs: Array[HBoxContainer] = []

@onready var _host: Control = %Host
@onready var _panel: PanelContainer = %Panel
@onready var _empty_hint: Control = %EmptyHint
@onready var _card: Control = %Card
@onready var _card_base: TextureRect = %CardBase
@onready var _play: Control = %Play
@onready var _owner_label: Label = %OwnerLabel
@onready var _next_button: Button = %NextButton
@onready var _type_label: Label = %TypeLabel
@onready var _facing_label: Label = %FacingLabel
@onready var _hp_slot: Control = %HpSlot
@onready var _hp_fill: ColorRect = %HpFill
@onready var _hp_minus: Button = %HpMinus
@onready var _hp_plus: Button = %HpPlus
@onready var _speed_label: Label = %SpeedLabel
@onready var _slower: BaseButton = %Slower
@onready var _faster: BaseButton = %Faster
@onready var _mast_up: TextureButton = %MastUp
@onready var _mast_down: TextureButton = %MastDown
@onready var _face_left: BaseButton = %TurnLeft
@onready var _face_right: BaseButton = %TurnRight
@onready var _archer_btn: TextureButton = %ArcherBtn
@onready var _weapon_btn: TextureButton = %WeaponBtn
@onready var _weapon_cd: Label = %WeaponCd
@onready var _crew_name: Label = %CrewName
@onready var _crew_label: Label = %CrewLabel
@onready var _engineer_name: Label = %EngineerName
@onready var _engineer_label: Label = %EngineerLabel
@onready var _marine_name: Label = %MarineName
@onready var _marine_label: Label = %MarineLabel
@onready var _details: VBoxContainer = %Details
@onready var _weapon_row: HBoxContainer = %WeaponRow
@onready var _commander_label: Label = %CommanderLabel
@onready var _steer_label: Label = %SteerLabel
@onready var _mast_crew_label: Label = %MastCrewLabel
@onready var _deck_label: Label = %DeckLabel
@onready var _rower_label: Label = %RowerLabel


func _ready() -> void:
	add_to_group("ship_stats")
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_host.add_to_group("screen_menu")
	_task_buttons = [
		%SteerMinus, %SteerPlus, %MastCrewMinus, %MastCrewPlus, %RowerMinus, %RowerPlus
	]
	_cheat_pairs = [%HpCheatRow, %EngCheatRow, %MarineCheatRow]
	var hp_tip := "Flotation hits left. The ship sinks at 0.\nThe buttons only work in test mode."
	var turn_tip := "Turn the bow one side per press.\n2 steering crew: turn freely. 1 crew: one side. 0 crew: no turning.\nNeeds a living commander."
	var sail_tip := "Raise or lower the sail. Up adds speed.\nNeeds 1 deck crew on the mast and a living commander."
	var speed_tip := "How many hexes the ship sails this turn. Negative backs up.\nSpeed can rise by 1 per turn. The dots on the map show the path.\nNeeds a living commander."
	_explain(_type_label, "Hull type and ship number.\nA Trireme slows by up to 2 per turn, a Quadrireme by 1.")
	_explain(_next_button, "Switch the card to your next living ship.\nThe map selection follows it.")
	_explain(_hp_slot, hp_tip)
	_explain(_hp_minus, hp_tip)
	_explain(_hp_plus, hp_tip)
	_explain(_facing_label, "The direction the bow points.\nThe ship sails this way when moving forward.")
	_explain(_face_left, turn_tip)
	_explain(_face_right, turn_tip)
	_explain(_mast_up, sail_tip)
	_explain(_mast_down, sail_tip)
	_explain(_slower, speed_tip)
	_explain(_faster, speed_tip)
	_explain(_speed_label, speed_tip)
	_explain(_weapon_btn, "Long Range Fire: this ship's ballista or catapult.")
	_explain(_archer_btn, "Long Range Fire: archers. Range 1. No recharge.")
	_explain(_deck_label, "Deck crew with no job. Put them on steering or the mast.")
	_explain(_steer_label, "Deck crew at the steering oars, up to 2.\n2 turn freely, 1 turns one side, 0 cannot turn.")
	_explain(%SteerMinus, "Deck crew at the steering oars, up to 2.\n2 turn freely, 1 turns one side, 0 cannot turn.")
	_explain(%SteerPlus, "Deck crew at the steering oars, up to 2.\n2 turn freely, 1 turns one side, 0 cannot turn.")
	_explain(_mast_crew_label, "Deck crew working the sail, up to 1.\nThe mast cannot move without one.")
	_explain(%MastCrewMinus, "Deck crew working the sail, up to 1.\nThe mast cannot move without one.")
	_explain(%MastCrewPlus, "Deck crew working the sail, up to 1.\nThe mast cannot move without one.")
	_explain(_rower_label, "Rowers on the oar benches out of the seats, plus the reserve.\nThe buttons move 5 rowers between the benches and the reserve.")
	_explain(%RowerMinus, "Rowers on the oar benches out of the seats, plus the reserve.\nThe buttons move 5 rowers between the benches and the reserve.")
	_explain(%RowerPlus, "Rowers on the oar benches out of the seats, plus the reserve.\nThe buttons move 5 rowers between the benches and the reserve.")
	_explain(%EngMinus, "Test mode only: add or remove one engineer.")
	_explain(%EngPlus, "Test mode only: add or remove one engineer.")
	_explain(%SoldMinus, "Test mode only: add or remove one soldier.")
	_explain(%SoldPlus, "Test mode only: add or remove one soldier.")
	_explain(%JavMinus, "Test mode only: add or remove one javelineer.")
	_explain(%JavPlus, "Test mode only: add or remove one javelineer.")
	_explain(%ArchMinus, "Test mode only: add or remove one archer.")
	_explain(%ArchPlus, "Test mode only: add or remove one archer.")
	## Scene has the buttons. We only connect them here.
	_next_button.pressed.connect(_next_ship)
	_face_left.pressed.connect(_turn.bind(1))
	_face_right.pressed.connect(_turn.bind(-1))
	_mast_up.pressed.connect(_toggle_mast)
	_mast_down.pressed.connect(_toggle_mast)
	_slower.pressed.connect(_change_speed.bind(-1))
	_faster.pressed.connect(_change_speed.bind(1))
	_archer_btn.pressed.connect(_pick_archers)
	_weapon_btn.pressed.connect(_pick_siege)
	%SteerMinus.pressed.connect(_change_steering.bind(-1))
	%SteerPlus.pressed.connect(_change_steering.bind(1))
	%MastCrewMinus.pressed.connect(_change_mast_crew.bind(-1))
	%MastCrewPlus.pressed.connect(_change_mast_crew.bind(1))
	%RowerMinus.pressed.connect(_change_rowers.bind(-1))
	%RowerPlus.pressed.connect(_change_rowers.bind(1))
	_hp_minus.pressed.connect(_change_hp.bind(-1))
	_hp_plus.pressed.connect(_change_hp.bind(1))
	%EngMinus.pressed.connect(_change_engineers.bind(-1))
	%EngPlus.pressed.connect(_change_engineers.bind(1))
	%SoldMinus.pressed.connect(_change_soldiers.bind(-1))
	%SoldPlus.pressed.connect(_change_soldiers.bind(1))
	%JavMinus.pressed.connect(_change_javelineers.bind(-1))
	%JavPlus.pressed.connect(_change_javelineers.bind(1))
	%ArchMinus.pressed.connect(_change_archers.bind(-1))
	%ArchPlus.pressed.connect(_change_archers.bind(1))
	## Start in the bottom-left. Drag empty parchment to move, corners to scale.
	_MenuFrame.new().setup(_host, _panel, Vector2(0, 1), 16.0)
	TurnController.phase_changed.connect(func(_p, _s, _t):
		_show_current()
		if _ship != null:
			get_tree().call_group("interaction", "follow_selected_ship", _ship)
	)
	TurnController.mode_changed.connect(func(_test_mode): _show_current())
	clear_ship()


func _explain(control: Control, text: String) -> void:
	control.tooltip_text = text
	if control is Label:
		control.mouse_filter = Control.MOUSE_FILTER_PASS


func _change_steering(delta: int) -> void:
	if not _can_give_orders():
		return
	var before := _ship.steering_crew()
	_ship.set_steering(before + delta)
	if delta > 0 and _ship.steering_crew() == before and before < Ship.MAX_STEERING_CREW:
		_Log.push("%s has no free deck crew for steering." % _ship.name)
	_show_current()


func _change_mast_crew(delta: int) -> void:
	if not _can_give_orders():
		return
	var before := _ship.mast_crew()
	_ship.set_mast_crew(before + delta)
	if delta > 0 and _ship.mast_crew() == before and before < Ship.MAX_MAST_CREW:
		_Log.push("%s has no free deck crew for the mast." % _ship.name)
	_show_current()


func _change_rowers(delta: int) -> void:
	if not _can_give_orders():
		return
	_ship.move_rowers(delta * 5)
	_show_current()


## Footer archer button. Sets LRF to bows and redraws the range preview.
func _pick_archers() -> void:
	if _ship == null or not TurnController.is_local_ship(_ship):
		return
	_ship._lrfMode = 0
	_refresh_weapon_line()
	get_tree().call_group("interaction", "preview_lrf_range", _ship)


## Footer ballista/catapult button. Sets LRF to this hull's one siege weapon.
func _pick_siege() -> void:
	if _ship == null or not TurnController.is_local_ship(_ship):
		return
	_ship._lrfMode = 1
	_refresh_weapon_line()
	get_tree().call_group("interaction", "preview_lrf_range", _ship)


## Greys the unused LRF pick. Grey weapon art plus a Caligo number is the reload wait.
func _refresh_weapon_line() -> void:
	var show_lrf := _ship != null and TurnController.is_local_ship(_ship)
	_weapon_row.visible = show_lrf
	if not show_lrf:
		return
	var siege = _ship._ballista if _ship._ballista else _ship._catapult
	var loaded := siege == null or siege.isLoaded()
	if _ship._ballista:
		_weapon_btn.texture_normal = _TEX_BALLISTA if loaded else _TEX_BALLISTA_GREY
	elif _ship._catapult:
		_weapon_btn.texture_normal = _TEX_CATAPULT if loaded else _TEX_CATAPULT_GREY
	else:
		_weapon_btn.texture_normal = _TEX_BALLISTA_GREY
	_weapon_cd.text = "" if loaded or siege == null else str(siege._reloadTimer)
	_archer_btn.modulate = Color.WHITE if _ship._lrfMode == 0 else Color(0.7, 0.7, 0.7)
	_weapon_btn.modulate = Color.WHITE if _ship._lrfMode == 1 else Color(0.7, 0.7, 0.7)
	_weapon_btn.disabled = siege == null


func show_ship(unit: Node) -> void:
	if unit is Ship:
		_ship = unit
	else:
		_ship = null
	_show_current()


func clear_ship() -> void:
	_ship = null
	_show_current()


func _change_hp(delta: int) -> void:
	if _ship == null:
		return
	var key := _ship.get_instance_id()
	var cap := _hp_cap()
	var next := clampi(_ship._flotationHits + delta, 0, cap)
	if delta > 0 and next == _ship._flotationHits and _ship._flotationHits == cap:
		cap += 1
		_hp_max[key] = cap
		next = cap
	_ship._flotationHits = next
	_show_current()


func _change_speed(delta: int) -> void:
	if not _can_command_ship():
		return
	var limited := not TurnController.test_mode
	if limited and not _ship.can_change_speed_to(_ship._rowingSpeed + delta):
		_Log.push("%s has reached its speed change for this turn." % _ship.name)
		return
	_ship.adjust_rowing_speed(delta)
	_orders_changed()


func _turn(steps: int) -> void:
	if not _can_command_ship():
		return
	var limited := not TurnController.test_mode
	if limited and not _ship.can_turn_to(posmod(_ship._facing + steps, Ship.HEX_DIR.size())):
		var crew := _ship.steering_crew()
		if crew == 0:
			_Log.push("%s has no steering crew and cannot turn." % _ship.name)
		else:
			_Log.push("%s has 1 steering crew and can turn one side this Command." % _ship.name)
		return
	_ship.turn_facing(steps)
	_orders_changed()


func _toggle_mast() -> void:
	if not _can_command_ship():
		return
	if not TurnController.test_mode and _ship.mast_crew() == 0:
		_Log.push("%s needs a deck crew member on the mast." % _ship.name)
		return
	_ship.set_mast_down(not _ship._isMastDown)
	_orders_changed()


func _orders_changed() -> void:
	_show_current()
	get_tree().call_group("interaction", "preview_phase_step", _ship)
	get_tree().call_group("turn_preview", "refresh")


func _next_ship() -> void:
	var mine: Array[Ship] = []
	for node in get_tree().get_nodes_in_group("ships"):
		if node is Ship and TurnController.is_local_ship(node) and node._flotationHits > 0:
			mine.append(node)
	if mine.is_empty():
		return
	mine.sort_custom(func(a: Ship, b: Ship): return a.name.naturalnocasecmp_to(b.name) < 0)
	var next := mine[(mine.find(_ship) + 1) % mine.size()]
	get_tree().call_group("interaction", "follow_selected_ship", next)
	show_ship(next)


func _engineer_max() -> int:
	if _ship.get_ship_kind() == SpeedCalculator.ShipKind.TRIREME:
		return _TRIREME_ENGINEERS
	return _QUADRIREME_ENGINEERS


func _change_engineers(delta: int) -> void:
	if _ship == null or _ship._owner == null:
		return
	if delta > 0:
		if _ship._engineers.size() >= _engineer_max():
			_Log.push("%s already has its max engineers." % _ship.name)
			return
		var engineer := Character.Engineer.new(_ship._owner)
		_ship._engineers.append(engineer)
		_ship._fighters.append(engineer)
	elif _ship._engineers.size() > 0:
		var index := _ship._engineers.size() - 1
		for i in _ship._engineers.size():
			if _ship._engineers[i]._allocatedTo == null:
				index = i
				break
		var engineer = _ship._engineers[index]
		_ship._engineers.remove_at(index)
		if _ship._ballista != null:
			_ship._ballista._engineers.erase(engineer)
		if _ship._catapult != null:
			_ship._catapult._engineers.erase(engineer)
		_drop_fighter(engineer)
	_show_current()


func _change_soldiers(delta: int) -> void:
	_change_list(_ship._marineSoldiers if _ship != null else [], delta, Character.Marine.Soldier.new)


func _change_javelineers(delta: int) -> void:
	_change_list(_ship._marineJavelineers if _ship != null else [], delta, Character.Marine.Javelineer.new)


func _change_archers(delta: int) -> void:
	_change_list(_ship._marineArchers if _ship != null else [], delta, Character.Marine.Archer.new)


func _change_list(list: Array, delta: int, make_one: Callable) -> void:
	if _ship == null or _ship._owner == null:
		return
	if delta > 0:
		var unit = make_one.call(_ship._owner)
		list.append(unit)
		_ship._fighters.append(unit)
	elif list.size() > 0:
		_drop_fighter(list.pop_back())
	_show_current()


func _drop_fighter(unit) -> void:
	_ship._fighters.erase(unit)
	_ship._boardingArchers.erase(unit)
	_ship._boardingJavelins.erase(unit)
	_ship._boardingMelee.erase(unit)


func _owner_name() -> String:
	if _ship._owner == null:
		return "None"
	return _ship._owner.getName()


func _hull_title() -> String:
	var kind := "Quadrireme"
	if _ship.get_ship_kind() == SpeedCalculator.ShipKind.TRIREME:
		kind = "Trireme"
	var number := _ship.name.get_slice(" ", 1)
	if number == "":
		return kind
	return "%s %s" % [kind, number]


func _orders_editable() -> bool:
	if TurnController.test_mode:
		return TurnController.phase == TurnController.Phase.SETUP or TurnController.phase == TurnController.Phase.COMMAND
	return TurnController.phase == TurnController.Phase.COMMAND and not TurnController.local_ready


func _can_give_orders() -> bool:
	return _ship != null and TurnController.is_local_ship(_ship) and _orders_editable()


func _can_command_ship() -> bool:
	return _can_give_orders() and (TurnController.test_mode or _ship.has_commander())


func _set_hp_fill(ratio: float) -> void:
	_hp_fill.anchor_right = clampf(ratio, 0.0, 1.0)


func _hp_cap() -> int:
	var key := _ship.get_instance_id()
	if not _hp_max.has(key):
		_hp_max[key] = maxi(_ship._flotationHits, 1)
	return int(_hp_max[key])


func _show_current() -> void:
	var has_ship := _ship != null
	var mine := has_ship and TurnController.is_local_ship(_ship)
	var cheats := has_ship and TurnController.test_mode
	var jobs := _can_give_orders()
	var command := _can_command_ship()
	_hp_minus.disabled = not cheats
	_hp_plus.disabled = not cheats
	_slower.disabled = not command
	_faster.disabled = not command
	_mast_up.disabled = not command
	_mast_down.disabled = not command
	_face_left.disabled = not command
	_face_right.disabled = not command
	for button in _task_buttons:
		button.disabled = not jobs
	for pair in _cheat_pairs:
		pair.visible = cheats
	_owner_label.remove_theme_color_override("font_color")
	## No selection: tiny black box. A ship: full parchment. Enemy: parchment without order buttons.
	_empty_hint.visible = not has_ship
	_card.visible = has_ship
	_facing_label.visible = has_ship
	_play.visible = mine
	_details.visible = mine
	_next_button.visible = mine
	if not has_ship:
		_owner_label.text = ""
		_refresh_weapon_line()
		return
	_type_label.text = _hull_title()
	_facing_label.text = _SHORT_FACING[posmod(_ship._facing, _SHORT_FACING.size())]
	var cap := _hp_cap()
	_set_hp_fill(float(_ship._flotationHits) / float(maxi(cap, 1)))
	## Speed uses _isMastDown for the sail bonus. That means the sails are drawing, so the card shows Sail_Up.
	_card_base.texture = _TEX_SAIL_PIC_UP if _ship._isMastDown else _TEX_SAIL_PIC_DOWN
	if not mine:
		_owner_label.text = "ENEMY  %s" % _owner_name()
		_owner_label.tooltip_text = "Another player's ship. Only its owner and hull are shown."
		var tag := _ship.get_node_or_null("OwnerTag") as Label3D
		if tag:
			_owner_label.add_theme_color_override("font_color", tag.modulate)
		_refresh_weapon_line()
		return
	_owner_label.text = _owner_name()
	_owner_label.tooltip_text = "The player who owns this ship. You can give it orders during Command."
	_speed_label.text = str(_ship.get_overall_speed())
	_mast_up.visible = _ship._isMastUp
	_mast_down.visible = not _ship._isMastUp
	if _ship.has_commander():
		_commander_label.text = "Commander: Alive"
		_explain(_commander_label, "Gives the orders. While alive you can change speed, mast, and facing.")
	else:
		_commander_label.text = "Commander: Dead (holding last orders)"
		_explain(_commander_label, "Dead. The ship holds its last speed, facing, and mast.\nCrew jobs can still change.")
	_steer_label.text = "Steering %d/%d" % [_ship.steering_crew(), Ship.MAX_STEERING_CREW]
	_mast_crew_label.text = "Mast crew %d/%d" % [_ship.mast_crew(), Ship.MAX_MAST_CREW]
	_deck_label.text = "Deck crew free %d" % _ship.crew_on(_ship._deckCrew, null)
	_rower_label.text = "Rowers %d/%d  Reserve %d" % [_ship.getActiveRowers().size(), _ship.rower_seats(), _ship._reserveRowers.size()]
	_fill_crew_text()
	_refresh_weapon_line()


func _fill_crew_text() -> void:
	var rowing := _ship.getActiveRowers().size()
	var boarding := _ship._boardingArchers.size() + _ship._boardingJavelins.size() + _ship._boardingMelee.size()
	var reserve := _ship._reserveRowers.size()
	var free_deck := _ship.crew_on(_ship._deckCrew, null)
	var soldiers := _ship._marineSoldiers.size()
	var javelineers := _ship._marineJavelineers.size()
	var archers := _ship._marineArchers.size()
	var engineers := _ship._engineers.size()
	var idle_eng := 0
	for engineer in _ship._engineers:
		if engineer._allocatedTo == null:
			idle_eng += 1
	var total := rowing + reserve + _ship._deckCrew.size() + soldiers + javelineers + archers + engineers
	var capacity := _QUADRIREME_CAPACITY
	if _ship.get_ship_kind() == SpeedCalculator.ShipKind.TRIREME:
		capacity = _TRIREME_CAPACITY
	_crew_label.text = "%d/%d/%d/%d/%d" % [rowing, boarding, reserve + free_deck, total, capacity]
	var crew_tip := "Rowing %d Boarding %d Inactive %d Total %d Max %d" % [rowing, boarding, reserve + free_deck, total, capacity]
	_explain(_crew_name, crew_tip)
	_explain(_crew_label, crew_tip)
	_engineer_label.text = "%d/%d" % [idle_eng, engineers]
	var eng_tip := "Inactive %d Total %d" % [idle_eng, engineers]
	_explain(_engineer_name, eng_tip)
	_explain(_engineer_label, eng_tip)
	_marine_label.text = "%d/%d/%d/%d" % [soldiers, javelineers, archers, soldiers + javelineers + archers]
	var mar_tip := "Soldiers %d Javelin %d Archers %d Total %d" % [soldiers, javelineers, archers, soldiers + javelineers + archers]
	_explain(_marine_name, mar_tip)
	_explain(_marine_label, mar_tip)
