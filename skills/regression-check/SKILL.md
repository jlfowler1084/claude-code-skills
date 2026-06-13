---
name: regression-check
description: >
  Verify that all shipped features still exist in the codebase by checking the
  project's feature-manifest.json. Use this skill before and after any code changes
  that modify existing files, during refactors, restructuring, or before commits.
  Trigger when the user mentions regression testing, feature verification, manifest
  checks, or says anything like "check nothing broke", "verify features", or "run
  regression check". Use for any session that modifies existing source files in a
  project with a feature-manifest.json.
---

# Regression Check Skill

## Purpose

Verify that all shipped features in a project still exist in the codebase by checking the project's `feature-manifest.json`. Run this **before and after** making code changes to catch any accidental deletions.

## When to Use

- **MANDATORY** at the start and end of every coding session that modifies existing files
- After any file rewrite, refactor, or restructuring
- Before committing changes
- When the user or prompt explicitly asks for a regression check

## How to Run

### Step 1: Locate the manifest

Look for `feature-manifest.json` in these locations (in order):
1. `./feature-manifest.json` (project root)
2. `./dashboard/feature-manifest.json` (monorepo with dashboard subfolder)

If no manifest is found, inform the user: "No feature-manifest.json found. Skipping regression check. Consider creating one to protect shipped features."

### Step 2: Read and parse the manifest

The manifest has this structure:
```json
{
  "_meta": { "project": "...", "base_path": "dashboard" },
  "base_path": "dashboard",
  "features": [
    {
      "ticket": "PROJ-46",
      "name": "Search History Panel",
      "file": "src/components/search/search-history.tsx",
      "exports": ["SearchHistoryPanel"],
      "patterns": ["search_runs", "loadHistory"],
      "area": "search"
    }
  ]
}
```

- `base_path`: Prepend this to all `file` paths (e.g., `dashboard/src/components/...`)
- `file`: Relative path to the source file
- `exports`: Function/component/variable names that must appear in the file (via `export` keyword or `export default`)
- `patterns`: String literals that must appear somewhere in the file content

### Step 3: Run verification

For each feature entry, run these checks using bash:

```bash
# 1. File existence check
test -f "$BASE_PATH/$FILE"

# 2. Export check — verify each named export exists
grep -q "export.*$EXPORT_NAME\|export default.*$EXPORT_NAME" "$BASE_PATH/$FILE"

# 3. Pattern check — verify each pattern string appears in the file
grep -q "$PATTERN" "$BASE_PATH/$FILE"
```

**Important:** Pattern matching is case-sensitive. Use `grep -qi` only if the manifest entry explicitly notes case-insensitive matching.

### Step 4: Output results

Print a formatted table to the console:

```
╔══════════════════════════════════════════════════════════════╗
║                  REGRESSION CHECK RESULTS                    ║
╠══════════════════════════════════════════════════════════════╣

Area: search
  ✅ PASS  PROJ-46  Search History Panel
  ✅ PASS  PROJ-58  Job Card Component
  ❌ FAIL  PROJ-58  Search Controls
     └─ MISSING EXPORT: SearchControls
     └─ FILE: src/components/search/search-controls.tsx

Area: intelligence
  ✅ PASS  PROJ-57  Intelligence Tab
  ✅ PASS  PROJ-56  Company Brief Generator

────────────────────────────────────────────────────────────────
TOTAL: 43/45 PASS | 2 FAIL
STATUS: ❌ REGRESSION DETECTED
╚══════════════════════════════════════════════════════════════╝
```

### Step 5: Handle failures

**If ALL PASS:** Report "No regressions detected" and proceed normally.

**If ANY FAIL:**
1. **STOP all other work immediately**
2. List every failure with the specific check that failed (missing file, missing export, missing pattern)
3. **Fix every regression before making any new changes or committing**
4. Re-run the regression check after fixing to confirm all pass
5. Only then resume the original task

**CRITICAL:** Do NOT skip, ignore, or defer failures. Do NOT commit with known regressions. Do NOT rationalize that a missing export is "expected" unless the user explicitly confirmed they intentionally removed that feature.

