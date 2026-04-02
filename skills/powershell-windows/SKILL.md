---
name: powershell-windows
description: >
  PowerShell Windows patterns for production scripts. Use when writing any PowerShell
  script, function, module, or scheduled task. Covers advanced functions, OutputType,
  parameter sets, tab completion (Register-ArgumentCompleter), splatting, structured
  error handling, logging (JSON + Event Log), Task Scheduler, and PSScriptAnalyzer.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# PowerShell Windows Patterns

Production patterns for Windows PowerShell scripts. Every script Claude Code
generates MUST follow these conventions.

---

## 1. Advanced Functions (Default Pattern)

EVERY function and script MUST use `[CmdletBinding()]` with a typed `param()` block.
This is non-negotiable — it gives you `-Verbose`, `-ErrorAction`, `-WhatIf`, `-Debug`,
and all common parameters for free.

```powershell
function Invoke-Example {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Count = 10,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand.Name)"
    }

    process {
        if ($PSCmdlet.ShouldProcess($Name, "Process item")) {
            # Work here
        }
    }

    end {
        Write-Verbose "Completed $($MyInvocation.MyCommand.Name)"
    }

    cleanup {
        # PowerShell 7.3+ — runs even after Ctrl+C / pipeline stop.
        # Use for releasing file locks, closing connections, removing temp files.
        # More reliable than finally for interactive/long-running scripts.
    }
}
```

### OutputType Declaration

ALWAYS declare `[OutputType()]` on functions. This enables IntelliSense for
consumers and makes pipeline behavior predictable. GitHub reviewers will notice.

```powershell
function Get-ProjectConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName
    )
    # ...
}

# Multiple possible output types
function Get-TaskResult {
    [CmdletBinding()]
    [OutputType([PSCustomObject], ParameterSetName = 'Detail')]
    [OutputType([string], ParameterSetName = 'Summary')]
    param(
        [Parameter(ParameterSetName = 'Detail')]
        [switch]$Detailed,

        [Parameter(ParameterSetName = 'Summary')]
        [switch]$SummaryOnly
    )
    # ...
}
```

### Parameter Sets

Use parameter sets for mutually exclusive parameter groups. Let PowerShell
enforce it at runtime instead of writing `if ($A -and $B) { throw }`.

```powershell
function Invoke-Deployment {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ByPath')]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,

        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByPath')]
        [switch]$Force
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ByName' { $target = Resolve-ProjectName $Name }
        'ByPath' { $target = $Path }
    }
    # ...
}
```

### Rules

