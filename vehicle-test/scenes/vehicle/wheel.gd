extends RayCast3D

@export var spring_length: float = 0.5
@export var spring_stiffness: float = 30
@export var spring_damer: float = 3
@export var wheel_radius: float = 0.33
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
	process_suspension(delta)
	process_acceleration(delta)
	process_steering(delta)
	

func process_suspension(delta: float) -> void:
	if is_colliding():
			# The direction the force will be applied
			var suspension_direction := global_basis.y
			var raycast_origin = global_position
			var raycast_collision_point = get_collision_point()
			
			# Subtract wheel radius because length of raycast is spring length + wheel radius
			var compressed_spring_length = raycast_collision_point.distance_to(raycast_origin) - wheel_radius
			var spring_displacement = clamp(spring_length - compressed_spring_length, 0, spring_length)
			
			var spring_force = spring_stiffness * spring_displacement
			
			# Divide by delta because we want time independent velocity, since apply_force will make the force time dependent again
			var spring_displacement_velocity = max((previous_spring_displacement - spring_displacement) / delta, 0)
			
			var damper_force = spring_damer * spring_displacement_velocity
			var suspension_force = basis.y * max(spring_force - damper_force, 0)
			
			previous_spring_displacement = spring_displacement
			
			# Apply the force at a contact point of spring with vehicle chassis
			vehicle.apply_force(suspension_direction * suspension_force, raycast_origin - vehicle.global_position)
			GDebugOverlay.draw(name + "_suspension", self, suspension_direction * suspension_force * 0.0005)

func process_acceleration(_delta: float) -> void:
	if not use_as_traction:
		return

	# TODO: engine RMP / torque simulation + power curve
	# TODO: transmission simulation (1. simple clutch, 2. gears)
	# TODO: brake simulation (with slip)
	
	var raycast_collision_point = get_collision_point()
	# T [nm] = r [m] * F [N] so to go from torque to force we need to divide it by wheel radius.
	var engine_power: float = 260 / wheel_radius
	var input: float = 0.0

	if Input.is_action_pressed("ui_up"):
		input = 1.0
	
	if Input.is_action_pressed("ui_down"):
		input = -1.0


	var acceleration_direction = -global_basis.z
	var acceleration_force = acceleration_direction * engine_power * input

	vehicle.apply_force(acceleration_force, raycast_collision_point - vehicle.global_position)
	GDebugOverlay.draw_with_origin(name + "_acceleration", raycast_collision_point, acceleration_force * 0.0005, Color.BLUE)

	
func process_steering(_delta: float) -> void:
	if not use_as_steering:
		return
