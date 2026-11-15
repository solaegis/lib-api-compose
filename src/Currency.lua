-- LibApiCompose — Currency.Compose / ComposeAll (style C)

local LAC = LibApiCompose
LAC.Currency = LAC.Currency or {}
local Currency = LAC.Currency
local SafeCall = LAC.SafeCall
local NonEmpty = LAC.NonEmpty

-- Currency types known to this build of the library; nil entries (constants missing on the
-- running client) are dropped. Extend via Currency.TYPES if ZOS adds one before LAC does.
local function known(...)
    local list = {}
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            list[#list + 1] = value
        end
    end
    return list
end

Currency.TYPES = known(
    CURT_MONEY,
    CURT_ALLIANCE_POINTS,
    CURT_TELVAR_STONES,
    CURT_WRIT_VOUCHERS,
    CURT_TRANSMUTE_CRYSTALS,
    CURT_UNDAUNTED_KEYS,
    CURT_UNDAUNTED_CRESTS,
    CURT_ARCHIVAL_FORTUNES,
    CURT_IMPERIAL_FRAGMENTS,
    CURT_STYLE_STONES,
    CURT_CROWNS,
    CURT_CROWN_GEMS,
    CURT_SEALS,
    CURT_TRADE_BARS,
    CURT_TOME_POINTS,
    CURT_TOME_POINT_CACHES,
    CURT_TOME_TOKENS,
    CURT_TOME_CHALLENGE_REROLLS
)

local function defaultLocation()
    return CURRENCY_LOCATION_CHARACTER
end

--- Compose one currency at one location → fresh record, or nil for an invalid currency type.
--- Identity: type, location
--- Fields: amount, max, name, icon, canBeStored
--- location defaults to CURRENCY_LOCATION_CHARACTER. Account-wide currencies (crowns, writ
--- vouchers, ...) live at CURRENCY_LOCATION_ACCOUNT — check canBeStored.
function Currency.Compose(currencyType, location)
    if currencyType == nil then
        return nil
    end
    if location == nil then
        location = defaultLocation()
    end
    if SafeCall(IsCurrencyValid, currencyType) ~= true then
        return nil
    end
    return {
        type = currencyType,
        location = location,
        amount = SafeCall(GetCurrencyAmount, currencyType, location) or 0,
        max = SafeCall(GetMaxPossibleCurrency, currencyType, location),
        name = NonEmpty(LAC.FormatName(SafeCall(GetCurrencyName, currencyType, false, false))),
        icon = NonEmpty(SafeCall(GetCurrencyKeyboardIcon, currencyType)),
        canBeStored = SafeCall(CanCurrencyBeStoredInLocation, currencyType, location) == true,
    }
end

--- Every currency that can be stored at a location (default: character).
--- Returns { list = {records}, count = n, total = number of known currency types }.
function Currency.ComposeAll(location)
    if location == nil then
        location = defaultLocation()
    end
    local list = {}
    for i = 1, #Currency.TYPES do
        local rec = Currency.Compose(Currency.TYPES[i], location)
        if rec and rec.canBeStored then
            list[#list + 1] = rec
        end
    end
    return { list = list, count = #list, total = #Currency.TYPES }
end
