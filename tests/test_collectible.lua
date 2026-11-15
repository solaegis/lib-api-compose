describe("Collectible", function()
    it("Compose returns formatted static facts and live state", function()
        mock.reset()
        mock.setCollectible(100, {
            name = "Bear^n",
            nickname = "Fluffy",
            icon = "bear.dds",
            category = COLLECTIBLE_CATEGORY_TYPE_MOUNT,
            unlocked = true,
            active = false,
        })
        local rec = LibApiCompose.Collectible.Compose(100)
        assertEqual(rec.id, 100)
        assertEqual(rec.name, "Bear")
        assertEqual(rec.nickname, "Fluffy")
        assertEqual(rec.icon, "bear.dds")
        assertEqual(rec.category, COLLECTIBLE_CATEGORY_TYPE_MOUNT)
        assertEqual(rec.unlocked, true)
        assertEqual(rec.active, false)
    end)

    it("Compose returns nil for invalid ids", function()
        assertFalsy(LibApiCompose.Collectible.Compose(0))
        assertFalsy(LibApiCompose.Collectible.Compose(nil))
        assertFalsy(LibApiCompose.Collectible.Compose("x"))
    end)

    it("Compose returns nil for ids that are not collectibles and does not cache them", function()
        mock.reset()
        assertFalsy(LibApiCompose.Collectible.Compose(424242))
        mock.setCollectible(424242, { name = "Now Real", category = 3 })
        assertEqual(LibApiCompose.Collectible.Compose(424242).name, "Now Real")
    end)

    it("Compose normalises empty strings to nil and reads the extended fields", function()
        mock.reset()
        mock.setCollectible(150, {
            name = "Memento",
            category = 5,
            unlocked = true,
            unlockState = 2,
            blocked = true,
            cooldownRemaining = 1500,
            cooldownDuration = 30000,
            description = "Does a thing",
        })
        local rec = LibApiCompose.Collectible.Compose(150)
        assertEqual(rec.nickname, nil)
        assertEqual(rec.icon, nil)
        assertEqual(rec.unlockState, 2)
        assertEqual(rec.isBlocked, true)
        assertEqual(rec.cooldownRemaining, 1500)
        assertEqual(rec.cooldownDuration, 30000)
        assertEqual(rec.description, nil, "description only with includeDescription")
        local full = LibApiCompose.Collectible.Compose(150, { includeDescription = true, includeLink = true })
        assertEqual(full.description, "Does a thing")
        assertEqual(full.link, "|H0:collectible:150|h|h")
    end)

    it("falls back to GetCollectibleInfo for the name", function()
        mock.reset()
        mock.setCollectible(160, { category = 5, infoName = "From Info^n" })
        local rec = LibApiCompose.Collectible.Compose(160)
        assertEqual(rec.name, "From Info")
    end)

    it("volatile fields are read live, not from cache", function()
        mock.reset()
        local data = { name = "Pet", category = 3, unlocked = false, active = false }
        mock.setCollectible(200, data)
        assertEqual(LibApiCompose.Collectible.Compose(200).unlocked, false)
        data.unlocked = true
        data.active = true
        data.nickname = "Rex"
        local rec = LibApiCompose.Collectible.Compose(200)
        assertEqual(rec.unlocked, true)
        assertEqual(rec.active, true)
        assertEqual(rec.nickname, "Rex")
    end)

    it("static facts are memoised until ClearCache", function()
        mock.reset()
        local data = { name = "Old", category = 3 }
        mock.setCollectible(300, data)
        assertEqual(LibApiCompose.Collectible.Compose(300).name, "Old")
        data.name = "New"
        assertEqual(LibApiCompose.Collectible.Compose(300).name, "Old")
        assertEqual(LibApiCompose.Collectible.Compose(300, { skipCache = true }).name, "New")
        LibApiCompose.ClearCache()
        assertEqual(LibApiCompose.Collectible.Compose(300).name, "New")
    end)

    it("returned records do not alias the cache", function()
        mock.reset()
        mock.setCollectible(400, { name = "Horse", category = COLLECTIBLE_CATEGORY_TYPE_MOUNT, unlocked = true })
        local first = LibApiCompose.Collectible.ComposeUnlockedByCategory(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
        first.list[1].name = "MUTATED"
        local second = LibApiCompose.Collectible.ComposeUnlockedByCategory(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
        assertEqual(second.list[1].name, "Horse")
        assertTruthy(first.list[1] ~= second.list[1])
        local single = LibApiCompose.Collectible.Compose(400)
        single.name = "ALSO MUTATED"
        assertEqual(LibApiCompose.Collectible.Compose(400).name, "Horse")
    end)

    it("ComposeUnlockedByCategory lists unlocked only with totals", function()
        mock.reset()
        mock.setCollectible(1, { name = "A", category = 9, unlocked = true })
        mock.setCollectible(2, { name = "B", category = 9, unlocked = false })
        mock.setCollectible(3, { name = "C", category = 9, unlocked = true })
        local res = LibApiCompose.Collectible.ComposeUnlockedByCategory(9)
        assertEqual(res.count, 2)
        assertEqual(res.total, 3)
        assertEqual(res.list[1].id, 1)
        assertEqual(res.list[2].id, 3)
    end)

    it("collection events invalidate unlocked lists", function()
        mock.reset()
        local data = { name = "Late", category = 9, unlocked = false }
        mock.setCollectible(10, data)
        assertEqual(LibApiCompose.Collectible.ComposeUnlockedByCategory(9).count, 0)
        data.unlocked = true
        assertEqual(LibApiCompose.Collectible.ComposeUnlockedByCategory(9).count, 0, "cached until event")
        mock.fireEvent(EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED)
        assertEqual(LibApiCompose.Collectible.ComposeUnlockedByCategory(9).count, 1)
    end)

    it("registers only events that exist on this client", function()
        local seen = {}
        for _, reg in ipairs(mock.registeredEvents()) do
            seen[reg.event] = true
        end
        assertEqual(seen[EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED], true)
        assertEqual(seen[EVENT_COLLECTIBLE_UPDATED], true)
    end)

    it("IndexByName lowercases formatted names, first id wins", function()
        mock.reset()
        mock.setCollectible(21, { name = "Grey Horse^n", category = 4 })
        mock.setCollectible(22, { name = "grey horse", category = 4 })
        mock.setCollectible(23, { name = "Bay", category = 4 })
        local map = LibApiCompose.Collectible.IndexByName(4)
        assertEqual(map["grey horse"], 21)
        assertEqual(map["bay"], 23)
        map["bay"] = 999
        assertEqual(LibApiCompose.Collectible.IndexByName(4)["bay"], 23)
    end)

    it("FindByName is case-insensitive and survives list invalidation", function()
        mock.reset()
        mock.setCollectible(31, { name = "Storm Atronach Wolf^n", category = 4 })
        local C = LibApiCompose.Collectible
        assertEqual(C.FindByName(4, "storm atronach WOLF"), 31)
        assertEqual(C.FindByName(4, "missing"), nil)
        assertEqual(C.FindByName(4, ""), nil)
        assertEqual(C.FindByName(nil, "x"), nil)
        local calls = 0
        local saved = GetTotalCollectiblesByCategoryType
        _G.GetTotalCollectiblesByCategoryType = function(...)
            calls = calls + 1
            return saved(...)
        end
        C.InvalidateLists()
        assertEqual(C.FindByName(4, "Storm Atronach Wolf"), 31)
        _G.GetTotalCollectiblesByCategoryType = saved
        assertEqual(calls, 0, "name index must not be rebuilt by unlock events")
    end)
end)

describe("Companion", function()
    it("ComposeActive returns nil without a companion", function()
        mock.reset()
        assertFalsy(LibApiCompose.Companion.ComposeActive())
    end)

    it("ComposeActive resolves collectible facts", function()
        mock.reset()
        mock.setCollectible(9353, {
            name = "Mirri Elendis^F",
            icon = "mirri.dds",
            category = COLLECTIBLE_CATEGORY_TYPE_COMPANION,
            unlocked = true,
            active = true,
        })
        mock.setCompanion({ defId = 2, collectibleId = 9353 })
        local rec = LibApiCompose.Companion.ComposeActive()
        assertEqual(rec.defId, 2)
        assertEqual(rec.collectibleId, 9353)
        assertEqual(rec.id, 9353)
        assertEqual(rec.name, "Mirri Elendis")
        assertEqual(rec.icon, "mirri.dds")
        assertEqual(rec.isActive, true)
    end)

    it("ComposeActive reads level and rapport", function()
        mock.reset()
        mock.setCollectible(9353, { name = "Mirri", category = COLLECTIBLE_CATEGORY_TYPE_COMPANION, unlocked = true })
        mock.setCompanion({ defId = 2, collectibleId = 9353, level = 12, xp = 340, rapport = 2500, rapportLevel = 4 })
        local rec = LibApiCompose.Companion.ComposeActive()
        assertEqual(rec.level, 12)
        assertEqual(rec.xp, 340)
        assertEqual(rec.rapport, 2500)
        assertEqual(rec.rapportLevel, 4)
        assertEqual(rec.isPending, false)
    end)

    it("ComposeActive falls back to the active companion collectible", function()
        mock.reset()
        mock.setCollectible(77, {
            name = "Bastian^M",
            category = COLLECTIBLE_CATEGORY_TYPE_COMPANION,
            unlocked = true,
            active = true,
        })
        mock.setCompanion({ defId = 1 })
        local rec = LibApiCompose.Companion.ComposeActive()
        assertEqual(rec.collectibleId, 77)
        assertEqual(rec.name, "Bastian")
    end)

    it("ComposeActive falls back to GetCompanionName without a collectible", function()
        mock.reset()
        mock.setCompanion({ defId = 5, name = "Ember^F" })
        local rec = LibApiCompose.Companion.ComposeActive()
        assertEqual(rec.collectibleId, nil)
        assertEqual(rec.name, "Ember")
    end)

    it("ComposeActive returns a pending companion only when asked", function()
        mock.reset()
        mock.setPendingCompanion({ defId = 3, name = "Isobel^F" })
        assertFalsy(LibApiCompose.Companion.ComposeActive())
        local rec = LibApiCompose.Companion.ComposeActive({ includePending = true })
        assertEqual(rec.isActive, false)
        assertEqual(rec.isPending, true)
        assertEqual(rec.defId, 3)
        assertEqual(rec.name, "Isobel")
        assertEqual(rec.level, nil)
    end)

    it("ComposeRoster lists unlocked companions", function()
        mock.reset()
        mock.setCollectible(1, { name = "A", category = COLLECTIBLE_CATEGORY_TYPE_COMPANION, unlocked = true })
        mock.setCollectible(2, { name = "B", category = COLLECTIBLE_CATEGORY_TYPE_COMPANION, unlocked = false })
        local roster = LibApiCompose.Companion.ComposeRoster()
        assertEqual(roster.count, 1)
        assertEqual(roster.total, 2)
    end)
end)
