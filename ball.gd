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
	"""抽奖机喷气逻辑：中心喷泉 + 边缘向心回流 + 水平漩涡"""
	if not is_selected:
		sleeping = false
		
		# 稍微放宽速度限制，让搅拌更激烈
		if linear_velocity.length() > 10.0:
			linear_velocity = linear_velocity.normalized() * 8.0
			
		var force = Vector3.ZERO
		
		# 计算小球到箱子中心 (X=0, Z=0) 的水平距离
		var horiz_pos = Vector2(position.x, position.z)
		var dist_to_center = horiz_pos.length()
		
		if dist_to_center < 0.6:
			# 1. 处于中心区域：强大的向上喷发
			force = Vector3(
				randf_range(-3.0, 3.0),
				randf_range(12.0, 16.0), # 强力向上
				randf_range(-3.0, 3.0)
			)
		else:
			# 2. 处于四周边缘：强制往中心推（绝对防卡墙）
			var to_center = Vector3(-position.x, 0, -position.z).normalized()
			force = to_center * randf_range(8.0, 12.0)
			# 给边缘的球加一点点上下的随机扰流
			force.y = randf_range(-2.0, 4.0)
			
		# 3. 添加切线漩涡力（让整个球堆顺时针旋转）
		var to_outward = Vector3(position.x, 0, position.z).normalized()
		var tangent = Vector3(0, 1, 0).cross(to_outward) # 向量叉乘得到圆周切线
		force += tangent * randf_range(4.0, 7.0)
		
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
		# 优化：碰到极限安全墙时，只削弱 20% 动能，防止瞬间失去活力
		state.linear_velocity *= 0.8 

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
