# Monetization System

## Responsibility
- GamePass logic
- DevProduct logic
- runtime cache of pass ownership

## Rules
- GamePasses are checked via MarketplaceService
- pass results cached in memory for the session
- DevProducts handled in `ProcessReceipt`
- monetization cannot bypass server validation

## Notes
- monetization state is not the same as profile state