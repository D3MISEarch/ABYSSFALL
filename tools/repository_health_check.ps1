[CmdletBinding()]
param(
	[string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
	param([string]$Message)
	$script:failures.Add($Message)
}

function Get-AbsoluteRepositoryPath {
	param([string]$RelativePath)
	return [System.IO.Path]::GetFullPath((Join-Path $RepositoryRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
}

function Get-TrackedFiles {
	param([string[]]$Patterns)
	return @(& git -C $RepositoryRoot ls-files -- @Patterns)
}

if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot '.git'))) {
	throw "Repository root does not contain Git metadata: $RepositoryRoot"
}

$adrDirectory = Join-Path $RepositoryRoot 'Docs/ADR'
$adrFiles = @(Get-ChildItem -LiteralPath $adrDirectory -File -Filter '*.md' | Sort-Object Name)
$adrNumbers = @{}
$allowedStatusValues = @(
	'APPROVED',
	'PROPOSED',
	'ACCEPTED FOR STAGE 5 IMPLEMENTATION',
	'ACCEPTED — MERGED',
	'OWNER APPROVED AT DESIGN-FOUNDATION LEVEL',
	'OWNER APPROVED — PENDING MERGE'
)

foreach ($adrFile in $adrFiles) {
	$nameMatch = [regex]::Match($adrFile.Name, '^ADR-(?<number>\d{3})-[A-Z0-9-]+\.md$')
	if (-not $nameMatch.Success) {
		Add-Failure "ADR filename is not canonical: $($adrFile.Name)"
		continue
	}

	$number = [int]$nameMatch.Groups['number'].Value
	if ($adrNumbers.ContainsKey($number)) {
		Add-Failure "Duplicate ADR number ADR-$('{0:d3}' -f $number): $($adrNumbers[$number].Name), $($adrFile.Name)"
	} else {
		$adrNumbers[$number] = $adrFile
	}

	$content = Get-Content -LiteralPath $adrFile.FullName -Raw
	$titleMatch = [regex]::Match($content, '(?m)^# ADR-(?<number>\d{3})(?:\s|:|—)')
	if (-not $titleMatch.Success -or [int]$titleMatch.Groups['number'].Value -ne $number) {
		Add-Failure "ADR heading does not match filename: $($adrFile.Name)"
	}

	$statusMatch = [regex]::Match($content, '(?ms)^## Status\r?\n\r?\n(?<value>[^\r\n]+)')
	if (-not $statusMatch.Success) {
		Add-Failure "ADR is missing the canonical Status section: $($adrFile.Name)"
	} elseif ($allowedStatusValues -notcontains $statusMatch.Groups['value'].Value.Trim()) {
		Add-Failure "ADR has an unsupported status value: $($adrFile.Name)"
	}
}

$reservedAdrNumbers = @(19)
foreach ($number in 10..21) {
	if (-not $adrNumbers.ContainsKey($number) -and $reservedAdrNumbers -notcontains $number) {
		Add-Failure "Missing ADR-$('{0:d3}' -f $number)"
	}
}
foreach ($number in $reservedAdrNumbers) {
	if ($adrNumbers.ContainsKey($number)) {
		Add-Failure "ADR-$('{0:d3}' -f $number) is reserved and must not have a record until its reviewed decision is restored"
	}
}

