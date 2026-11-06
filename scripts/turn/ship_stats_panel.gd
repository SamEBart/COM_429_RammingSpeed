extends CanvasLayer
## Bottom-left ship card. Facing, hull, speed, mast, and crew.
## Hovering anything on the card shows a short description of how it works.

const _SHORT_FACING := ["SE", "NE", "N", "NW", "SW", "S"]
const _TRIREME_CAPACITY := 250
const _QUADRIREME_CAPACITY := 650
const _MenuFrame := preload("res://scripts/turn/menu_frame.gd")
const _Log = preload("res://scripts/turn/game_log.gd")

## Card background. Keep alpha high so the map does not show through the text.
@export var background_color := Color(0.04, 0.04, 0.06, 0.96)

var _ship: Ship
var _hp_max: Dictionary = {}

var _owner_label: Label
var _next_button: Button
var _type_label: Label
var _facing_label: Label
var _hp_text: Label
var _hp_minus: Button
var _hp_plus: Button
var _speed_label: Label
var _slower: Button
var _faster: Button
var _mast: Button
var _face_left: Button
var _face_right: Button
var _crew_label: Label
var _engineer_label: Label
var _marine_label: Label
var _details: VBoxContainer
var _weapon_row: HBoxContainer
var _weapon_label: Label
var _commander_label: Label
var _steer_label: Label
var _mast_crew_label: Label
var _deck_label: Label
var _ballista_label: Label
var _catapult_label: Label
var _repair_label: Label
var _rower_label: Label
var _task_buttons: Array[Button] = []
## Test-mode buttons that create or remove crew. Hidden in normal mode.
var _cheat_pairs: Array[HBoxContainer] = []


