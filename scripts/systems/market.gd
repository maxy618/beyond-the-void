class_name MarketState
extends RefCounted

## Finite stock market with bounded integer prices. Stock can never go negative.

var definition: Dictionary = {}
var stock: Dictionary = {}
var cycle_progress: float = 0.0

func setup(market_definition: Dictionary) -> void:
	definition = market_definition
	stock.clear()
	cycle_progress = 0.0
	for line in definition.get("initial_stock", []):
		stock[str(line.get("item_id", ""))] = int(line.get("quantity", 0))

func display_name_key() -> String:
	return str(definition.get("display_key", ""))

func stock_of(item_id: String) -> int:
	return int(stock.get(item_id, 0))

func is_listed(item_id: String) -> bool:
	return stock.has(item_id)

func target_of(item_id: String) -> int:
	for line in definition.get("initial_stock", []):
		if str(line.get("item_id", "")) == item_id:
			return int(line.get("target_stock", 1))
	return 1

func stock_room(item_id: String) -> int:
	var model = definition.get("stock_model", {})
	var max_stock := maxi(target_of(item_id) + 1, int(float(target_of(item_id)) * float(model.get("max_stock_factor", 3.0))))
	return maxi(0, max_stock - stock_of(item_id))

func stock_factor(item_id: String) -> float:
	var model = definition.get("stock_model", {})
	var target := maxf(1.0, float(target_of(item_id)))
	var current := maxf(0.5, float(stock_of(item_id)))
	var raw := pow(target / current, 0.4)
	return clampf(raw, float(model.get("price_floor_factor", 0.55)), float(model.get("price_ceiling_factor", 2.8)))

func demand_multiplier(item_id: String, registry) -> float:
	var item = registry.get_item(item_id)
	var tags: Array = item.get("tags", [])
	var best := 1.0
	for modifier in definition.get("demand_modifiers", []):
		if str(modifier.get("tag", "")) in tags:
			best = maxf(best, float(modifier.get("multiplier", 1.0)))
	return best

func unit_buy_price(item_id: String, registry) -> int:
	var item = registry.get_item(item_id)
	var model = definition.get("stock_model", {})
	var raw := float(item.get("base_value", 1)) * stock_factor(item_id) * demand_multiplier(item_id, registry)
	raw *= 1.0 + float(model.get("buy_fee", 0.05))
	return maxi(1, int(round(raw)))

func unit_sell_price(item_id: String, registry) -> int:
	var item = registry.get_item(item_id)
	var model = definition.get("stock_model", {})
	var raw := float(item.get("base_value", 1)) * stock_factor(item_id) * demand_multiplier(item_id, registry)
	raw *= 1.0 - float(model.get("sell_fee", 0.03))
	return maxi(1, int(round(raw)))

func quote_buy(item_id: String, amount: int, registry) -> Dictionary:
	var rules = definition.get("trade_rules", {})
	if not is_listed(item_id):
		return {"ok": false, "code": "market_empty"}
	if amount < int(rules.get("min_quantity", 1)) or amount > int(rules.get("max_quantity", 99)):
		return {"ok": false, "code": "invalid_target"}
	if stock_of(item_id) < amount:
		return {"ok": false, "code": "out_of_stock"}
	var unit := unit_buy_price(item_id, registry)
	return {
		"ok": true, "code": "ok", "item_id": item_id, "quantity": amount,
		"unit_price": unit, "total": unit * amount,
		"stock_before": stock_of(item_id),
		"price_before": unit_buy_price(item_id, registry),
	}

func commit_buy(item_id: String, amount: int, inventory: Inventory, credits: int, registry) -> Dictionary:
	var quote := quote_buy(item_id, amount, registry)
	if not bool(quote.get("ok", false)):
		return quote
	if credits < int(quote.get("total", 0)):
		return {"ok": false, "code": "no_credits"}
	var add_check := inventory.can_add(item_id, amount)
	if not bool(add_check.get("ok", false)):
		return add_check
	var stock_before := stock_of(item_id)
	var credits_after := credits - int(quote.get("total", 0))
	stock[item_id] = stock_before - amount
	inventory.add(item_id, amount)
	return {
		"ok": true, "code": "bought", "item_id": item_id, "quantity": amount,
		"unit_price": quote.get("unit_price", 0), "total": quote.get("total", 0),
		"credits_after": credits_after,
		"stock_before": stock_before, "stock_after": stock_of(item_id),
		"price_before": quote.get("price_before", 0), "price_after": unit_buy_price(item_id, registry),
	}

func quote_sell(item_id: String, amount: int, registry) -> Dictionary:
	var rules = definition.get("trade_rules", {})
	if not is_listed(item_id) and not bool(rules.get("sell_unlisted", false)):
		return {"ok": false, "code": "market_empty"}
	if amount < int(rules.get("min_quantity", 1)) or amount > int(rules.get("max_quantity", 99)):
		return {"ok": false, "code": "invalid_target"}
	if stock_room(item_id) < amount:
		return {"ok": false, "code": "capacity"}
	var unit := unit_sell_price(item_id, registry)
	return {
		"ok": true, "code": "ok", "item_id": item_id, "quantity": amount,
		"unit_price": unit, "total": unit * amount,
		"stock_before": stock_of(item_id),
	}

func commit_sell(item_id: String, amount: int, inventory: Inventory, credits: int, registry) -> Dictionary:
	var quote := quote_sell(item_id, amount, registry)
	if not bool(quote.get("ok", false)):
		return quote
	if inventory.count(item_id) < amount:
		return {"ok": false, "code": "missing_inputs"}
	var stock_before := stock_of(item_id)
	inventory.remove(item_id, amount)
	stock[item_id] = stock_before + amount
	return {
		"ok": true, "code": "sold", "item_id": item_id, "quantity": amount,
		"unit_price": quote.get("unit_price", 0), "total": quote.get("total", 0),
		"credits_after": credits + int(quote.get("total", 0)),
		"stock_before": stock_before, "stock_after": stock_of(item_id),
		"price_before": unit_buy_price(item_id, registry), "price_after": unit_buy_price(item_id, registry),
	}

func tick(seconds: float) -> void:
	var interval := maxf(1.0, float(definition.get("update_interval_seconds", 900)))
	cycle_progress += seconds
	while cycle_progress >= interval:
		cycle_progress -= interval
		for line in definition.get("initial_stock", []):
			var item_id := str(line.get("item_id", ""))
			var target := int(line.get("target_stock", 0))
			var current := stock_of(item_id)
			if current < target:
				stock[item_id] = mini(target, current + maxi(1, int(line.get("production_per_cycle", 0))))
			elif current > target:
				stock[item_id] = maxi(target, current - maxi(0, int(line.get("consumption_per_cycle", 0))))

func to_state() -> Dictionary:
	return {"stock": stock.duplicate(), "cycle_progress": cycle_progress}

func from_state(state: Dictionary) -> void:
	var saved: Dictionary = state.get("stock", {})
	for item_id in saved.keys():
		if stock.has(str(item_id)):
			stock[str(item_id)] = maxi(0, int(saved[item_id]))
	cycle_progress = float(state.get("cycle_progress", 0.0))
