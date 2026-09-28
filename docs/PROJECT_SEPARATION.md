# Project separation

Animuuufx/Aera-Infinity is the source-of-truth repository for the AQW Infinity private-server project.

Do not merge it with Animuuufx/Aera, which is the older Aera AQW/Flash project.

## Aera-Infinity

Use for:

- Unity Aera Infinity client integration
- InfinityServer overlay/integration
- Aera Infinity database/content migration
- Aera Infinity admin/content-authoring tooling
- Aera Infinity deployment/setup

## Older Aera repository

Keep there:

- Flash/AS3 client work
- SmartFoxServer emulator work
- AQW Flash-specific database/admin/site code
- old Aera/AQW private-server artifacts

When a feature exists in both projects, implement it separately against each project's native architecture rather than copying an entire subsystem between them.