func _ready() -> void:
	add_to_group("ship_stats")
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_to_group("screen_menu")
	add_child(host)

	var panel := PanelContainer.new()
	panel.add_theme_font_size_override("font_size", 13)
	var background := StyleBoxFlat.new()
	background.bg_color = background_color
	background.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", background)
	host.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.custom_minimum_size.x = 320
	margin.add_child(box)

	var owner_row := HBoxContainer.new()
	box.add_child(owner_row)
	_owner_label = Label.new()
	_owner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_owner_label.mouse_filter = Control.MOUSE_FILTER_PASS
	owner_row.add_child(_owner_label)
	_next_button = _small_button("Next ship", _next_ship, 72)
	_explain(_next_button, "Switch the card to your next living ship.\nThe map selection follows it.")
	owner_row.add_child(_next_button)

	var header := HBoxContainer.new()
	box.add_child(header)
	_type_label = Label.new()
	_type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_explain(_type_label, "Hull type and ship number.\nA Trireme slows by up to 2 per turn, a Quadrireme by 1.")
	header.add_child(_type_label)
	_facing_label = Label.new()
	_facing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_explain(_facing_label, "The direction the bow points.\nThe ship sails this way when moving forward.")
	header.add_child(_facing_label)

	# Everything below the header. Hidden for enemy ships.
	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 2)
	box.add_child(_details)
	box = _details

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 4)
	box.add_child(hp_row)
	var hp_tip := "Flotation hits left. The ship sinks at 0.\nThe buttons only work in test mode."
	var hp_name := Label.new()
	hp_name.text = "HP"
	hp_name.add_theme_font_size_override("font_size", 11)
	_explain(hp_name, hp_tip)
	hp_row.add_child(hp_name)
	_hp_text = Label.new()
	_hp_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_explain(_hp_text, hp_tip)
	hp_row.add_child(_hp_text)
	_hp_minus = _mark_button("-", _change_hp.bind(-1))
	_hp_plus = _mark_button("+", _change_hp.bind(1))
	_explain(_hp_minus, hp_tip)
	_explain(_hp_plus, hp_tip)
	hp_row.add_child(_hp_minus)
	hp_row.add_child(_hp_plus)

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 4)
	box.add_child(speed_row)
	var speed_tip := "How many hexes the ship sails this turn. Negative backs up.\nSpeed can rise by 1 per turn. The dots on the map show the path.\nNeeds a living commander."
	_speed_label = Label.new()
	_explain(_speed_label, speed_tip)
	speed_row.add_child(_speed_label)
	_slower = _mark_button("-", _change_speed.bind(-1))
	_faster = _mark_button("+", _change_speed.bind(1))
	_explain(_slower, speed_tip)
	_explain(_faster, speed_tip)
	speed_row.add_child(_slower)
	speed_row.add_child(_faster)
	_mast = _small_button("", _toggle_mast, 0)
	_explain(_mast, "Raise or lower the sail. Up adds speed.\nNeeds 1 deck crew on the mast and a living commander.")
	speed_row.add_child(_mast)
	speed_row.add_child(_gap())
	var turn_tip := "Turn the bow one side per press.\n2 steering crew: turn freely. 1 crew: one side. 0 crew: no turning.\nNeeds a living commander."
	var turn_label := Label.new()
	turn_label.text = "Turn"
	_explain(turn_label, turn_tip)
	speed_row.add_child(turn_label)
	_face_left = _small_button("Left", _turn.bind(1), 40)
	_face_right = _small_button("Right", _turn.bind(-1), 44)
	_explain(_face_left, turn_tip)
	_explain(_face_right, turn_tip)
	speed_row.add_child(_face_left)
	speed_row.add_child(_face_right)

	var status_row := HBoxContainer.new()
	box.add_child(status_row)
	_commander_label = _small_label(status_row)
	_commander_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_label = _small_label(status_row)
	_explain(_deck_label, "Deck crew with no job. Put them on steering or the mast.")

	var jobs := GridContainer.new()
	jobs.columns = 2
	jobs.add_theme_constant_override("h_separation", 12)
	jobs.add_theme_constant_override("v_separation", 2)
	box.add_child(jobs)
	_steer_label = _task_row(jobs, _change_steering, "Deck crew at the steering oars, up to 2.\n2 turn freely, 1 turns one side, 0 cannot turn.")
	_mast_crew_label = _task_row(jobs, _change_mast_crew, "Deck crew working the sail, up to 1.\nThe mast cannot move without one.")
	_ballista_label = _task_row(jobs, _change_weapon_crew.bind(true), "Engineers on the ballista. It needs crew to fire.\n- means this ship has no ballista.")
	_catapult_label = _task_row(jobs, _change_weapon_crew.bind(false), "Engineers on the catapult. It needs crew to fire.\n- means this ship has no catapult.")
	_repair_label = _task_row(jobs, _change_repair, "Engineers repairing the hull.")
	_rower_label = _task_row(jobs, _change_rowers, "Rowers on the oar benches out of the seats, plus the reserve.\nThe buttons move 5 rowers between the benches and the reserve.")

	_weapon_row = HBoxContainer.new()
	_weapon_row.add_theme_constant_override("separation", 4)
	_weapon_row.visible = false
	box.add_child(_weapon_row)
	_weapon_label = Label.new()
	_weapon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_explain(_weapon_label, "The weapon used for Long Range Fire.")
	_weapon_row.add_child(_weapon_label)
	var shuffle := _small_button("Shuffle", _cycle_weapon, 60)
	_explain(shuffle, "Switch between archers, ballista, and catapult.")
	_weapon_row.add_child(shuffle)

	_crew_label = _small_label(box)
	_explain(_crew_label, "Boarding: marines sent onto another ship.\nTotal: everyone aboard. Max: the most this hull can carry.")

	var engineer_row := HBoxContainer.new()
	box.add_child(engineer_row)
	_engineer_label = _small_label(engineer_row)
	_engineer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_explain(_engineer_label, "Engineers with no job, and all engineers aboard.\nThey crew the ballista, the catapult, and repairs.")
	engineer_row.add_child(_labeled_pair("Eng", _change_engineers, "engineer"))

	_marine_label = _small_label(box)
	_explain(_marine_label, "Marines fight when boarding. Their jobs are fixed.\nSoldiers fight hand to hand, javelineers and archers throw and shoot.")
	var marine_row := HBoxContainer.new()
	box.add_child(marine_row)
	marine_row.add_child(_labeled_pair("S", _change_soldiers, "soldier"))
	marine_row.add_child(_gap())
	marine_row.add_child(_labeled_pair("J", _change_javelineers, "javelineer"))
	marine_row.add_child(_gap())
	marine_row.add_child(_labeled_pair("A", _change_archers, "archer"))

	_MenuFrame.new().setup(host, panel, Vector2(0, 1), 12.0)

	TurnController.phase_changed.connect(func(_p, _s, _t):
		_show_current()
		if _ship != null:
			get_tree().call_group("interaction", "follow_selected_ship", _ship)
	)
	TurnController.mode_changed.connect(func(_test_mode): _show_current())
	clear_ship()


