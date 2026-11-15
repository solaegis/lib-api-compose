-- LibApiCompose — Buff.ComposeAll (style A over a unit tag)

local LAC = LibApiCompose
LAC.Buff = LAC.Buff or {}
local Buff = LAC.Buff

-- GetUnitBuffInfo(unitTag, index) -> buffName, timeStarted, timeEnding, buffSlot, stackCount,
--     iconFilename, deprecatedBuffType, effectType, abilityType, statusEffectType, abilityId,
--     canClickOff, castByPlayer
local function compose(
    unitTag,
    index,
    name,
    timeStarted,
    timeEnding,
    buffSlot,
    stackCount,
    icon,
    _,
    effectType,
    abilityType,
    statusEffectType,
    abilityId,
    canClickOff,
    castByPlayer
)
    return {
        unitTag = unitTag,
        index = index,
        abilityId = abilityId,
        name = LAC.NonEmpty(LAC.FormatName(name)),
        icon = LAC.NonEmpty(icon),
        startTime = timeStarted,
        endTime = timeEnding,
        -- Permanent effects report identical start and end times.
        isPermanent = timeStarted == timeEnding,
        buffSlot = buffSlot,
        stacks = stackCount,
        effectType = effectType,
        abilityType = abilityType,
        statusEffectType = statusEffectType,
        isDebuff = BUFF_EFFECT_TYPE_DEBUFF ~= nil and effectType == BUFF_EFFECT_TYPE_DEBUFF,
        canClickOff = canClickOff == true,
        castByPlayer = castByPlayer == true,
    }
end

--- Every buff/debuff on a unit (default "player") → array of fresh records.
--- Identity: unitTag, index, abilityId
--- Fields: name, icon, startTime (s), endTime (s), isPermanent, buffSlot, stacks, effectType,
---         abilityType, statusEffectType, isDebuff, canClickOff, castByPlayer
--- startTime / endTime are in seconds on the GetFrameTimeSeconds clock.
--- index is only valid until the unit's effects change — do not store it.
function Buff.ComposeAll(unitTag)
    unitTag = unitTag or "player"
    return LAC.Iterate.MapIndex(function()
        return GetNumBuffs(unitTag)
    end, function(index)
        return GetUnitBuffInfo(unitTag, index)
    end, function(index, ...)
        return compose(unitTag, index, ...)
    end, true)
end

--- First buff on a unit with the given abilityId → record, or nil.
function Buff.Find(unitTag, abilityId)
    if abilityId == nil then
        return nil
    end
    unitTag = unitTag or "player"
    local found = nil
    LAC.Iterate.ForIndex(function()
        return GetNumBuffs(unitTag)
    end, function(index)
        return GetUnitBuffInfo(unitTag, index)
    end, function(index, ...)
        if select(11, ...) == abilityId then
            found = compose(unitTag, index, ...)
            return true
        end
        return nil
    end, true)
    return found
end
