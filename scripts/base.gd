extends Node2D

signal destroyed(base)

@export var is_player: bool = true
@export var max_health: int = 800

var current_health: int
var base_size := Vector2(160, 220)

func _ready() -> void:
    current_health = max_health
    update()

func reset() -> void:
    current_health = max_health
    update()

func take_damage(amount: float) -> void:
    if current_health <= 0:
        return
    current_health = max(current_health - int(amount), 0)
    update()
    if current_health <= 0:
        destroyed.emit(self)

func heal(amount: float) -> void:
    current_health = clamp(current_health + int(amount), 0, max_health)
    update()

func is_alive() -> bool:
    return current_health > 0

func get_health_ratio() -> float:
    if max_health == 0:
        return 0.0
    return float(current_health) / float(max_health)

func _draw() -> void:
    var body_color := Color(0.28, 0.52, 0.95) if is_player else Color(0.85, 0.32, 0.32)
    var outline_color := Color(0.04, 0.07, 0.1)
    var rect := Rect2(-base_size * 0.5, base_size)
    draw_rect(rect, body_color)
    draw_rect(rect, outline_color, false, 4.0)

    var hp_ratio := get_health_ratio()
    var bar_size := Vector2(base_size.x, 18)
    var bar_pos := Vector2(-base_size.x * 0.5, -base_size.y * 0.55)
    draw_rect(Rect2(bar_pos, bar_size), Color(0.12, 0.12, 0.12, 0.9))
    draw_rect(Rect2(bar_pos, Vector2(bar_size.x * hp_ratio, bar_size.y)), Color(0.22, 0.85, 0.32))

func _process(_delta: float) -> void:
    pass
