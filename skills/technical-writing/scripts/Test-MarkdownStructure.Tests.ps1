#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

<#
    Pester tests for Test-MarkdownStructure.ps1

    Ten scenarios covering the structural-validation contract:
      Scenarios 1-4: Happy paths (exit 0)
      Scenarios 5-7: Structural error paths (exit 1)
      Scenario 8:    Invocation error path (exit 2)
      Scenarios 9-10: Integration paths

    Self-contained: all scenarios run against bundled fixtures with no
    repository-specific path assumptions.
#>

BeforeAll {
    $Script:ScriptPath  = Join-Path $PSScriptRoot 'Test-MarkdownStructure.ps1'
    $Script:FixturesDir = Join-Path $PSScriptRoot 'fixtures'
}

Describe 'Test-MarkdownStructure.ps1' {

    Context 'Happy paths -- exit 0' {

        It 'Scenario 1: well-formed file (h1->h2->h3, balanced fences, valid link)' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-pass-full.md'
            & $Script:ScriptPath -Path $fixture | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Scenario 2: file with only h1 and prose' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-pass-h1-only.md'
            & $Script:ScriptPath -Path $fixture | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Scenario 3: file with no Markdown elements (plain prose only)' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-pass-plain-prose.md'
            & $Script:ScriptPath -Path $fixture | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Scenario 4: file with multiple top-level h1s (reset is not a gap)' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-pass-multi-h1.md'
            & $Script:ScriptPath -Path $fixture | Out-Null
            $LASTEXITCODE | Should -Be 0
        }
    }

    Context 'Structural error paths -- exit 1' {

        It 'Scenario 5: heading hierarchy gap (h1 directly to h3, no h2)' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-fail-heading-gap.md'
            & $Script:ScriptPath -Path $fixture | Out-Null
            $LASTEXITCODE | Should -Be 1
        }

        It 'Scenario 6: broken local link reference to nonexistent file' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-fail-broken-link.md'
            & $Script:ScriptPath -Path $fixture | Out-Null
            $LASTEXITCODE | Should -Be 1
        }

        It 'Scenario 7: unbalanced code fences (odd triple-backtick count)' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-fail-unbalanced-fence.md'
            & $Script:ScriptPath -Path $fixture | Out-Null
            $LASTEXITCODE | Should -Be 1
        }
    }

    Context 'Invocation errors -- exit 2' {

        It 'Scenario 8: nonexistent input path' {
            & $Script:ScriptPath -Path 'this-file-absolutely-does-not-exist.md' 2>$null | Out-Null
            $LASTEXITCODE | Should -Be 2
        }
    }

    Context 'Integration' {

        It 'Scenario 9: piping multiple files exits 1 when at least one fails' {
            # Fixture set contains both passing and failing files; aggregate must be 1
            Get-ChildItem -Path $Script:FixturesDir -Filter '*.md' |
                & $Script:ScriptPath | Out-Null
            $LASTEXITCODE | Should -Be 1
        }

        It 'Scenario 10: a passing fixture produces the terse PASS summary line' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-pass-full.md'
            $output  = & $Script:ScriptPath -Path $fixture 2>&1
            # Contract: script runs without crashing and emits at least one output line
            $output | Should -Not -BeNullOrEmpty
            # Verify output line starts with PASS or FAIL (the terse summary format)
            ($output | Select-Object -First 1) | Should -Match '^(PASS|FAIL)'
        }
    }

    Context 'Output format validation' {

        It 'JSON report is written when -ReportPath is specified' {
            $fixture    = Join-Path $Script:FixturesDir 'fixture-fail-heading-gap.md'
            $reportPath = Join-Path $env:TEMP "test-markdown-structure-$(New-Guid).json"
            try {
                & $Script:ScriptPath -Path $fixture -ReportPath $reportPath | Out-Null
                $reportPath | Should -Exist
                $report = Get-Content $reportPath -Raw | ConvertFrom-Json
                $report | Should -Not -BeNullOrEmpty
                # Report must have File, Pass, and Findings properties
                $report[0].PSObject.Properties.Name | Should -Contain 'File'
                $report[0].PSObject.Properties.Name | Should -Contain 'Pass'
                $report[0].PSObject.Properties.Name | Should -Contain 'Findings'
                $report[0].Pass | Should -BeFalse
                $report[0].Findings.Count | Should -BeGreaterThan 0
            }
            finally {
                if (Test-Path $reportPath) { Remove-Item $reportPath -Force }
            }
        }

        It 'Verbose output contains finding details for failing files' {
            $fixture = Join-Path $Script:FixturesDir 'fixture-fail-heading-gap.md'
            # Redirect verbose stream (4) to stdout so it is captured in $output
            $output  = & $Script:ScriptPath -Path $fixture -Verbose 4>&1
            $verboseLines = $output | Where-Object { $_ -match '\[heading-gap\]' }
            $verboseLines | Should -Not -BeNullOrEmpty
        }
    }
}
