extends ColorRect
## Drag this corner to scale the parent menu. The opposite corner stays put.

const _MAX_SCALE := 1.8

var pivot_corner := Vector2.ZERO
var _dragging := false
var _start_scale := 1.0
var _start_mouse := Vector2.ZERO


func _ready() -> void:
	color = Color(0.85, 0.92, 1.0, 0.55)
	z_index = 5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	var host := get_parent() as Control
	if host:
		host.resized.connect(_keep_pivot)


func _max_scale(host: Control) -> float:
	var viewport := host.get_viewport_rect().size
	var margin := 36.0
	var card := host.size
	if card.x < 1.0 or card.y < 1.0:
		return 1.0
	var pivot := card * pivot_corner
	var handle_local := card * (Vector2.ONE - pivot_corner)
	var anchor: Vector2 = host.get_global_transform() * pivot
	var delta := handle_local - pivot
	var limit := _MAX_SCALE
	if absf(delta.x) > 1.0:
		var room_x: float = (viewport.x - margin - anchor.x) / delta.x if delta.x > 0.0 else (margin - anchor.x) / delta.x
		limit = minf(limit, room_x)
	if absf(delta.y) > 1.0:
		var room_y: float = (viewport.y - margin - anchor.y) / delta.y if delta.y > 0.0 else (margin - anchor.y) / delta.y
		limit = minf(limit, room_y)
	return clampf(limit, 0.7, _MAX_SCALE)


func _keep_pivot() -> void:
	var host := get_parent() as Control
	if host:
		host.pivot_offset = host.size * pivot_corner


func _gui_input(event: InputEvent) -> void:
	var host := get_parent() as Control
	if host == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_start_scale = host.scale.x
			_start_mouse = event.global_position
			_keep_pivot()
		else:
			_dragging = false
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var outward := Vector2(1.0, 1.0) - pivot_corner * 2.0
		var pulled: float = (event.global_position - _start_mouse).dot(outward)
		var next := clampf(_start_scale + pulled / 200.0, 0.7, _max_scale(host))
		_keep_pivot()
		host.scale = Vector2(next, next)
		accept_event()
