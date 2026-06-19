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
2. Server starts timer
3. Server computes outcome on `Balloon_Stop`
4. Server updates Coins through Replica
5. Server sends `Balloon_Result`
6. Client switches phase and shows VFX/UI

## Notes
- Camera transitions are client-side only
- Server remains authoritative for reward and outcome