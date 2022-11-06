extends AnimatedSprite2D


@onready var character := get_parent() as CharacterBody2D


func _process(delta):
	if character.is_on_floor():
		if abs(character.velocity.x) >= 0.01:
			play("run")
		else:
			play("idle")
	else:
		if abs(character.velocity.y) <= 120:
			play("jump_midair")
		elif character.velocity.y < 0:
			play("jump_up")
		else:
			play("jump_fall")
	
	if character.velocity.x < 0:
		flip_h = true
	elif character.velocity.x > 0:
		flip_h = false