$markdownFiles = @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -File -Filter '*.md')
foreach ($markdownFile in $markdownFiles) {
	$content = Get-Content -LiteralPath $markdownFile.FullName -Raw
	foreach ($match in [regex]::Matches($content, 'ADR-(?<number>\d{3})')) {
		$number = [int]$match.Groups['number'].Value
		if (-not $adrNumbers.ContainsKey($number) -and $reservedAdrNumbers -notcontains $number) {
			Add-Failure "Missing ADR reference ADR-$('{0:d3}' -f $number) in $($markdownFile.FullName)"
		}
	}
	foreach ($match in [regex]::Matches($content, '\]\((?<target>[^)#]+(?:Docs/)?ADR/[^)#]+\.md)(?:#[^)]+)?\)')) {
		$target = $match.Groups['target'].Value.Trim('<>')
		$targetPath = [System.IO.Path]::GetFullPath((Join-Path $markdownFile.DirectoryName ($target -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
		if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
			Add-Failure "Broken ADR Markdown link in $($markdownFile.FullName): $target"
		}
	}
}

$trackedScripts = @(Get-TrackedFiles @('*.gd'))
$trackedUidFiles = @(Get-TrackedFiles @('*.gd.uid'))
$gitignoreContent = Get-Content -LiteralPath (Join-Path $RepositoryRoot '.gitignore') -Raw
if ($gitignoreContent -match '(?m)^\s*\*\.uid\s*$') {
	Add-Failure 'The tracked-sidecar policy must not ignore *.uid files'
}
$gitattributesContent = Get-Content -LiteralPath (Join-Path $RepositoryRoot '.gitattributes') -Raw
foreach ($requiredAttribute in @('*.import text eol=lf', '*.gd.uid text eol=lf')) {
	if ($gitattributesContent -notmatch [regex]::Escape($requiredAttribute)) {
		Add-Failure "Missing Godot metadata line-ending rule: $requiredAttribute"
	}
}
$trackedUidSet = @{}
foreach ($uidFile in $trackedUidFiles) {
	$trackedUidSet[$uidFile] = $true
}
foreach ($scriptFile in $trackedScripts) {
	$expectedUidFile = "$scriptFile.uid"
	if (-not $trackedUidSet.ContainsKey($expectedUidFile)) {
		Add-Failure "Missing tracked Godot UID sidecar: $expectedUidFile"
	}
}
foreach ($uidFile in $trackedUidFiles) {
	$scriptFile = $uidFile.Substring(0, $uidFile.Length - 4)
	if ($trackedScripts -notcontains $scriptFile) {
		Add-Failure "Orphan tracked Godot UID sidecar: $uidFile"
	}
}

$untrackedUidFiles = @(& git -C $RepositoryRoot ls-files --others --exclude-standard -- '*.uid')
foreach ($uidFile in $untrackedUidFiles) {
	Add-Failure "Untracked Godot UID sidecar violates the tracked-sidecar policy: $uidFile"
}

$uidDefinitions = @{}
foreach ($uidFile in @(Get-TrackedFiles @('*.gd.uid', '*.import'))) {
	$uidPath = Get-AbsoluteRepositoryPath $uidFile
	$content = Get-Content -LiteralPath $uidPath -Raw
	foreach ($match in [regex]::Matches($content, 'uid://[A-Za-z0-9]+')) {
		$uid = $match.Value
		if ($uidDefinitions.ContainsKey($uid) -and $uidDefinitions[$uid] -ne $uidFile) {
			Add-Failure "Duplicate UID declaration $uid in $uidFile and $($uidDefinitions[$uid])"
		} else {
			$uidDefinitions[$uid] = $uidFile
		}
	}
}
foreach ($projectFile in @(Get-TrackedFiles @('*.gd', '*.tscn', '*.tres', '*.res', '*.import', 'project.godot'))) {
	$projectPath = Get-AbsoluteRepositoryPath $projectFile
	$content = Get-Content -LiteralPath $projectPath -Raw
	foreach ($match in [regex]::Matches($content, 'uid://[A-Za-z0-9]+')) {
		if (-not $uidDefinitions.ContainsKey($match.Value)) {
			Add-Failure "UID reference has no tracked declaration: $($match.Value) in $projectFile"
		}
	}
}

$trackedFiles = @(Get-TrackedFiles @())
$caseDuplicateGroups = @($trackedFiles | Group-Object { $_.ToLowerInvariant() } | Where-Object { $_.Count -gt 1 })
foreach ($group in $caseDuplicateGroups) {
	Add-Failure "Case-insensitive duplicate tracked paths: $($group.Group -join ', ')"
}

$workflowFiles = @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot '.github/workflows') -File -Filter '*.yml')
foreach ($workflowFile in $workflowFiles) {
	$content = Get-Content -LiteralPath $workflowFile.FullName -Raw
	$workflowPaths = New-Object System.Collections.Generic.List[string]
	foreach ($match in [regex]::Matches($content, '["''](?<path>(?:scripts|tests|scenes)/[^"'']+)["'']')) {
		$workflowPaths.Add($match.Groups['path'].Value)
	}
	foreach ($match in [regex]::Matches($content, 'res://(?<path>[^\s"'']+\.gd)')) {
		$workflowPaths.Add($match.Groups['path'].Value)
	}
	foreach ($workflowPath in ($workflowPaths | Sort-Object -Unique)) {
		if ($workflowPath.IndexOfAny([char[]]'*?[$') -ge 0) {
			continue
		}
		if (-not (Test-Path -LiteralPath (Get-AbsoluteRepositoryPath $workflowPath))) {
			Add-Failure "Workflow path target does not exist: $($workflowFile.Name) -> $workflowPath"
		}
	}
}

if ($failures.Count -gt 0) {
	Write-Output "FAIL: Repository health check found $($failures.Count) violation(s):"
	foreach ($failure in $failures) {
		Write-Output "FAIL: $failure"
	}
	exit 1
}

Write-Output "PASS: ADR inventory ($($adrNumbers.Count) records; ADR-019 reserved)"
Write-Output "PASS: tracked Godot UID sidecars ($($trackedUidFiles.Count) for $($trackedScripts.Count) scripts; LF metadata policy)"
Write-Output "PASS: UID declarations and references"
Write-Output "PASS: no case-insensitive duplicate tracked paths"
Write-Output "PASS: workflow path targets"
