# Aera LocalDataOnly architecture

`drathaxie/InfinityServer` is used as a protocol/gameplay engine only. Aera does not use upstream captured world/catalog data as authoritative content.

## Authoritative sources

1. **Aera MySQL 5.7 database** — accounts, characters, inventory, items, classes, monsters, NPCs, maps, placements, quests, shops and related state.
2. **Aera gamefiles folder** — local `.unity3d` files under `server/gamefiles/assetbundles/windows`.
3. **Aera Unity client** — connects directly to the Aera API/socket endpoints.

## Startup flow

Before the API or game socket starts, `server/aera_mysql_sync.py` rebuilds InfinityServer's runtime SQLite content from Aera MySQL.

The sync clears old InfinityServer seeded content first. `server.py` also skips `seed.run()` while `AERA_LOCAL_DATA_ONLY=1`, so a restart cannot refill the DB with upstream content.

## No live AQW Infinity fallback

Local mode replaces the client bootstrap/content handlers for base classes, monster data, asset-bundle IDs and soundtracks. Unknown IDs remain missing locally instead of being learned from AE.

The Aera client loads bundles from:

`/gamefiles/assetbundles/windows/<relative filename>`

The route reads only from `AERA_GAMEFILES_ROOT`. Missing files log `MISS` and return HTTP 404.

## Start map

`AERA_START_MAP` defaults to `battleon`, replacing InfinityServer's upstream `infinityportal` first-join assumption.

## Compatibility bridge

InfinityServer currently models one active character per account. Until that is extended, the sync imports the lowest Aera character id for each account and reports additional characters as skipped. It never silently merges them.