## One crew task: a label plus - and + buttons, all sharing one hover description. Returns the label.
func _task_row(parent: Container, on_delta: Callable, tip: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var label := _small_label(row)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var minus := _mark_button("-", on_delta.bind(-1))
	var plus := _mark_button("+", on_delta.bind(1))
	row.add_child(minus)
	row.add_child(plus)
	for control in [row, label, minus, plus]:
		_explain(control, tip)
	_task_buttons.append(minus)
	_task_buttons.append(plus)
	return label


func _small_label(parent: Container) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 11)
	parent.add_child(label)
	return label


## Shows text in a box when the mouse rests on the control.
## Labels ignore the mouse by default, so they are switched to pass it through.
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


func _change_repair(delta: int) -> void:
	if not _can_give_orders():
		return
	var before := _ship.repair_crew()
	_ship.set_repair_crew(before + delta)
	if delta > 0 and _ship.repair_crew() == before:
		_Log.push("%s has no free engineers." % _ship.name)
	_show_current()


## Moves 5 rowers at a time between the reserve and the oar benches.
func _change_rowers(delta: int) -> void:
	if not _can_give_orders():
		return
	_ship.move_rowers(delta * 5)
	_show_current()


## Moves one engineer onto or off the ballista (true) or the catapult (false).
func _change_weapon_crew(on_ballista: bool, delta: int) -> void:
	if not _can_give_orders():
		return
	var weapon = _ship._ballista if on_ballista else _ship._catapult
	if weapon == null:
		return
	if delta > 0:
		var before: int = weapon._engineers.size()
		weapon.allocateEngineer(_ship)
		if weapon._engineers.size() == before:
			_Log.push("%s has no free engineers." % _ship.name)
	elif weapon._engineers.size() > 0:
		var engineer: Character.Engineer = weapon._engineers.pop_back()
		engineer._allocatedTo = null
	_show_current()


func _cycle_weapon() -> void:
	if _ship == null:
		return
	Global._subAction = posmod(Global._subAction + 1, 3)
	_refresh_weapon_line()
	get_tree().call_group("interaction", "preview_lrf_range", _ship)


func _weapon_name() -> String:
	if Global._subAction == 1:
		return "Ballista"
	if Global._subAction == 2:
		return "Catapult"
	return "Archers"


func _refresh_weapon_line() -> void:
	var show_weapon := _ship != null and TurnController.phase == TurnController.Phase.EXECUTION and TurnController.action_step == TurnController.ActionStep.LONG_RANGE_FIRE
	_weapon_row.visible = show_weapon
	if show_weapon:
		Global._subAction = posmod(Global._subAction, 3)
		_weapon_label.text = "Weapon: %s" % _weapon_name()


func show_ship(unit: Node) -> void:
	if unit is Ship:
		_ship = unit
	else:
		_ship = null
	_show_current()


func clear_ship() -> void:
	_ship = null
	_show_current()


func _small_button(text: String, on_press: Callable, width: int = 18) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 18)
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(on_press)
	return button


func _mark_button(text: String, on_press: Callable) -> Button:
	var button := _small_button(text, on_press)
	button.add_theme_font_size_override("font_size", 18)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := button.get_theme_stylebox(state)
		if style == null:
			continue
		var copy := style.duplicate()
		copy.content_margin_left = 1
		copy.content_margin_right = 1
		copy.content_margin_top = 0
		copy.content_margin_bottom = 0
		button.add_theme_stylebox_override(state, copy)
	return button


func _gap() -> Control:
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


