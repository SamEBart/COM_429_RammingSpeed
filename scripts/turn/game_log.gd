extends CanvasLayer
## Short copy of the turn and movement lines that also go to the Godot output.

const _ScaleHandle := preload("res://scripts/turn/menu_scale_handle.gd")

static var _view
var _lines: PackedStringArray = []
var _scroll: ScrollContainer
var _body: Label
const MAX_LINES := 40


func _ready() -> void:
	_view = self
	layer = 10
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	host.grow_horizontal = Control.GROW_DIRECTION_END
	host.grow_vertical = Control.GROW_DIRECTION_BEGIN
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_to_group("screen_menu")
	add_child(host)

	var panel := PanelContainer.new()
	panel.add_theme_constant_override("margin_top", 4)
	panel.add_theme_constant_override("margin_right", 18)
	host.add_child(panel)
	panel.resized.connect(_fit_output_host.bind(host, panel))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Output"
	title.add_theme_font_size_override("font_size", 11)
	box.add_child(title)

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(280, 96)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 10)
	_body.custom_minimum_size = Vector2(260, 0)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_body)

	var handle = _ScaleHandle.new()
	handle.pivot_corner = Vector2(0, 1)
	handle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	handle.offset_left = -14
	handle.offset_top = 0
	handle.offset_right = 0
	handle.offset_bottom = 14
	host.add_child(handle)


func _fit_output_host(host: Control, panel: Control) -> void:
	var card_size := panel.size
	host.offset_left = 16.0
	host.offset_bottom = -16.0
	host.offset_right = 16.0 + card_size.x
	host.offset_top = -16.0 - card_size.y


static func push(text: String) -> void:
	print(text)
	if _view:
		_view._add(text)


func _add(text: String) -> void:
	for line in text.split("\n"):
		if line.is_empty():
			continue
		_lines.append(line)
	while _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	_body.text = "\n".join(_lines)
	_follow_latest.call_deferred()


func _follow_latest() -> void:
	await get_tree().process_frame
	var bar := _scroll.get_v_scroll_bar()
	_scroll.scroll_vertical = int(bar.max_value)
