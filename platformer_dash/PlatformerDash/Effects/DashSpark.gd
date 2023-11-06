# Created by sh1n24

extends GPUParticles2D

func play(direction: Vector2):
	process_material.direction = Vector3(direction.x, direction.y, 0)
	emitting = true

func stop():
	emitting = false
	$Timer.start()

func _on_Timer_timeout():
	queue_free()
