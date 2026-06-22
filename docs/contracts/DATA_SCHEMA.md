# Data Schema

## Rules
- Любое breaking change требует обновления schema version
- Все server-critical данные живут в ProfileStore
- Клиент не является источником истины
- `MonetizationEntitlements` — persisted last-known cache, не source of truth
- GamePass ownership: MarketplaceService — source of truth, MonetizationEntitlements.GamePasses — fallback при ошибке Marketplace
- DevProduct ServerLuck не сохраняется в профиле (runtime-only)
- Timed-бусты фильтруются на load: просроченные удаляются

## ProfileTemplate
{
    Coins = 0,
    Balloons = { Default = 1 },
    ActiveBalloon = "Default",

    StandPets = {},
    Index = {},

    BaseLevel = 1,
    BaseSlots = 10,

    RebirthCount = 0,
    BaseLuck = 1,

    LuckBonuses = {
        temporary = {},
        permanent = 0,
    },

    TutorialStep = 0,

    Stickers = {},

    MonetizationEntitlements = {
        GamePasses = {
            SkipRollAnimation = false,
            WithoutBombs      = false,
            RebirthMoney      = false,
            StarterPack       = false,
        },

        Claims = {
            StarterPack = false,
        },

        Timed = {},
    },
}

## Notes
 StandPets = единственный список питомцев игрока, включая авто-посаженных и переставляемых
 Index = список уникальных имён питомцев, которых игрок хотя бы раз получал
 Default Balloon = стартовый шар игрока и уже присутствует в инвентаре
 Balloon inventory хранится как словарь `{[balloonName]: count}`
 Coins, Balloons, ActiveBalloon, StandPets, Index, BaseLevel, BaseSlots, RebirthCount, BaseLuck, LuckBonuses, TutorialStep, Stickers, MonetizationEntitlements реплицируются через Replica
 MonetizationEntitlements.GamePasses — last-known cache ownership GamePass. Записывается при успешном UserOwnsGamePassAsync (true/false). При ошибке не трогается.
 MonetizationEntitlements.Claims — одноразовые claim-флаги (StarterPack). Обеспечивают idempotency.
 MonetizationEntitlements.Timed — временные бусты, переживающие rejoin. Каждый элемент: { id: string, startsAt: number, expiresAt: number }. Просроченные удаляются при загрузке.
 ServerLuck (DevProduct) не сохраняется в профиле — runtime-only, живёт в LuckService.
 Stickers = список имён стикеров, полученных через DevProduct. Управляется только через ProcessReceipt.
