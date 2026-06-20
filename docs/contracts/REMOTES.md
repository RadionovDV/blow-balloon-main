# Remote Contracts

> Все remotes создаются и изменяются только по этому документу.

## Rules
- RemoteEvent — one-shot события
- RemoteFunction — только синхронные запросы с ответом
- Replica — только для постоянного состояния

## Registry

### Balloon_Start
- Type: RemoteEvent
- Direction: Client → Server
- Purpose: игрок начал надувать шар
- Payload: none

### Balloon_Stop
- Type: RemoteEvent
- Direction: Client → Server
- Purpose: игрок отпустил шар
- Payload: none

### Balloon_Equip
- Type: RemoteEvent
- Direction: Client → Server
- Purpose: выбрать шар из списка
- Payload: { balloonName: string }

### Balloon_Result
- Type: RemoteEvent
- Direction: Server → Client
- Purpose: результат цикла шара
- Payload: { type: string, petData: table?, reward: number? }

###  Pet_PlaceStand
- Type: RemoteEvent
- Direction: Client → Server
- Purpose: поставить питомца на стенд
- Payload: { slotIndex: number, uid: string }

###  Pet_RemoveStand
- Type: RemoteEvent
- Direction: Client → Server
- Purpose: убрать питомца со стенда
- Payload: { slotIndex: number }

###  Shop_BuyBalloon
- Type: RemoteFunction
- Direction: Client → Server
- Purpose: купить шар
- Payload: { balloonName: string }
- Return: `true/false`

###  Base_Collect
- Type: RemoteFunction
- Direction: Client → Server
- Purpose: собрать доход со слота
- Payload: { slotIndex: number }

###  Base_Assigned
- Type: RemoteEvent
- Direction: Server → Client
- Purpose: назначена база игроку
- Payload: { baseId: number }

###  Tutorial_Step
- Type: RemoteEvent
- Direction: Server → Client
- Purpose: переключение шага туториала
- Payload: { step: number }

###  Notification
- Type: RemoteEvent
- Direction: Server → Client
- Purpose: показать нотификацию
- Payload: { text: string, style: string? }
