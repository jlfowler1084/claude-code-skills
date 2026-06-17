BeforeAll { $script:repo = $PSScriptRoot }

Describe 'install.ps1' {
    It 'mirrors the skill into each selected target under -Root' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("pc-" + [guid]::NewGuid())
        & "$repo/install.ps1" -Root $root -Targets Claude, Codex, Gemini, Qwen
        Test-Path "$root/.claude/skills/packet-capture/SKILL.md"  | Should -BeTrue
        Test-Path "$root/.agents/skills/packet-capture/SKILL.md"  | Should -BeTrue   # Codex
        Test-Path "$root/.gemini/skills/packet-capture/SKILL.md"  | Should -BeTrue
        Test-Path "$root/.qwen/skills/packet-capture/SKILL.md"    | Should -BeTrue
        Remove-Item $root -Recurse -Force
    }
    It 'honors a narrowed -Targets set' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("pc-" + [guid]::NewGuid())
        & "$repo/install.ps1" -Root $root -Targets Claude
        Test-Path "$root/.claude/skills/packet-capture/SKILL.md" | Should -BeTrue
        Test-Path "$root/.agents/skills/packet-capture/SKILL.md" | Should -BeFalse
        Remove-Item $root -Recurse -Force
    }
    It 'is idempotent: re-running does not nest packet-capture inside packet-capture' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("pc-" + [guid]::NewGuid())
        & "$repo/install.ps1" -Root $root -Targets Claude
        & "$repo/install.ps1" -Root $root -Targets Claude
        Test-Path "$root/.claude/skills/packet-capture/packet-capture" | Should -BeFalse
        Test-Path "$root/.claude/skills/packet-capture/SKILL.md"       | Should -BeTrue
        Remove-Item $root -Recurse -Force
    }
}
