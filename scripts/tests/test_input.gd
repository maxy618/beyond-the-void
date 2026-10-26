extends BtvTestSuite

func test_move_vector_is_clamped() -> void:
	var input := InputState.new()
	input.set_move(Vector2(3.0, 4.0))
	near(input.move_vector.length(), 1.0, 0.001, "move vector clamped to unit length")
	check(input.joystick_active, "joystick active")
	input.set_move(Vector2(0.01, 0.0))
	check(not input.joystick_active, "tiny drift is not a held direction")

func test_clear_releases_every_held_control() -> void:
	var input := InputState.new()
	input.set_move(Vector2(1.0, 0.0))
	input.action_held = true
	input.clear()
	equal(input.move_vector, Vector2.ZERO, "movement cleared")
	equal(input.action_held, false, "action cleared")
	equal(input.joystick_active, false, "joystick released")
