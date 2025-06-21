extends CanvasLayer

@export var camera: Camera3D
@onready var control: DebugOverlayControl = $DebugOverlayControl

func _ready() -> void:
	GDebugOverlay.draw_vector.connect(_on_draw_vector)
	GDebugOverlay.clear_vector.connect(_on_clear_vector)

func _on_draw_vector(key: String, origin: Vector3, vector: Vector3, color: Color, width: float) -> void:
	control.draw(key, origin, vector, color, width)

func _on_clear_vector(key: String) -> void:
	control.clear(key)
