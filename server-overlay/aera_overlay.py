#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
server_py = ROOT / 'server' / 'server.py'
webapi_py = ROOT / 'server' / 'webapi.py'

if not server_py.exists() or not webapi_py.exists():
    raise SystemExit('ERROR: point this script at an InfinityServer checkout root.')


def replace_once(text, old, new, label):
    if new in text:
        return text
    if old not in text:
        raise SystemExit(
            f'ERROR: upstream layout changed; could not patch {label}. '
            'Update the Aera overlay against the latest InfinityServer main branch.'
        )
    return text.replace(old, new, 1)


s = server_py.read_text(encoding='utf-8')
if 'import os\n' not in s:
    s = replace_once(
        s,
        'import json\nimport sys\n',
        'import json\nimport os\nimport sys\n',
        'server import os',
    )
s = replace_once(
    s,
    'HOST = "0.0.0.0"\nPORT = 5588  # must match docs/RedirectPatch.cs',
    'HOST = os.environ.get("INFINITY_GAME_HOST", "0.0.0.0")\nPORT = int(os.environ.get("INFINITY_GAME_PORT", "6677"))',
    'game host/port',
)
s = s.replace(
    'print(f"InfinityServer listening on {addrs}  ({store})")',
    'print(f"Aera Infinity listening on {addrs}  ({store})")',
)
server_py.write_text(s, encoding='utf-8')

s = webapi_py.read_text(encoding='utf-8')
s = replace_once(
    s,
    'HOST = "0.0.0.0"\nPORT = 8182                                   # mod ApiPatch rewrites WebApiURL -> here',
    'HOST = os.environ.get("INFINITY_API_HOST", "0.0.0.0")\nPORT = int(os.environ.get("INFINITY_API_PORT", "6678"))',
    'api host/port',
)
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
webapi_py.write_text(s, encoding='utf-8')

print('Aera overlay applied successfully.')
print('  API : INFINITY_API_PORT (default 6678)')
print('  Game: INFINITY_GAME_PORT (default 6677)')
print('  Client: Aera Unity client; no stock AQW Infinity redirect is required.')
