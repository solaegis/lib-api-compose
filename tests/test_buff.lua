describe("Buff", function()
    it("ComposeAll maps every return of GetUnitBuffInfo", function()
        mock.reset()
        mock.setBuffs("player", {
            {
                name = "Major Brutality^n",
                started = 10,
                ending = 40,
                stacks = 1,
                abilityId = 61665,
                castByPlayer = true,
            },
            { name = "Burning", started = 5, ending = 9, effectType = BUFF_EFFECT_TYPE_DEBUFF, abilityId = 18084 },
            { name = "Boon: The Thief", started = 0, ending = 0, abilityId = 13975, canClickOff = true },
        })
        local list = LibApiCompose.Buff.ComposeAll()
        assertEqual(#list, 3)
        assertEqual(list[1].name, "Major Brutality")
        assertEqual(list[1].unitTag, "player")
        assertEqual(list[1].index, 1)
        assertEqual(list[1].startTime, 10)
        assertEqual(list[1].endTime, 40)
        assertEqual(list[1].abilityId, 61665)
        assertEqual(list[1].castByPlayer, true)
        assertEqual(list[1].isDebuff, false)
        assertEqual(list[1].isPermanent, false)
        assertEqual(list[2].isDebuff, true)
        assertEqual(list[3].isPermanent, true)
        assertEqual(list[3].canClickOff, true)
    end)

    it("ComposeAll returns an empty list for a unit without buffs", function()
        mock.reset()
        assertEqual(#LibApiCompose.Buff.ComposeAll("reticleover"), 0)
    end)

    it("Find returns the first buff with an ability id", function()
        mock.reset()
        mock.setBuffs("player", {
            { name = "A", abilityId = 1 },
            { name = "B", abilityId = 2 },
        })
        local B = LibApiCompose.Buff
        assertEqual(B.Find("player", 2).name, "B")
        assertEqual(B.Find(nil, 1).index, 1)
        assertFalsy(B.Find("player", 3))
        assertFalsy(B.Find("player", nil))
    end)
end)
