describe("Skill", function()
    local function seed()
        mock.reset()
        mock.setSkills({
            [1] = {
                {
                    id = 41,
                    name = "Dark Magic^n",
                    rank = 50,
                    xp = 10,
                    nextXP = 0,
                    abilities = {
                        {
                            id = 1001,
                            name = "Crystal Shard^n",
                            ultimate = false,
                            purchased = true,
                            progressionIndex = 3,
                        },
                        { id = 1002, name = "Negate Magic", ultimate = true },
                        { id = 1003, name = "Unholy Knowledge", passive = true, purchased = true, upgradeLevel = 2 },
                    },
                },
                { id = 42, name = "Daedric Summoning", rank = 12, abilities = {} },
            },
            [2] = {
                { id = 60, name = "Grimoire Line", abilities = { { id = 2001, name = "Scribed", craftedId = 5 } } },
            },
        })
    end

    it("ComposeLine reads line facts", function()
        seed()
        local line = LibApiCompose.Skill.ComposeLine(1, 1)
        assertEqual(line.id, 41)
        assertEqual(line.name, "Dark Magic")
        assertEqual(line.rank, 50)
        assertEqual(line.isActive, true)
        assertEqual(line.isDiscovered, true)
        assertEqual(line.xp.current, 10)
        assertFalsy(LibApiCompose.Skill.ComposeLine(1, 9))
        assertFalsy(LibApiCompose.Skill.ComposeLine(nil, 1))
    end)

    it("ComposeAbility reads active, ultimate, passive and crafted abilities", function()
        seed()
        local S = LibApiCompose.Skill
        local active = S.ComposeAbility(1, 1, 1)
        assertEqual(active.abilityId, 1001)
        assertEqual(active.name, "Crystal Shard")
        assertEqual(active.isPurchased, true)
        assertEqual(active.isPassive, false)
        assertEqual(active.progressionIndex, 3)
        assertEqual(active.upgradeLevel, nil)
        assertEqual(S.ComposeAbility(1, 1, 2).isUltimate, true)
        local passive = S.ComposeAbility(1, 1, 3)
        assertEqual(passive.isPassive, true)
        assertEqual(passive.upgradeLevel, 2)
        assertEqual(passive.maxUpgradeLevel, 2)
        local crafted = S.ComposeAbility(2, 1, 1)
        assertEqual(crafted.isCrafted, true)
        assertEqual(crafted.craftedAbilityId, 5)
        assertFalsy(S.ComposeAbility(1, 1, 99))
    end)

    it("ComposeLines walks one type or every type", function()
        seed()
        local S = LibApiCompose.Skill
        assertEqual(#S.ComposeLines(1), 2)
        local all = S.ComposeLines()
        assertEqual(#all, 3)
        assertEqual(all[3].skillType, 2)
        assertEqual(#S.ComposeLines(7), 0)
    end)

    it("ComposeAbilities and ForEachAbility walk abilities", function()
        seed()
        local S = LibApiCompose.Skill
        assertEqual(#S.ComposeAbilities(1, 1), 3)
        assertEqual(#S.ComposeAbilities(1, 2), 0)
        local names = {}
        S.ForEachAbility(function(rec)
            names[#names + 1] = rec.name
        end)
        assertEqual(#names, 4)
        local seen = 0
        S.ForEachAbility(function()
            seen = seen + 1
            return seen == 2
        end)
        assertEqual(seen, 2)
    end)
end)
