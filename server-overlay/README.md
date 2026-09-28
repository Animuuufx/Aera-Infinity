# Aera Infinity local-data overlay v0.2.1

This overlay uses the current complete `drathaxie/InfinityServer` `main` line as the protocol/gameplay engine, but **does not use its captured AQW Infinity world/catalog as Aera content**.

With `AERA_LOCAL_DATA_ONLY=1`:

- upstream `seed.run()` is disabled;
- Aera's MySQL database is synced into the runtime DB before startup;
- old seeded runtime world/catalog/account rows are removed before each sync;
- monster, bundle and soundtrack lookups never learn missing content from AE;
- local `.unity3d` files are served from `AERA_GAMEFILES_ROOT`;
- missing local files return 404 instead of silently using the live CDN;
- the initial map defaults to `battleon`.

Normal installation does not require Administrator.

Requirements: Git in the current PowerShell session, Python 3.12+, and access to the existing Aera MySQL/database and gamefiles.

Run:

`powershell -ExecutionPolicy Bypass -File .\INSTALL_AERA_INFINITYSERVER.ps1`

The current Aera client integration is **v2.3.1 LocalDataOnly**.
