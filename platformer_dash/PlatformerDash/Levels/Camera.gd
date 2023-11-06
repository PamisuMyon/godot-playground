
extends Camera2D

var is_shaking = false	# 是否处于振动状态
var shake_strength: Vector2	# 振动力度
var shake_damping: Vector2	# 振动衰减
var shake_amount: int	# 振动数量

func _process(delta):
	if shake_amount <= 0:
		is_shaking = false
		offset = Vector2.ZERO
	if is_shaking:
		offset = shake_strength
		shake_strength -= shake_damping
		shake_amount -= 1

func shake(strength: Vector2, amount: int = 3):
	is_shaking = true
	shake_strength = strength
	shake_damping = strength / amount
	shake_amount = amount

func _on_player_dash(strength: Vector2, amount: int = 3):
	shake(strength, amount)
