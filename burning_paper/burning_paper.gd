extends Node2D

@onready var paper = $Parchment
@onready var particles = $Particles
@onready var spark = $Particles/Spark
@onready var smoke = $Particles/Smoke

@export var edge_start = 1.0
@export var edge_end = -0.2

var is_buring = false
var bottom = .0
var top = .0


func _ready():
#	Engine.time_scale = 0.5
	var size = paper.get_rect().size
	bottom = paper.global_position.y + size.y / 2
	top = paper.global_position.y - size.y / 2
	# particles.global_position.y = bottom
#	paper.material.set_shader_parameter("u_edge", edge_start);


func _process(delta):
	if Input.is_key_pressed(KEY_B):
		if not is_buring:
			is_buring = true
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_method(burn, edge_start, edge_end, 2.0)


func burn(value : float):
	particles.global_position.y = max(-300, bottom - (bottom - top) * (1.0 - value))
	paper.material.set_shader_parameter("u_edge", value)


func _on_Tween_tween_started(object, key):
	particles.global_position.y = bottom
	if not spark.emitting:
		spark.emitting = true
	if not smoke.emitting:
		smoke.emitting = true
	await get_tree().create_timer(0.8).timeout;
	spark.show()
	smoke.show()


func _on_Tween_tween_completed(object, key):
	spark.emitting = false;
	smoke.emitting = false;
	await get_tree().create_timer(0.3).timeout;
	spark.hide()
	smoke.hide()
	is_buring = false
