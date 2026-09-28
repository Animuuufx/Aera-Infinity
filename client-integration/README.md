# Aera Unity client — LocalDataOnly

Use the **Aera Unity project**, not a redirected stock AQW Infinity executable.

Current integration line: **v2.3.1 LocalDataOnly**.

- API: `http://217.61.240.140:6678/`
- Game TCP: returned by the Aera API; default `217.61.240.140:6677`
- Asset bundles: `http://217.61.240.140:6678/gamefiles/assetbundles/windows/`
- `FlatAssetBundlePaths=true`

A database filename such as `monsters/46637_draconianwater.unity3d` is requested directly from Aera's local gamefile HTTP route. It is no longer configured to load bundles from `infinity.aq.com`.

Missing local files fail locally with HTTP 404; LocalDataOnly mode has no silent AE CDN fallback.
