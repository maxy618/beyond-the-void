class_name QuestEngine
extends RefCounted

## Ordered, event-driven quests with idempotent rewards and persisted receipts.

var session = null
var active: Dictionary = {}
var completed: Array = []
var receipts: Dictionary = {}
var pending_rewards: Dictionary = {}
var last_event: Dictionary = {}

func setup(game_session) -> void:
	session = game_session

func reset() -> void:
	active.clear()
	completed.clear()
	receipts.clear()
	pending_rewards.clear()
	last_event.clear()

func start_auto_quests() -> void:
	for quest_id in session.registry.quests.keys():
		var quest = session.registry.get_quest(str(quest_id))
		if bool(quest.get("auto_start", false)):
			start_quest(str(quest_id))

func start_quest(quest_id: String) -> Dictionary:
	var quest = session.registry.get_quest(quest_id)
	if quest.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if active.has(quest_id):
		return {"ok": false, "code": "quest_already_active"}
	if quest_id in completed:
		return {"ok": false, "code": "quest_completed"}
	if not _conditions_met(quest.get("start_conditions", [])):
		return {"ok": false, "code": "locked"}
	active[quest_id] = {"completed_steps": [], "seen": {}, "counts": {}, "started_at": session.game_time}
	var state: Dictionary = active[quest_id]
	_auto_complete_current(quest_id, state)
	session.notify("quest_started")
	return {"ok": true, "code": "quest_started", "quest_id": quest_id}

func handle_event(event_type: String, data: Dictionary = {}) -> void:
	last_event = {"type": event_type, "data": data}
	for quest_id in active.keys().duplicate():
		if not active.has(quest_id):
			continue
		var state: Dictionary = active[quest_id]
		_try_event(quest_id, state, event_type, data)
		_auto_complete_current(quest_id, state)

func on_inventory_changed() -> void:
	for quest_id in active.keys().duplicate():
		if not active.has(quest_id):
			continue
		_auto_complete_current(quest_id, active[quest_id])
	retry_pending_rewards()

func _try_event(quest_id: String, state: Dictionary, event_type: String, data: Dictionary) -> void:
	var step := _current_step(quest_id, state)
	if step.is_empty():
		return
	var objective: Dictionary = step.get("objective", {})
	var otype := str(objective.get("type", ""))
	var target := str(objective.get("id", ""))
	var event_id := str(data.get("id", ""))
	match otype:
		"enter_location":
			if event_type == "enter_location" and event_id == target:
				_complete_step(quest_id, state, step)
		"observe_species":
			if event_type == "observe_species":
				if target != "" and event_id != target:
					return
				var seen: Dictionary = state.get("seen", {})
				seen[event_id] = true
				state["seen"] = seen
				if seen.size() >= int(objective.get("count", 1)):
					_complete_step(quest_id, state, step)
		"collect_item", "deliver_item":
			if event_type == "collect_item" or event_type == "inventory_changed":
				if _inventory_requirement_met(objective):
					_consume_delivery(objective, otype)
					_complete_step(quest_id, state, step)
		"craft_recipe":
			if event_type == "craft_recipe" and event_id == target:
				_complete_step(quest_id, state, step)
		"speak_to_npc":
			if event_type == "speak_to_npc" and event_id == target:
				_complete_step(quest_id, state, step)
		"interact_object", "repair_object":
			var action := str(data.get("action", ""))
			var required_action := str(objective.get("action", ""))
			if event_type == "interact_object" and event_id == target and (required_action.is_empty() or action == required_action):
				_complete_step(quest_id, state, step)
		"build_module":
			if event_type == "build_module" and event_id == target:
				_complete_step(quest_id, state, step)
		"reach_system":
			if event_type == "reach_system" and event_id == target:
				_complete_step(quest_id, state, step)
		"trade_quantity":
			if event_type == "trade_quantity" and (target.is_empty() or event_id == target):
				var counts: Dictionary = state.get("counts", {})
				counts[target] = int(counts.get(target, 0)) + int(data.get("quantity", 0))
				state["counts"] = counts
				if int(counts[target]) >= int(objective.get("count", 1)):
					_complete_step(quest_id, state, step)
		"wait_for_event":
			if event_type == "wait_for_event" and event_id == target:
				_complete_step(quest_id, state, step)
		"set_world_fact":
			if event_type == "set_world_fact" and bool(session.facts.get(target, false)):
				_complete_step(quest_id, state, step)

func _auto_complete_current(quest_id: String, state: Dictionary) -> void:
	var guard := 0
	while guard < 50:
		guard += 1
		var step := _current_step(quest_id, state)
		if step.is_empty():
			_complete_quest(quest_id, state)
			return
		var objective: Dictionary = step.get("objective", {})
		var otype := str(objective.get("type", ""))
		var done := false
		match otype:
			"collect_item", "deliver_item":
				if _inventory_requirement_met(objective):
					_consume_delivery(objective, otype)
					done = true
			"observe_species":
				var seen_count := _matching_observation_count(objective)
				if seen_count >= int(objective.get("count", 1)):
					done = true
			"speak_to_npc":
				if bool(session.facts.get("talked." + str(objective.get("id", "")), false)):
					done = true
			"enter_location":
				if session.location_id() == str(objective.get("id", "")):
					done = true
			"reach_system":
				if session.system_id == str(objective.get("id", "")):
					done = true
			"build_module":
				for building in session.buildings:
					if str(building.get("definition_id", "")) == str(objective.get("id", "")):
						done = true
						break
			"set_world_fact":
				if bool(session.facts.get(str(objective.get("id", "")), false)):
					done = true
		if not done:
			return
		_complete_step(quest_id, state, step)
		state = active.get(quest_id, state)

