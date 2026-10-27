extends Node
## Lets the player move and scale a screen menu.
## Drag any empty part of the menu to move it. Drag any corner to scale it, and the opposite corner stays put.
## The corner handles are invisible. The resize cursor shows when the mouse is over one.

const _HANDLE_SIZE := 14.0
const _MIN_SCALE := 0.7
const _MAX_SCALE := 1.8
const _SCREEN_MARGIN := 8.0

var _host: Control
var _panel: Control
## The corner (0 or 1 on each axis) that stays in place when the menu's content grows or shrinks.
var _home_corner := Vector2.ZERO
## The corner held still right now. Scaling holds the corner across from the dragged one.
var _fixed_corner := Vector2.ZERO
## Screen position of the fixed corner.
var _corner_pos := Vector2.ZERO
var _screen_size := Vector2.ZERO
var _moving := false
var _start_mouse := Vector2.ZERO
var _start_scale := 1.0


## host is the menu root and panel is the visible box the host follows in size.
## start_corner picks the screen corner the menu starts in, margin is its gap from the screen edges.
func setup(host: Control, panel: Control, start_corner: Vector2, margin: float) -> void:
	_host = host
	_panel = panel
	_home_corner = start_corner
	_fixed_corner = start_corner
	_screen_size = host.get_viewport_rect().size
	_corner_pos = _screen_size * start_corner + Vector2(margin, margin) * (Vector2.ONE - start_corner * 2.0)
	host.set_anchors_preset(Control.PRESET_TOP_LEFT)
	host.add_child(self)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_panel_input)
	panel.resized.connect(_place)
	host.get_viewport().size_changed.connect(_on_screen_resized)
	for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		host.add_child(_make_handle(corner))
	_place()


func _make_handle(corner: Vector2) -> ColorRect:
	var handle := ColorRect.new()
	handle.color = Color.TRANSPARENT
	handle.z_index = 5
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	if corner.x == corner.y:
		handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	else:
		handle.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
	handle.anchor_left = corner.x
	handle.anchor_right = corner.x
	handle.anchor_top = corner.y
	handle.anchor_bottom = corner.y
	handle.offset_left = -_HANDLE_SIZE * corner.x
	handle.offset_right = _HANDLE_SIZE * (1.0 - corner.x)
	handle.offset_top = -_HANDLE_SIZE * corner.y
	handle.offset_bottom = _HANDLE_SIZE * (1.0 - corner.y)
	handle.gui_input.connect(_on_handle_input.bind(handle, corner))
	return handle


## Sizes the host to the panel and keeps the fixed corner where it is.
## A menu that grows past the screen edge is drawn inside it, and goes back once it shrinks.
func _place() -> void:
	_host.size = _panel.size
	_host.pivot_offset = _host.size * _fixed_corner
	_host.position = _corner_pos + _push_on_screen() - _host.size * _fixed_corner


## Moves the saved spot back inside the screen edges after a drag.
func _keep_on_screen() -> void:
	_corner_pos += _push_on_screen()
	_host.position = _corner_pos - _host.size * _fixed_corner


## How far the menu has to slide to sit fully inside the screen edges.
func _push_on_screen() -> Vector2:
	var shown := _host.size * _host.scale.x
	var top_left := _corner_pos - shown * _fixed_corner
	var lowest := Vector2.ONE * _SCREEN_MARGIN
	var highest := (_host.get_viewport_rect().size - shown - lowest).max(lowest)
	return top_left.clamp(lowest, highest) - top_left


## Holds a different corner still without moving the menu on screen.
func _pin_corner(corner: Vector2) -> void:
	var shown := _host.size * _host.scale.x
	var top_left := _corner_pos - shown * _fixed_corner
	_fixed_corner = corner
	_corner_pos = top_left + shown * corner
	_place()


## Keeps the menu the same distance from the screen edges of its home corner.
func _on_screen_resized() -> void:
	var screen := _host.get_viewport_rect().size
	_corner_pos += (screen - _screen_size) * _home_corner
	_screen_size = screen
	_place()


func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_moving = event.pressed
		_start_mouse = event.global_position
		_panel.accept_event()
	elif event is InputEventMouseMotion and _moving:
		_corner_pos += event.global_position - _start_mouse
		_start_mouse = event.global_position
		_keep_on_screen()
		_panel.accept_event()


func _on_handle_input(event: InputEvent, handle: Control, corner: Vector2) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pin_corner(Vector2.ONE - corner)
			_start_scale = _host.scale.x
			_start_mouse = event.global_position
		else:
			_pin_corner(_home_corner)
		handle.accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var outward := corner * 2.0 - Vector2.ONE
		var pulled: float = (event.global_position - _start_mouse).dot(outward)
		var next := clampf(_start_scale + pulled / 200.0, _MIN_SCALE, _MAX_SCALE)
		_host.scale = Vector2(next, next)
		_keep_on_screen()
		handle.accept_event()
