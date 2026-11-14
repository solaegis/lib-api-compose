-- LibApiCompose — ItemLink.ComposeOnUse (style C)

local LAC = LibApiCompose
LAC.ItemLink = LAC.ItemLink or {}
local ItemLink = LAC.ItemLink

--- Compose consumable/on-use preview from an item link → fresh record, or nil for empty link.
--- Identity: link
--- Fields: icon, hasAbility, header, description, cooldown (ms), remainingCooldown (ms)
--- Mirrors GetItemLinkOnUseAbilityInfo:
---   hasAbility, header, description, cooldown, hasScaling, minLevel, maxLevel, isCP, remainingCooldown
function ItemLink.ComposeOnUse(link, _opts)
    if type(link) ~= "string" or link == "" then
        return nil
    end

    local hasAbility, header, description, cooldown, remaining = false, nil, nil, nil, nil
    local ok, aHas, aHeader, aDesc, aCooldown, _, _, _, _, aRemaining =
        LAC.SafeCallMulti(GetItemLinkOnUseAbilityInfo, link)
    if ok then
        hasAbility = aHas == true
        header = aHeader
        description = aDesc
        cooldown = aCooldown
        remaining = aRemaining
    end

    return {
        link = link,
        icon = LAC.SafeCall(GetItemLinkIcon, link),
        hasAbility = hasAbility,
        header = header,
        description = description,
        cooldown = cooldown,
        remainingCooldown = remaining,
    }
end
