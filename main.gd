extends Node3D

@onready var box_node = $Box
@onready var result_label = $CanvasLayer/Control/VBoxContainer/ResultLabel
@onready var start_button = $CanvasLayer/Control/VBoxContainer/StartButton
@onready var win_area = $Box/WinArea
# 新增：获取右侧的名单 Label
@onready var winner_list_label = $CanvasLayer/Control/RightPanel/ListContainer/WinnerListLabel

var balls: Array[RigidBody3D] = []
var is_drawing: bool = false
var selected_ball: RigidBody3D = null
var can_win: bool = false
var draw_count: int = 0 # 记录已经抽了几个

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	win_area.body_entered.connect(_on_win_area_body_entered)
	_load_config_and_spawn_balls()

func _load_config_and_spawn_balls():
	var config_data = _load_json_config()
	if config_data.is_empty():
		return
	for item in config_data:
		if item.has("name"):
			_spawn_ball(item["name"])

func _load_json_config() -> Array:
	var config = []
	var file = FileAccess.open("res://config.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			config = json.data
	return config

func _spawn_ball(ball_name: String):
	var ball_scene = preload("res://ball.tscn")
	var ball = ball_scene.instantiate() as RigidBody3D
	ball.ball_name = ball_name
	
	var label_3d = ball.get_node_or_null("Label3D")
	if label_3d:
		label_3d.text = ball_name
	
	var x = randf_range(-0.8, 0.8)
	var z = randf_range(-0.8, 0.8)
	var y = randf_range(0.5, 1.5) 
	ball.position = Vector3(x, y, z)
	
	box_node.add_child(ball)
	balls.append(ball)

func _on_start_button_pressed():
	if is_drawing:
		return
		
	if selected_ball:
		if selected_ball in balls:
			balls.erase(selected_ball)
		selected_ball.queue_free()
		selected_ball = null
	
	if balls.is_empty():
		result_label.text = "抽奖结束：所有球均已抽出！"
		return
		
	is_drawing = true
	can_win = false
	result_label.text = "小球激烈角逐中 (5秒后开启检测)..."
	
	for ball in balls:
		if is_instance_valid(ball):
			ball.linear_damp = 0.0
	
	get_tree().create_timer(5.0).timeout.connect(func():
		if is_drawing:
			can_win = true
			result_label.text = "🔴 红色检测区域已激活，随时中奖！"
	)
	
	while is_drawing and not selected_ball:
		_blow_balls()
		await get_tree().create_timer(0.3).timeout

func _blow_balls():
	for ball in balls:
		if is_instance_valid(ball) and not ball.is_selected:
			ball.blow()

func _on_win_area_body_entered(body: Node3D):
	if not is_drawing or not can_win or selected_ball != null:
		return
	if body not in balls:
		return
		
	selected_ball = body
	is_drawing = false
	can_win = false 
	
	for ball in balls:
		if ball != selected_ball and is_instance_valid(ball):
			ball.linear_damp = 5.0
	
	var display_pos = Vector3(2.5, 3.5, 0.0) 
	selected_ball.highlight_and_float(display_pos)
	
	# 更新中奖信息和列表
	draw_count += 1
	result_label.text = "🎉 第 " + str(draw_count) + " 位中奖者：" + selected_ball.ball_name + " 🎉"
	
	# 换行拼接到右侧列表里
	var list_text = str(draw_count) + ". " + selected_ball.ball_name
	if winner_list_label.text == "":
		winner_list_label.text = list_text
	else:
		winner_list_label.text += "\n" + list_text
