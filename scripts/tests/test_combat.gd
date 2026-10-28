extends BtvTestSuite

## Stage 1 combat contract: cooldown, damage order, death/revive, deterministic hostiles.

func test_fire_cooldown() -> void:
	var p := BtvPlayer.new()
	check(p.try_fire(), "first shot should be accepted")
	check(not p.try_fire(), "immediate second shot should be blocked by cooldown")
	p._fire_cooldown = 0.0
	check(p.try_fire(), "shot should be accepted after cooldown expires")
	check(p.combat, "firing should enter the combat pose")
	p.free()

func test_shield_absorbs_before_hull() -> void:
	var p := BtvPlayer.new()
	p.shield = 50.0
	p.health = 100.0
	p.take_damage(10.0)
	equal(p.shield, 40.0, "shield should absorb the first 10 damage")
	equal(p.health, 100.0, "hull should stay untouched while shield holds")
	p.take_damage(60.0)
	equal(p.shield, 0.0, "shield should be exhausted")
	equal(p.health, 80.0, "overflow should hit the hull only")
	p.free()

func test_death_and_revive() -> void:
	var p := BtvPlayer.new()
	p.shield = 50.0
	p.health = 100.0
	p.take_damage(1000.0)
	check(not p.alive, "lethal damage should kill the player")
	p.revive(Vector2(5.0, 6.0))
	check(p.alive, "revive should restore the living state")
	equal(p.health, 100.0, "revive should restore full hull")
	equal(p.shield, 50.0, "revive should restore full shield")
	equal(p.position, Vector2(5.0, 6.0), "revive should move the player to the spawn")
	p.free()

func test_hit_center_accounts_for_altitude() -> void:
	var p := BtvPlayer.new()
	p.position = Vector2(100.0, 200.0)
	p.altitude = 10.0
	equal(p.hit_center(), Vector2(100.0, 168.0), "hit center should sit 22 px above boots plus altitude")
	p.free()

func test_hostile_plan_is_deterministic() -> void:
	var bounds := Rect2(0.0, 0.0, 5120.0, 2560.0)
	var spawn := Vector2(2430.0, 2080.0)
	var a := BtvCombatDirector.plan_hostiles_static(777, spawn, bounds)
	var b := BtvCombatDirector.plan_hostiles_static(777, spawn, bounds)
	var c := BtvCombatDirector.plan_hostiles_static(778, spawn, bounds)
	equal(a.size(), 3, "combat plan should spawn three hostiles")
	equal(b.size(), 3, "same seed should produce the same count")
	for i in range(a.size()):
		equal(str(a[i].get("kind", "")), str(b[i].get("kind", "")), "same seed should keep hostile kind %d" % i)
		equal(a[i].get("pos", Vector2.ZERO), b[i].get("pos", Vector2.ZERO), "same seed should keep hostile position %d" % i)
	var moved := false
	for i in range(mini(a.size(), c.size())):
		if a[i].get("pos", Vector2.ZERO) != c[i].get("pos", Vector2.ZERO):
			moved = true
	check(moved, "a different seed should move at least one hostile")
	for entry in a:
		var pos: Vector2 = entry.get("pos", Vector2.ZERO)
		check(pos.x >= 60.0 and pos.x <= bounds.end.x - 60.0, "hostile x should stay inside bounds")
		check(pos.y >= 60.0 and pos.y <= bounds.end.y - 60.0, "hostile y should stay inside bounds")
		check(not BtvSurfaceWorld.WATER_RECT.grow(40.0).has_point(pos), "hostile should not spawn in water")
		check(pos.distance_to(spawn) >= 200.0, "hostile should not spawn on top of the player")