func _complete_step(quest_id: String, state: Dictionary, step: Dictionary) -> void:
	var completed_steps: Array = state.get("completed_steps", [])
	var step_id := str(step.get("id", ""))
	if step_id in completed_steps:
		return
	completed_steps.append(step_id)
	state["completed_steps"] = completed_steps
	session.add_journal(str(step.get("journal_key", "")))
	session.notify("quest_step")
	if _current_step(quest_id, state).is_empty():
		_complete_quest(quest_id, state)

func _complete_quest(quest_id: String, state: Dictionary) -> void:
	if not active.has(quest_id):
		return
	active.erase(quest_id)
	if not quest_id in completed:
		completed.append(quest_id)
	var quest = session.registry.get_quest(quest_id)
	session.facts["quest.completed." + quest_id] = true
	session.notify("quest_completed")
	_grant_rewards(quest_id, quest)
	if not _conditions_met(quest.get("start_conditions", [])):
		pass

func _grant_rewards(quest_id: String, quest: Dictionary) -> Dictionary:
	var rewards: Dictionary = quest.get("rewards", {})
	var receipt_key := str(rewards.get("idempotency_key", ""))
	if receipt_key.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if receipts.has(receipt_key):
		return {"ok": true, "code": "already_claimed", "receipt_key": receipt_key}
	var reward_items: Array = rewards.get("items", [])
	if not session.inventory.can_add_many(reward_items).get("ok", false):
		pending_rewards[quest_id] = true
		session.notify("rewards_pending")
		return {"ok": false, "code": "capacity"}
	receipts[receipt_key] = {"quest_id": quest_id, "claimed_at": session.game_time}
	pending_rewards.erase(quest_id)
	session.credits += int(rewards.get("credits", 0))
	if not reward_items.is_empty():
		session.inventory.add_many(reward_items)
	for flag in rewards.get("flags", []):
		session.facts[str(flag)] = true
	session.add_journal(str(rewards.get("journal_key", "")))
	session.notify("rewards")
	return {"ok": true, "code": "reward_received", "receipt_key": receipt_key, "rewards": rewards}

func retry_pending_rewards() -> void:
	if pending_rewards.is_empty():
		return
	for quest_id in pending_rewards.keys().duplicate():
		var quest = session.registry.get_quest(str(quest_id))
		if not quest.is_empty():
			_grant_rewards(str(quest_id), quest)

func claim_rewards(quest_id: String) -> Dictionary:
	if not quest_id in completed:
		return {"ok": false, "code": "invalid_target"}
	return _grant_rewards(quest_id, session.registry.get_quest(quest_id))

func _current_step(quest_id: String, state: Dictionary) -> Dictionary:
	var quest = session.registry.get_quest(quest_id)
	var steps: Array = quest.get("steps", [])
	var index := (state.get("completed_steps", []) as Array).size()
	if index < 0 or index >= steps.size():
		return {}
	return steps[index]

func _inventory_requirement_met(objective: Dictionary) -> bool:
	return session.inventory.count(str(objective.get("id", ""))) >= int(objective.get("count", 1))

func _consume_delivery(objective: Dictionary, otype: String) -> void:
	if otype == "deliver_item":
		session.inventory.remove(str(objective.get("id", "")), int(objective.get("count", 1)))

func _matching_observation_count(objective: Dictionary) -> int:
	var target := str(objective.get("id", ""))
	if target != "":
		return 1 if session.observations.has(target) else 0
	return session.observations.size()

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
				if not active.has(cid):
					return false
			"quest_completed":
				if not cid in completed:
					return false
			"observed_species":
				if not session.observations.has(cid):
					return false
			_:
				return false
	return true

func current_objective_text() -> String:
	for quest_id in active.keys():
		var state: Dictionary = active[quest_id]
		var step := _current_step(str(quest_id), state)
		if not step.is_empty():
			return session.loc.t(str(step.get("title_key", "")))
	return session.loc.t("ui.no_objective")

func active_quest_ids() -> Array:
	return active.keys()

func status(quest_id: String) -> String:
	if active.has(quest_id):
		return "active"
	if quest_id in completed:
		return "completed"
	return "not_started"

func to_state() -> Dictionary:
	return {
		"active": active.duplicate(true),
		"completed": completed.duplicate(),
		"receipts": receipts.duplicate(true),
		"pending_rewards": pending_rewards.duplicate(true),
	}

func from_state(state: Dictionary) -> void:
	active = (state.get("active", {}) as Dictionary).duplicate(true)
	completed = (state.get("completed", []) as Array).duplicate()
	receipts = (state.get("receipts", {}) as Dictionary).duplicate(true)
	pending_rewards = (state.get("pending_rewards", {}) as Dictionary).duplicate(true)