- Name functions as `Verb-Noun` (use approved verbs: `Get-Verb`)
- ALWAYS include `[OutputType()]` — declare what the function returns
- Always type parameters: `[string]`, `[int]`, `[switch]`, `[datetime]`
- Use `[Parameter(Mandatory)]` — not `Read-Host` for required input
- Use `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, `[ValidateRange()]`,
  `[ValidatePattern()]`, `[ValidateScript()]` as appropriate
- Use `begin/process/end/cleanup` blocks when accepting pipeline input
- Use `cleanup` block (PS 7.3+) for resource release in long-running scripts
- Use `$PSCmdlet.ShouldProcess()` for any function that changes state
- Use parameter sets for mutually exclusive params — not runtime `if` checks
- NEVER use `Write-Output` for debugging — it pollutes the return value.
  Use `Write-Verbose`, `Write-Debug`, or `Write-Information` instead
- Return values intentionally — every unassigned expression becomes output

### Pipeline Input

```powershell
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]$Path,

    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string]$FilePath
)
```

---

## 2. Splatting

Use splatting when a cmdlet takes more than 2-3 parameters. Store parameters
in a hashtable and pass with `@`.

### Basic Splatting

```powershell
$params = @{
    Path      = "C:\Users"
    Recurse   = $true
    Filter    = "*.png"
    ErrorAction = 'SilentlyContinue'
}
Get-ChildItem @params
```

### Conditional Parameters

Add keys only when needed — one version of the command to maintain:

```powershell
$params = @{
    ComputerName = $Server
    ScriptBlock  = { Get-Service }
}
if ($Credential) {
    $params['Credential'] = $Credential
}
Invoke-Command @params
```

### Multi-Splat (Shared Parameters)

```powershell
$commonParams = @{
    Credential   = $cred
    ComputerName = $server
}
$serviceParams = @{
    Name = 'W3SVC'
}
Get-Service @commonParams @serviceParams
```

---

## 3. Tab Completion (Register-ArgumentCompleter)

EVERY custom cmdlet with path parameters, enum-like values, or known option
sets MUST have tab completion registered. Nobody should have to type full
paths or guess valid values. This is non-negotiable for module cmdlets.

### File/Directory Path Completion

```powershell
Register-ArgumentCompleter -CommandName 'Invoke-DropZone' -ParameterName 'Path' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-ChildItem -Path "$wordToComplete*" -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_.FullName,
                $_.Name,
                'ParameterValue',
                $_.FullName
            )
        }
}
```

### Dynamic Value Completion (From Data Source)

```powershell
# Complete project names from a registry file
Register-ArgumentCompleter -CommandName 'Get-ProjectConfig' -ParameterName 'ProjectName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $registryPath = Join-Path $env:USERPROFILE '.claude' 'project-registry.json'
    if (Test-Path $registryPath) {
        $projects = (Get-Content $registryPath -Raw | ConvertFrom-Json).projects
        $projects | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
```

### ValidateSet with Completer Class (PS 7+)

For parameters where valid values come from a dynamic source, use a completer
class instead of static `[ValidateSet()]`:

```powershell
class ProjectNameCompleter : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $registryPath = Join-Path $env:USERPROFILE '.claude' 'project-registry.json'
        if (Test-Path $registryPath) {
            return (Get-Content $registryPath -Raw | ConvertFrom-Json).projects
        }
        return @()
    }
}

function Get-ProjectStatus {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet([ProjectNameCompleter])]
        [string]$ProjectName
    )
    # Tab completes AND validates at runtime
}
```

### Module Registration Pattern

In your `.psm1` module file, register completers at module load time —
after all functions are exported:

```powershell
# At the bottom of YourModule.psm1, after Export-ModuleMember

