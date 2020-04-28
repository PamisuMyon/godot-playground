extends Node
class_name StateMachine

var state = null
var previous_state = null
var states = {}

func state_logic(delta):
	if state != null:
		state._do_actions(delta)
		var new_state = state._check_conditions(delta)
		if new_state != null:
			set_state(new_state)

func set_state(new_state_name):
	if states.has(new_state_name):
		previous_state = state
		state = states[new_state_name]
#		print_debug("State Change: ", new_state_name)
		if previous_state != null:
			previous_state._exit_state()
		if state != null:
			state._enter_state()

func set_state_deferred(new_state_name):
	call_deferred("set_state", new_state_name)

func add_state(new_state):
	states[new_state._name()] = new_state
