extends CanvasLayer
## Bottom-right ship card. Facing, hull, speed, mast, and crew.

const _SHORT_FACING := ["SE", "NE", "N", "NW", "SW", "S"]
const _TRIREME_CAPACITY := 250
const _QUADRIREME_CAPACITY := 650
const _ScaleHandle := preload("res://scripts/turn/menu_scale_handle.gd")

var _ship: Ship
var _hp_max: Dictionary = {}

var _owner_label: Label
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
var _crew_buttons: Array[Button] = []


func _ready() -> void:
	add_to_group("ship_stats")
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	host.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	host.grow_vertical = Control.GROW_DIRECTION_BEGIN
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_to_group("screen_menu")
	add_child(host)

	var panel := PanelContainer.new()
	panel.add_theme_font_size_override("font_size", 9)
	host.add_child(panel)
	panel.resized.connect(_fit_stats_host.bind(host, panel))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.custom_minimum_size.x = 156
	margin.add_child(box)

	_owner_label = Label.new()
	_owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_owner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_owner_label)

	var header := HBoxContainer.new()
	box.add_child(header)
	_type_label = Label.new()
	_type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_type_label)
	_facing_label = Label.new()
	_facing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_facing_label)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 4)
	box.add_child(hp_row)
	var hp_name := Label.new()
	hp_name.text = "HP"
	hp_name.add_theme_font_size_override("font_size", 8)
	hp_row.add_child(hp_name)
	_hp_text = Label.new()
	_hp_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp_text)
	_hp_minus = _mark_button("-", _change_hp.bind(-1))
	_hp_plus = _mark_button("+", _change_hp.bind(1))
	hp_row.add_child(_hp_minus)
	hp_row.add_child(_hp_plus)

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 4)
	box.add_child(speed_row)
	_speed_label = Label.new()
	_speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_row.add_child(_speed_label)
	_slower = _mark_button("-", _change_speed.bind(-1))
	_faster = _mark_button("+", _change_speed.bind(1))
	speed_row.add_child(_slower)
	speed_row.add_child(_faster)
	_mast = Button.new()
	_mast.add_theme_font_size_override("font_size", 8)
	_mast.custom_minimum_size = Vector2(0, 14)
	_mast.pressed.connect(_toggle_mast)
	speed_row.add_child(_mast)

	var facing_row := HBoxContainer.new()
	facing_row.add_theme_constant_override("separation", 4)
	box.add_child(facing_row)
	var turn_label := Label.new()
	turn_label.text = "Turn"
	facing_row.add_child(turn_label)
	_face_left = _small_button("Left", _turn.bind(1), 32)
	_face_right = _small_button("Right", _turn.bind(-1), 36)
	facing_row.add_child(_face_left)
	facing_row.add_child(_face_right)

	_crew_label = Label.new()
	_crew_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_crew_label.add_theme_font_size_override("font_size", 8)
	box.add_child(_crew_label)
	var crew_row := HBoxContainer.new()
	box.add_child(crew_row)
	crew_row.add_child(_labeled_pair("Row", _change_rowing))
	crew_row.add_child(_labeled_pair("Idle", _change_idle))

	var engineer_row := HBoxContainer.new()
	box.add_child(engineer_row)
	_engineer_label = Label.new()
	_engineer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_engineer_label.add_theme_font_size_override("font_size", 8)
	engineer_row.add_child(_engineer_label)
	engineer_row.add_child(_labeled_pair("Eng", _change_engineers))

	_marine_label = Label.new()
	_marine_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_marine_label.add_theme_font_size_override("font_size", 8)
	box.add_child(_marine_label)
	var marine_row := HBoxContainer.new()
	box.add_child(marine_row)
	marine_row.add_child(_labeled_pair("S", _change_soldiers))
	marine_row.add_child(_gap())
	marine_row.add_child(_labeled_pair("J", _change_javelineers))
	marine_row.add_child(_gap())
	marine_row.add_child(_labeled_pair("A", _change_archers))

	var handle = _ScaleHandle.new()
	handle.pivot_corner = Vector2.ONE
	handle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	handle.offset_left = 0
	handle.offset_top = 0
	handle.offset_right = 14
	handle.offset_bottom = 14
	host.add_child(handle)

	TurnController.phase_changed.connect(func(_p, _s, _t):
		_show_current()
		if _ship != null:
			get_tree().call_group("interaction", "follow_selected_ship", _ship)
	)
	clear_ship()


func _fit_stats_host(host: Control, panel: Control) -> void:
	var card_size := panel.size
	host.offset_left = -12.0 - card_size.x
	host.offset_top = -12.0 - card_size.y
	host.offset_right = -12.0
	host.offset_bottom = -12.0


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
	button.custom_minimum_size = Vector2(width, 14)
	button.add_theme_font_size_override("font_size", 8)
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


