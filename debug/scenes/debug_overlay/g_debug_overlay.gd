extends Node

signal draw_vector(object: Node3D, color: Color, width: float)

func draw(object: Node3D, vector: Vector3, color: Color = Color.GREEN, width: float = 2.0) -> void:
	draw_vector.emit(object, vector, color, width)
