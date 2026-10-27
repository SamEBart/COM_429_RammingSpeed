extends CanvasLayer
## Short copy of the turn and movement lines that also go to the Godot output.

const _MenuFrame := preload("res://scripts/turn/menu_frame.gd")

static var _view
var _lines: PackedStringArray = []
var _scroll: ScrollContainer
var _body: Label
const MAX_LINES := 40


func _ready() -> void:
	_view = self
	layer = 10
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_to_group("screen_menu")
	add_child(host)

	var panel := PanelContainer.new()
	panel.add_theme_constant_override("margin_top", 4)
	panel.add_theme_constant_override("margin_right", 18)
	host.add_child(panel)

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

	_MenuFrame.new().setup(host, panel, Vector2.ONE, 16.0)


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
