extends RigidBody3D

class_name Ball

@export var ball_name: String = ""
@export var is_selected: bool = false
var original_color: Color

func _ready():
	continuous_cd = true
	var physics_mat = PhysicsMaterial.new()
	physics_mat.bounce = 0.7  
	physics_mat.friction = 0.1 
	physics_material_override = physics_mat

	var mesh_instance = $MeshInstance3D
	if mesh_instance and mesh_instance.mesh:
		var material = StandardMaterial3D.new()
		original_color = _get_random_color()
		material.albedo_color = original_color
		mesh_instance.material_override = material

	var label_3d = get_node_or_null("Label3D")
	if label_3d:
		label_3d.position = Vector3(0, 0.35, 0) 
		label_3d.no_depth_test = true 

func _get_random_color() -> Color:
	var hues = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
	var hue = hues[randi() % hues.size()]
	return Color(hue, 0.8, 1.0)

func blow():
	"""根据小球所在位置，施加对流风力"""
	if not is_selected:
		sleeping = false
		
		if linear_velocity.length() > 8.0:
			linear_velocity = linear_velocity.normalized() * 6.0
			
		var force = Vector3.ZERO
		var force_magnitude = randf_range(8.0, 12.0) # 基础风力大小
		
		if position.x > 0:
			# 如果球在右半边：向左下 45度 吹气
			# 向量 (-1, -1, 0) 标准化后就是精准的左下45度
			var dir = Vector3(-1.0, -1.0, 0.0).normalized()
			force = dir * force_magnitude
		else:
			# 如果球在左半边：向右上 15度 吹气
			# tan(15°) ≈ 0.268，所以向量 (1, 0.268, 0) 就是右上15度
			var dir = Vector3(1.0, 0.268, 0.0).normalized()
			force = dir * force_magnitude
			
		# 给 Z 轴（前后方向）加一点点随机扰流，防止小球全部卡在同一个平面上
		force.z += randf_range(-3.0, 3.0)
		
		apply_central_impulse(force)

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if is_selected:
		return
		
	var pos = state.transform.origin
	var clamped = false
	
	if pos.x < -1.25: pos.x = -1.25; clamped = true
	if pos.x > 1.25: pos.x = 1.25; clamped = true
	if pos.z < -1.25: pos.z = -1.25; clamped = true
	if pos.z > 1.25: pos.z = 1.25; clamped = true
	
	if pos.y < 0.2: pos.y = 0.2; clamped = true
	if pos.y > 1.75: pos.y = 1.75; clamped = true 
	
	if clamped:
		state.transform.origin = pos
		state.linear_velocity *= 0.5 

func highlight_and_float(target_pos: Vector3):
	is_selected = true
	freeze = true 
	collision_layer = 0
	collision_mask = 0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(3, 3, 3), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var mesh_instance = $MeshInstance3D
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = Color(1.0, 0.84, 0.0)

func reset_state():
	is_selected = false
	freeze = false
	collision_layer = 1
	collision_mask = 3
	scale = Vector3.ONE
	var mesh_instance = $MeshInstance3D
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = original_color
