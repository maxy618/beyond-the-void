class_name CraftingService
extends RefCounted

## Atomic crafting: the resulting inventory is simulated before the real one changes.

static func is_unlocked(recipe: Dictionary, observations: Dictionary) -> bool:
	var unlock = recipe.get("unlock", {})
	if typeof(unlock) != TYPE_DICTIONARY:
		return true
	var required: Array = unlock.get("observations", [])
	for species_id in required:
		if not observations.has(str(species_id)):
			return false
	return true

static func can_craft(recipe: Dictionary, inventory: Inventory, observations: Dictionary) -> Dictionary:
	if recipe.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if not is_unlocked(recipe, observations):
		return {"ok": false, "code": "locked"}
	var inputs: Array = recipe.get("inputs", [])
	if not inventory.has_many(inputs):
		return {"ok": false, "code": "missing_inputs"}
	var copy := inventory.duplicate_inventory()
	if not copy.remove_many(inputs):
		return {"ok": false, "code": "missing_inputs"}
	var outputs: Array = recipe.get("outputs", [])
	var added: Dictionary = copy.add_many(outputs)
	if not bool(added.get("ok", false)):
		return {"ok": false, "code": str(added.get("code", "capacity"))}
	return {"ok": true, "code": "ok"}

static func craft(recipe: Dictionary, inventory: Inventory, observations: Dictionary) -> Dictionary:
	var check := can_craft(recipe, inventory, observations)
	if not bool(check.get("ok", false)):
		return check
	var inputs: Array = recipe.get("inputs", [])
	var outputs: Array = recipe.get("outputs", [])
	var copy := inventory.duplicate_inventory()
	copy.remove_many(inputs)
	copy.add_many(outputs)
	inventory.items = copy.items.duplicate()
	return {
		"ok": true,
		"code": "crafted",
		"recipe_id": str(recipe.get("content_id", "")),
		"consumed": inputs,
		"outputs": outputs,
	}
