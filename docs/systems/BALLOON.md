# Balloon System

## Responsibility
- Inflate loop
- Burst logic
- Reward calculation
- Transition to roulette
- Client phase machine

## Server Side
### BalloonService
- validates inflate start/stop
- checks balloon ownership before inflate start
- consumes one balloon from inventory on `Balloon_Start`
- tracks server timer
- calculates reward
- decides burst / roulette / coin-only result

## Client Side
### BalloonController
Phases:
- Idle
- Near
- Inflating
- Viewing
- Ready
- Roulette

## Main Flow
1. Client sends `Balloon_Start`
2. Server validates ownership and consumes one balloon from inventory
3. Server starts timer
4. Server computes outcome on `Balloon_Stop`
5. Server updates Coins through Replica
6. Server sends `Balloon_Result`
7. Client switches phase and shows VFX/UI

## Notes
- Camera transitions are client-side only
- Server remains authoritative for reward and outcome
