extends ShapeCast3D

@export_enum("front_left", "front_right", "rear_left", "rear_right") var wheel_config_key: String

@onready var vehicle: RigidBody3D = get_parent().get_parent()
@onready var wheel_config: WheelConfig = vehicle[wheel_config_key]

var wheel_center_origin: Vector3
var previous_spring_displacement: float = 0.0

# References
# - https://medium.com/@remvoorhuis/how-to-program-realistic-vehicle-physics-for-realtime-environments-games-part-i-simple-b4c2375dc7fa
# - https://www.youtube.com/watch?v=CdPYlj5uZeI

func _ready() -> void:
	# Initial wheel center.
	wheel_center_origin = Vector3.DOWN * wheel_config.spring_length

	# Initial wheel's collision shape position.
	target_position.y = - wheel_config.spring_length

	# Exclude vehicle itself from collision detection.
	add_exception(vehicle)

func _physics_process(delta: float) -> void:
	GDebugOverlay.clear(name + "_suspension")
	GDebugOverlay.clear(name + "_acceleration")
	GDebugOverlay.clear(name + "_engine_brake")
	GDebugOverlay.clear(name + "_lateral")

	if is_colliding():
		# We only care about a single collision point.
		var collision_normal: Vector3 = get_collision_normal(0)
		var global_collision_point: Vector3 = get_collision_point(0)
		
		process_suspension(delta, global_collision_point, collision_normal)
		process_acceleration(delta, global_collision_point)
		process_slip(delta, global_collision_point)

		# TODO: visually, acceleration of tires should not be collision-dependent
	
	process_steering(delta)

	GDebugOverlay.draw_with_origin(name + "_test123", to_global(wheel_center_origin), -global_basis.z * 0.5, Color.ORANGE)

func to_vehicle_local(global_point: Vector3) -> Vector3:
	return global_point - vehicle.global_position

func get_point_velocity(global_point: Vector3) -> Vector3:
	# NOTE: no idea what's going on here
	return vehicle.linear_velocity + vehicle.angular_velocity.cross(global_point - vehicle.global_position)


func process_suspension(delta: float, collision_point: Vector3, collision_normal: Vector3) -> void:
	if is_colliding():
			# The direction the force will be applied
			var suspension_direction := global_basis.y
			var global_raycast_origin = global_position
			
			
			# Calculate distance between wheel center point and contact point of spring with vehicle chassis.
			# We scale the collision normal by wheel radius to get from collision point to wheel center point.
			var compressed_spring_length = (collision_point + collision_normal * wheel_config.wheel_radius).distance_to(global_raycast_origin)
			
			var spring_displacement = clamp(wheel_config.spring_length - compressed_spring_length, 0, wheel_config.spring_length)
			var spring_force = wheel_config.spring_stiffness * spring_displacement
			
			# Divide by delta because we want time independent velocity, since apply_force will make the force time dependent again
			var spring_displacement_velocity = max((previous_spring_displacement - spring_displacement) / delta, 0)
			
			var damper_force = wheel_config.spring_damper * spring_displacement_velocity
			var suspension_force = basis.y * max(spring_force - damper_force, 0)
			
			previous_spring_displacement = spring_displacement
			
			# Apply the force at a contact point of spring with vehicle chassis
			vehicle.apply_force(suspension_direction * suspension_force, to_vehicle_local(global_raycast_origin))
			GDebugOverlay.draw(name + "_suspension", self, suspension_direction * suspension_force * 0.0005)

			# Calculate new wheel center point. Doesn't affect the suspension calculation - only used
			# for drawing debug vectors.
			wheel_center_origin = Vector3.DOWN * compressed_spring_length

func process_acceleration(delta: float, raycast_collision_point: Vector3) -> void:
	if not wheel_config.use_as_traction:
		return

	# TODO: rewrite this simulation

	# T [nm] = r [m] * F [N] so to go from torque to force we need to divide it by wheel radius.
	var engine_power: float = wheel_config.torque_on_wheels / wheel_config.wheel_radius
	var input: float = Input.get_axis("ui_down", "ui_up")

	var acceleration_direction = - global_basis.z
	var acceleration_force = acceleration_direction * engine_power * input

	vehicle.apply_force(acceleration_force, to_vehicle_local(raycast_collision_point))
	GDebugOverlay.draw_with_origin(name + "_acceleration", raycast_collision_point, acceleration_force * 0.0005, Color.BLUE)

	if input == 0.0:
		process_engine_brake(delta, raycast_collision_point)


func process_engine_brake(_delta: float, raycast_collision_point: Vector3) -> void:
	# TODO: rewrite this simulation
	var brake_direction: Vector3 = global_basis.z
	var tire_global_velocity: Vector3 = get_point_velocity(global_position)
	
	var brake_force: Vector3 = - brake_direction * brake_direction.dot(tire_global_velocity) * vehicle.mass * wheel_config.engine_brake_coefficient

	vehicle.apply_force(brake_force, to_vehicle_local(raycast_collision_point))
	GDebugOverlay.draw_with_origin(name + "_engine_brake", raycast_collision_point, brake_force * 0.01, Color.PINK)
	
func process_steering(_delta: float) -> void:
	if not wheel_config.use_as_steering:
		return

	# TODO: rewrite this simulation

	var input: float = Input.get_axis("ui_right", "ui_left")
	var steering_angle: float = clamp(wheel_config.max_steering_angle * input, -wheel_config.max_steering_angle, wheel_config.max_steering_angle)
	
	# Enough to rotate the raycast, since acceleration processing will compute direction based on it's basis.
	rotation.y = deg_to_rad(steering_angle)
	GDebugOverlay.draw(name + "_steering", self, -global_basis.z, Color.MAGENTA)

func process_slip(delta: float, raycast_collision_point: Vector3) -> void:
	# TODO: rewrite this simulation

	var slip_direction: Vector3 = global_basis.x
	var tire_global_velocity: Vector3 = get_point_velocity(global_position)
	var lateral_velocity: float = slip_direction.dot(tire_global_velocity)

	var lateral_force: Vector3 = slip_direction * (-lateral_velocity / delta) * wheel_config.grip_coefficient

	vehicle.apply_force(lateral_force, to_vehicle_local(raycast_collision_point))
	GDebugOverlay.draw_with_origin(name + "_lateral", raycast_collision_point, lateral_force * 0.001, Color.RED)
