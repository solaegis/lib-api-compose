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
            maxStack = 100,
            name = "Sword^n",
            uniqueId = 123456789,
        })
        local rec = LibApiCompose.BagSlot.Compose(1, 2, { includeName = true })
        assertTruthy(rec)
        assertEqual(rec.bagId, 1)
        assertEqual(rec.slotIndex, 2)
        assertEqual(rec.id, 99)
        assertEqual(rec.link, "|H0:item:99|h|h")
        assertEqual(rec.isGear, true)
        assertEqual(rec.isGlyph, false)
        assertEqual(rec.stack, 2)
        assertEqual(rec.maxStack, 100)
        assertEqual(rec.name, "Sword")
        assertEqual(rec.uniqueId, 123456789)
        assertEqual(rec.uniqueIdString, "123456789")
        local b, s = LibApiCompose.BagSlot.Args(rec)
        assertEqual(b, 1)
        assertEqual(s, 2)
    end)

    it("Compose returns triage fields", function()
        mock.reset()
        mock.setItem(1, 4, {
            id = 7,
            link = "|H0:item:7|h|h",
            type = ITEMTYPE_POTION,
            quality = 2,
            displayQuality = 4,
            sellPrice = 55,
            equipType = 0,
            locked = true,
            junk = true,
            bound = true,
            stolen = true,
            reqLevel = 50,
            reqCP = 160,
        })
        local rec = LibApiCompose.BagSlot.Compose(1, 4)
        assertEqual(rec.functionalQuality, 2)
        assertEqual(rec.displayQuality, 4)
        assertEqual(rec.sellValue, 55)
        assertEqual(rec.isLocked, true)
        assertEqual(rec.isJunk, true)
        assertEqual(rec.isBound, true)
        assertEqual(rec.isStolen, true)
        assertEqual(rec.requiredLevel, 50)
        assertEqual(rec.requiredCP, 160)
        assertEqual(rec.isGear, false)
        assertEqual(rec.name, nil, "name only with includeName")
    end)

    it("Compose returns a fresh table each call", function()
        mock.reset()
        mock.setItem(1, 1, { id = 1, link = "|H0:item:1|h|h", type = ITEMTYPE_WEAPON })
        local a = LibApiCompose.BagSlot.Compose(1, 1)
        local b = LibApiCompose.BagSlot.Compose(1, 1)
        assertTruthy(a ~= b)
    end)

    it("ForBag walks occupied 0-based slots and stops early", function()
        mock.reset()
        mock.setBagSize(BAG_BACKPACK, 4)
        mock.setItem(BAG_BACKPACK, 0, { id = 10, link = "|H0:item:10|h|h" })
        mock.setItem(BAG_BACKPACK, 2, { id = 12, link = "|H0:item:12|h|h" })
        mock.setItem(BAG_BACKPACK, 3, { id = 13, link = "|H0:item:13|h|h" })
        local seen = {}
        local visited = LibApiCompose.BagSlot.ForBag(BAG_BACKPACK, function(rec)
            seen[#seen + 1] = rec.slotIndex
        end)
        assertEqual(visited, 3)
        assertEqual(seen[1], 0)
        assertEqual(seen[2], 2)
        local stopped = LibApiCompose.BagSlot.ForBag(BAG_BACKPACK, function()
            return true
        end)
        assertEqual(stopped, 1)
    end)

    it("MapBag walks the craft bag via GetNextVirtualBagSlotId", function()
        mock.reset()
        mock.setItem(BAG_VIRTUAL, 150000, { id = 150000, link = "|H0:item:150000|h|h", stack = 200 })
        mock.setItem(BAG_VIRTUAL, 30, { id = 30, link = "|H0:item:30|h|h" })
        local ids = LibApiCompose.BagSlot.MapBag(BAG_VIRTUAL, function(rec)
            return rec.id
        end)
        assertEqual(#ids, 2)
        assertEqual(ids[1], 30)
        assertEqual(ids[2], 150000)
    end)

    it("ComposeWorn adds equip slot fields", function()
        mock.reset()
        mock.setBagSize(BAG_WORN, 3)
        mock.setItem(BAG_WORN, 2, { id = 5, link = "|H0:item:5|h|h", type = ITEMTYPE_ARMOR })
        local worn = LibApiCompose.BagSlot.ComposeWorn()
        assertEqual(#worn, 1)
        assertEqual(worn[1].equipSlot, 2)
        assertEqual(worn[1].equipSlotName, "SI_EQUIPSLOT_2")
    end)

    it("Gear.ComposeFromSlot adds set and trait fields", function()
        mock.reset()
        mock.setItem(1, 3, {
            id = 50,
            link = "|H0:item:50|h|h",
            type = ITEMTYPE_ARMOR,
            quality = 3,
            hasSet = true,
            setName = "Test Set^n",
            setId = 7,
            setCount = 2,
            setMax = 5,
            traitType = 5,
            researchable = true,
            hasCharges = true,
            enchantHeader = "Enchant",
            enchantDesc = "Adds stuff",
        })
        local rec = LibApiCompose.Gear.ComposeFromSlot(1, 3)
        assertTruthy(rec)
        assertEqual(rec.hasSet, true)
        assertEqual(rec.set.id, 7)
        assertEqual(rec.set.name, "Test Set")
        assertEqual(rec.set.count, 2)
        assertEqual(rec.set.max, 5)
        assertEqual(rec.traitType, 5)
        assertEqual(rec.trait.name, "SI_ITEMTRAITTYPE_5")
        assertEqual(rec.isResearchable, true)
        assertEqual(rec.canMarkJunk, true)
        assertEqual(rec.enchant.hasEnchant, true)
        assertEqual(rec.enchant.hasCharges, true)
        assertEqual(rec.enchant.name, "Enchant")
        assertEqual(rec.enchant.description, "Adds stuff")
    end)

    it("Gear treats charge-less jewelry enchants as enchanted", function()
        mock.reset()
        mock.setItem(1, 6, {
            id = 60,
            link = "|H0:item:60|h|h",
            type = ITEMTYPE_ARMOR,
            hasCharges = false,
            enchantHeader = "Increase Physical Harm",
        })
        local rec = LibApiCompose.Gear.ComposeFromSlot(1, 6)
        assertEqual(rec.enchant.hasEnchant, true)
        assertEqual(rec.enchant.hasCharges, false)
    end)

    it("Gear canMarkJunk mirrors CanItemBeMarkedAsJunk, isJunk is separate", function()
        mock.reset()
        mock.setItem(1, 7, { id = 70, link = "|H0:item:70|h|h", type = ITEMTYPE_WEAPON, junk = true })
        local rec = LibApiCompose.Gear.ComposeFromSlot(1, 7)
        assertEqual(rec.canMarkJunk, true)
        assertEqual(rec.isJunk, true)
        mock.setItem(1, 8, { id = 80, link = "|H0:item:80|h|h", type = ITEMTYPE_WEAPON, canJunk = false })
        assertEqual(LibApiCompose.Gear.ComposeFromSlot(1, 8).canMarkJunk, false)
    end)

    it("Gear keeps record shape for non-gear without set/trait lookups", function()
        mock.reset()
        mock.setItem(1, 9, { id = 90, link = "|H0:item:90|h|h", type = ITEMTYPE_POTION, hasSet = true, traitType = 5 })
        local rec = LibApiCompose.Gear.ComposeFromSlot(1, 9)
        assertEqual(rec.hasSet, false)
        assertEqual(rec.set.hasSet, false)
        assertEqual(rec.traitType, nil)
        assertEqual(rec.isIntricate, false)
        assertEqual(rec.enchant.hasEnchant, false)
    end)
end)

describe("ItemLink.ComposeOnUse", function()
    it("returns ability metadata from the real return shape", function()
        local rec = LibApiCompose.ItemLink.ComposeOnUse("|H0:item:1|h|h")
        assertTruthy(rec)
        assertEqual(rec.hasAbility, true)
        assertEqual(rec.header, "Header")
        assertEqual(rec.description, "Description")
        assertEqual(rec.cooldown, 45000)
        assertEqual(rec.remainingCooldown, 1000)
        assertEqual(rec.icon, "icon.dds")
        assertEqual(rec.link, "|H0:item:1|h|h")
        assertEqual(rec.abilityId, nil)
    end)

    it("reports hasAbility=false for items without an on-use", function()
        local rec = LibApiCompose.ItemLink.ComposeOnUse("|H0:item:2|h|h")
        assertEqual(rec.hasAbility, false)
    end)

    it("returns nil for empty link", function()
        assertFalsy(LibApiCompose.ItemLink.ComposeOnUse(""))
        assertFalsy(LibApiCompose.ItemLink.ComposeOnUse(nil))
    end)
end)
