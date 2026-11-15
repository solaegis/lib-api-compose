describe("Unit", function()
    it("Compose returns nil for a unit that does not exist", function()
        mock.reset()
        assertFalsy(LibApiCompose.Unit.Compose("reticleover"))
        assertFalsy(LibApiCompose.Unit.Compose(42))
    end)

    it("Compose defaults to the player and formats names", function()
        mock.reset()
        mock.setUnit("player", {
            name = "Test Hero^Mx",
            displayName = "@tester",
            level = 50,
            cp = 1800,
            effectiveCp = 160,
            classId = 2,
            className = "Sorcerer^m",
            raceId = 7,
            raceName = "Breton^m",
            alliance = 2,
            zone = "Glenumbra^N",
            isPlayer = true,
            combat = true,
            powers = {
                [COMBAT_MECHANIC_FLAGS_HEALTH] = { 100, 200, 250 },
                [COMBAT_MECHANIC_FLAGS_MAGICKA] = { 5, 6, 7 },
            },
        })
        local rec = LibApiCompose.Unit.Compose()
        assertEqual(rec.unitTag, "player")
        assertEqual(rec.name, "Test Hero")
        assertEqual(rec.displayName, "@tester")
        assertEqual(rec.level, 50)
        assertEqual(rec.championPoints, 1800)
        assertEqual(rec.effectiveChampionPoints, 160)
        assertEqual(rec.className, "Sorcerer")
        assertEqual(rec.raceName, "Breton")
        assertEqual(rec.allianceName, "Alliance2")
        assertEqual(rec.zoneName, "Glenumbra")
        assertEqual(rec.isPlayer, true)
        assertEqual(rec.isDead, false)
        assertEqual(rec.isInCombat, true)
        assertEqual(rec.health.current, 100)
        assertEqual(rec.health.max, 200)
        assertEqual(rec.health.effectiveMax, 250)
        assertEqual(rec.magicka.max, 6)
        assertEqual(rec.stamina.current, 0)
    end)

    it("opts.skipPower leaves the power pools out", function()
        mock.reset()
        mock.setUnit("group1", { name = "Ally" })
        local rec = LibApiCompose.Unit.Compose("group1", { skipPower = true })
        assertEqual(rec.name, "Ally")
        assertEqual(rec.health, nil)
        assertEqual(rec.displayName, nil)
    end)
end)
