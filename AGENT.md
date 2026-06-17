# docs/TECHNICAL_SPECIFICATION.md 
Техническая задачи и полное описание текущего проекта в рамках MVP. 

# docs/MORE_FEATURES.md 
Дополнительные фичи, которые будут реализовывать после MVP. Во время формарования архитектуры их нужно учитывать

# docs/IMPLEMENTING_PLAN.md
- Дерево файлов, схема PlayerData, таблица NetworkBridge
- 3 этапа списком файлов с кратким описанием (без API-деталей)
- 8 правил разработки + ссылка на API_REFERENCE

# docs/API_REFERENCE.md
- Полное API PlayerDataServer, PlayerDataClient, Signal, StatefulObjectController
- Скелет и API UIManager
- Формат GameConfig (RarityEnum, BalloonConfig, константы)
- Сигнатуры RaritySystem, AudioController, NetworkBridge с колонкой "Направление"

# UI
- В игре уже все UI элементы созданы, тебе их не нужно создавать внутри кода
- Все необходимые окна (магазин, index, кнопки взаимодействия с шаром) находится в StarterGui
- Все UI элементы которые будут подгружаться динамически находятся в ReplicatedStorage.UI.Objects

# PlayerDataStore
- В проекте уже реализована система для временного и постоянного сохранения данных
- Предусмотрена система sessionLocker 
- Используй её API для любых сохранений данных игрока
- Реализует loaded, saved и updated ивенты для клиента

# Signal
- Замена BindableEvent
- Для реализации логики Event внутри сервера или клиента

# StatefulObjectController
- Механизм который упрощает работу со сменой состояний несколькоих объектов
- Полезен для реализации Tween для UI объектов

# Дополнительно
- Я не буду использовать Rojo для синхронизации кода с Roblox Studio. Весь код я буду переносить вручную