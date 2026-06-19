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
GamePasses = runtime cache, не обязательно сохранять