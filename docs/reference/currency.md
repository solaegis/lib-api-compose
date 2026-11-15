# Currency

`src/Currency.lua` — currency amounts by type and location. Enrichment style C.

## Functions

### `Currency.Compose`

```text
Currency.Compose(currencyType, location?) -> rec | nil
```

| Parameter | Type | Description |
|---|---|---|
| `currencyType` | `CurrencyType` | `CURT_MONEY`, `CURT_ALLIANCE_POINTS`, `CURT_TELVAR_STONES`, … |
| `location` | `CurrencyLocation?` | `CURRENCY_LOCATION_CHARACTER` (default), `_BANK`, `_ACCOUNT`, `_GUILD_BANK`. |

**Returns:** a [record](#record), or `nil` when `currencyType` is `nil` or invalid (`IsCurrencyValid`).

Each currency lives in particular locations: gold on the character and in the bank, crowns and writ vouchers on
the account. Asking for a location that can't hold it returns a record with `amount = 0` and
`canBeStored = false`.

```lua
local LAC = LibApiCompose
local gold = LAC.Currency.Compose(CURT_MONEY)
local banked = LAC.Currency.Compose(CURT_MONEY, CURRENCY_LOCATION_BANK)
d((gold and gold.amount or 0) + (banked and banked.amount or 0))
```

*Since 1.0.0.*

### `Currency.ComposeAll`

```text
Currency.ComposeAll(location?) -> { list, count, total }
```

Records for every currency in `Currency.TYPES` that can be stored at `location` (default: character).

| Key | Type | Meaning |
|---|---|---|
| `list` | `table` | records, in `Currency.TYPES` order |
| `count` | `integer` | `#list` |
| `total` | `integer` | `#Currency.TYPES` |

*Since 1.0.0.*

## Record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `type` | `CurrencyType` | argument | identity |
| `location` | `CurrencyLocation` | argument | identity |
| `amount` | `integer` | `GetCurrencyAmount` | `0` when unreadable |
| `max` | `integer?` | `GetMaxPossibleCurrency` | |
| `name` | `string?` | `GetCurrencyName(type, false, false)` + `FormatName` | plural, capitalised |
| `icon` | `string?` | `GetCurrencyKeyboardIcon` | |
| `canBeStored` | `boolean` | `CanCurrencyBeStoredInLocation` | |

## Constants

| Name | Value | Meaning |
|---|---|---|
| `Currency.TYPES` | array of `CURT_*` | Currency types the library knows, limited to those defined on the running client. Append to it if ZOS adds a currency before LAC does. |
