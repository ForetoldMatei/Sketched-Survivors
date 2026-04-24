extends CharacterBody2D
class_name Player

const RuntimeSkill = preload("res://scripts/skills/RuntimeSkill.gd")
const ModifierSystem = preload("res://scripts/modifiers/ModifierSystem.gd")
const PROJECTILE_SCENE = preload("res://scenes/actors/projectiles/ProjectileBase.tscn")
const BLOOD_POOL_SCENE = preload("res://scenes/run/effects/BloodPool.tscn")

@export_category("Class")
@export var class_id: StringName = &"class_ink_duelist"

@export_category("References")
@export var stats_component_path: NodePath = NodePath("StatsComponent")
@export var health_component_path: NodePath = NodePath("HealthComponent")
@export var auto_attack_timer_path: NodePath = NodePath("AutoAttackTimer")
@export var active_skill_timer_path: NodePath = NodePath("ActiveSkillTimer")
@export var sketch_visual_path: NodePath = NodePath("SketchVisual")
@export var trail_root_path: NodePath = NodePath("TrailRoot")

@export_category("Dash")
@export var dash_trail_count: int = 5
@export var dash_trail_interval: float = 0.025
@export var dash_burst_radius_bonus: float = 0.0
@export var dash_hit_radius: float = 30.0

@export_category("Vampire")
@export var vampire_pool_radius: float = 28.0
@export var vampire_pool_duration: float = 5.0
@export var vampire_pool_heal_per_second: float = 8.0

@onready var stats_component: StatsComponent = get_node_or_null(stats_component_path)
@onready var health_component: HealthComponent = get_node_or_null(health_component_path)
@onready var auto_attack_timer: Timer = get_node_or_null(auto_attack_timer_path)
@onready var active_skill_timer: Timer = get_node_or_null(active_skill_timer_path)
@onready var sprite: Node2D = get_node_or_null(sketch_visual_path)
@onready var trail_root: Node2D = get_node_or_null(trail_root_path)

var auto_attack_skill: RuntimeSkill
var active_skill: RuntimeSkill
var runtime_skills: Dictionary = {}
var is_dashing: bool = false
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_speed: float = 0.0
var dash_time_remaining: float = 0.0
var dash_hit_cooldowns: Dictionary = {}
var dash_trail_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	var class_def := ContentDB.get_class_def(class_id)
	stats_component.set_base_stats(class_def.get("base_stats", {}))
	auto_attack_skill = _build_runtime_skill(StringName(class_def.get("starting_auto_attack", "")))
	active_skill = _build_runtime_skill(StringName(class_def.get("starting_active_skill", "")))

	for perk_id in RunState.selected_perk_ids:
		ModifierSystem.apply_perk_to_player(self, ContentDB.get_perk_def(perk_id))

	health_component.initialize_from_stats()
	health_component.died.connect(_on_died)
	auto_attack_timer.wait_time = _get_auto_attack_cooldown()
	active_skill_timer.wait_time = _get_active_skill_cooldown()
	EventBus.enemy_died.connect(_on_enemy_died)

func _exit_tree() -> void:
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)

func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)
	if is_dashing:
		_update_dash_state(delta)
	else:
		var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_vector * float(stats_component.get_stat("move_speed", 200.0))
		move_and_slide()

	look_at(get_global_mouse_position())
	if sprite != null:
		sprite.rotation = 0.0

	if auto_attack_timer.is_stopped():
		_fire_auto_attack()
		auto_attack_timer.start(_get_auto_attack_cooldown())

	if active_skill_timer.is_stopped() and Input.is_action_just_pressed("active_skill_1") and not is_dashing:
		_cast_active_skill()
		active_skill_timer.start(_get_active_skill_cooldown())

func _build_runtime_skill(skill_id: StringName) -> RuntimeSkill:
	var runtime_skill := RuntimeSkill.new()
	runtime_skill.setup_from_skill_def(ContentDB.get_skill_def(skill_id))
	runtime_skills[skill_id] = runtime_skill
	return runtime_skill

func get_runtime_skill(skill_id: StringName) -> RuntimeSkill:
	return runtime_skills.get(skill_id)

func apply_modifier(modifier_id: StringName) -> void:
	RunState.selected_modifier_ids.append(modifier_id)
	ModifierSystem.apply_modifier_to_player(self, ContentDB.get_modifier_def(modifier_id))
	auto_attack_timer.wait_time = _get_auto_attack_cooldown()
	active_skill_timer.wait_time = _get_active_skill_cooldown()
	if health_component.current_health > health_component.get_max_health():
		health_component.current_health = health_component.get_max_health()
	health_component.health_changed.emit(health_component.current_health, health_component.get_max_health())

func take_damage(amount: float) -> void:
	if is_invulnerable:
		return
	health_component.take_damage(amount)

func heal(amount: float) -> void:
	health_component.heal(amount * float(stats_component.get_stat("healing_power_mult", 1.0)))

func _fire_auto_attack() -> void:
	if auto_attack_skill == null:
		return
	if auto_attack_skill.has_tag(&"projectile"):
		var projectile := PROJECTILE_SCENE.instantiate()
		projectile.global_position = global_position
		projectile.initialize(
			self,
			auto_attack_skill,
			(get_global_mouse_position() - global_position).normalized(),
			stats_component
		)
		get_tree().current_scene.get_node("ProjectileLayer").add_child(projectile)
		return
	if auto_attack_skill.has_tag(&"melee"):
		_perform_melee_attack(auto_attack_skill)

