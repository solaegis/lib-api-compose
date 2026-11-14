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

    it("ComposeRoster lists unlocked companions", function()
        mock.reset()
        mock.setCollectible(1, { name = "A", category = COLLECTIBLE_CATEGORY_TYPE_COMPANION, unlocked = true })
        mock.setCollectible(2, { name = "B", category = COLLECTIBLE_CATEGORY_TYPE_COMPANION, unlocked = false })
        local roster = LibApiCompose.Companion.ComposeRoster()
        assertEqual(roster.count, 1)
        assertEqual(roster.total, 2)
    end)
end)
