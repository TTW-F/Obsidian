param(
    [string]$Root = ".",
    [string[]]$IncludeDirs = @(),
    [int]$MinBacklinks = 2,
    [string[]]$AllowedTypes = @("area", "topic", "map"),
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-TargetRoots {
    param(
        [string]$RootPath,
        [string[]]$Dirs
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path
    if (-not $Dirs -or $Dirs.Count -eq 0) {
        return @($resolvedRoot)
    }

    $targets = @()
    foreach ($dir in $Dirs) {
        $candidate = if ([System.IO.Path]::IsPathRooted($dir)) {
            $dir
        } else {
            Join-Path $resolvedRoot $dir
        }

        if (Test-Path -LiteralPath $candidate) {
            $targets += (Resolve-Path -LiteralPath $candidate).Path
        } else {
            Write-Warning "Skip missing include dir: $candidate"
        }
    }
    return $targets
}

function Get-FrontmatterInfo {
    param([string]$Content)

    $result = [ordered]@{
        HasFrontmatter = $false
        Tags = @()
        Type = $null
    }

    if ($Content -notmatch "(?ms)\A---\r?\n(.*?)\r?\n---") {
        return [pscustomobject]$result
    }

    $result.HasFrontmatter = $true
    $frontmatter = $Matches[1]
    $lines = $frontmatter -split "\r?\n"
    $currentKey = $null

    foreach ($line in $lines) {
        if ($line -match "^(?<key>[A-Za-z0-9_-]+):\s*(?<value>.*)$") {
            $currentKey = $Matches["key"]
            $value = $Matches["value"].Trim()
            if ($currentKey -eq "type" -and $value) {
                $result.Type = $value
            } elseif ($currentKey -eq "tags" -and $value) {
                $result.Tags += $value
            }
            continue
        }

        if ($currentKey -eq "tags" -and $line -match "^\s*-\s*(.+?)\s*$") {
            $result.Tags += $Matches[1]
        }
    }

    $result.Tags = @($result.Tags | Where-Object { $_ } | Select-Object -Unique)
    return [pscustomobject]$result
}

function Get-SectionHeadings {
    param([string]$Content)
    return @([regex]::Matches($Content, '(?m)^##\s+(.+?)\s*$') | ForEach-Object { $_.Groups[1].Value.Trim() })
}

function Get-WikiLinks {
    param([string]$Content)
    return @([regex]::Matches($Content, '\[\[([^\]]+)\]\]') | ForEach-Object {
        $raw = $_.Groups[1].Value.Trim()
        if ($raw.Contains("|")) {
            $raw = $raw.Split("|")[0].Trim()
        }
        if ($raw.Contains("#")) {
            $raw = $raw.Split("#")[0].Trim()
        }
        $raw = $raw -replace '/', '\'
        if ($raw.Contains("\")) {
            $raw = ($raw.Split("\") | Where-Object { $_ })[-1]
        }
        $raw
    } | Where-Object { $_ } | Select-Object -Unique)
}

function New-Issue {
    param(
        [string]$Path,
        [string]$Kind,
        [string]$Message
    )

    [pscustomobject]@{
        path = $Path
        kind = $Kind
        message = $Message
    }
}

$targetRoots = Resolve-TargetRoots -RootPath $Root -Dirs $IncludeDirs
$allMarkdownFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter "*.md" |
    Where-Object { $_.FullName -notmatch '\\\.git\\|\\\.obsidian\\|\\\.codex\\' }

$files = @()
foreach ($targetRoot in $targetRoots) {
    $files += Get-ChildItem -LiteralPath $targetRoot -Recurse -File -Filter "*.md"
}
$files = $files | Sort-Object FullName -Unique

$contentByPath = @{}
$nameByPath = @{}
$pathByBaseName = @{}

foreach ($file in $allMarkdownFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $contentByPath[$file.FullName] = $content
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $nameByPath[$file.FullName] = $baseName
    if (-not $pathByBaseName.ContainsKey($baseName)) {
        $pathByBaseName[$baseName] = @()
    }
    $pathByBaseName[$baseName] += $file.FullName
}

$backlinkCount = @{}
foreach ($path in $contentByPath.Keys) {
    $backlinkCount[$path] = 0
}

foreach ($entry in $contentByPath.GetEnumerator()) {
    $sourcePath = $entry.Key
    $links = Get-WikiLinks -Content $entry.Value
    foreach ($link in $links) {
        if ($pathByBaseName.ContainsKey($link)) {
            foreach ($targetPath in $pathByBaseName[$link]) {
                if ($targetPath -ne $sourcePath) {
                    $backlinkCount[$targetPath]++
                }
            }
        }
    }
}

$issues = @()
$summaries = @()

foreach ($file in $files) {
    $path = $file.FullName
    $content = $contentByPath[$path]
    $name = $nameByPath[$path]
    $frontmatter = Get-FrontmatterInfo -Content $content
    $headings = Get-SectionHeadings -Content $content
    $links = Get-WikiLinks -Content $content
    $localIssues = @()

    if (-not $frontmatter.HasFrontmatter) {
        $localIssues += New-Issue -Path $path -Kind "frontmatter" -Message "Missing frontmatter block."
    }

    if (-not $frontmatter.Type) {
        $localIssues += New-Issue -Path $path -Kind "type" -Message "Missing type in frontmatter."
    } elseif ($AllowedTypes.Count -gt 0 -and $frontmatter.Type -notin $AllowedTypes) {
        $localIssues += New-Issue -Path $path -Kind "type" -Message "Unexpected type '$($frontmatter.Type)'. Allowed: $($AllowedTypes -join ', ')."
    }

    if (-not $frontmatter.Tags -or $frontmatter.Tags.Count -eq 0) {
        $localIssues += New-Issue -Path $path -Kind "tags" -Message "Missing tags in frontmatter."
    }

    if ($headings -notcontains "相关笔记") {
        $localIssues += New-Issue -Path $path -Kind "section" -Message "Missing '相关笔记' section."
    }

    if ($links.Count -eq 0) {
        $localIssues += New-Issue -Path $path -Kind "links" -Message "No wiki links found."
    }

    $incoming = if ($backlinkCount.ContainsKey($path)) { $backlinkCount[$path] } else { 0 }
    if ($incoming -lt $MinBacklinks) {
        $localIssues += New-Issue -Path $path -Kind "backlinks" -Message "Low backlinks: $incoming (< $MinBacklinks)."
    }

    $issues += $localIssues
    $summaries += [pscustomobject]@{
        path = $path
        name = $name
        type = $frontmatter.Type
        tags = @($frontmatter.Tags)
        has_frontmatter = $frontmatter.HasFrontmatter
        has_related_notes = ($headings -contains "相关笔记")
        wiki_link_count = $links.Count
        backlink_count = $incoming
        issue_count = $localIssues.Count
    }
}

$report = [pscustomobject]@{
    root = (Resolve-Path -LiteralPath $Root).Path
    include_dirs = $targetRoots
    min_backlinks = $MinBacklinks
    file_count = $summaries.Count
    issue_count = $issues.Count
    issues = $issues
    summaries = $summaries
}

if ($AsJson) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Output "Obsidian Note Audit"
Write-Output "Root: $($report.root)"
Write-Output "Scopes: $($targetRoots -join '; ')"
Write-Output "Files: $($report.file_count)"
Write-Output "Issues: $($report.issue_count)"
Write-Output ""

if ($issues.Count -eq 0) {
    Write-Output "No issues found."
    exit 0
}

$issues |
    Group-Object kind |
    Sort-Object Count -Descending |
    ForEach-Object {
        Write-Output ("[{0}] {1}" -f $_.Name, $_.Count)
        $_.Group | ForEach-Object {
            Write-Output ("  - {0} :: {1}" -f $_.path, $_.message)
        }
        Write-Output ""
    }