# --- Tab Completion ---
Register-ArgumentCompleter -CommandName 'Get-MyNote' -ParameterName 'NotePath' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $basePath = (Get-MyConfig).BasePath
    Get-ChildItem -Path (Join-Path $basePath "$wordToComplete*") -File -Filter '*.md' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($basePath.Length + 1)
            [System.Management.Automation.CompletionResult]::new(
                $relativePath, $_.BaseName, 'ParameterValue', $relativePath
            )
        }
}
```

### When to Register Completers

| Parameter Type | Completer Approach |
|----------------|-------------------|
| File/directory paths | Path completer with `Get-ChildItem` |
| Project/config names | Dynamic completer from JSON registry |
| Enum-like choices (static) | `[ValidateSet('A','B','C')]` (built-in completion) |
| Enum-like choices (dynamic) | `IValidateSetValuesGenerator` class |
| Remote resources | Completer that queries API/database with caching |

---

## 4. Error Handling

### ErrorActionPreference Strategy

| Context | Setting | Why |
|---------|---------|-----|
| Automation/scheduled scripts | `Stop` | Fail fast, catch everything |
| Interactive functions | `Stop` inside try blocks | Controlled recovery |
| Probing/testing | `SilentlyContinue` | Expected failures |

### Production Try/Catch Pattern

```powershell
function Invoke-SafeOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Target
    )

    $originalEAP = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Stop'

        # Work here — all errors become terminating
        $result = Get-Item -Path $Target
        return $result
    }
    catch [System.IO.FileNotFoundException] {
        Write-Warning "File not found: $Target"
        return $null
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning "Access denied: $Target"
        return $null
    }
    catch {
        # Unknown error — log details and re-throw
        Write-Warning "Unexpected error: $_"
        Write-Warning "Stack: $($_.ScriptStackTrace)"
        throw
    }
    finally {
        $ErrorActionPreference = $originalEAP
        # Cleanup: close handles, remove temp files, etc.
    }
}
```

### Error Output Rules

| Cmdlet | Use For | Goes To |
|--------|---------|---------|
| `Write-Error` | Non-terminating errors (pipeline continues) | Error stream |
| `throw` | Terminating errors (stop execution) | Exception |
| `Write-Warning` | Recoverable issues, degraded operation | Warning stream |
| `Write-Verbose` | Operational detail (shown with `-Verbose`) | Verbose stream |
| `Write-Debug` | Developer diagnostics (shown with `-Debug`) | Debug stream |
| `Write-Information` | Structured informational output | Information stream |

CRITICAL: `throw` is affected by `$ErrorActionPreference` when used inside
advanced functions. If `$ErrorActionPreference = 'SilentlyContinue'`, a `throw`
can be silently swallowed. Use `$PSCmdlet.ThrowTerminatingError()` for guaranteed
termination:

```powershell
$err = [System.Management.Automation.ErrorRecord]::new(
    [System.Exception]::new("Critical failure in $Target"),
    'CriticalFailure',
    [System.Management.Automation.ErrorCategory]::OperationStopped,
    $Target
)
$PSCmdlet.ThrowTerminatingError($err)
```

---

## 5. Structured Logging

### JSON Log Files

All automation scripts MUST log to structured JSON. Always use `-Depth 10`.

```powershell
function Write-StructuredLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$Operation,

        [Parameter()]
        [hashtable]$Data
    )

    $entry = [ordered]@{
        Timestamp = (Get-Date -Format 'o')
        Level     = $Level
        Operation = $Operation
        Message   = $Message
        Computer  = $env:COMPUTERNAME
        User      = $env:USERNAME
        PID       = $PID
    }
    if ($Data) {
        $entry['Data'] = $Data
    }

    $json = $entry | ConvertTo-Json -Depth 10 -Compress
    Add-Content -Path $LogPath -Value $json -Encoding UTF8
}
```

### Windows Event Log Integration

For visibility in Event Viewer — register a source once, then write:

```powershell
# One-time registration (requires elevation)
if (-not [System.Diagnostics.EventLog]::SourceExists('MyProject')) {
    New-EventLog -LogName Application -Source 'MyProject'
}

# Write operational events
Write-EventLog -LogName Application -Source 'MyProject' `
    -EventId 1000 -EntryType Information `
    -Message "Task completed: $TaskName"

# Write warnings
Write-EventLog -LogName Application -Source 'MyProject' `
    -EventId 2000 -EntryType Warning `
    -Message "Task degraded: $TaskName - $WarningDetail"

# Write errors
Write-EventLog -LogName Application -Source 'MyProject' `
    -EventId 3000 -EntryType Error `
    -Message "Task failed: $TaskName - $_"
