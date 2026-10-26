class_name BtvDialogueSheet
extends BtvPanelBase

## A conversation is a view over DialogueEngine; choices are revalidated on commit.

func setup_dialogue(p_session: GameSession, p_loc: Localization) -> void:
	setup(p_session, p_loc, "ui.dialogue")

func _fill() -> void:
	if not session.dialogue.is_active():
		add_empty(loc.t("ui.close_dialogue"))
		return
	add_section(session.dialogue.speaker_text())
	var text := BtvTheme.wrapped(session.dialogue.current_text(), 17, BtvTheme.TEXT)
	text.add_theme_constant_override("line_spacing", 5)
	body.add_child(text)
	body.add_child(BtvTheme.spacer(8))
	var choices: Array = session.dialogue.visible_choices()
	for raw_choice in choices:
		var choice: Dictionary = raw_choice
		var button := BtvTheme.button(str(choice.get("text", "")), 50)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_choose.bind(str(choice.get("id", ""))))
		body.add_child(button)
	if choices.is_empty():
		var close_button := BtvTheme.button(loc.t("ui.close_dialogue"), 50)
		close_button.pressed.connect(close)
		body.add_child(close_button)

func _choose(choice_id: String) -> void:
	var result := session.dialogue.choose(choice_id)
	if not bool(result.get("ok", false)):
		refresh()
		return
	if session.dialogue.is_active():
		refresh()
	else:
		close()
