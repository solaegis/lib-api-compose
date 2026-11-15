-- LibApiCompose — Unit.Compose (style F: unit tag)

local LAC = LibApiCompose
LAC.Unit = LAC.Unit or {}
local Unit = LAC.Unit
local SafeCall = LAC.SafeCall
local NonEmpty = LAC.NonEmpty

local function power(unitTag, powerType)
    if powerType == nil then
        return nil
    end
    local ok, current, max, effectiveMax = LAC.SafeCallMulti(GetUnitPower, unitTag, powerType)
    if not ok then
        return nil
    end
    return { current = current, max = max, effectiveMax = effectiveMax }
end

--- Compose a unit tag ("player", "reticleover", "group1", "companion", ...) → fresh record,
--- or nil when the unit does not exist. unitTag defaults to "player".
--- Identity: unitTag
--- Fields: name, displayName, level, championPoints, effectiveChampionPoints, classId, className,
---         raceId, raceName, alliance, allianceName, gender, zoneName, isPlayer, isDead,
---         isInCombat, isOnline, health/magicka/stamina = { current, max, effectiveMax }
--- opts.skipPower — leave out the three power pools (cheaper for name-plate style reads).
function Unit.Compose(unitTag, opts)
    opts = opts or {}
    unitTag = unitTag or "player"
    if type(unitTag) ~= "string" or SafeCall(DoesUnitExist, unitTag) ~= true then
        return nil
    end

    local health, magicka, stamina = nil, nil, nil
    if not opts.skipPower then
        health = power(unitTag, COMBAT_MECHANIC_FLAGS_HEALTH)
        magicka = power(unitTag, COMBAT_MECHANIC_FLAGS_MAGICKA)
        stamina = power(unitTag, COMBAT_MECHANIC_FLAGS_STAMINA)
    end

    local alliance = SafeCall(GetUnitAlliance, unitTag)

    return {
        unitTag = unitTag,
        name = NonEmpty(LAC.FormatName(SafeCall(GetUnitName, unitTag))),
        displayName = NonEmpty(SafeCall(GetUnitDisplayName, unitTag)),
        level = SafeCall(GetUnitLevel, unitTag),
        championPoints = SafeCall(GetUnitChampionPoints, unitTag),
        effectiveChampionPoints = SafeCall(GetUnitEffectiveChampionPoints, unitTag),
        classId = SafeCall(GetUnitClassId, unitTag),
        className = NonEmpty(LAC.FormatName(SafeCall(GetUnitClass, unitTag))),
        raceId = SafeCall(GetUnitRaceId, unitTag),
        raceName = NonEmpty(LAC.FormatName(SafeCall(GetUnitRace, unitTag))),
        alliance = alliance,
        allianceName = alliance and NonEmpty(LAC.FormatName(SafeCall(GetAllianceName, alliance))) or nil,
        gender = SafeCall(GetUnitGender, unitTag),
        zoneName = NonEmpty(LAC.FormatName(SafeCall(GetUnitZone, unitTag))),
        isPlayer = SafeCall(IsUnitPlayer, unitTag) == true,
        isDead = SafeCall(IsUnitDead, unitTag) == true,
        isInCombat = SafeCall(IsUnitInCombat, unitTag) == true,
        isOnline = SafeCall(IsUnitOnline, unitTag) == true,
        health = health,
        magicka = magicka,
        stamina = stamina,
    }
end
