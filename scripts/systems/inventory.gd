class_name Inventory
extends RefCounted

## Mass- and stack-limited field inventory. Mutations are validated before commit.

var registry = null
var items: Dictionary = {}
var capacity_kg: float = 80.0

func setup(content) -> void:
	registry = content

func count(item_id: String) -> int:
	return int(items.get(item_id, 0))

func total_mass() -> float:
	if registry == null:
		return 0.0
	var mass := 0.0
	for item_id in items.keys():
		var item = registry.get_item(str(item_id))
		mass += float(item.get("mass_kg", 0.0)) * int(items[item_id])
	return mass

func can_add(item_id: String, amount: int = 1) -> Dictionary:
	if amount <= 0:
		return {"ok": false, "code": "invalid_target"}
	var item = registry.get_item(item_id)
	if item.is_empty():
		return {"ok": false, "code": "item_missing"}
	var limit := int(item.get("stack_limit", 99))
	if count(item_id) + amount > limit:
		return {"ok": false, "code": "capacity"}
	var new_mass := total_mass() + float(item.get("mass_kg", 0.0)) * amount
	if new_mass > capacity_kg + 0.0001:
		return {"ok": false, "code": "capacity"}
	return {"ok": true, "code": "ok"}

func add(item_id: String, amount: int = 1) -> Dictionary:
	var check := can_add(item_id, amount)
	if not bool(check.get("ok", false)):
		return check
	items[item_id] = count(item_id) + amount
	return {"ok": true, "code": "ok", "item_id": item_id, "count": amount}

func remove(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or count(item_id) < amount:
		return false
	var left := count(item_id) - amount
	if left == 0:
		items.erase(item_id)
	else:
		items[item_id] = left
	return true

func has_many(entries: Array) -> bool:
	for line in entries:
		if count(str(line.get("item_id", ""))) < int(line.get("count", 0)):
			return false
	return true

func can_add_many(entries: Array) -> Dictionary:
	var copy := duplicate_inventory()
	for line in entries:
		var result: Dictionary = copy.add(str(line.get("item_id", "")), int(line.get("count", 0)))
		if not bool(result.get("ok", false)):
			return result
	return {"ok": true, "code": "ok"}

func add_many(entries: Array) -> Dictionary:
	var copy := duplicate_inventory()
	for line in entries:
		var result: Dictionary = copy.add(str(line.get("item_id", "")), int(line.get("count", 0)))
		if not bool(result.get("ok", false)):
			return result
	items = copy.items.duplicate()
	return {"ok": true, "code": "ok"}

func remove_many(entries: Array) -> bool:
	if not has_many(entries):
		return false
	for line in entries:
		remove(str(line.get("item_id", "")), int(line.get("count", 0)))
	return true

func duplicate_inventory() -> Inventory:
	var copy := Inventory.new()
	copy.setup(registry)
	copy.capacity_kg = capacity_kg
	copy.items = items.duplicate()
	return copy

func to_dict() -> Dictionary:
	return items.duplicate()

func from_dict(data: Dictionary) -> void:
	items.clear()
	for key in data.keys():
		var amount := int(data[key])
		if amount > 0:
			items[str(key)] = amount
