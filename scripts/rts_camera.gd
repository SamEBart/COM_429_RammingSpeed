extends Node3D

@onready var _rotationX = $CameraRotationX
@onready var _zoomPivot = $CameraRotationX/CameraZoomPivot
@onready var _camera = $CameraRotationX/CameraZoomPivot/Camera3D

var _moveSpeed = 0.6
var _moveTarget: Vector3
var _rotateKeysSpeed = 1.5
var _rotateKeysTarget: float
var _zoomSpeed = 2.0
var _zoomTarget: float
var _minZoom = -20.0
var _maxZoom = 20.0
var _mouseSensitivity = 0.2

func _ready() -> void:
	_moveTarget = position
	_rotateKeysTarget = rotation_degrees.y
	_zoomTarget = _camera.position.z

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed("Rotate"):
		_rotateKeysTarget -= event.relative.x * _mouseSensitivity
		_rotationX.rotation_degrees.x -= event.relative.y * _mouseSensitivity
		_rotationX.rotation_degrees.x = clamp(_rotationX.rotation_degrees.x, -10, 30)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Rotate"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.is_action_just_released("Rotate"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# GET INPUT DIRECTIONS
	var inputDirection = Input.get_vector("Left", "Right", "Up", "Down")
	var movementDirection = (transform.basis * Vector3(inputDirection.x, 0, inputDirection.y)).normalized()
	var rotateKeys = Input.get_axis("RotateCameraRight", "RotateCameraLeft")
	var zoomDirection = (int(Input.is_action_just_released("CameraZoomOut")) -
						int(Input.is_action_just_released("CameraZoomIn")))
	
	# SET MOVEMENT TARGETS
	_moveTarget += _moveSpeed * movementDirection
	_rotateKeysTarget += rotateKeys * _rotateKeysSpeed
	_zoomTarget += zoomDirection * _zoomSpeed
	
	# LERP TO MOVEMENTS
	position = lerp(position, _moveTarget, 0.05)
	rotation_degrees.y = lerp(rotation_degrees.y, _rotateKeysTarget, 0.05)
	_camera.position.z = lerp(_camera.position.z, _zoomTarget, 0.10)
