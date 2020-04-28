extends KinematicBody2D
class_name Player

signal on_floor_update

const FLOOR_NORMAL = Vector2(0, -1)
const MAX_FLOOR_ANGLE = 25.0
const MAX_SLOPE_ANGLE = 45.0
const SNAP = Vector2(0, 32)
const DROP_THROUGH_MASK = 0

var max_speed = Vector2(7 * 32, 1000)
var acceleration = Vector2(1000, 1000)
var friction = 0.55
var jump_force = -450
var gravity_ratio = 1
var direction = 0
var velocity = Vector2()
var snap = Vector2.ZERO
var stateMachine = StateMachine.new()
var is_on_floor

onready var sprite = $AnimatedSprite
onready var GroundCheck = $GroundCheck

func _ready():
	stateMachine.add_state(IdleState.new(self))
	stateMachine.add_state(RunState.new(self))
	stateMachine.add_state(JumpState.new(self))
	stateMachine.add_state(FallState.new(self))
	stateMachine.set_state_deferred(IdleState._name())
	AudioBusLayout

func _physics_process(delta):
	stateMachine.state_logic(delta)

func _apply_movement(delta):
	if direction != 0:
		velocity.x += direction * acceleration.x * delta
		velocity.x = clamp(velocity.x, -max_speed.x, max_speed.x)
	else:
		velocity.x = approach(velocity.x, 0, abs(velocity.x * friction))
		
	velocity.y += acceleration.y * gravity_ratio * delta
	velocity.y = clamp(velocity.y, -max_speed.y, max_speed.y)

#	velocity = move_and_slide(velocity, FLOOR_NORMAL, true)
	velocity = move_and_slide_with_snap(velocity, snap, FLOOR_NORMAL, true)
	
	# 更新着地状态
	var was_on_floor = is_on_floor
	if was_on_floor == null || was_on_floor != is_on_floor:
		emit_signal("on_floor_update", is_on_floor)

static func approach(start: float, end: float, amount: float):
	if (start < end):
		return min(start + amount, end)
	else:
		return max(start - amount, end)


class PlayerState extends "res://Common/BaseState.gd":
	var p: Player
	
	func _init(player: Player):
		p = player
	
	func _do_actions(delta):
		_handle_input(delta)
		p._apply_movement(delta)
	
	func _handle_input(delta):
		p.direction = -int(Input.is_action_pressed("ui_left")) + int(Input.is_action_pressed("ui_right"))
		
		# 处理从平台落下
		var ray: RayCast2D = p.GroundCheck
#		print("is_colliding: ", ray.is_colliding())
#		print("shape id: ", ray.get_collider_shape())
		if ray.is_colliding():
			pass
#			print("is_shape_one_way: ", ray.get_collider().is_shape_owner_one_way_collision_enabled(ray.get_collider_shape()))
#		print("is_down: ", Input.is_action_pressed("ui_down"))
		
		if ray.is_colliding():
			ray.get_collider()
			
		
		if ray.is_colliding() \
			&& ray.get_collider().is_shape_owner_one_way_collision_enabled(ray.get_collider_shape()) \
			&& Input.is_action_pressed("ui_down"):
			p.set_collision_layer_bit(p.DROP_THROUGH_MASK, false)
			p.set_collision_mask_bit(p.DROP_THROUGH_MASK, false)
		else:
			p.set_collision_layer_bit(p.DROP_THROUGH_MASK, true)
			p.set_collision_mask_bit(p.DROP_THROUGH_MASK, true)
		
		# 处理斜坡滑动
		if p.is_on_floor():
			var n: Vector2 = p.GroundCheck.get_collision_normal()
			var floor_angle = rad2deg(acos(n.dot(p.FLOOR_NORMAL)))
			if floor_angle > MAX_FLOOR_ANGLE:
				p.gravity_ratio = (floor_angle - MAX_FLOOR_ANGLE) / (MAX_SLOPE_ANGLE - MAX_FLOOR_ANGLE) * 0.3
			else:
				p.gravity_ratio = 0.1
		else:
			p.gravity_ratio = 1
			
		# 根据朝向改变动画翻转
		if p.direction < 0:
			p.sprite.flip_h = true
		elif p.direction > 0:
			p.sprite.flip_h = false
			
	func floats_equal(a, b, EPSILON = 0.5):
		return abs(a - b) <= EPSILON


class IdleState extends PlayerState:
	var frame = 0	# 记录状态退出时的帧
	
	func _init(player).(player):
		pass
	
	static func _name():
		return "idle"
	
	func _handle_input(delta):
		._handle_input(delta)
		if Input.is_action_just_pressed("ui_up"):
			p.snap = Vector2.ZERO
			p.velocity.y += p.jump_force
	
	func _check_conditions(delta) -> BaseState:
		if p.is_on_floor():
			if not floats_equal(p.velocity.x, 0):
				return RunState._name()
		elif p.velocity.y > 0:
			return FallState._name()
		elif p.velocity.y < 0:
			return JumpState._name()
		return null
	
	func _enter_state():
		p.snap = p.SNAP
		p.sprite.play("idle")
		p.sprite.frame = frame
	
	func _exit_state():
		frame = p.sprite.frame


class RunState extends PlayerState:
	static func _name():
		return "run"
	
	func _init(player).(player):
		pass
	
	func _handle_input(delta):
		._handle_input(delta)
		if Input.is_action_just_pressed("ui_up"):
			p.snap = Vector2.ZERO
			p.velocity.y += p.jump_force
	
	func _check_conditions(delta) -> BaseState:
		if p.is_on_floor():
			if floats_equal(p.velocity.x, 0):
				return IdleState._name()
		elif p.velocity.y > 0:
			return FallState._name()
		elif p.velocity.y < 0:
			return JumpState._name()
		return null
	
	func _enter_state():
		p.snap = p.SNAP
		p.sprite.play("run")
	
	func _exit_state():
		pass


class JumpState extends PlayerState:
	static func _name():
		return "jump"
	
	func _init(player).(player):
		pass
	
	func _check_conditions(delta) -> BaseState:
		if p.is_on_floor():
			if floats_equal(p.velocity.x, 0):
				return IdleState._name()
			else:
				return RunState._name()
		elif p.velocity.y > 0:
			return FallState._name()
		return null
	
	func _enter_state():
		p.sprite.play("jump_up")
	
	func _exit_state():
		pass


class FallState extends PlayerState:
	static func _name():
		return "fall"
	
	func _init(player).(player):
		pass
	
	func _check_conditions(delta) -> BaseState:
		if p.is_on_floor():
			if floats_equal(p.velocity.x, 0):
				return IdleState._name()
			else:
				return RunState._name()
		elif p.velocity.y < 0:
			return JumpState._name()
		return null
	
	func _enter_state():
		p.sprite.play("jump_fall")
	
	func _exit_state():
		pass