func _labeled_pair(title: String, on_delta: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name := Label.new()
	name.text = title
	row.add_child(name)
	var minus := _mark_button("-", on_delta.bind(-1))
	var plus := _mark_button("+", on_delta.bind(1))
	row.add_child(minus)
	row.add_child(plus)
	_crew_buttons.append(minus)
	_crew_buttons.append(plus)
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
	if _ship == null or not _orders_editable():
		return
	_ship.adjust_rowing_speed(delta)
	_show_current()
	get_tree().call_group("interaction", "preview_phase_step", _ship)


func _turn(steps: int) -> void:
	if _ship == null or not _orders_editable():
		return
	_ship.turn_facing(steps)
	_show_current()
	get_tree().call_group("interaction", "preview_phase_step", _ship)


func _toggle_mast() -> void:
	if _ship == null or not _orders_editable():
		return
	_ship.set_mast_down(not _ship._mastDown)
	_show_current()


func _change_rowing(delta: int) -> void:
	if _ship == null or _ship._owner == null:
		return
	if delta > 0:
		if _ship._oarBanks.is_empty():
			return
		_ship._oarBanks[0]._activeRowers.append(Character.Rower.new(_ship._owner))
	else:
		for bank in _ship._oarBanks:
			if bank._activeRowers.size() > 0:
				bank._activeRowers.pop_back()
				break
	_show_current()


func _change_idle(delta: int) -> void:
	if _ship == null or _ship._owner == null:
		return
	if delta > 0:
		_ship._reserveRowers.append(Character.Rower.new(_ship._owner))
	elif _ship._reserveRowers.size() > 0:
		_ship._reserveRowers.pop_back()
	_show_current()


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


func _orders_editable() -> bool:
	return TurnController.phase == TurnController.Phase.SETUP or TurnController.phase == TurnController.Phase.COMMAND


func _hp_cap() -> int:
	var key := _ship.get_instance_id()
	if not _hp_max.has(key):
		_hp_max[key] = maxi(_ship._flotationHits, 1)
	return int(_hp_max[key])


func _show_current() -> void:
	var has_ship := _ship != null
	var orders := has_ship and _orders_editable()
	_hp_minus.disabled = not has_ship
	_hp_plus.disabled = not has_ship
	_slower.disabled = not orders
	_faster.disabled = not orders
	_mast.disabled = not orders
	_face_left.disabled = not orders
	_face_right.disabled = not orders
	for button in _crew_buttons:
		button.disabled = not has_ship
	if not has_ship:
		_owner_label.text = ""
		_type_label.text = "Click a ship"
		_facing_label.text = ""
		_hp_text.text = "0/0"
		_speed_label.text = "Speed 0"
		_mast.text = "Mast: Up"
		_crew_label.text = "Crew: Rowing 0  Boarding 0  Inactive 0\nTotal 0  Max 0"
		_engineer_label.text = "Engineers: Inactive 0  Total 0"
		_marine_label.text = "Marines: Soldier 0  Javeline 0  Archers 0  Total 0"
		return

	_owner_label.text = _owner_name()
	_type_label.text = _hull_title()
	_facing_label.text = _SHORT_FACING[posmod(_ship._facing, _SHORT_FACING.size())]

	_hp_text.text = "%d/%d" % [_ship._flotationHits, _hp_cap()]
	_speed_label.text = "Speed %d" % _ship.get_overall_speed()
	var mast := "Up"
	if _ship._mastDown:
		mast = "Down"
	_mast.text = "Mast: %s" % mast
	_fill_crew_text()


func _fill_crew_text() -> void:
	var rowing := _ship.getActiveRowers().size()
	var boarding := _ship._boardingArchers.size() + _ship._boardingJavelins.size() + _ship._boardingMelee.size()
	var inactive := _ship._reserveRowers.size()
	var soldiers := _ship._marineSoldiers.size()
	var javelineers := _ship._marineJavelineers.size()
	var archers := _ship._marineArchers.size()
	var engineers := _ship._engineers.size()
	var idle_engineers := 0
	for engineer in _ship._engineers:
		if engineer._allocatedTo == null:
			idle_engineers += 1
	var total := rowing + inactive + _ship._deckCrew.size() + soldiers + javelineers + archers + engineers
	var capacity := _QUADRIREME_CAPACITY
	if _ship.get_ship_kind() == SpeedCalculator.ShipKind.TRIREME:
		capacity = _TRIREME_CAPACITY
	_crew_label.text = "Crew: Rowing %d  Boarding %d  Inactive %d\nTotal %d  Max %d" % [rowing, boarding, inactive, total, capacity]
	_engineer_label.text = "Engineers: Inactive %d  Total %d" % [idle_engineers, engineers]
	_marine_label.text = "Marines: Soldier %d  Javeline %d  Archers %d  Total %d" % [soldiers, javelineers, archers, soldiers + javelineers + archers]
