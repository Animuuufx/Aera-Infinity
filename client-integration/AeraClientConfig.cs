using System;
using System.IO;
using UnityEngine;

[Serializable]
public class AeraClientConfigData
{
    public bool UsePrivateServer = true;
    public string ApiBaseUrl = "http://217.61.240.140:6678/";
    public string AssetBundleBaseUrl = "https://infinity.aq.com/game/assetbundles/windows/";
    public bool FlatAssetBundlePaths = false;
    public bool EnforceClientVersion = false;
    public bool StartFullscreen = true;
}

public static class AeraClientConfig
{
    private const string FileName = "aera-client.json";
    private static bool loaded;
    private static AeraClientConfigData data = new AeraClientConfigData();

    public static bool UsePrivateServer { get { EnsureLoaded(); return data.UsePrivateServer; } }
    public static bool FlatAssetBundlePaths { get { EnsureLoaded(); return data.FlatAssetBundlePaths; } }
    public static bool EnforceClientVersion { get { EnsureLoaded(); return data.EnforceClientVersion; } }
    public static bool StartFullscreen { get { EnsureLoaded(); return data.StartFullscreen; } }
    public static string ApiBaseUrl { get { EnsureLoaded(); return NormalizeBaseUrl(data.ApiBaseUrl); } }
    public static string AssetBundleBaseUrl { get { EnsureLoaded(); return NormalizeBaseUrl(data.AssetBundleBaseUrl); } }

    public static void Load()
    {
        if (loaded) return;
        loaded = true;

        string path = Path.Combine(Application.streamingAssetsPath, FileName);
        try
        {
            if (File.Exists(path))
            {
                var parsed = JsonUtility.FromJson<AeraClientConfigData>(File.ReadAllText(path));
                if (parsed != null) data = parsed;
            }
        }
        catch (Exception ex)
        {
            Debug.LogWarning("Aera client config could not be read: " + ex.Message);
        }

        if (UsePrivateServer)
            Debug.Log("Aera Infinity API: " + ApiBaseUrl);
    }

    private static void EnsureLoaded()
    {
        if (!loaded) Load();
    }

    private static string NormalizeBaseUrl(string value)
    {
        if (string.IsNullOrWhiteSpace(value)) return string.Empty;
        value = value.Trim().Replace('\\', '/');
        return value.EndsWith("/", StringComparison.Ordinal) ? value : value + "/";
    }
}
