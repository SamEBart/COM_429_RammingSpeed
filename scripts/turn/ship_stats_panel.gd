extends CanvasLayer
## Bottom-right stats for the ship that was just clicked.

var _ship: Ship
var _body: Label
var _slower: Button
var _faster: Button
var _mast: Button
var _turn_left: Button
var _turn_right: Button


func _ready() -> void:
	add_to_group("ship_stats")
	var panel := PanelContainer.new()
	panel.add_to_group("screen_menu")
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -340
	panel.offset_top = -420
	panel.offset_right = -16
	panel.offset_bottom = -16
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Ship Stats"
	box.add_child(title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(280, 0)
	box.add_child(_body)

	var row := HBoxContainer.new()
	box.add_child(row)
	_slower = Button.new()
	_slower.text = "Speed -"
	_slower.pressed.connect(_change_speed.bind(-1))
	row.add_child(_slower)
	_faster = Button.new()
	_faster.text = "Speed +"
	_faster.pressed.connect(_change_speed.bind(1))
	row.add_child(_faster)

	_mast = Button.new()
	_mast.text = "Toggle Mast"
	_mast.pressed.connect(_toggle_mast)
	box.add_child(_mast)

	var facing_row := HBoxContainer.new()
	box.add_child(facing_row)
	_turn_left = Button.new()
	_turn_left.text = "Turn Left"
	_turn_left.pressed.connect(_turn.bind(1))
	facing_row.add_child(_turn_left)
	_turn_right = Button.new()
	_turn_right.text = "Turn Right"
	_turn_right.pressed.connect(_turn.bind(-1))
	facing_row.add_child(_turn_right)

	TurnController.phase_changed.connect(func(_p, _s, _t):
		_show_current()
		if _ship != null:
			get_tree().call_group("interaction", "follow_selected_ship", _ship)
	)
	clear_ship()


func show_ship(unit: Node) -> void:
	if unit is Ship:
		_ship = unit
	else:
		_ship = null
	_show_current()


func clear_ship() -> void:
	_ship = null
	_show_current()


func _change_speed(delta: int) -> void:
	if _ship == null or not _orders_editable():
		return
	_ship.adjust_rowing_speed(delta)
	_show_current()


func _toggle_mast() -> void:
	if _ship == null or not _orders_editable():
		return
	_ship.set_mast_down(not _ship._mastDown)
	_show_current()


func _turn(steps: int) -> void:
	if _ship == null or not _orders_editable():
		return
	_ship.turn_facing(steps)
	_show_current()
	get_tree().call_group("interaction", "preview_phase_step", _ship)


func _orders_editable() -> bool:
	return TurnController.phase == TurnController.Phase.SETUP or TurnController.phase == TurnController.Phase.COMMAND


func _show_current() -> void:
	var editable := _ship != null and _orders_editable()
	_slower.disabled = not editable
	_faster.disabled = not editable
	_mast.disabled = not editable
	_turn_left.disabled = not editable
	_turn_right.disabled = not editable
	if _ship == null:
		_body.text = "Click a ship."
		return
	var kind := "Quadrireme"
	if _ship.get_ship_kind() == SpeedCalculator.ShipKind.TRIREME:
		kind = "Trireme"
	var owner_name := "None"
	if _ship._owner != null:
		owner_name = _ship._owner.getName()
	var deck_crew_count := 0
	if _ship._deckCrew != null:
		deck_crew_count = _ship._deckCrew.size()
	var mast := "Up"
	if _ship._mastDown:
		mast = "Down"
	var speed := _ship.get_overall_speed()
	var phase_line := ""
	if TurnController.phase == TurnController.Phase.EXECUTION:
		phase_line = "\n" + PhaseSpeedChart.describe_phase(speed, TurnController.execution_step)
	_body.text = "%s\nOwner: %s\nType: %s\nRowing speed: %d\nMast: %s\nOverall speed: %d\nFacing: %s\n%s%s\nDeck crew: %d\nFlotation: %d\n%s" % [
		_ship.name,
		owner_name,
		kind,
		_ship._rowingSpeed,
		mast,
		speed,
		_ship.get_facing_name(),
		PhaseSpeedChart.describe(speed),
		phase_line,
		deck_crew_count,
		_ship.getFloatationHits(),
		TurnController.get_phase_label(),
	]
