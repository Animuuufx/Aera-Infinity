# Aera Unity client integration

This project uses the Aera Unity client directly against the InfinityServer-compatible API/socket protocol.

It does not require the stock AQW Infinity executable, Doorstop, or InfinityLoader redirection.

Current endpoints:

- API: http://217.61.240.140:6678/
- Game socket: returned by the API as 217.61.240.140:6677
- Versioned asset bundles: https://infinity.aq.com/game/assetbundles/windows/

Only Aera-owned configuration/integration code is stored here. The full Unity project and third-party/decompiled game sources are intentionally not copied into this public repository.

Current Aera client integration line: v2.3.0 InfinityServerNative.
