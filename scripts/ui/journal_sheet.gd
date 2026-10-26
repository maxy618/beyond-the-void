class_name BtvJournalSheet
extends BtvPanelBase

## Field log, quest state and the observational codex in one scroll.

func setup_journal(p_session: GameSession, p_loc: Localization) -> void:
	setup(p_session, p_loc, "ui.journal_title")

func _fill() -> void:
	add_section(loc.t("ui.quest_log"))
	var active_ids: Array = session.quests.active_quest_ids()
	if active_ids.is_empty():
		add_note(loc.t("ui.no_objective"))
	for raw_id in active_ids:
		var quest_id := str(raw_id)
		var quest: Dictionary = session.registry.get_quest(quest_id)
		var state: Dictionary = session.quests.active.get(quest_id, {})
		var completed_steps: Array = state.get("completed_steps", [])
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL_SOFT, 12, BtvTheme.LINE, 1))
		body.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 5)
		card.add_child(column)
		var title := BtvTheme.label(loc.t(str(quest.get("title_key", ""))), 16, BtvTheme.AMBER)
		column.add_child(title)
		column.add_child(BtvTheme.wrapped(loc.t(str(quest.get("summary_key", ""))), 13, BtvTheme.TEXT_DIM))
		for raw_step in quest.get("steps", []):
			var step: Dictionary = raw_step
			var done := str(step.get("id", "")) in completed_steps
			column.add_child(BtvTheme.wrapped(("✓ " if done else "· ") + loc.t(str(step.get("title_key", ""))), 13, BtvTheme.ACCENT if done else BtvTheme.TEXT))
	var completed_ids: Array = session.quests.completed
	if not completed_ids.is_empty():
		add_section(loc.t("ui.completed"))
		for raw_id in completed_ids:
			var quest: Dictionary = session.registry.get_quest(str(raw_id))
			add_note("✓ " + loc.t(str(quest.get("title_key", ""))))
	body.add_child(BtvTheme.spacer(4))
	add_section(loc.t("ui.journal_entries"))
	var entries: Array = session.journal
	if entries.is_empty():
		add_note(loc.t("ui.no_journal"))
	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		var key := str(entry.get("key", ""))
		if not key.is_empty():
			add_note(loc.t(key) if loc.has(key) else key)
	body.add_child(BtvTheme.spacer(4))
	add_section(loc.t("ui.codex_title"))
	var species_ids: Array = session.observations.keys()
	species_ids.sort_custom(func(a, b) -> bool:
		return _species_name(str(a)).nocasecmp_to(_species_name(str(b))) < 0
	)
	if species_ids.is_empty():
		add_empty(loc.t("ui.codex_empty"))
	for raw_id in species_ids:
		var species_id := str(raw_id)
		var species: Dictionary = session.registry.get_species(species_id)
		var observed: Dictionary = session.observations.get(species_id, {})
		var count := int(observed.get("count", 1))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.BG_DEEP, 10, BtvTheme.LINE, 1))
		body.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		card.add_child(column)
		var top := HBoxContainer.new()
		column.add_child(top)
		var name_label := BtvTheme.label(_species_name(species_id), 15, BtvTheme.TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_label)
		top.add_child(BtvTheme.label(loc.t("ui.observation_count", {"count": count}), 11, BtvTheme.TEXT_FAINT))
		column.add_child(BtvTheme.wrapped(loc.t(str(species.get("field_note_key", ""))), 12, BtvTheme.TEXT_DIM))
		if session.mode == "planet" and not session.planet_id.is_empty():
			column.add_child(BtvTheme.wrapped(loc.t("ui.species_population", {
				"current": session.ecology.population(session.planet_id, species_id),
				"target": session.ecology.target_population(species_id),
			}), 11, BtvTheme.ACCENT))
		column.add_child(BtvTheme.wrapped(loc.t("ui.ethics") + ": " + loc.t(str(_ethics_key(species))), 11, BtvTheme.TEXT_FAINT))

func _species_name(species_id: String) -> String:
	var species: Dictionary = session.registry.get_species(species_id)
	return loc.t(str(species.get("display_key", "")))

func _ethics_key(species: Dictionary) -> String:
	var rules: Array = species.get("ethical_rules", [])
	if rules.is_empty():
		return "ui.ethics_note"
	var first = rules[0]
	if typeof(first) == TYPE_STRING:
		return str(first)
	if typeof(first) == TYPE_DICTIONARY:
		return str(first.get("text_key", "ui.ethics_note"))
	return "ui.ethics_note"
