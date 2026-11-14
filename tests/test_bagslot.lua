describe("BagSlot and Gear", function()
    it("Compose returns nil for empty slot", function()
        mock.reset()
        local rec = LibApiCompose.BagSlot.Compose(1, 1)
        assertFalsy(rec)
    end)

    it("Compose returns identity fields", function()
        mock.reset()
        mock.setItem(1, 2, {
            id = 99,
            link = "|H0:item:99|h|h",
            type = ITEMTYPE_WEAPON,
            quality = 3,
            stack = 2,
            name = "Sword",
        })
        local rec = LibApiCompose.BagSlot.Compose(1, 2, { includeName = true })
        assertTruthy(rec)
        assertEqual(rec.bagId, 1)
        assertEqual(rec.slotIndex, 2)
        assertEqual(rec.id, 99)
        assertEqual(rec.link, "|H0:item:99|h|h")
        assertEqual(rec.isGear, true)
        assertEqual(rec.stack, 2)
        assertEqual(rec.name, "Sword")
        local b, s = LibApiCompose.BagSlot.Args(rec)
        assertEqual(b, 1)
        assertEqual(s, 2)
    end)

    it("Gear.ComposeFromSlot adds set and trait fields", function()
        mock.reset()
        mock.setItem(1, 3, {
            id = 50,
            link = "|H0:item:50|h|h",
            type = ITEMTYPE_ARMOR,
            quality = 3,
            hasSet = true,
            setName = "Test Set",
            setId = 7,
            setCount = 2,
            setMax = 5,
            traitType = 5,
            researchable = false,
            hasEnchant = true,
            enchantHeader = "Enchant",
        })
        local rec = LibApiCompose.Gear.ComposeFromSlot(1, 3)
        assertTruthy(rec)
        assertEqual(rec.hasSet, true)
        assertEqual(rec.set.id, 7)
        assertEqual(rec.traitType, 5)
        assertEqual(rec.canMarkJunk, true)
        assertEqual(rec.enchant.hasEnchant, true)
    end)
end)

describe("ItemLink.ComposeOnUse", function()
    it("returns ability metadata", function()
        local rec = LibApiCompose.ItemLink.ComposeOnUse("|H0:item:1|h|h")
        assertTruthy(rec)
        assertEqual(rec.abilityId, 12345)
        assertEqual(rec.header, "Header")
        assertEqual(rec.link, "|H0:item:1|h|h")
    end)

    it("returns nil for empty link", function()
        assertFalsy(LibApiCompose.ItemLink.ComposeOnUse(""))
        assertFalsy(LibApiCompose.ItemLink.ComposeOnUse(nil))
    end)
end)
