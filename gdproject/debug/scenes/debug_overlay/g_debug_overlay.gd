extends Node

signal draw_vector(key: String, origin: Vector3, vector: Vector3, color: Color, width: float)
signal clear_vector(key: String)

func draw(key: String, object: Node3D, vector: Vector3, color: Color = Color.GREEN, width: float = 3.0) -> void:
	draw_vector.emit(key, object.global_transform.origin, vector, color, width)

func draw_with_origin(key: String, origin: Vector3, vector: Vector3, color: Color = Color.GREEN, width: float = 3.0) -> void:
	draw_vector.emit(key, origin, vector, color, width)

func clear(key: String) -> void:
	clear_vector.emit(key)
