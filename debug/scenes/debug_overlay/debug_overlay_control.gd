extends Control
class_name DebugOverlayControl

const MAX_VECTOR_LENGTH: float = 3.0

var vectors = {}

func _draw() -> void:
	for vector: DebugVector in vectors.values():
		vector.draw(self, get_parent().camera)

func draw_triangle(pos: Vector2, dir: Vector2, size: float, color: Color) -> void:
	var a: Vector2 = pos + dir * size
	var b: Vector2 = pos + dir.rotated(2 * PI / 3) * size
	var c: Vector2 = pos + dir.rotated(4 * PI / 3) * size
	var points: PackedVector2Array = PackedVector2Array([a, b, c])
	draw_polygon(points, PackedColorArray([color]))
	
func draw(key: String, origin: Vector3, vector: Vector3, color: Color, width: float) -> void:
	vectors[key] = DebugVector.new(origin, vector, color, width)
	queue_redraw()

func clear(key: String) -> void:
	vectors.erase(key)
	queue_redraw()

class DebugVector:
	var origin: Vector3
	var vector: Vector3
	var color: Color
	var width: float

	func _init(origin: Vector3, vector: Vector3, color: Color, width: float) -> void:
		self.origin = origin
		self.vector = vector
		self.color = color
		self.width = width

	func draw(control: DebugOverlayControl, camera: Camera3D) -> void:
		var scale: float = 1.0 / (vector.length() / MAX_VECTOR_LENGTH) if vector.length() > MAX_VECTOR_LENGTH else 1.0
		var start: Vector2 = camera.unproject_position(origin)
		var end: Vector2 = camera.unproject_position(origin + vector)
		control.draw_line(start, end, color, width * scale)
		control.draw_triangle(end, start.direction_to(end), width * 2 * (3 if scale < 1.0 else 1), color)
