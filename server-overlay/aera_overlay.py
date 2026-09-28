#!/usr/bin/env python3
"""Apply the Aera Infinity compatibility layer to an upstream InfinityServer checkout.

Aera local-data-only mode deliberately disables upstream seed/world content and routes the
client to Aera's own MySQL-synced SQLite catalog plus locally served .unity3d files.
"""
from pathlib import Path
import sys

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
server_py = ROOT / "server" / "server.py"
webapi_py = ROOT / "server" / "webapi.py"
world_cmds_py = ROOT / "server" / "handlers" / "world_cmds.py"
context_py = ROOT / "server" / "handlers" / "context.py"

if not server_py.exists() or not webapi_py.exists() or not world_cmds_py.exists() or not context_py.exists():
    raise SystemExit("ERROR: point this script at an InfinityServer checkout root.")


def replace_once(text, old, new, label):
    if new in text:
        return text
    if old not in text:
        raise SystemExit(
            f"ERROR: upstream layout changed; could not patch {label}. "
            "Update the Aera overlay against the current InfinityServer main branch."
        )
    return text.replace(old, new, 1)


# ---------------- game socket ----------------
s = server_py.read_text(encoding="utf-8")
if "import os\n" not in s:
    s = replace_once(s, "import json\nimport sys\n", "import json\nimport os\nimport sys\n", "server import os")
s = replace_once(
    s,
    'HOST = "0.0.0.0"\nPORT = 5588  # must match docs/RedirectPatch.cs',
    'HOST = os.environ.get("INFINITY_GAME_HOST", "0.0.0.0")\nPORT = int(os.environ.get("INFINITY_GAME_PORT", "6677"))',
    "game host/port",
)
s = replace_once(
    s,
    "    db.init()\n    seed.run()\n",
    "    db.init()\n"
    "    if os.environ.get(\"AERA_LOCAL_DATA_ONLY\", \"1\").strip().lower() in (\"1\", \"true\", \"yes\", \"on\"):\n"
    "        print(\"[AERA] Local-data-only mode: upstream InfinityServer seed content is disabled.\")\n"
    "    else:\n"
    "        seed.run()\n",
    "disable upstream seed",
)
s = s.replace(
    'print(f"InfinityServer listening on {addrs}  ({store})")',
    'print(f"Aera Infinity listening on {addrs}  ({store})")',
)
server_py.write_text(s, encoding="utf-8")


# ---------------- HTTP API ----------------
s = webapi_py.read_text(encoding="utf-8")
s = replace_once(
    s,
    'HOST = "0.0.0.0"\nPORT = 8182                                   # mod ApiPatch rewrites WebApiURL -> here',
    'HOST = os.environ.get("INFINITY_API_HOST", "0.0.0.0")\nPORT = int(os.environ.get("INFINITY_API_PORT", "6678"))',
    "api host/port",
)

config_marker = 'UPSTREAM = "https://infinity.aq.com/game/api/"\n'
config_block = (
    'UPSTREAM = "https://infinity.aq.com/game/api/"\n'
    'AERA_LOCAL_DATA_ONLY = os.environ.get("AERA_LOCAL_DATA_ONLY", "1").strip().lower() in ("1", "true", "yes", "on")\n'
    'AERA_GAMEFILES_ROOT = pathlib.Path(os.environ.get("AERA_GAMEFILES_ROOT", "")).expanduser() if os.environ.get("AERA_GAMEFILES_ROOT") else None\n'
)
s = replace_once(s, config_marker, config_block, "Aera local-data configuration")

s = s.replace(
    '"sName": "Infinity", "sIP": PUBLIC_HOST, "iPort": GAME_PORT,',
    '"sName": "Aera Infinity", "sIP": PUBLIC_HOST, "iPort": GAME_PORT,',
)
s = s.replace(
    '"live": "Welcome to Infinity, our own private server build!",\n         "test": "Welcome to Infinity, our own private server build!"',
    '"live": "Welcome to Aera Infinity!",\n         "test": "Welcome to Aera Infinity!"',
)
s = s.replace(
    '"live": "Infinity Server News", "test": "Infinity Server News"',
    '"live": "Aera Infinity News", "test": "Aera Infinity News"',
)

