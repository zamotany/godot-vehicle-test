extends RigidBody3D

@export_range(0.0, 1.0) var camera_sensitivity = 0.01
@export var tilt_limit = deg_to_rad(75)
@export var camera: Camera3D

@export_group("Wheels")
@export var front_left: WheelConfig
@export var front_right: WheelConfig
@export var rear_left: WheelConfig
@export var rear_right: WheelConfig

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/CameraArm

var is_camera_locked: bool = true

func _ready() -> void:
	# Attach remote transform to camera. Useful if we want to detach camera from vehicle at some point.
	var remote_camera := RemoteTransform3D.new()
	remote_camera.remote_path = camera.get_path()
	camera_arm.add_child(remote_camera)

func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_unlock_camera"):
		is_camera_locked = false
	else:
		is_camera_locked = true
	


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and !is_camera_locked:
		# Horizontal rotation
		camera_pivot.rotation.y += -event.relative.x * camera_sensitivity

		# Vertical rotation
		camera_arm.rotation.x -= event.relative.y * camera_sensitivity
		camera_arm.rotation.x = clamp(camera_arm.rotation.x, deg_to_rad(-90), deg_to_rad(90))