extends Unit

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var range_collider_activate: Area3D = $ActivationArea
@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var healthbar_node: ProgressBar = $Healthbar

var patrol_path: Node3D = null
var path_array: Array[Marker3D] = []
var enemies_in_range: Array[Node3D] = []

func _ready():
	name = "minion_%d_%d" % [team, id]
	activation_range = 10.0
	speed = 3.0
	max_health = 500.0
	attack_damage = 12.0
	attack_speed = 1.25
	attack_timeout = 1.0
	setup(
		nav_agent,
		range_collider_activate,
		range_collider_attack,
		mesh_instance,
		attack_timer,
		healthbar_node
	)

func _physics_process(delta):
	if not multiplayer.is_server():
		return
	# Get Next State
	


func get_closest_patrol_point() -> Vector3:
	if path_array.size() == 0:
		return global_position
	var closest_point: Vector3 = path_array[0].global_position
	var distance: float
	for point in path_array:
		distance = global_position.distance_squared_to(point.global_position)
		if distance < 1:
			path_array.remove_at(path_array.find(point))
			continue
		if distance < global_position.distance_squared_to(closest_point):
			closest_point = point.global_position
	return closest_point


func get_closest_enemy() -> Node3D:
	if enemies_in_range.size() <= 0:
		return
	var closest_enemy: Node3D = enemies_in_range[0]
	var distance: float
	for enemy in enemies_in_range:
		distance = global_position.distance_squared_to(enemy.global_position)
		if distance < 1:
			enemies_in_range.remove_at(enemies_in_range.find(enemy))
			continue
		if distance < global_position.distance_squared_to(closest_enemy.global_position):
			closest_enemy = enemy
	return closest_enemy


func _on_activation_area_body_entered(body):
	if not body.team == team and not enemies_in_range.has(body):
		enemies_in_range.append(body)


func _on_activation_area_body_exited(body):
	if enemies_in_range.has(body):
		enemies_in_range.remove_at(enemies_in_range.find(body))


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	if target_entity == null:
		move_and_slide()
	elif global_position.distance_squared_to(target_entity.global_position) > attack_range * 2:
		move_and_slide()
	if not global_position.is_equal_approx(nav_agent.get_next_path_position()):
		if not Vector3.UP.cross(nav_agent.get_next_path_position() - global_position).is_zero_approx():
			look_at(nav_agent.get_next_path_position(), Vector3.UP)
