describe("ItemLink.Compose and Gear.ComposeFromLink", function()
    it("Compose returns nil for empty and non-item links", function()
        mock.reset()
        assertFalsy(LibApiCompose.ItemLink.Compose(""))
        assertFalsy(LibApiCompose.ItemLink.Compose(nil))
        assertFalsy(LibApiCompose.ItemLink.Compose("|H0:collectible:5|h|h"))
    end)

    it("Compose reads link facts without a bag slot", function()
        mock.reset()
        mock.setItem(1, 1, {
            id = 321,
            link = "|H0:item:321|h|h",
            name = "Ring of Tests^n",
            type = ITEMTYPE_ARMOR,
            specializedType = 4,
            quality = 4,
            displayQuality = 5,
            sellPrice = 90,
            equipType = 12,
            bindType = 1,
            bound = true,
            crafted = true,
            reqLevel = 50,
            reqCP = 160,
            setPiece = true,
        })
        local rec = LibApiCompose.ItemLink.Compose("|H0:item:321|h|h", { includeName = true })
        assertEqual(rec.id, 321)
        assertEqual(rec.name, "Ring of Tests")
        assertEqual(rec.type, ITEMTYPE_ARMOR)
        assertEqual(rec.specializedType, 4)
        assertEqual(rec.functionalQuality, 4)
        assertEqual(rec.displayQuality, 5)
        assertEqual(rec.sellValue, 90)
        assertEqual(rec.equipType, 12)
        assertEqual(rec.bindType, 1)
        assertEqual(rec.isBound, true)
        assertEqual(rec.isCrafted, true)
        assertEqual(rec.requiredLevel, 50)
        assertEqual(rec.requiredCP, 160)
        assertEqual(rec.isGear, true)
        assertEqual(rec.isSetCollectionPiece, true)
        assertEqual(rec.isSetCollectionUnlocked, false)
        assertEqual(rec.bagId, nil)
        assertEqual(LibApiCompose.ItemLink.Compose("|H0:item:321|h|h").name, nil)
    end)

    it("ParseId extracts the item id without ZOS calls", function()
        assertEqual(LibApiCompose.ItemLink.ParseId("|H1:item:45061:363:50:0|h|h"), 45061)
        assertEqual(LibApiCompose.ItemLink.ParseId("|H0:collectible:5|h|h"), nil)
        assertEqual(LibApiCompose.ItemLink.ParseId(nil), nil)
    end)

    it("Gear.ComposeFromLink matches ComposeFromSlot for link-derived fields", function()
        mock.reset()
        mock.setItem(1, 3, {
            id = 50,
            link = "|H0:item:50|h|h",
            type = ITEMTYPE_WEAPON,
            hasSet = true,
            setName = "Test Set^n",
            setId = 7,
            traitType = ITEM_TRAIT_TYPE_WEAPON_INTRICATE,
            weaponType = 3,
            hasCharges = true,
            charges = 10,
            maxCharges = 20,
            enchantHeader = "Enchant",
        })
        local fromLink = LibApiCompose.Gear.ComposeFromLink("|H0:item:50|h|h")
        local fromSlot = LibApiCompose.Gear.ComposeFromSlot(1, 3)
        assertEqual(fromLink.set.name, "Test Set")
        assertEqual(fromLink.set.id, fromSlot.set.id)
        assertEqual(fromLink.isIntricate, true)
        assertEqual(fromLink.weaponType, 3)
        assertEqual(fromLink.enchant.hasCharges, true)
        assertEqual(fromLink.enchant.charges, nil, "charges need a slot")
        assertEqual(fromLink.canMarkJunk, nil, "junk eligibility needs a slot")
        assertEqual(fromSlot.enchant.charges, 10)
        assertFalsy(LibApiCompose.Gear.ComposeFromLink(""))
    end)
end)
