# Aera Infinity

This repository is **only** for the Aera AQW Infinity private-server project.

It is intentionally separate from the older **Aera AQW/Flash private server** project. Do not copy or merge the old Aera AQW emulator, website, database schema, Flash client, SmartFox code, or AQW-specific content into this repository unless a future migration explicitly requires a small compatibility asset.

## What belongs here

- Aera Infinity server integration/overlay code
- Aera Infinity client integration code and configuration
- Database/content migration tools that target the Infinity server
- Admin/content-authoring tools specifically for Aera Infinity
- Documentation, setup scripts, tests, and deployment configuration for Aera Infinity

## What does not belong here

- The older Aera AQW Flash private server
- SmartFoxServer/AS3 emulator code
- AQW Flash client source
- Unrelated Aera website/game code
- Full third-party upstream source copied wholesale

## Upstream emulator

Aera Infinity currently integrates with:

- Upstream: `drathaxie/InfinityServer`
- Track: latest complete `main` line
- Aera keeps only its own integration/overlay code here instead of vendoring the full upstream project.

The installer/update tooling clones or updates upstream separately, then applies the Aera-specific overlay.

## Client

The target client is the **Aera Unity client**, not a redirected stock AQW Infinity executable.

Current integration line:

- Aera client: `v2.3.0 InfinityServerNative`
- API: `http://217.61.240.140:6678/`
- Game TCP: `217.61.240.140:6677`

The Aera client speaks directly to the InfinityServer-compatible API/socket protocol.

## Repository layout

```text
server-overlay/     Aera-owned patches/scripts applied to upstream InfinityServer
client-integration/ Aera-owned Unity client config/integration helpers
docs/               migration and architecture notes
```

Do not mix this repository with `Animuuufx/Aera`. That repository remains the older Aera project line.
