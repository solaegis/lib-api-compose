-- LibApiCompose — ItemLink.ComposeOnUse (style C)

local LAC = LibApiCompose
LAC.ItemLink = LAC.ItemLink or {}
local ItemLink = LAC.ItemLink

--- Compose consumable/on-use preview from an item link.
--- Identity: link
--- Fields: icon, abilityId, header, description
function ItemLink.ComposeOnUse(link, _opts)
    if not link or link == "" then
        return nil
    end

    local icon = nil
    if GetItemLinkIcon then
        icon = LAC.SafeCall(GetItemLinkIcon, link)
    end

    local abilityId = nil
    local header = nil
    local description = nil

    if GetItemLinkOnUseAbilityInfo then
        local ok, aId, aHeader, aDesc = LAC.SafeCallMulti(GetItemLinkOnUseAbilityInfo, link)
        if ok then
            abilityId = aId
            header = aHeader
            description = aDesc
        end
    elseif GetItemLinkOnUseAbilityId then
        abilityId = LAC.SafeCall(GetItemLinkOnUseAbilityId, link)
    end

    return {
        link = link,
        icon = icon,
        abilityId = abilityId,
        header = header,
        description = description,
    }
end
