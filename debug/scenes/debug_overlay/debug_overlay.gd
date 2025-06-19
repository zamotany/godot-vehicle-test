extends CanvasLayer

@export var camera: Camera3D
@onready var control: DebugOverlayControl = $DebugOverlayControl

func _ready() -> void:
	GDebugOverlay.draw_vector.connect(_on_draw_vector)

func _on_draw_vector(object: Node3D, vector: Vector3, color: Color, width: float) -> void:
	control.draw(object, vector, color, width)
