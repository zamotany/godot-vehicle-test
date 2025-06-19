extends RayCast3D

@export var spring_length: float = 0.5
@export var spring_stiffness: float = 30
@export var spring_damer: float = 3
@export var wheel_radius: float = 0.33

@onready var vehicle: RigidBody3D = get_parent().get_parent()

var previous_spring_displacement: float = 0.0

# References
# - https://medium.com/@remvoorhuis/how-to-program-realistic-vehicle-physics-for-realtime-environments-games-part-i-simple-b4c2375dc7fa

func _ready() -> void:
	target_position.y = -(spring_length + wheel_radius)
	add_exception(vehicle)

func _physics_process(delta: float) -> void:
	if is_colliding():
		# The direction the force will be applied
		var suspention_direction := global_basis.y
		var raycast_origin = global_position
		var raycast_collistion_point = get_collision_point()
		
		# Subtract wheel radius because length of raycast is spring length + wheel radius
		var compressed_spring_length = raycast_collistion_point.distance_to(raycast_origin) - wheel_radius
		var spring_displacement = clamp(spring_length - compressed_spring_length, 0, spring_length)
		
		var spring_force = spring_stiffness * spring_displacement
		
		# Divide by delta because we want time independent velocity, since apply_force will make the force time dependent again
		var spring_displacement_velocity = max((previous_spring_displacement - spring_displacement) / delta, 0)
		
		var damper_force = spring_damer * spring_displacement_velocity
		var suspension_force = basis.y * max(spring_force - damper_force, 0)
		
		previous_spring_displacement = spring_displacement
		
		# Apply the force at a contact point of pring with vehicle chassis
		vehicle.apply_force(suspention_direction * suspension_force, raycast_origin)
		GDebugOverlay.draw(self, suspention_direction * suspension_force * 0.0005)