func _labeled_pair(title: String, on_delta: Callable, crew_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name := Label.new()
	name.text = title
	row.add_child(name)
	var minus := _mark_button("-", on_delta.bind(-1))
	var plus := _mark_button("+", on_delta.bind(1))
	row.add_child(minus)
	row.add_child(plus)
	for control in [row, name, minus, plus]:
		_explain(control, "Test mode only: add or remove one %s." % crew_name)
	_cheat_pairs.append(row)
	return row


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


## Speed, facing, or mast changed. Refresh the card and the paths drawn on the map.
func _orders_changed() -> void:
	_show_current()
	get_tree().call_group("interaction", "preview_phase_step", _ship)
	get_tree().call_group("turn_preview", "refresh")


## Selects the local player's next living ship, in name order, and shows it on the card.
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


func _change_engineers(delta: int) -> void:
	if _ship == null or _ship._owner == null:
		return
	if delta > 0:
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


## Orders can only change during Command, until the local player presses Ready.
## Test mode also allows Setup.
func _orders_editable() -> bool:
	if TurnController.test_mode:
		return TurnController.phase == TurnController.Phase.SETUP or TurnController.phase == TurnController.Phase.COMMAND
	return TurnController.phase == TurnController.Phase.COMMAND and not TurnController.local_ready


## Crew jobs: the ship is yours and orders are open.
func _can_give_orders() -> bool:
	return _ship != null and TurnController.is_local_ship(_ship) and _orders_editable()


## Speed, mast, and facing also need a living commander (test mode skips that).
func _can_command_ship() -> bool:
	return _can_give_orders() and (TurnController.test_mode or _ship.has_commander())


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
	_mast.disabled = not command
	_face_left.disabled = not command
	_face_right.disabled = not command
	for button in _task_buttons:
		button.disabled = not jobs
	for pair in _cheat_pairs:
		pair.visible = cheats
	_owner_label.remove_theme_color_override("font_color")
	_facing_label.visible = mine
	_details.visible = mine
	_next_button.visible = mine
	if not has_ship:
		_owner_label.text = ""
		_type_label.text = "Click a ship"
		_refresh_weapon_line()
		return
	_type_label.text = _hull_title()
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
	_facing_label.text = _SHORT_FACING[posmod(_ship._facing, _SHORT_FACING.size())]
	_hp_text.text = "%d/%d" % [_ship._flotationHits, _hp_cap()]
	_speed_label.text = "Speed %d" % _ship.get_overall_speed()
	_mast.text = "Mast: %s" % ("Down" if _ship._isMastDown else "Up")
	if _ship.has_commander():
		_commander_label.text = "Commander: Alive"
		_explain(_commander_label, "Gives the orders. While alive you can change speed, mast, and facing.")
	else:
		_commander_label.text = "Commander: Dead (holding last orders)"
		_explain(_commander_label, "Dead. The ship holds its last speed, facing, and mast.\nCrew jobs can still change.")
	_steer_label.text = "Steering %d/%d" % [_ship.steering_crew(), Ship.MAX_STEERING_CREW]
	_mast_crew_label.text = "Mast crew %d/%d" % [_ship.mast_crew(), Ship.MAX_MAST_CREW]
	_deck_label.text = "Deck crew free %d" % _ship.crew_on(_ship._deckCrew, null)
	_ballista_label.text = "Ballista eng %s" % ("-" if _ship._ballista == null else str(_ship._ballista._engineers.size()))
	_catapult_label.text = "Catapult eng %s" % ("-" if _ship._catapult == null else str(_ship._catapult._engineers.size()))
	_repair_label.text = "Repair eng %d" % _ship.repair_crew()
	_rower_label.text = "Rowers %d/%d  Reserve %d" % [_ship.getActiveRowers().size(), _ship.rower_seats(), _ship._reserveRowers.size()]
	_fill_crew_text()
	_refresh_weapon_line()


func _fill_crew_text() -> void:
	var rowing := _ship.getActiveRowers().size()
	var boarding := _ship._boardingArchers.size() + _ship._boardingJavelins.size() + _ship._boardingMelee.size()
	var reserve := _ship._reserveRowers.size()
	var soldiers := _ship._marineSoldiers.size()
	var javelineers := _ship._marineJavelineers.size()
	var archers := _ship._marineArchers.size()
	var engineers := _ship._engineers.size()
	var total := rowing + reserve + _ship._deckCrew.size() + soldiers + javelineers + archers + engineers
	var capacity := _QUADRIREME_CAPACITY
	if _ship.get_ship_kind() == SpeedCalculator.ShipKind.TRIREME:
		capacity = _TRIREME_CAPACITY
	_crew_label.text = "Crew: Boarding %d  Total %d  Max %d" % [boarding, total, capacity]
	_engineer_label.text = "Engineers: Free %d  Total %d" % [_ship.crew_on(_ship._engineers, null), engineers]
	_marine_label.text = "Marines: Soldier %d  Javeline %d  Archers %d  Total %d" % [soldiers, javelineers, archers, soldiers + javelineers + archers]
