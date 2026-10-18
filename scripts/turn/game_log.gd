extends CanvasLayer
## Short copy of the turn and movement lines that also go to the Godot output.

static var _view
var _lines: PackedStringArray = []
var _body: Label
const MAX_LINES := 6


func _ready() -> void:
	_view = self
	layer = 10
	var panel := PanelContainer.new()
	panel.add_to_group("screen_menu")
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 16
	panel.offset_top = -120
	panel.offset_right = 340
	panel.offset_bottom = -16
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Output"
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.max_lines_visible = 4
	_body.add_theme_font_size_override("font_size", 13)
	_body.custom_minimum_size = Vector2(300, 48)
	box.add_child(_body)


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
