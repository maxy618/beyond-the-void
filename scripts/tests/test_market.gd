extends BtvTestSuite

const MARKET_ID := "market.vela.coast"
const ITEM_ID := "item.saltglass_shard"

func test_buy_moves_stock_and_credits() -> void:
	var session := new_session()
	var market := session.get_market(MARKET_ID)
	not_null(market, "market exists")
	var stock_before := market.stock_of(ITEM_ID)
	var credits_before := session.credits
	var held_before := session.inventory.count(ITEM_ID)
	var result := session.buy(MARKET_ID, ITEM_ID, 3)
	check(result.get("ok", false), "buy succeeds: " + str(result))
	equal(market.stock_of(ITEM_ID), stock_before - 3, "stock decreases")
	equal(session.credits, credits_before - int(result.get("total", 0)), "credits decrease")
	equal(session.inventory.count(ITEM_ID), held_before + 3, "inventory increases")
	check(session.credits >= 0, "credits never negative")

func test_sell_moves_stock_and_credits() -> void:
	var session := new_session()
	var market := session.get_market(MARKET_ID)
	var stock_before := market.stock_of(ITEM_ID)
	var credits_before := session.credits
	var held_before := session.inventory.count(ITEM_ID)
	var result := session.sell(MARKET_ID, ITEM_ID, 2)
	check(result.get("ok", false), "sell succeeds: " + str(result))
	equal(market.stock_of(ITEM_ID), stock_before + 2, "stock increases")
	equal(session.credits, credits_before + int(result.get("total", 0)), "credits increase")
	equal(session.inventory.count(ITEM_ID), held_before - 2, "inventory decreases")

func test_stock_is_finite() -> void:
	var session := new_session()
	var market := session.get_market(MARKET_ID)
	var stock := market.stock_of(ITEM_ID)
	var credits := session.credits
	var result := session.buy(MARKET_ID, ITEM_ID, stock + 1)
	check(not result.get("ok", false), "cannot buy beyond finite stock")
	equal(market.stock_of(ITEM_ID), stock, "failed buy leaves stock")
	equal(session.credits, credits, "failed buy leaves credits")

func test_buy_without_credits_does_not_mutate() -> void:
	var session := new_session()
	session.credits = 0
	var market := session.get_market(MARKET_ID)
	var stock := market.stock_of(ITEM_ID)
	var result := session.buy(MARKET_ID, ITEM_ID, 1)
	check(not result.get("ok", false), "no-credit purchase rejected")
	equal(market.stock_of(ITEM_ID), stock, "no-credit purchase leaves stock")

func test_buy_without_capacity_does_not_mutate() -> void:
	var session := new_session()
	session.inventory.capacity_kg = session.inventory.total_mass() + 0.01
	var market := session.get_market(MARKET_ID)
	var stock := market.stock_of(ITEM_ID)
	var credits := session.credits
	var result := session.buy(MARKET_ID, ITEM_ID, 2)
	check(not result.get("ok", false), "capacity-limited purchase rejected")
	equal(market.stock_of(ITEM_ID), stock, "failed purchase leaves stock")
	equal(session.credits, credits, "failed purchase leaves credits")

func test_unlisted_sale_and_invalid_quantity() -> void:
	var session := new_session()
	var market := session.get_market(MARKET_ID)
	check(not session.sell(MARKET_ID, "item.mira_photo", 1).get("ok", false), "keepsake is not sellable at this market")
	check(not session.sell(MARKET_ID, ITEM_ID, 0).get("ok", false), "zero quantity rejected")
	check(not session.buy(MARKET_ID, ITEM_ID, 0).get("ok", false), "zero purchase rejected")
	equal(market.stock_of(ITEM_ID), 18, "invalid trades leave stock untouched")

func test_prices_are_bounded_integers() -> void:
	var session := new_session()
	var market := session.get_market(MARKET_ID)
	for item_id in market.definition.get("initial_stock", []):
		var id := str(item_id.get("item_id", ""))
		var item: Dictionary = registry.get_item(id)
		var unit_buy := market.unit_buy_price(id, registry)
		var unit_sell := market.unit_sell_price(id, registry)
		check(unit_buy >= 1 and unit_sell >= 1, "price positive for " + id)
		check(unit_buy <= int(float(item.get("base_value", 1)) * 4.0), "buy price bounded for " + id)
		check(unit_sell <= unit_buy, "sell does not exceed buy for " + id)

func test_restock_moves_toward_target() -> void:
	var session := new_session()
	var market := session.get_market(MARKET_ID)
	var result := session.buy(MARKET_ID, ITEM_ID, 3)
	check(result.get("ok", false), "drain stock")
	var after_buy := market.stock_of(ITEM_ID)
	market.tick(900.0)
	equal(market.stock_of(ITEM_ID), after_buy + 2, "production restocks two units per cycle")
	check(market.stock_of(ITEM_ID) <= market.target_of(ITEM_ID), "restock does not exceed target")

func test_market_state_roundtrip() -> void:
	var session := new_session()
	var market := session.get_market(MARKET_ID)
	check(session.buy(MARKET_ID, ITEM_ID, 2).get("ok", false), "buy before snapshot")
	var snapshot := market.to_state()
	var other := MarketState.new()
	other.setup(registry.get_market(MARKET_ID))
	other.from_state(snapshot)
	equal(other.stock_of(ITEM_ID), market.stock_of(ITEM_ID), "stock restored")
	near(other.cycle_progress, market.cycle_progress, 0.001, "cycle restored")
