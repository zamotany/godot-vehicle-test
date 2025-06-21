extends Control
class_name DebugOverlayControl

var vectors = {}

func _draw() -> void:
	for vector: DebugVector in vectors.values():
		vector.draw(self, get_parent().camera)

func draw_triangle(pos, dir, size, color) -> void:
	var a = pos + dir * size
	var b = pos + dir.rotated(2 * PI / 3) * size
	var c = pos + dir.rotated(4 * PI / 3) * size
	var points = PackedVector2Array([a, b, c])
	draw_polygon(points, PackedColorArray([color]))
	
func draw(key: String, origin: Vector3, vector: Vector3, color: Color, width: float) -> void:
	vectors[key] = DebugVector.new(origin, vector, color, width)
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
		var start = camera.unproject_position(origin)
		var end = camera.unproject_position(origin + vector)
		control.draw_line(start, end, color, width)
		control.draw_triangle(end, start.direction_to(end), width * 2, color)