## Manifest Maintenance

When you ship a **new feature**, add an entry to `feature-manifest.json`:

```json
{
  "ticket": "PROJ-XX",
  "name": "Descriptive Feature Name",
  "file": "src/path/to/main-file.tsx",
  "exports": ["MainExportName"],
  "patterns": ["key_string_that_proves_feature_works"],
  "area": "area_name"
}
```

When you **intentionally remove** a feature (user-confirmed), remove its manifest entry and note the removal in your commit message.

## Script Version (Optional)

If the project has a `tools/regression-check.sh` or `tools/regression-check.ps1`, run that instead of performing manual checks. The script reads the same manifest and produces the same output format.

### Bash script template (save as `tools/regression-check.sh`):

```bash
#!/bin/bash
# Regression Check — reads feature-manifest.json and verifies all entries
set -e

MANIFEST="feature-manifest.json"
if [ ! -f "$MANIFEST" ]; then
  MANIFEST="dashboard/feature-manifest.json"
fi
if [ ! -f "$MANIFEST" ]; then
  echo "No feature-manifest.json found. Skipping."
  exit 0
fi

BASE=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('base_path','.'))")
PASS=0
FAIL=0
FAILURES=""

while IFS= read -r feature; do
  NAME=$(echo "$feature" | python3 -c "import sys,json; f=json.load(sys.stdin); print(f['name'])")
  FILE=$(echo "$feature" | python3 -c "import sys,json; f=json.load(sys.stdin); print(f['file'])")
  TICKET=$(echo "$feature" | python3 -c "import sys,json; f=json.load(sys.stdin); print(f.get('ticket',''))")
  EXPORTS=$(echo "$feature" | python3 -c "import sys,json; f=json.load(sys.stdin); print('|'.join(f.get('exports',[])))")
  PATTERNS=$(echo "$feature" | python3 -c "import sys,json; f=json.load(sys.stdin); print('|||'.join(f.get('patterns',[])))")

  FULL_PATH="$BASE/$FILE"
  FAILED=0
  FAIL_REASONS=""

  # File check
  if [ ! -f "$FULL_PATH" ]; then
    FAILED=1
    FAIL_REASONS="$FAIL_REASONS\n     └─ FILE NOT FOUND: $FULL_PATH"
  else
    # Export checks
    if [ -n "$EXPORTS" ]; then
      IFS='|' read -ra EXP_ARR <<< "$EXPORTS"
      for exp in "${EXP_ARR[@]}"; do
        if [ -n "$exp" ] && ! grep -q "$exp" "$FULL_PATH"; then
          FAILED=1
          FAIL_REASONS="$FAIL_REASONS\n     └─ MISSING EXPORT: $exp"
        fi
      done
    fi
    # Pattern checks
    if [ -n "$PATTERNS" ]; then
      IFS='|||' read -ra PAT_ARR <<< "$PATTERNS"
      for pat in "${PAT_ARR[@]}"; do
        if [ -n "$pat" ] && ! grep -q "$pat" "$FULL_PATH"; then
          FAILED=1
          FAIL_REASONS="$FAIL_REASONS\n     └─ MISSING PATTERN: $pat"
        fi
      done
    fi
  fi

  if [ "$FAILED" -eq 0 ]; then
    echo "  ✅ PASS  $TICKET  $NAME"
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL  $TICKET  $NAME"
    echo -e "$FAIL_REASONS"
    FAIL=$((FAIL + 1))
    FAILURES="$FAILURES\n$NAME ($FILE)"
  fi
done < <(python3 -c "import json; [print(json.dumps(f)) for f in json.load(open('$MANIFEST'))['features']]")

TOTAL=$((PASS + FAIL))
echo ""
echo "────────────────────────────────────────────────────────"
echo "TOTAL: $PASS/$TOTAL PASS | $FAIL FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "STATUS: ❌ REGRESSION DETECTED"
  exit 1
else
  echo "STATUS: ✅ ALL CLEAR"
  exit 0
fi
```
