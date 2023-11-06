# Created by sh1n24

extends GPUParticles2D

var texture_left
var texture_right

func _ready():
	# 读取残影图片
	texture_left = preload("res://Resources/adventurer-dash-shadow-left.png")
	texture_right = preload("res://Resources/adventurer-dash-shadow-right.png")

func play(direction: float):
	# 根据方向显示残影
	if direction > 0:
		texture = texture_right
	else:
		texture = texture_left
	emitting = true

func stop():
	# 停止发射，延时销毁
	emitting = false
	$Timer.start()

func _on_Timer_timeout():
	queue_free()
