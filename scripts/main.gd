extends Node2D

const UNIT_LIBRARY := {
    "grunt": {
        "name": "Grunt",
        "cost": 50,
        "speed": 120.0,
        "damage": 8.0,
        "attack_cooldown": 0.8,
        "range": 52.0,
        "max_hp": 70.0,
        "body_size": Vector2(44, 30)
    },
    "ranger": {
        "name": "Ranger",
        "cost": 80,
        "speed": 140.0,
        "damage": 6.0,
        "attack_cooldown": 0.45,
        "range": 120.0,
        "max_hp": 55.0,
        "body_size": Vector2(40, 26)
    },
    "tank": {
        "name": "Tank",
        "cost": 120,
        "speed": 90.0,
        "damage": 18.0,
        "attack_cooldown": 1.4,
        "range": 70.0,
        "max_hp": 135.0,
        "body_size": Vector2(60, 38)
    }
}

const PASSIVE_INCOME := 18
const BATTLEFIELD_MIN_X := 80.0
const BATTLEFIELD_MAX_X := 1200.0
const PLAYER_SPAWN_X := 220.0
const ENEMY_SPAWN_X := 1060.0

@onready var player_base := $PlayerBase
@onready var enemy_base := $EnemyBase
@onready var units_container := $Units
@onready var resource_timer := $ResourceTimer
@onready var enemy_spawn_timer := $EnemySpawnTimer
@onready var resource_label := $UILayer/HUD/Margin/VBox/TopRow/ResourceLabel
@onready var status_label := $UILayer/HUD/Margin/VBox/TopRow/StatusLabel
@onready var grunt_button := $UILayer/HUD/Margin/VBox/ButtonRow/GruntButton
@onready var ranger_button := $UILayer/HUD/Margin/VBox/ButtonRow/RangerButton
@onready var tank_button := $UILayer/HUD/Margin/VBox/ButtonRow/TankButton
@onready var game_over_panel := $UILayer/GameOverPanel
@onready var result_label := $UILayer/GameOverPanel/Container/ResultLabel
@onready var restart_button := $UILayer/GameOverPanel/Container/RestartButton

var player_gold: int = 150
var enemy_gold: int = 150
var game_over: bool = false
var player_units: Array = []
var enemy_units: Array = []

var unit_scene := preload("res://scenes/Unit.tscn")
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    RenderingServer.set_default_clear_color(Color(0.08, 0.09, 0.12))
    resource_timer.timeout.connect(_on_resource_timer_timeout)
    enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
    grunt_button.pressed.connect(func(): spawn_player_unit("grunt"))
    ranger_button.pressed.connect(func(): spawn_player_unit("ranger"))
    tank_button.pressed.connect(func(): spawn_player_unit("tank"))
    restart_button.pressed.connect(_on_restart_pressed)
    player_base.destroyed.connect(func(_base): end_game(false))
    enemy_base.destroyed.connect(func(_base): end_game(true))
    _update_unit_button_text()
    update_ui()

func _process(_delta: float) -> void:
    if game_over:
        return
    update_battle_status()

func spawn_player_unit(unit_key: String) -> void:
    if game_over:
        return
    var data := UNIT_LIBRARY.get(unit_key, null)
    if data == null:
        return
    if player_gold < data["cost"]:
        return
    player_gold -= data["cost"]
    var unit := unit_scene.instantiate()
    units_container.add_child(unit)
    unit.position = Vector2(PLAYER_SPAWN_X, player_base.position.y - 20.0)
    unit.setup(data, true, self)
    register_unit(unit)
    update_ui()

func spawn_enemy_unit(unit_key: String) -> void:
    if game_over:
        return
    var data := UNIT_LIBRARY.get(unit_key, null)
    if data == null:
        return
    if enemy_gold < data["cost"]:
        return
    enemy_gold -= data["cost"]
    var unit := unit_scene.instantiate()
    units_container.add_child(unit)
    unit.position = Vector2(ENEMY_SPAWN_X, enemy_base.position.y - 20.0)
    unit.setup(data, false, self)
    register_unit(unit)
    update_ui()

func register_unit(unit) -> void:
    if unit.is_player:
        player_units.append(unit)
    else:
        enemy_units.append(unit)
    unit.died.connect(_on_unit_died)

