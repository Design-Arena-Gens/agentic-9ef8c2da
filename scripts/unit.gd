extends Node2D

signal died(unit)

var stats: Dictionary
var is_player: bool = true
var main_ref: Node = null
var current_health: float = 0.0
var attack_cooldown: float = 0.0
var target: Node2D = null
var move_direction := Vector2.RIGHT
var body_size := Vector2(48, 32)
var rng := RandomNumberGenerator.new()
var _has_reported_death := false

func _ready() -> void:
    set_physics_process(true)

func setup(data: Dictionary, is_player_side: bool, main_node: Node) -> void:
    stats = data
    is_player = is_player_side
    main_ref = main_node
    current_health = data.get("max_hp", 50)
    move_direction = Vector2.RIGHT if is_player else Vector2.LEFT
    rng.randomize()
    position.y += rng.randf_range(-18.0, 18.0)
    attack_cooldown = 0.0
    body_size = data.get("body_size", body_size)
    update()

func _physics_process(delta: float) -> void:
    if current_health <= 0.0:
        return

    attack_cooldown = max(attack_cooldown - delta, 0.0)

    if target and not _is_target_valid(target):
        target = null

    if target == null and main_ref:
        target = main_ref.find_target_for(self)

    var desired_position := position
    var max_speed := stats.get("speed", 80.0)
    var attack_range := stats.get("range", 45.0)

    var has_attacked := false
    if target:
        var target_pos := target.global_position
        var distance := global_position.distance_to(target_pos)
        if distance <= attack_range:
            has_attacked = _attempt_attack()
        else:
            desired_position += move_direction * max_speed * delta
    else:
        desired_position += move_direction * max_speed * delta

    position = desired_position

    if has_attacked:
        update()

    if main_ref:
        main_ref.keep_unit_inside_bounds(self)

func _attempt_attack() -> bool:
    if attack_cooldown > 0.0 or target == null:
        return false
    if target.has_method("take_damage"):
        target.take_damage(stats.get("damage", 6))
    attack_cooldown = stats.get("attack_cooldown", 1.0)
    if target.has_method("is_alive") and not target.is_alive():
        target = null
    return true

func take_damage(amount: float) -> void:
    if current_health <= 0.0:
        return
    current_health = max(current_health - amount, 0.0)
    update()
    if current_health <= 0.0:
        _die()

func _die() -> void:
    if _has_reported_death:
        return
    _has_reported_death = true
    died.emit(self)
    queue_free()

func is_alive() -> bool:
    return current_health > 0.0

func _exit_tree() -> void:
    if _has_reported_death:
        return
    _has_reported_death = true
    died.emit(self)

func _is_target_valid(target_node: Node) -> bool:
    if target_node == null:
        return false
    if not is_instance_valid(target_node):
        return false
    if target_node.has_method("is_alive"):
        return target_node.is_alive()
    return true

func _draw() -> void:
    var body_color := Color(0.24, 0.88, 0.42) if is_player else Color(0.95, 0.34, 0.34)
    var outline_color := Color(0.05, 0.08, 0.12)
    var rect := Rect2(-body_size * 0.5, body_size)
    draw_rect(rect, body_color)
    draw_rect(rect, outline_color, false, 3.0)

    var weapon_length := stats.get("range", 36.0) * 0.45
    var dir := move_direction.normalized()
    draw_line(Vector2.ZERO, dir * weapon_length, outline_color, 4.0)

    var hp_ratio := 0.0
    if stats.get("max_hp", 0) > 0:
        hp_ratio = current_health / stats.get("max_hp", 1)
    var bar_pos := Vector2(-body_size.x * 0.5, -body_size.y * 0.9)
    var bar_size := Vector2(body_size.x, 8.0)
    draw_rect(Rect2(bar_pos, bar_size), Color(0.12, 0.12, 0.12, 0.9))
    draw_rect(Rect2(bar_pos, Vector2(bar_size.x * hp_ratio, bar_size.y)), Color(0.22, 0.85, 0.32))
