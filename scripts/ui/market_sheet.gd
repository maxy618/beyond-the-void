class_name BtvMarketSheet
extends BtvPanelBase

## Finite-stock exchange. Every button calls the same atomic quote/commit path as tests.

var market_id: String = ""

func setup_market(p_session: GameSession, p_loc: Localization, p_market_id: String) -> void:
	market_id = p_market_id
	var market: Dictionary = p_session.registry.get_market(market_id)
	var title := str(market.get("display_key", "ui.market_title"))
	setup(p_session, p_loc, title)

func _fill() -> void:
	var market: MarketState = session.get_market(market_id)
	if market == null:
		add_empty(loc.t("ui.market_empty"))
		return
	add_note(loc.t("ui.finite_stock"))
	add_note(loc.t("ui.credits_value", {"credits": session.credits}))
	var definition: Dictionary = session.registry.get_market(market_id)
	var explanation := str(definition.get("player_facing_explanation_key", ""))
	if not explanation.is_empty() and loc.has(explanation):
		add_note(loc.t(explanation))
	body.add_child(BtvTheme.spacer(4))
	var stock_lines: Array = definition.get("initial_stock", [])
	for raw_line in stock_lines:
		var line: Dictionary = raw_line
		var item_id := str(line.get("item_id", ""))
		var stock := market.stock_of(item_id)
		var buy_price := market.unit_buy_price(item_id, session.registry)
		var sell_price := market.unit_sell_price(item_id, session.registry)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL_SOFT, 12, BtvTheme.LINE, 1))
		body.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 5)
		card.add_child(column)
		var top := HBoxContainer.new()
		column.add_child(top)
		var name_label := BtvTheme.label(_item_name(item_id), 16, BtvTheme.TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_label)
		top.add_child(BtvTheme.label(loc.t("ui.market_stock", {"stock": stock}), 12, BtvTheme.TEXT_DIM))
		column.add_child(BtvTheme.wrapped("%s · %s" % [
			loc.t("ui.market_price", {"price": buy_price}),
			loc.t("ui.market_target", {"stock": market.target_of(item_id)}),
		], 12, BtvTheme.TEXT_DIM))
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 8)
		column.add_child(buttons)
		var buy := BtvTheme.button("%s · %d cr" % [loc.t("ui.buy_one"), buy_price], 46)
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy.disabled = stock <= 0 or session.credits < buy_price
		buy.pressed.connect(_buy.bind(item_id))
		buttons.add_child(buy)
		var sell := BtvTheme.button("%s · %d cr" % [loc.t("ui.sell_one"), sell_price], 46)
		sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sell.disabled = session.inventory.count(item_id) <= 0 or market.stock_room(item_id) <= 0
		sell.pressed.connect(_sell.bind(item_id))
		buttons.add_child(sell)
	if stock_lines.is_empty():
		add_empty(loc.t("ui.market_empty"))

func _buy(item_id: String) -> void:
	var result := session.buy(market_id, item_id, 1)
	if bool(result.get("ok", false)):
		refresh()

func _sell(item_id: String) -> void:
	var result := session.sell(market_id, item_id, 1)
	if bool(result.get("ok", false)):
		refresh()

func _item_name(item_id: String) -> String:
	var item: Dictionary = session.registry.get_item(item_id)
	return loc.t(str(item.get("display_key", "")))
