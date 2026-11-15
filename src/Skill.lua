-- LibApiCompose — Skill lines and abilities (styles B, G)
--
-- Indices are the ZOS skill indices: skillType (SKILL_TYPE_*), lineIndex, abilityIndex (1-based).
-- Nothing here is cached: rank, purchase and morph state change during play.

local LAC = LibApiCompose
LAC.Skill = LAC.Skill or {}
local Skill = LAC.Skill
local SafeCall = LAC.SafeCall
local NonEmpty = LAC.NonEmpty

--- Compose a skill line → fresh record, or nil when the line does not exist.
--- Identity: skillType, lineIndex, id
--- Fields: name, rank, isActive, isDiscovered, isAdvised, xp = { last, next, current }
function Skill.ComposeLine(skillType, lineIndex)
    if skillType == nil or lineIndex == nil then
        return nil
    end
    local lineId = SafeCall(GetSkillLineId, skillType, lineIndex)
    if not lineId or lineId <= 0 then
        return nil
    end

    local ok, rank, isAdvised, isActive, isDiscovered = LAC.SafeCallMulti(GetSkillLineDynamicInfo, skillType, lineIndex)
    if not ok then
        rank, isAdvised, isActive, isDiscovered = nil, nil, nil, nil
    end
    local xp = nil
    local xpOk, lastRankXP, nextRankXP, currentXP = LAC.SafeCallMulti(GetSkillLineXPInfo, skillType, lineIndex)
    if xpOk then
        xp = { last = lastRankXP, next = nextRankXP, current = currentXP }
    end

    return {
        skillType = skillType,
        lineIndex = lineIndex,
        id = lineId,
        name = NonEmpty(LAC.FormatName(SafeCall(GetSkillLineNameById, lineId))),
        rank = rank,
        isActive = isActive == true,
        isDiscovered = isDiscovered == true,
        isAdvised = isAdvised == true,
        xp = xp,
    }
end

--- Compose one ability of a skill line → fresh record, or nil when it does not exist.
--- Identity: skillType, lineIndex, abilityIndex, abilityId
--- Fields: name, icon, earnedRank, rank, isPassive, isUltimate, isPurchased, progressionIndex,
---         isCrafted, craftedAbilityId, upgradeLevel, maxUpgradeLevel
--- abilityId is the currently chosen morph / passive rank. upgradeLevel fields are for passives.
function Skill.ComposeAbility(skillType, lineIndex, abilityIndex)
    if skillType == nil or lineIndex == nil or abilityIndex == nil then
        return nil
    end
    -- GetSkillAbilityInfo -> name, texture, earnedRank, passive, ultimate, purchased,
    --                        progressionIndex, rank
    local ok, name, texture, earnedRank, passive, ultimate, purchased, progressionIndex, rank =
        LAC.SafeCallMulti(GetSkillAbilityInfo, skillType, lineIndex, abilityIndex)
    name = ok and NonEmpty(LAC.FormatName(name)) or nil
    if not name then
        return nil
    end

    local isCrafted = SafeCall(IsCraftedAbilitySkill, skillType, lineIndex, abilityIndex) == true
    local craftedAbilityId = nil
    if isCrafted then
        craftedAbilityId = SafeCall(GetCraftedAbilitySkillCraftedAbilityId, skillType, lineIndex, abilityIndex)
    end
    local upgradeLevel, maxUpgradeLevel = nil, nil
    if passive then
        local upOk, current, max = LAC.SafeCallMulti(GetSkillAbilityUpgradeInfo, skillType, lineIndex, abilityIndex)
        if upOk then
            upgradeLevel, maxUpgradeLevel = current, max
        end
    end

    return {
        skillType = skillType,
        lineIndex = lineIndex,
        abilityIndex = abilityIndex,
        abilityId = SafeCall(GetSkillAbilityId, skillType, lineIndex, abilityIndex, false),
        name = name,
        icon = NonEmpty(texture),
        earnedRank = earnedRank,
        rank = rank,
        isPassive = passive == true,
        isUltimate = ultimate == true,
        isPurchased = purchased == true,
        progressionIndex = progressionIndex,
        isCrafted = isCrafted,
        craftedAbilityId = craftedAbilityId,
        upgradeLevel = upgradeLevel,
        maxUpgradeLevel = maxUpgradeLevel,
    }
end

--- Every skill line, or only those of one skillType. Returns an array of line records.
function Skill.ComposeLines(skillType)
    if skillType ~= nil then
        return LAC.Iterate.MapIndex(
            function()
                return GetNumSkillLines(skillType)
            end,
            nil,
            function(lineIndex)
                return Skill.ComposeLine(skillType, lineIndex)
            end
        )
    end
    return LAC.Iterate.NestedMap({
        { getNum = GetNumSkillTypes },
        { getNum = GetNumSkillLines },
    }, Skill.ComposeLine)
end

--- Every ability of one skill line. Returns an array of ability records.
function Skill.ComposeAbilities(skillType, lineIndex)
    if skillType == nil or lineIndex == nil then
        return {}
    end
    return LAC.Iterate.MapIndex(
        function()
            return GetNumSkillAbilities(skillType, lineIndex)
        end,
        nil,
        function(abilityIndex)
            return Skill.ComposeAbility(skillType, lineIndex, abilityIndex)
        end
    )
end

--- Walk every ability of every line: fn(abilityRec). Return true to stop.
--- This is a few thousand ZOS calls — run it on demand, not per frame.
function Skill.ForEachAbility(fn)
    if not fn then
        return
    end
    LAC.Iterate.NestedFor({
        { getNum = GetNumSkillTypes },
        { getNum = GetNumSkillLines },
        { getNum = GetNumSkillAbilities },
    }, function(skillType, lineIndex, abilityIndex)
        local rec = Skill.ComposeAbility(skillType, lineIndex, abilityIndex)
        if rec then
            return fn(rec)
        end
        return nil
    end)
end
