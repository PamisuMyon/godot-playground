extends Node
class_name BaseState

#var _name = null

static func _name():
	return null

func _do_actions(delta):
	pass

func _check_conditions(delta) -> BaseState:
	return null

func _enter_state():
	pass

func _exit_state():
	pass