func _perform_melee_attack(skill: RuntimeSkill) -> void:
	var radius := float(skill.get_value("radius", 72.0)) * float(stats_component.get_stat("area_mult", 1.0))
	var arc_degrees := float(skill.get_value("arc_degrees", 180.0))
	var arc_radians := deg_to_rad(arc_degrees) * 0.5
	var damage := float(skill.get_value("damage", 20.0)) * float(stats_component.get_stat("melee_damage_mult", 1.0))
	var facing := (get_global_mouse_position() - global_position).normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("take_damage"):
			continue
		var to_enemy = enemy.global_position - global_position
		if to_enemy.length() > radius:
			continue
		if absf(facing.angle_to(to_enemy.normalized())) <= arc_radians:
			enemy.take_damage(damage, self)

func _cast_active_skill() -> void:
	if active_skill == null:
		return
	if active_skill.skill_id == &"skill_dash_slash":
		_cast_dash_slash()
	elif active_skill.skill_id == &"skill_sanguine_guard":
		_cast_sanguine_guard()

func _cast_dash_slash() -> void:
	var aim_direction := (get_global_mouse_position() - global_position).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.RIGHT
	var dash_distance := float(active_skill.get_value("dash_distance", 160.0)) * float(stats_component.get_stat("dash_distance_mult", 1.0))
	var dash_duration := maxf(0.05, float(active_skill.get_value("dash_duration", 0.16)))
	dash_direction = aim_direction
	dash_speed = dash_distance / dash_duration
	dash_time_remaining = dash_duration
	dash_hit_cooldowns.clear()
	dash_trail_timer = 0.0
	is_dashing = true
	_set_invulnerable_for(maxf(dash_duration, float(active_skill.get_value("invulnerability_duration", dash_duration))))

func _cast_sanguine_guard() -> void:
	var heal_percent := float(active_skill.get_value("heal_percent", 0.10))
	var flat_heal := float(active_skill.get_value("flat_heal", 0.0))
	var heal_amount := health_component.get_max_health() * heal_percent + flat_heal
	heal(heal_amount)

func _update_dash_state(delta: float) -> void:
	dash_time_remaining -= delta
	velocity = dash_direction * dash_speed
	move_and_slide()
	_damage_enemies_along_dash(delta)
	dash_trail_timer -= delta
	if dash_trail_timer <= 0.0:
		_spawn_dash_trail()
		dash_trail_timer = maxf(0.01, dash_trail_interval)
	if dash_time_remaining <= 0.0:
		is_dashing = false
		velocity = Vector2.ZERO
		_damage_enemies_burst()

func _damage_enemies_along_dash(delta: float) -> void:
	var hit_interval := maxf(0.02, float(active_skill.get_value("hit_interval", 0.04)))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("take_damage"):
			continue
		var enemy_id := enemy.get_instance_id()
		if dash_hit_cooldowns.has(enemy_id):
			dash_hit_cooldowns[enemy_id] = float(dash_hit_cooldowns[enemy_id]) - delta
			if float(dash_hit_cooldowns[enemy_id]) > 0.0:
				continue
		if enemy.global_position.distance_to(global_position) <= dash_hit_radius:
			var damage := float(active_skill.get_value("damage", 26.0)) * float(active_skill.get_value("damage_multiplier", 1.0))
			enemy.take_damage(damage, self)
			dash_hit_cooldowns[enemy_id] = hit_interval

func _damage_enemies_burst() -> void:
	var hit_radius := (float(active_skill.get_value("radius", 44.0)) + dash_burst_radius_bonus) * float(stats_component.get_stat("area_mult", 1.0))
	var damage := float(active_skill.get_value("damage", 26.0)) * float(active_skill.get_value("damage_multiplier", 1.0))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("take_damage"):
			continue
		if enemy.global_position.distance_to(global_position) <= hit_radius:
			enemy.take_damage(damage, self)

func _set_invulnerable_for(duration: float) -> void:
	is_invulnerable = true
	invulnerability_timer = maxf(invulnerability_timer, duration)

func _update_invulnerability(delta: float) -> void:
	if not is_invulnerable:
		return
	invulnerability_timer -= delta
	if invulnerability_timer <= 0.0:
		invulnerability_timer = 0.0
		is_invulnerable = false

func _spawn_dash_trail() -> void:
	if sprite == null or trail_root == null:
		return
	var ghost := Polygon2D.new()
	var body := sprite.get_node_or_null("Body")
	if body is Polygon2D:
		ghost.polygon = body.polygon
		ghost.color = Color(0.22, 0.22, 0.26, 0.35)
	ghost.global_position = global_position
	ghost.rotation = rotation
	trail_root.add_child(ghost)
	var tween := create_tween()
	tween.parallel().tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(ghost, "scale", Vector2.ONE * 0.8, 0.18)
	tween.finished.connect(ghost.queue_free)

func _get_auto_attack_cooldown() -> float:
	var base_cooldown := float(auto_attack_skill.get_value("cooldown", 0.35))
	return maxf(0.05, base_cooldown * float(stats_component.get_stat("cooldown_mult", 1.0)))

func _get_active_skill_cooldown() -> float:
	return maxf(0.05, float(active_skill.get_value("cooldown", 3.5)))

func _on_enemy_died(_enemy: Node, killer: Node, death_position: Vector2) -> void:
	if killer != self:
		return
	var chance := float(stats_component.get_stat("vampire_pool_chance", 0.0))
	if chance <= 0.0 or randf() > chance:
		return
	var blood_pool := BLOOD_POOL_SCENE.instantiate()
	blood_pool.global_position = death_position
	blood_pool.configure(self, vampire_pool_duration, vampire_pool_heal_per_second, vampire_pool_radius)
	get_tree().current_scene.get_node("EffectLayer").add_child(blood_pool)

func _on_died() -> void:
	EventBus.player_died.emit()
	queue_free()
