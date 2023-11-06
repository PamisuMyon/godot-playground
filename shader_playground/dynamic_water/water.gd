extends Sprite2D

@export var water_top = 0.2
var area: Area2D


func _enter_tree():
	_init_area()


func _init_area():
	"""初始化碰撞区域子节点"""
	area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	
	# 采用矩形作为区域形状
	var rect = RectangleShape2D.new()
	var size = get_rect().size
	rect.extents = size / 2
	var upper_space = rect.extents.y * water_top
	rect.extents.y -= upper_space
	area.position.y = upper_space
	
	collision_shape.shape = rect
	area.add_child(collision_shape)
	add_child(area)
	area.connect("body_shape_entered", _on_body_shape_entered)


func _ready():
	material.set_shader_parameter("u_scale", scale)
	material.set_shader_parameter("u_water_top", water_top)


func _on_body_shape_entered(body_id, body, body_shape, area_shape):
	"""入水"""
	# 计算入水点
	var offset = body.global_position - self.global_position
	var x = get_rect().size.x * scale.x / 2 + offset.x
	var entry_point = Vector2(x, area.position.y)
	# 传递给Shader
	material.set_shader_parameter("u_entry_point", entry_point)
	material.set_shader_parameter("u_enter_time", Time.get_ticks_msec() / 1000)
