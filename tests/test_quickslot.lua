describe("Quickslot", function()
    it("Compose marks empty slots", function()
        mock.reset()
        local rec = LibApiCompose.Quickslot.Compose(1)
        assertTruthy(rec)
        assertEqual(rec.isEmpty, true)
        assertEqual(rec.hotbarCategory, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
        assertEqual(rec.usable, false)
    end)

    it("Compose returns nil without a slot index", function()
        assertFalsy(LibApiCompose.Quickslot.Compose(nil))
    end)

    it("Compose reads item slots", function()
        mock.reset()
        mock.setSlot(HOTBAR_CATEGORY_QUICKSLOT_WHEEL, 2, {
            type = ACTION_TYPE_ITEM,
            id = 44,
            name = "Potion^n",
            texture = "potion.dds",
            count = 12,
            usable = true,
        })
        local rec = LibApiCompose.Quickslot.Compose(2)
        assertEqual(rec.isEmpty, false)
        assertEqual(rec.actionType, ACTION_TYPE_ITEM)
        assertEqual(rec.actionId, 44)
        assertEqual(rec.name, "Potion")
        assertEqual(rec.icon, "potion.dds")
        assertEqual(rec.count, 12)
        assertEqual(rec.usable, true)
        assertEqual(rec.isCurrent, false)
        local s, h = LibApiCompose.Quickslot.Args(rec)
        assertEqual(s, 2)
        assertEqual(h, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
        local t, id = LibApiCompose.Quickslot.ActionArgs(rec)
        assertEqual(t, ACTION_TYPE_ITEM)
        assertEqual(id, 44)
    end)

    it("Compose falls back to collectible name/icon", function()
        mock.reset()
        mock.setCollectible(500, { name = "Assistant^F", icon = "asst.dds", category = 8 })
        mock.setSlot(HOTBAR_CATEGORY_QUICKSLOT_WHEEL, 3, { type = ACTION_TYPE_COLLECTIBLE, id = 500 })
        local rec = LibApiCompose.Quickslot.Compose(3)
        assertEqual(rec.name, "Assistant")
        assertEqual(rec.icon, "asst.dds")
        assertEqual(rec.collectibleCategory, 8)
    end)

    it("ComposeWheel returns every slot with a non-empty count", function()
        mock.reset()
        mock.setSlot(HOTBAR_CATEGORY_QUICKSLOT_WHEEL, 1, { type = ACTION_TYPE_ITEM, id = 1 })
        mock.setSlot(HOTBAR_CATEGORY_QUICKSLOT_WHEEL, 8, { type = ACTION_TYPE_ITEM, id = 8 })
        local wheel = LibApiCompose.Quickslot.ComposeWheel()
        assertEqual(wheel.total, 8)
        assertEqual(#wheel.list, 8)
        assertEqual(wheel.count, 2)
        assertEqual(wheel.list[8].actionId, 8)
        assertEqual(wheel.list[4].isEmpty, true)
    end)

    it("Compose reads cooldown, item link and the current slot", function()
        mock.reset()
        mock.setSlot(HOTBAR_CATEGORY_QUICKSLOT_WHEEL, 5, {
            type = ACTION_TYPE_ITEM,
            id = 44,
            cooldownRemaining = 2000,
            cooldownDuration = 45000,
            itemLink = "|H0:item:44|h|h",
        })
        mock.setCurrentQuickslot(5)
        local rec = LibApiCompose.Quickslot.Compose(5)
        assertEqual(rec.cooldownRemaining, 2000)
        assertEqual(rec.cooldownDuration, 45000)
        assertEqual(rec.itemLink, "|H0:item:44|h|h")
        assertEqual(rec.isCurrent, true)
        assertEqual(rec.name, nil, "empty slot name becomes nil")
    end)

    it("ComposeWheel serves the other wheels and rejects skill bars", function()
        mock.reset()
        mock.setSlot(HOTBAR_CATEGORY_EMOTE_WHEEL, 2, { type = ACTION_TYPE_ITEM, id = 3 })
        local Q = LibApiCompose.Quickslot
        local emotes = Q.ComposeWheel(LibApiCompose.HOTBAR.CATEGORY_EMOTE_WHEEL)
        assertEqual(emotes.total, 8)
        assertEqual(emotes.count, 1)
        assertEqual(emotes.list[2].isCurrent, false)
        local bar = Q.ComposeWheel(HOTBAR_CATEGORY_PRIMARY)
        assertEqual(bar.total, 0)
        assertEqual(#bar.list, 0)
        assertEqual(Q.IsWheel(HOTBAR_CATEGORY_TOOL_WHEEL), true)
        assertEqual(Q.IsWheel(HOTBAR_CATEGORY_BACKUP), false)
        assertEqual(Q.IsWheel(nil), false)
    end)
end)