```

### Event ID Convention

| Range | Level | Use |
|-------|-------|-----|
| 1000-1999 | Info | Successful operations, start/stop |
| 2000-2999 | Warning | Degraded but continued, retries |
| 3000-3999 | Error | Failures, exceptions |

### Automation Script Logging Pattern

Every scheduled/automation script should follow this structure:

```powershell
$logPath = Join-Path $PSScriptRoot "logs\$($MyInvocation.MyCommand.Name -replace '\.ps1$','')-$(Get-Date -Format 'yyyyMMdd').json"
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$startTime = Get-Date
Write-StructuredLog -LogPath $logPath -Level Info -Operation 'Start' `
    -Message "Script started" -Data @{ Args = $PSBoundParameters }

try {
    # ... main work ...

    $duration = (Get-Date) - $startTime
    Write-StructuredLog -LogPath $logPath -Level Success -Operation 'Complete' `
        -Message "Script completed" -Data @{
            DurationSeconds = [math]::Round($duration.TotalSeconds, 2)
            ItemsProcessed  = $processedCount
        }
    Write-EventLog -LogName Application -Source 'MyProject' `
        -EventId 1001 -EntryType Information `
        -Message "Completed: $($MyInvocation.MyCommand.Name) ($($duration.TotalSeconds)s)"
    exit 0
}
catch {
    Write-StructuredLog -LogPath $logPath -Level Error -Operation 'Fatal' `
        -Message $_.Exception.Message -Data @{
            ScriptStackTrace = $_.ScriptStackTrace
            ErrorId          = $_.FullyQualifiedErrorId
        }
    Write-EventLog -LogName Application -Source 'MyProject' `
        -EventId 3001 -EntryType Error `
        -Message "Failed: $($MyInvocation.MyCommand.Name) - $($_.Exception.Message)"
    exit 1
}
```

---

## 6. Windows Task Scheduler

### Registering Tasks (No Foreground Window)

CRITICAL: To prevent visible PowerShell windows, set the task principal to
"Run whether user is logged on or not" with `LogonType = 'Password'` or
`LogonType = 'S4U'` (no password storage needed for S4U).

```powershell
$action = New-ScheduledTaskAction `
    -Execute 'pwsh.exe' `
    -Argument '-NoProfile -NonInteractive -WindowStyle Hidden -File "C:\Scripts\MyScheduledTask.ps1"' `
    -WorkingDirectory 'C:\Projects\MyProject'

$trigger = New-ScheduledTaskTrigger -Daily -At '06:00'

$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType S4U `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName 'MyProject-DailyTask' `
    -TaskPath '\MyProject\' `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description 'Description of what this task does'
```

### Key Arguments for pwsh.exe / powershell.exe

| Argument | Purpose |
|----------|---------|
| `-NoProfile` | Skip profile loading (faster, no side effects) |
| `-NonInteractive` | Never prompt for input (fail instead) |
| `-WindowStyle Hidden` | Minimize window flash (backup to S4U principal) |
| `-ExecutionPolicy Bypass` | Only if policy blocks script execution |
| `-File "path"` | Run a script file (not `-Command`) |

### Task Folder Convention

All project tasks go under a project-specific folder (e.g. `\MyProject\`)
in Task Scheduler. Never register at the root `\` path.

### Verifying Task Health

```powershell
$task = Get-ScheduledTask -TaskName 'MyProject-DailyTask'
$info = $task | Get-ScheduledTaskInfo

# Check last run result (0 = success)
if ($info.LastTaskResult -ne 0) {
    Write-Warning "Task failed with code: $($info.LastTaskResult)"
}

# Check if overdue
if ($info.NextRunTime -lt (Get-Date)) {
    Write-Warning "Task is overdue: next run was $($info.NextRunTime)"
}
```

---

## 7. Operator Syntax Rules

### Parentheses Required for Logical Operators

```powershell
# WRONG — "parameter 'or'" error
if (Test-Path "a" -or Test-Path "b") { }

# CORRECT — each cmdlet call in parentheses
if ((Test-Path "a") -or (Test-Path "b")) { }
```

### Null Check Before Access

```powershell
# WRONG — errors if $array is $null
$array.Count -gt 0

# CORRECT
$array -and $array.Count -gt 0

# CORRECT — for strings
if ($text) { $text.Length }
```

### String Interpolation

```powershell
# Complex expressions — store in variable first
$value = $obj.Property.SubProperty
Write-Verbose "Result: $value"

# Or use subexpression (but prefer variable for readability)
Write-Verbose "Result: $($obj.Property.SubProperty)"
```

---

## 8. Unicode / Encoding

### ASCII Only in Scripts

| Purpose | Don't Use | Use Instead |
|---------|-----------|-------------|
| Success | Emoji/unicode | `[OK]` `[+]` |
| Error | Emoji/unicode | `[!]` `[X]` `[ERROR]` |
| Warning | Emoji/unicode | `[*]` `[WARN]` |
| Info | Emoji/unicode | `[i]` `[INFO]` |
| Progress | Emoji/unicode | `[...]` |

### File Encoding

- Write files as UTF-8 without BOM: `-Encoding UTF8`
- When reading files that may have BOM: `Get-Content -Encoding UTF8`
- JSON output: always `ConvertTo-Json -Depth 10`

---

## 9. Common Pitfalls

| Error Message | Cause | Fix |
|---------------|-------|-----|
| "parameter 'or'" | Missing parentheses | Wrap each cmdlet in `()` |
| "Unexpected token" | Unicode character | Use ASCII only |
| "Cannot find property" | Null object | Check null first |
| "Cannot convert" | Type mismatch | Use `.ToString()` or cast |
| "Cannot bind argument" | Wrong param type | Check `[Parameter()]` types |
| Truncated JSON | Missing `-Depth` | Always use `-Depth 10` |
| Visible scheduled task window | Wrong logon type | Use `LogonType S4U` |
| Task exit code 1 | Unhandled error | Wrap in try/catch, exit 0/1 |

---

## 10. File Paths

```powershell
# Use Join-Path — never string concatenation for paths
$configPath = Join-Path $env:USERPROFILE '.claude' 'CLAUDE.md'

# Use $PSScriptRoot for paths relative to the script
$dataDir = Join-Path $PSScriptRoot 'data'

# Test before access
if (-not (Test-Path $configPath)) {
    Write-Warning "Config not found: $configPath"
    return
}
```

---

## 11. PSScriptAnalyzer

Run `Invoke-ScriptAnalyzer` before committing any `.ps1` or `.psm1` file.
This catches the exact issues Claude Code tends to produce — missing
CmdletBinding, aliases in production code, unused variables, and style
violations.

### Pre-Commit Check

```powershell
# Analyze a single file
Invoke-ScriptAnalyzer -Path .\MyScript.ps1 -Severity Warning, Error

# Analyze all scripts in a project
Invoke-ScriptAnalyzer -Path .\tools\ -Recurse -Severity Warning, Error

# Fix auto-fixable issues
Invoke-ScriptAnalyzer -Path .\MyScript.ps1 -Fix
```

### Key Rules to Never Suppress

| Rule | What It Catches |
|------|----------------|
| `PSUseApprovedVerbs` | Non-standard verb in function name |
| `PSAvoidUsingCmdletAliases` | `ls`, `cd`, `%` instead of full names |
| `PSUseDeclaredVarsMoreThanAssignments` | Variables assigned but never used |
| `PSAvoidUsingWriteHost` | `Write-Host` instead of proper streams |
| `PSUseShouldProcessForStateChangingFunctions` | Missing `-WhatIf` on set/remove/new |
| `PSAvoidUsingPositionalParameters` | Positional args instead of named |
| `PSProvideCommentHelp` | Missing comment-based help block |
| `PSUseOutputTypeCorrectly` | Missing or incorrect `[OutputType()]` |

### Integration

When writing scripts for GitHub repos, treat PSScriptAnalyzer warnings as
errors. Clean output from `Invoke-ScriptAnalyzer` is the minimum bar for
any committed `.ps1` file. Consider adding as a pre-commit hook or GitHub Action.

### Install / Update

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

---

## 12. Production Script Template

```powershell
#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.21' }

<#
.SYNOPSIS
    Brief description of what this script does.
.DESCRIPTION
    Detailed description including context, dependencies, and behavior.
.PARAMETER Name
    Description of the Name parameter.
.PARAMETER LogPath
    Optional path for JSON log output. Defaults to logs/ subdirectory.
.EXAMPLE
    .\Invoke-Example.ps1 -Name "test"
    Runs the example with the given name.
.EXAMPLE
    .\Invoke-Example.ps1 -Name "test" -Verbose
    Runs with verbose operational output.
.EXAMPLE
    .\Invoke-Example.ps1 -Name "test" -WhatIf
    Shows what would happen without making changes.
.NOTES
    Author: YourName
    Created: YYYY-MM-DD
.LINK
    https://github.com/your-org/your-project
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter()]
    [string]$LogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Paths