login_old = '        "bundles": {"Characters": CHARACTERS_BUNDLE},\n        "Characters_Bundle": CHARACTERS_BUNDLE,\n'
login_new = '        "bundles": {"Characters": aera_character_bundle(conn) if AERA_LOCAL_DATA_ONLY else CHARACTERS_BUNDLE},\n        "Characters_Bundle": aera_character_bundle(conn) if AERA_LOCAL_DATA_ONLY else CHARACTERS_BUNDLE,\n'
s = replace_once(s, login_old, login_new, "local character bundle")

route_marker = '# path (lowercased, no query) -> (method, handler taking (conn, query_or_form))\nROUTES = {'
local_impl = r'''# ---- Aera local-data-only endpoints ----------------------------------------
def aera_character_bundle(conn):
    row = conn.execute("SELECT bundle_id,name,filename FROM asset_bundles WHERE bundle_id=?", (70955,)).fetchone()
    if row and row["filename"]:
        return {"ID": int(row["bundle_id"]), "Name": row["name"] or "Characters",
                "Filename": row["filename"], "VersionContent": 0, "VersionStage": 0,
                "VersionLive": 0, "Dirty": False}
    return {"ID": 70955, "Name": "Characters", "Filename": "gameassets/70955_characters.unity3d",
            "VersionContent": 0, "VersionStage": 0, "VersionLive": 0, "Dirty": False}


def aera_get_base_classes(conn, qs):
    """Build base-class bootstrap data only from Aera's synced catalog."""
    items = []
    for row in conn.execute("SELECT item_id FROM items WHERE is_class=1 ORDER BY item_id"):
        item = db.item(conn, int(row["item_id"]))
        if item is not None:
            items.append(item)
    return {"items": items, "hairs": db.hairs_list(conn),
            "character_bundle": aera_character_bundle(conn)}


def aera_get_monster_data(conn, qs):
    """Never crawl AE. Return only monster/NPC definitions present in Aera's synced DB."""
    out = []
    for mid in _ids(qs):
        c = montemplates.catalog(conn, mid)
        if c is not None:
            _normalize_equipped_items(c)
            out.append(c)
    return out


def aera_get_asset_bundles(conn, qs):
    """Resolve bundle IDs only from Aera's local asset_bundles table."""
    out = []
    for bid in _ids(qs):
        row = conn.execute(
            "SELECT bundle_id,name,filename,version_content,version_stage,version_live FROM asset_bundles WHERE bundle_id=?",
            (int(bid),)).fetchone()
        if row is None:
            out.append({"ID": int(bid), "Name": "", "Filename": "",
                        "VersionContent": 0, "VersionStage": 0, "VersionLive": 0})
        else:
            out.append({"ID": int(row["bundle_id"]), "Name": row["name"] or "",
                        "Filename": row["filename"] or "", "VersionContent": 0,
                        "VersionStage": 0, "VersionLive": 0, "Dirty": False})
    return out


def aera_get_soundtracks(conn, qs):
    """Rebuild the soundtrack response from Aera map metadata; no live API request."""
    ids = set(_ids(qs))
    if not ids:
        return []
    found = {}
    for row in conn.execute("SELECT doc FROM maps WHERE doc IS NOT NULL"):
        try:
            area = (json.loads(row["doc"]) or {}).get("area") or {}
        except Exception:
            continue
        sid = int(area.get("SoundtrackID") or 0)
        bundle = area.get("SoundtrackBundle")
        prefab = area.get("SoundtrackPrefabName") or ""
        if sid in ids and sid not in found and bundle and prefab:
            found[sid] = {"SoundtrackID": sid, "Name": prefab, "PrefabName": prefab,
                          "SafeToStream": False, "Artist": "", "SongName": "",
                          "Album": "", "Tag": "", "assetbundleData": bundle}
    return [found[i] for i in _ids(qs) if i in found]


def aera_read_gamefile(route_key):
    """Read one local captured .unity3d file, safely rooted under AERA_GAMEFILES_ROOT."""
    prefix = "gamefiles/assetbundles/windows/"
    if not AERA_GAMEFILES_ROOT or not route_key.startswith(prefix):
        return None
    rel = urllib.parse.unquote(route_key[len(prefix):]).replace("\\", "/").lstrip("/")
    if not rel or ".." in pathlib.PurePosixPath(rel).parts:
        return None
    try:
        root = AERA_GAMEFILES_ROOT.resolve()
        target = (root / pathlib.PurePosixPath(rel)).resolve()
        if target != root and root not in target.parents:
            return None
        return target.read_bytes() if target.is_file() else None
    except Exception:
        return None


# path (lowercased, no query) -> (method, handler taking (conn, query_or_form))
ROUTES = {'''
s = replace_once(s, route_marker, local_impl, "local endpoint implementations")

