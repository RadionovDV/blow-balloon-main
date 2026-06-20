# Data Schema

## Rules
- Любое breaking change требует обновления schema version
- Все server-critical данные живут в ProfileStore
- Клиент не является источником истины

## ProfileTemplate
{
    Coins = 0,
    Balloons = { Default = 1 },
    ActiveBalloon = "Default",

    Pets = {},
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

    GamePasses = {},
}

## Notes
 Pets = список/массив питомцев игрока
 StandPets = питомцы, размещённые на стойках
 Index = список уникальных имён питомцев, которых игрок хотя бы раз получал
 Default Balloon = стартовый шар игрока и уже присутствует в инвентаре
 Balloon inventory хранится как словарь `{[balloonName]: count}`
 GamePasses = runtime cache, не обязательно сохранять
 Coins, Balloons, ActiveBalloon, Pets, StandPets, Index, BaseLevel, BaseSlots, RebirthCount, BaseLuck, LuckBonuses, TutorialStep реплицируются через Replica