$ScriptDir = $PSScriptRoot
if (-not $LogPath) {
    $LogPath = Join-Path $ScriptDir "logs\$(($MyInvocation.MyCommand.Name -replace '\.ps1$', ''))-$(Get-Date -Format 'yyyyMMdd').json"
}
$logDir = Split-Path $LogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# --- Functions ---

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Info','Warning','Error','Success')][string]$Level,
        [Parameter(Mandatory)][string]$Message,
        [Parameter()][string]$Operation,
        [Parameter()][hashtable]$Data
    )
    $entry = [ordered]@{
        Timestamp = (Get-Date -Format 'o')
        Level     = $Level
        Operation = $Operation
        Message   = $Message
    }
    if ($Data) { $entry['Data'] = $Data }
    $json = $entry | ConvertTo-Json -Depth 10 -Compress
    Add-Content -Path $script:LogPath -Value $json -Encoding UTF8

    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error'   { Write-Warning "[ERROR] $Message" }
        default   { Write-Verbose "[$Level] $Message" }
    }
}

# --- Main ---

$startTime = Get-Date
Write-Log -Level Info -Operation 'Start' -Message "Script started" `
    -Data @{ Parameters = ($PSBoundParameters | ConvertTo-Json -Depth 5 -Compress) }

try {
    # === YOUR LOGIC HERE ===

    $duration = (Get-Date) - $startTime
    Write-Log -Level Success -Operation 'Complete' -Message "Done in $([math]::Round($duration.TotalSeconds, 2))s"
    exit 0
}
catch {
    Write-Log -Level Error -Operation 'Fatal' -Message $_.Exception.Message `
        -Data @{ Stack = $_.ScriptStackTrace; ErrorId = $_.FullyQualifiedErrorId }
    exit 1
}
```

---

## 13. Module Function Template

For functions inside `.psm1` modules, use this pattern with tab completion
registration:

```powershell
function Get-MyActivity {
    <#
    .SYNOPSIS
        Retrieves recent project activity entries.
    .DESCRIPTION
        Scans the project directory for recently modified files and returns
        structured activity data. Supports filtering by date range, folder,
        and content type.
    .PARAMETER BasePath
        Path to the project root. Tab-completes from known project locations.
    .PARAMETER Since
        Return activity after this date. Defaults to 24 hours ago.
    .PARAMETER Folder
        Limit to a specific project folder. Tab-completes from subdirectories.
    .EXAMPLE
        Get-MyActivity -Since (Get-Date).AddDays(-7)
        Returns all project activity from the last week.
    .EXAMPLE
        Get-MyActivity -Folder 'src/components'
        Returns activity in the components folder.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter()]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$BasePath = (Get-MyConfig).BasePath,

        [Parameter()]
        [datetime]$Since = (Get-Date).AddHours(-24),

        [Parameter()]
        [string]$Folder
    )

    begin {
        Write-Verbose "Scanning project activity since $($Since.ToString('g'))"
    }

    process {
        $searchPath = if ($Folder) {
            Join-Path $BasePath $Folder
        } else {
            $BasePath
        }

        $params = @{
            Path        = $searchPath
            Recurse     = $true
            Filter      = '*.md'
            ErrorAction = 'SilentlyContinue'
        }
        Get-ChildItem @params |
            Where-Object { $_.LastWriteTime -ge $Since } |
            ForEach-Object {
                [PSCustomObject]@{
                    Name         = $_.BaseName
                    RelativePath = $_.FullName.Substring($BasePath.Length + 1)
                    Modified     = $_.LastWriteTime
                    SizeKB       = [math]::Round($_.Length / 1KB, 1)
                }
            } |
            Sort-Object Modified -Descending
    }
}

# --- Tab Completion (register at module load) ---

Register-ArgumentCompleter -CommandName 'Get-MyActivity' -ParameterName 'Folder' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $basePath = (Get-MyConfig).BasePath
    Get-ChildItem -Path (Join-Path $basePath "$wordToComplete*") -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            $rel = $_.FullName.Substring($basePath.Length + 1)
            [System.Management.Automation.CompletionResult]::new($rel, $rel, 'ParameterValue', $rel)
        }
}
```
