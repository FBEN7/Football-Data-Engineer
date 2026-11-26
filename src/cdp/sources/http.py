"""Download helper for the source adapters: cache on disk, retry, never keep a partial file."""

from __future__ import annotations

import time
from pathlib import Path

import requests

_session = requests.Session()
_session.headers["User-Agent"] = "club-data-platform (open-source portfolio project)"


class NotFound(Exception):
    """HTTP 404: the file does not exist upstream."""


def download(url: str, dest: Path, *, auth=None, headers=None, retries: int = 4) -> Path:
    """Fetch `url` into `dest` unless it is already there. Returns `dest`."""
    if dest.exists():
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(retries):
        try:
            with _session.get(url, auth=auth, headers=headers, timeout=120, stream=True) as resp:
                if resp.status_code == 404:
                    raise NotFound(url)
                resp.raise_for_status()
                tmp = dest.with_suffix(dest.suffix + ".part")
                with tmp.open("wb") as fh:
                    for chunk in resp.iter_content(chunk_size=1 << 20):
                        fh.write(chunk)
                tmp.replace(dest)
                return dest
        except NotFound:
            raise
        except requests.RequestException:
            if attempt == retries - 1:
                raise
            time.sleep(2**attempt)
    raise AssertionError("unreachable")
