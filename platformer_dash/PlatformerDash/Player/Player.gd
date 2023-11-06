
extends CharacterBody2D

signal player_dash

const FLOOR_NORMAL = Vector2(0, -1)
enum { NONE, IDLE, RUN, AIRBORNE, DASH }	# 状态

@export var max_speed = Vector2(180.0, 1000.0)	# 最大速度
@export var acceleration = 1200.0	# 水平加速度
@export var gravity = 950.0	# 重力
@export var friction = 0.55	# 水平摩擦力
@export var jump_force = -310.0	# 跳跃速度
@export var jump_abort_acc = 1000.0	# 提前下落加速度
@export var dash_force = 500.0	# 冲刺速度
@export var max_dash_duration = 0.15	# 最大冲刺时间
@export var max_dash_times = 1	# 最多冲刺次数

var direction := Vector2.ZERO	# 当前方向
var direction_raw := Vector2.ZERO	# 值仅为0或1的当前方向输入
var jump_pressed := false	# 跳跃按键是否按下
var jump_pressing := false	# 跳跃按键是否按住
var dash_pressed := false	# 冲刺按键是否按下

var state := NONE	# 当前状态
var is_on_ground := false	# 是否在地面
var gravity_ratio := 1.0	# 重力比率
var dash_duration = max_dash_duration	# 当前冲刺时间
var dash_times = max_dash_times	# 当前冲刺次数

@onready var dash_shadow_scn = preload("res://PlatformerDash/Effects/DashShadow.tscn")
@onready var dash_spark_scn = preload("res://PlatformerDash/Effects/DashSpark.tscn")
@onready var dash_impact_scn = preload("res://PlatformerDash/Effects/DashImpact.tscn")
var dash_shadow
var dash_spark
@onready var sprite = $AnimatedSprite2D
@onready var ground_check = $GroundCheck

func _ready():
#	Engine.time_scale = 0.2
	set_state(IDLE)

func _process(delta):
	# 获取输入
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction_raw.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	direction_raw.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	if Input.is_action_just_pressed("jump"):
		jump_pressed = true
	jump_pressing = Input.is_action_pressed("jump")
	if Input.is_action_just_pressed("dash"):
		dash_pressed = true
	
func _physics_process(delta):
	# 状态机逻辑
	if state != null:
		# 检查是否符合状态转移条件
		var new_state = _check_conditions(delta)
		if new_state != null:
			set_state(new_state)
		# 执行当前状态行为
		_do_actions(delta)


func _check_ground():
	"""地面检测"""
	for ray in ground_check.get_children():
		ray.force_raycast_update()
		if ray.is_colliding():
			return true
	return false
	
func _calculate_velocity(delta):
	"""计算速度"""
	# 水平方向
	if direction.x != 0:
		velocity.x += direction.x * acceleration * delta
		velocity.x = clamp(velocity.x, -max_speed.x, max_speed.x)
	else:
		velocity.x =  approach(velocity.x, 0, abs(velocity.x * friction))
	
	# 竖直方向
	velocity.y += gravity * delta
	velocity.x = clamp(velocity.x, -max_speed.y, max_speed.y)

func _apply_movement():
	"""应用移动"""
	set_velocity(velocity)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()
	velocity = velocity

func _sprite_flip():
	"""sprite翻转"""
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true

func _check_dash():
	"""检测是否有冲刺按键输入"""
	if dash_pressed:
		dash_pressed = false
		if dash_times > 0:
			dash_times -= 1
			return true
	return false

func _calculate_dash_direction():
	"""额外处理手柄摇杆冲刺方向，固定8个冲刺方向"""
	# 使用键盘直接返回
	if direction == direction_raw:
		return direction.normalized()
	# 使用手柄返回
	return direction_raw.normalized()

# ---------状态机函数-----------

func _do_actions(delta):
	"""执行当前状态行为"""
	is_on_ground = _check_ground()
	match state:
		IDLE, RUN:
			if jump_pressed:
				velocity.y = jump_force
				jump_pressed = false
				sprite.play("takeoff")
			
			_sprite_flip()
			_calculate_velocity(delta)
			_apply_movement()
		AIRBORNE:
			# 按住跳跃更高
			if not jump_pressing and velocity.y < 0:
				velocity.y += jump_abort_acc * delta
			# 动画
			if approx(velocity.y, 0.0, 50.0):
				sprite.play("midair")
			elif velocity.y < 0:
				sprite.play("rise")
			else:
				sprite.play("fall")
				
			_sprite_flip()
			_calculate_velocity(delta)
			_apply_movement()
		DASH:
			dash_duration -= delta
			_apply_movement()

func _check_conditions(delta):
	"""检查当前状态转移条件，返回需要转移到的状态"""
	match state:
		IDLE:
			if _check_dash():
				return DASH
			if is_on_ground:
				if direction.x != 0:
					return RUN
			else:
				return AIRBORNE
		RUN:
			if _check_dash():
				return DASH
			if is_on_ground:
				if direction.x == 0:
					return IDLE
			else:
				return AIRBORNE
		AIRBORNE:
			if _check_dash():
				return DASH
			if is_on_ground:
				return IDLE if direction.x == 0 else RUN
		DASH:
			if _check_dash():
				return DASH
			if dash_duration <= 0.0:
				if is_on_ground:
					return IDLE if direction.x == 0 else RUN
				else:
					return AIRBORNE

func set_state(new_state):
	"""设置当前状态"""
	_exit_state(state)
	state = new_state
	_enter_state(state)
	
func _exit_state(previous_state):
	"""退出状态"""
	match previous_state:
		DASH:
			if dash_shadow:
				dash_shadow.stop()
				dash_shadow = null
			if dash_spark:
				dash_spark.stop()
				dash_spark = null
			velocity.y *= .6

func _enter_state(new_state):
	"""进入状态"""
	match new_state:
		IDLE:
			gravity_ratio = 0.1
			dash_times = max_dash_times
			sprite.play("idle")
		RUN:
			gravity_ratio = 0.1
			dash_times = max_dash_times
			sprite.play("run")
		AIRBORNE:
			gravity_ratio = 1.0
		DASH:
			dash_duration = max_dash_duration
			var dash_direction = Vector2.ZERO
			if direction == Vector2.ZERO:
				dash_direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
			else:
				dash_direction = _calculate_dash_direction()
			velocity = dash_direction * dash_force
			sprite.play("dash")
			dash_shadow = dash_shadow_scn.instantiate()
			dash_spark = dash_spark_scn.instantiate()
			add_child(dash_shadow)
			add_child(dash_spark)
			dash_shadow.play(-1 if sprite.flip_h else 1)
			dash_spark.play(dash_direction)
			var dash_impact = dash_impact_scn.instantiate()
			dash_impact.direction = dash_direction
			dash_impact.global_position = global_position
			get_parent().add_child(dash_impact)
			emit_signal("player_dash", -8 * dash_direction)
			

# ---------状态机函数end-----------

# ------------通用函数-------------
static func approach(start, end, amount):
	if (start < end):
		return min(start + amount, end)
	else:
		return max(start - amount, end)
		
static func approx(a, b, epsilon = 0.01):
	return abs(a - b) < epsilon
	
# ------------通用函数end-------------