s = s.replace(
    '    "data/getbaseclasses":   ("GET",  get_base_classes),',
    '    "data/getbaseclasses":   ("GET",  aera_get_base_classes if AERA_LOCAL_DATA_ONLY else get_base_classes),',
)
s = s.replace(
    '    "data/getmonsterdata":   ("GET",  get_monster_data),',
    '    "data/getmonsterdata":   ("GET",  aera_get_monster_data if AERA_LOCAL_DATA_ONLY else get_monster_data),',
)
s = s.replace(
    '    "data/getassetbundlesbyids": ("GET", get_asset_bundles),',
    '    "data/getassetbundlesbyids": ("GET", aera_get_asset_bundles if AERA_LOCAL_DATA_ONLY else get_asset_bundles),',
)
s = s.replace(
    '    "data/getsoundtracks":   ("GET",  get_soundtracks),',
    '    "data/getsoundtracks":   ("GET",  aera_get_soundtracks if AERA_LOCAL_DATA_ONLY else get_soundtracks),',
)

handle_marker = '        if method == "GET" and key in ("account", "account/"):\n'
handle_insert = (
    '        if method == "GET" and key.startswith("gamefiles/assetbundles/windows/"):\n'
    '            data = aera_read_gamefile(key)\n'
    '            if data is None:\n'
    '                print(f"  [aera-files] MISS {key}")\n'
    '                return self._send_bytes(b"", 404, "application/octet-stream")\n'
    '            print(f"  [aera-files] GET {key} -> {len(data)}B")\n'
    '            return self._send_bytes(data, 200, "application/octet-stream")\n\n'
    '        if method == "GET" and key in ("account", "account/"):\n'
)
s = replace_once(s, handle_marker, handle_insert, "local gamefile HTTP route")

s = s.replace(
    '    mode = "CAPTURE+proxy" if CAPTURE_PROXY else "local-only"',
    '    mode = "AERA LOCAL DATA ONLY" if AERA_LOCAL_DATA_ONLY else ("CAPTURE+proxy" if CAPTURE_PROXY else "local-only")',
)

webapi_py.write_text(s, encoding="utf-8")

w = world_cmds_py.read_text(encoding="utf-8")
if "import os\n" not in w:
    w = replace_once(w, '"""\nimport combat\n', '"""\nimport os\n\nimport combat\n', "world handler import os")
w = replace_once(
    w,
    '    if cmd == "firstJoin":\n        base, room = "infinityportal", "1"\n',
    '    if cmd == "firstJoin":\n        base, room = os.environ.get("AERA_START_MAP", "battleon").lower(), "1"\n',
    "Aera firstJoin map",
)
world_cmds_py.write_text(w, encoding="utf-8")

c = context_py.read_text(encoding="utf-8")
if "import os\n" not in c:
    if "import asyncio\n" in c:
        c = c.replace("import asyncio\n", "import asyncio\nimport os\n", 1)
    else:
        raise SystemExit("ERROR: upstream layout changed; could not patch context import os.")
c = replace_once(
    c,
    '    area = (maps.area_payload(base, session.conn)\n            or maps.area_payload("infinityportal", session.conn))\n',
    '    fallback_map = os.environ.get("AERA_START_MAP", "battleon").lower()\n'
    '    area = (maps.area_payload(base, session.conn)\n            or maps.area_payload(fallback_map, session.conn))\n'
    '    if area is None:\n'
    '        print(f"  [AERA] join rejected: map {base!r} and fallback {fallback_map!r} are not in local DB")\n'
    '        return\n',
    "Aera local map fallback",
)
context_py.write_text(c, encoding="utf-8")


print("Aera overlay applied successfully.")
print("  API : INFINITY_API_PORT (default 6678)")
print("  Game: INFINITY_GAME_PORT (default 6677)")
print("  AERA_LOCAL_DATA_ONLY=1 disables upstream world seeding + monster/bundle/soundtrack lookup.")
print("  Client uses Aera's Unity project and local captured gamefiles; no stock-client redirect is required.")
