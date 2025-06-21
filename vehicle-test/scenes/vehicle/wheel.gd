extends RayCast3D

@export var spring_length: float = 0.5
@export var spring_stiffness: float = 30
@export var spring_damper: float = 3
@export var wheel_radius: float = 0.33
@export var grip_coefficient: float = 30.0
@export var max_steering_angle: float = 60
@export var torque_on_wheels: float = 500
@export var engine_brake_coefficient: float = 0.1
@export var use_as_traction: bool = false
@export var use_as_steering: bool = false

@onready var vehicle: RigidBody3D = get_parent().get_parent()

var previous_spring_displacement: float = 0.0

# References
# - https://medium.com/@remvoorhuis/how-to-program-realistic-vehicle-physics-for-realtime-environments-games-part-i-simple-b4c2375dc7fa
# - https://www.youtube.com/watch?v=CdPYlj5uZeI

func _ready() -> void:
	target_position.y = - (spring_length + wheel_radius)
	add_exception(vehicle)

func _physics_process(delta: float) -> void:
	GDebugOverlay.clear(name + "_suspension")
	GDebugOverlay.clear(name + "_acceleration")
	GDebugOverlay.clear(name + "_engine_brake")
	GDebugOverlay.clear(name + "_lateral")

	if is_colliding():
		var raycast_collision_point = get_collision_point()
		
		process_suspension(delta, raycast_collision_point)
		process_acceleration(delta, raycast_collision_point)
		process_slip(delta, raycast_collision_point)

		# TODO: visually, acceleration of tires should not be collision-dependent
	
	process_steering(delta)

func to_vehicle_offset(global_point: Vector3) -> Vector3:
	return global_point - vehicle.global_position

func process_suspension(delta: float, raycast_collision_point: Vector3) -> void:
	if is_colliding():
			# The direction the force will be applied
			var suspension_direction := global_basis.y
			var raycast_origin = global_position
			
			
			# Subtract wheel radius because length of raycast is spring length + wheel radius
			var compressed_spring_length = raycast_collision_point.distance_to(raycast_origin) - wheel_radius
			var spring_displacement = clamp(spring_length - compressed_spring_length, 0, spring_length)
			
			var spring_force = spring_stiffness * spring_displacement
			
			# Divide by delta because we want time independent velocity, since apply_force will make the force time dependent again
			var spring_displacement_velocity = max((previous_spring_displacement - spring_displacement) / delta, 0)
			
			var damper_force = spring_damper * spring_displacement_velocity
			var suspension_force = basis.y * max(spring_force - damper_force, 0)
			
			previous_spring_displacement = spring_displacement
			
			# Apply the force at a contact point of spring with vehicle chassis
			vehicle.apply_force(suspension_direction * suspension_force, to_vehicle_offset(raycast_origin))
			GDebugOverlay.draw(name + "_suspension", self, suspension_direction * suspension_force * 0.0005)

func process_acceleration(delta: float, raycast_collision_point: Vector3) -> void:
	if not use_as_traction:
		return

	# TODO: engine RMP / torque simulation + power curve
	# TODO: transmission simulation (1. simple clutch, 2. gears)
	# TODO: brake simulation (with slip)

	# T [nm] = r [m] * F [N] so to go from torque to force we need to divide it by wheel radius.
	var engine_power: float = torque_on_wheels / wheel_radius
	var input: float = Input.get_axis("ui_down", "ui_up")

	var acceleration_direction = - global_basis.z
	var acceleration_force = acceleration_direction * engine_power * input

	vehicle.apply_force(acceleration_force, to_vehicle_offset(raycast_collision_point))
	GDebugOverlay.draw_with_origin(name + "_acceleration", raycast_collision_point, acceleration_force * 0.0005, Color.BLUE)

	if input == 0.0:
		process_engine_brake(delta, raycast_collision_point)


func process_engine_brake(_delta: float, raycast_collision_point: Vector3) -> void:
	var brake_direction: Vector3 = global_basis.z
	var tire_global_velocity: Vector3 = get_point_velocity(global_position)
	
	var brake_force: Vector3 = -brake_direction * brake_direction.dot(tire_global_velocity) * vehicle.mass * engine_brake_coefficient

	vehicle.apply_force(brake_force, to_vehicle_offset(raycast_collision_point))
	GDebugOverlay.draw_with_origin(name + "_engine_brake", raycast_collision_point, brake_force * 0.01, Color.PINK)
	
func process_steering(_delta: float) -> void:
	if not use_as_steering:
		return

	var input: float = Input.get_axis("ui_right", "ui_left")
	var steering_angle: float = clamp(max_steering_angle * input, -max_steering_angle, max_steering_angle)
	
	# Enough to rotate the raycast, since acceleration processing will compute direction based on it's basis.
	rotation.y = deg_to_rad(steering_angle)
	GDebugOverlay.draw(name + "_steering", self, -global_basis.z, Color.MAGENTA)

func get_point_velocity(global_point: Vector3) -> Vector3:
	# NOTE: no idea what's going on here
	return vehicle.linear_velocity + vehicle.angular_velocity.cross(global_point - vehicle.global_position)

func process_slip(delta: float, raycast_collision_point: Vector3) -> void:
	var slip_direction: Vector3 = global_basis.x
	var tire_global_velocity: Vector3 = get_point_velocity(global_position)
	var lateral_velocity: float = slip_direction.dot(tire_global_velocity)

	var lateral_force: Vector3 = slip_direction * (-lateral_velocity / delta) * grip_coefficient

	vehicle.apply_force(lateral_force, to_vehicle_offset(raycast_collision_point))
	GDebugOverlay.draw_with_origin(name + "_lateral", raycast_collision_point, lateral_force * 0.001, Color.RED)
