describe("Hotbar", function()
    it("slot range comes from the action bar constants", function()
        local H = LibApiCompose.Hotbar
        assertEqual(H.FIRST_SLOT, 3)
        assertEqual(H.LAST_SLOT, 7)
        assertEqual(H.ULTIMATE_SLOT, 8)
    end)

    it("ComposeSlot reads abilities and resolves crafted abilities", function()
        mock.reset()
        mock.setSlot(HOTBAR_CATEGORY_PRIMARY, 3, {
            type = ACTION_TYPE_ABILITY,
            id = 28000,
            name = "Wall of Tests^n",
            texture = "wall.dds",
            usable = true,
            cooldownRemaining = 500,
            cooldownDuration = 1000,
        })
        mock.setSlot(HOTBAR_CATEGORY_PRIMARY, 4, { type = ACTION_TYPE_CRAFTED_ABILITY, id = 7 })
        local H = LibApiCompose.Hotbar
        local ability = H.ComposeSlot(3, HOTBAR_CATEGORY_PRIMARY)
        assertEqual(ability.abilityId, 28000)
        assertEqual(ability.craftedAbilityId, nil)
        assertEqual(ability.name, "Wall of Tests")
        assertEqual(ability.icon, "wall.dds")
        assertEqual(ability.usable, true)
        assertEqual(ability.cooldownRemaining, 500)
        assertEqual(ability.isUltimate, false)
        local crafted = H.ComposeSlot(4, HOTBAR_CATEGORY_PRIMARY)
        assertEqual(crafted.craftedAbilityId, 7)
        assertEqual(crafted.abilityId, 100007)
        assertFalsy(H.ComposeSlot(nil))
    end)

    it("ComposeBar walks slots 3..8 of the active bar by default", function()
        mock.reset()
        mock.setActiveHotbar(HOTBAR_CATEGORY_BACKUP)
        mock.setSlot(HOTBAR_CATEGORY_BACKUP, 8, { type = ACTION_TYPE_ABILITY, id = 9 })
        mock.setSlot(HOTBAR_CATEGORY_BACKUP, 1, { type = ACTION_TYPE_ABILITY, id = 1 })
        local bar = LibApiCompose.Hotbar.ComposeBar()
        assertEqual(bar.total, 6)
        assertEqual(bar.count, 1)
        assertEqual(bar.list[1].slotIndex, 3)
        assertEqual(bar.list[6].isUltimate, true)
        assertEqual(bar.list[6].hotbarCategory, HOTBAR_CATEGORY_BACKUP)
        assertEqual(bar.list[1].isEmpty, true)
    end)
end)
