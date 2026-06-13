"""CLI wrapper around tavily-python for the web-research skill.

Reads TAVILY_API_KEY from the process environment. On Windows, falls back to
reading the User-scope registry via PowerShell when the env var is missing —
this handles the `setx` process-ancestry gap where VS Code / Claude Code
inherit a stale environment from a parent that predates the key being set.

Output is a JSON blob on stdout. Exit codes:
    0   success
    1   missing API key (setup problem)
    2   API / network error (may be retryable)
    3   bad arguments
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import subprocess
import sys
from pathlib import Path

logging.basicConfig(level=logging.WARNING, format="%(levelname)s: %(message)s")
log = logging.getLogger("tavily-search")


def _load_api_key() -> str | None:
    """Return TAVILY_API_KEY from env, falling back to Windows user registry."""
    key = os.environ.get("TAVILY_API_KEY")
    if key:
        return key

    if not sys.platform.startswith("win"):
        return None

    # Windows fallback: read the User-scope registry via PowerShell.
    # Handles the common gap where `setx` succeeds but the current process tree
    # predates the write and never inherits the new value.
    try:
        result = subprocess.run(
            [
                "powershell",
                "-NoProfile",
                "-Command",
                "[Environment]::GetEnvironmentVariable('TAVILY_API_KEY', 'User')",
            ],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        log.warning("PowerShell fallback failed: %s", exc)
        return None

    value = result.stdout.strip()
    return value or None


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Tavily search CLI — returns ranked results + page markdown as JSON.",
    )
    parser.add_argument("query", help="Search query")
    parser.add_argument(
        "--depth",
        choices=["basic", "advanced"],
        default="advanced",
        help="Search depth (default: advanced)",
    )
    parser.add_argument(
        "--max-results",
        type=int,
        default=5,
        help="Max results to return (default: 5)",
    )
    parser.add_argument(
        "--time-range",
        choices=["day", "week", "month", "year"],
        default=None,
        help="Restrict to recent content",
    )
    parser.add_argument(
        "--topic",
        choices=["general", "news", "finance"],
        default="general",
        help="Topic routing (default: general)",
    )
    parser.add_argument(
        "--include-raw",
        action="store_true",
        default=True,
        help="Include full page markdown (default: on)",
    )
    parser.add_argument(
        "--no-raw",
        dest="include_raw",
        action="store_false",
        help="Skip page content (search snippets only)",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=None,
        help="Write JSON to file instead of stdout",
    )
    return parser.parse_args()


def main() -> int:
    if sys.platform.startswith("win"):
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")

    args = _parse_args()

    api_key = _load_api_key()
    if not api_key:
        log.error(
            "TAVILY_API_KEY not found in environment or Windows user registry. "
            "Run: setx TAVILY_API_KEY \"tvly-...\" then restart your terminal."
        )
        return 1

    try:
        from tavily import TavilyClient
    except ImportError:
        log.error("tavily-python not installed. Run: python -m pip install tavily-python")
        return 1

    client = TavilyClient(api_key=api_key)

    search_kwargs = {
        "query": args.query,
        "search_depth": args.depth,
        "max_results": args.max_results,
        "topic": args.topic,
        "include_answer": "advanced",
        "include_raw_content": "markdown" if args.include_raw else False,
    }
    if args.time_range:
        search_kwargs["time_range"] = args.time_range

    try:
        response = client.search(**search_kwargs)
    except Exception as exc:
        log.error("Tavily API call failed: %s", exc)
        return 2

    payload = json.dumps(response, indent=2, ensure_ascii=False)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload, encoding="utf-8")
        print(f"Wrote {args.output} ({len(payload)} bytes)", file=sys.stderr)
    else:
        print(payload)

    return 0


if __name__ == "__main__":
    sys.exit(main())