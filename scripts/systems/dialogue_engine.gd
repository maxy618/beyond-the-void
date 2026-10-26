class_name DialogueEngine
extends RefCounted

## Data-driven dialogue. Choice conditions are re-evaluated at the moment of commit.

var session = null
var dialogue_id: String = ""
var current_node_id: String = ""
var active: bool = false
var last_choice_result: Dictionary = {}

func setup(game_session) -> void:
	session = game_session

func reset() -> void:
	dialogue_id = ""
	current_node_id = ""
	active = false
	last_choice_result.clear()

func start(id: String) -> Dictionary:
	var definition = session.registry.get_dialogue(id)
	if definition.is_empty():
		return {"ok": false, "code": "invalid_target"}
	dialogue_id = id
	current_node_id = str(definition.get("entry_node", ""))
	if not _nodes().has(current_node_id):
		return {"ok": false, "code": "invalid_target"}
	active = true
	session.facts["talked." + id] = true
	session.quests.handle_event("speak_to_npc", {"id": id})
	session.notify("dialogue")
	return {"ok": true, "code": "dialogue_started", "dialogue_id": id, "node_id": current_node_id}

func close() -> void:
	active = false
	current_node_id = ""
	dialogue_id = ""
	session.notify("dialogue")

func is_active() -> bool:
	return active

func speaker_text() -> String:
	var definition = session.registry.get_dialogue(dialogue_id)
	return session.loc.t(str(definition.get("speaker_key", "")))

func current_text() -> String:
	var node := current_node()
	return session.loc.t(str(node.get("text_key", "")))

func current_node() -> Dictionary:
	var nodes := _nodes()
	return nodes.get(current_node_id, {})

func visible_choices() -> Array:
	var out: Array = []
	for choice in current_node().get("choices", []):
		if _conditions_met(choice.get("conditions", [])):
			var copy: Dictionary = choice.duplicate(true)
			copy["text"] = session.loc.t(str(choice.get("text_key", "")))
			out.append(copy)
	return out

func choose(choice_id: String) -> Dictionary:
	if not active:
		return {"ok": false, "code": "dialogue_inactive"}
	var choice: Dictionary = {}
	for candidate in current_node().get("choices", []):
		if str(candidate.get("id", "")) == choice_id:
			choice = candidate
			break
	if choice.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if not _conditions_met(choice.get("conditions", [])):
		last_choice_result = {"ok": false, "code": "choice_locked"}
		return last_choice_result
	for effect in choice.get("effects", []):
		_apply_effect(effect)
	var next = choice.get("next", null)
	if next == null or str(next).is_empty():
		active = false
		current_node_id = ""
		last_choice_result = {"ok": true, "code": "dialogue_closed", "closed": true}
	else:
		var next_id := str(next)
		if not _nodes().has(next_id):
			active = false
			last_choice_result = {"ok": false, "code": "invalid_target"}
			return last_choice_result
		current_node_id = next_id
		last_choice_result = {"ok": true, "code": "dialogue_advanced", "closed": false, "node_id": next_id}
	session.notify("dialogue")
	return last_choice_result

func _nodes() -> Dictionary:
	return session.registry.get_dialogue(dialogue_id).get("nodes", {})

func _conditions_met(conditions: Array) -> bool:
	for condition in conditions:
		if typeof(condition) != TYPE_DICTIONARY:
			return false
		var ctype := str(condition.get("type", ""))
		var cid := str(condition.get("id", ""))
		match ctype:
			"flag":
				if not bool(session.facts.get(cid, false)):
					return false
			"not_flag":
				if bool(session.facts.get(cid, false)):
					return false
			"has_item":
				if session.inventory.count(cid) < int(condition.get("count", 1)):
					return false
			"quest_active":
				if not session.quests.active.has(cid):
					return false
			"quest_completed":
				if not cid in session.quests.completed:
					return false
			"observed_species":
				if not session.observations.has(cid):
					return false
			_:
				return false
	return true

func _apply_effect(effect: Dictionary) -> void:
	match str(effect.get("type", "")):
		"set_flag":
			session.facts[str(effect.get("id", ""))] = true
		"start_quest":
			session.quests.start_quest(str(effect.get("id", "")))
		"add_journal":
			session.add_journal(str(effect.get("key", "")))
		"add_credits":
			session.credits += int(effect.get("amount", 0))
		"add_item":
			session.inventory.add(str(effect.get("id", "")), int(effect.get("count", 1)))
			session.quests.on_inventory_changed()
		_:
			pass