func _on_unit_died(unit) -> void:
    player_units.erase(unit)
    enemy_units.erase(unit)
    update_ui()

func _on_resource_timer_timeout() -> void:
    if game_over:
        return
    player_gold += PASSIVE_INCOME
    enemy_gold += PASSIVE_INCOME
    update_ui()

func _on_enemy_spawn_timer_timeout() -> void:
    if game_over:
        return
    var affordable := []
    for key in UNIT_LIBRARY.keys():
        var data := UNIT_LIBRARY[key]
        if enemy_gold >= data["cost"]:
            affordable.append(key)
    if affordable.is_empty():
        return
    affordable.sort_custom(func(a, b): return UNIT_LIBRARY[a]["cost"] < UNIT_LIBRARY[b]["cost"])
    var choice := affordable[-1]
    if affordable.size() > 1 and rng.randf() < 0.35:
        choice = affordable[rng.randi_range(0, affordable.size() - 1)]
    spawn_enemy_unit(choice)

func find_target_for(unit: Node2D) -> Node2D:
    var opponents := enemy_units if unit.is_player else player_units
    var closest: Node2D = null
    var best_dist := INF
    for opp in opponents:
        if not is_instance_valid(opp):
            continue
        if not opp.is_alive():
            continue
        var dist := unit.global_position.distance_to(opp.global_position)
        if dist < best_dist:
            best_dist = dist
            closest = opp
    if closest != null:
        return closest
    if unit.is_player:
        return enemy_base if enemy_base.is_alive() else null
    return player_base if player_base.is_alive() else null

func keep_unit_inside_bounds(unit: Node2D) -> void:
    var pos := unit.position
    pos.x = clamp(pos.x, BATTLEFIELD_MIN_X, BATTLEFIELD_MAX_X)
    unit.position = pos

func end_game(player_won: bool) -> void:
    if game_over:
        return
    game_over = true
    update_ui()
    var message := "Victory! You destroyed the enemy stronghold." if player_won else "Defeat! Your stronghold has fallen."
    status_label.text = message
    result_label.text = message
    game_over_panel.visible = true

func update_ui() -> void:
    update_resource_label()
    update_battle_status()
    update_button_states()

func update_resource_label() -> void:
    resource_label.text = "Gold: %d | Enemy Gold: %d" % [player_gold, enemy_gold]

func update_battle_status() -> void:
    status_label.text = "Your Base: %d HP | Enemy Base: %d HP" % [player_base.current_health, enemy_base.current_health]

func update_button_states() -> void:
    for button in [grunt_button, ranger_button, tank_button]:
        var key := _button_to_key(button)
        var cost := UNIT_LIBRARY[key]["cost"]
        button.disabled = player_gold < cost or game_over
        if not game_over:
            button.text = "%s (%d)" % [UNIT_LIBRARY[key]["name"], cost]
        else:
            button.text = UNIT_LIBRARY[key]["name"]

func _button_to_key(button: Button) -> String:
    if button == grunt_button:
        return "grunt"
    if button == ranger_button:
        return "ranger"
    return "tank"

func _on_restart_pressed() -> void:
    restart_match()

func restart_match() -> void:
    for unit in player_units.duplicate():
        if is_instance_valid(unit):
            unit.queue_free()
    for unit in enemy_units.duplicate():
        if is_instance_valid(unit):
            unit.queue_free()
    player_units.clear()
    enemy_units.clear()
    player_base.reset()
    enemy_base.reset()
    player_gold = 150
    enemy_gold = 150
    game_over = false
    game_over_panel.visible = false
    resource_timer.start()
    enemy_spawn_timer.start()
    update_ui()

func _update_unit_button_text() -> void:
    grunt_button.text = "%s (%d)" % [UNIT_LIBRARY["grunt"]["name"], UNIT_LIBRARY["grunt"]["cost"]]
    ranger_button.text = "%s (%d)" % [UNIT_LIBRARY["ranger"]["name"], UNIT_LIBRARY["ranger"]["cost"]]
    tank_button.text = "%s (%d)" % [UNIT_LIBRARY["tank"]["name"], UNIT_LIBRARY["tank"]["cost"]]
