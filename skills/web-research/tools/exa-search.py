"""CLI wrapper around exa-py for the web-research skill.

Neural/semantic web search via Exa. Reads EXA_API_KEY from the process
environment. On Windows, falls back to reading the User-scope registry via
PowerShell when the env var is missing — this handles the `setx`
process-ancestry gap where an editor/terminal inherits a stale environment
from a parent that predates the key being set.

Output is a JSON blob on stdout with a top-level `results` array shaped to
match tavily-search.py (score / title / url / published_date / author /
text), so the same `jq` extraction works across both engines.

Exit codes:
    0   success
    1   missing API key or SDK (setup problem)
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
log = logging.getLogger("exa-search")


def _load_api_key() -> str | None:
    """Return EXA_API_KEY from env, falling back to the Windows user registry."""
    key = os.environ.get("EXA_API_KEY")
    if key:
        return key

    if not sys.platform.startswith("win"):
        return None

    # Windows fallback: read the User-scope registry via PowerShell. Handles the
    # common gap where `setx` succeeds but the current process tree predates the
    # write and never inherits the new value.
    try:
        result = subprocess.run(
            [
                "powershell",
                "-NoProfile",
                "-Command",
                "[Environment]::GetEnvironmentVariable('EXA_API_KEY', 'User')",
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
        description="Exa neural/semantic search CLI — returns ranked results (+ page text) as JSON.",
    )
    parser.add_argument("query", help="Search query")
    parser.add_argument(
        "--type",
        choices=["auto", "neural", "keyword"],
        default="auto",
        help="Search mode: neural (semantic), keyword, or auto (Exa decides). Default: auto",
    )
    parser.add_argument(
        "--num-results",
        type=int,
        default=5,
        help="Max results to return (default: 5)",
    )
    parser.add_argument(
        "--category",
        default=None,
        help="Restrict to a content category (e.g. 'research paper', 'news', 'company', 'github', 'pdf')",
    )
    parser.add_argument(
        "--start-published-date",
        default=None,
        metavar="YYYY-MM-DD",
        help="Only return content published on or after this date",
    )
    parser.add_argument(
        "--include-text",
        action="store_true",
        default=True,
        help="Include full page text (default: on)",
    )
    parser.add_argument(
        "--no-text",
        dest="include_text",
        action="store_false",
        help="Skip page text (search results only)",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=None,
        help="Write JSON to file instead of stdout",
    )
    return parser.parse_args()


def _result_to_dict(result: object) -> dict:
    """Normalize an Exa result object into a tavily-compatible dict."""
    return {
        "title": getattr(result, "title", None),
        "url": getattr(result, "url", None),
        "score": getattr(result, "score", None),
        "published_date": getattr(result, "published_date", None),
        "author": getattr(result, "author", None),
        "text": getattr(result, "text", None),
    }


def main() -> int:
    if sys.platform.startswith("win"):
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")

    args = _parse_args()

    api_key = _load_api_key()
    if not api_key:
        log.error(
            "EXA_API_KEY not found in environment or Windows user registry. "
            'Run: setx EXA_API_KEY "your-key" then restart your terminal.'
        )
        return 1

    try:
        from exa_py import Exa
    except ImportError:
        log.error("exa-py not installed. Run: python -m pip install exa-py")
        return 1

    client = Exa(api_key=api_key)

    search_kwargs: dict = {"type": args.type, "num_results": args.num_results}
    if args.category:
        search_kwargs["category"] = args.category
    if args.start_published_date:
        search_kwargs["start_published_date"] = args.start_published_date

    try:
        if args.include_text:
            response = client.search_and_contents(args.query, text=True, **search_kwargs)
        else:
            response = client.search(args.query, **search_kwargs)
    except Exception as exc:
        log.error("Exa API call failed: %s", exc)
        return 2

    results = [_result_to_dict(r) for r in getattr(response, "results", [])]
    payload = json.dumps(
        {"query": args.query, "type": args.type, "results": results},
        indent=2,
        ensure_ascii=False,
    )

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload, encoding="utf-8")
        print(f"Wrote {args.output} ({len(payload)} bytes)", file=sys.stderr)
    else:
        print(payload)

    return 0


if __name__ == "__main__":
    sys.exit(main())
