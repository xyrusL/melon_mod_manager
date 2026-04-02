param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('stable', 'prerelease', 'beta')]
  [string]$Channel,

  [string]$Remote = 'origin',

  [switch]$Push
)

$ErrorActionPreference = 'Stop'

function Get-PubspecVersion {
  if (!(Test-Path 'pubspec.yaml')) {
    throw "pubspec.yaml not found. Run this script from repository root."
  }
  $match = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$' | Select-Object -First 1
  if ($null -eq $match) {
    throw "Could not find version field in pubspec.yaml."
  }
  $raw = $match.Matches[0].Groups[1].Value.Trim()
  if ([string]::IsNullOrWhiteSpace($raw)) {
    throw "pubspec.yaml version is empty."
  }
  return $raw.Split('+')[0]
}

function Ensure-CleanGitTree {
  $status = git status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to read git status."
  }
  if (-not [string]::IsNullOrWhiteSpace($status)) {
    throw "Working tree is not clean. Commit/stash changes before tagging."
  }
}

function Validate-ChannelVersion {
  param(
    [string]$Version,
    [string]$Channel
  )

  if ($Channel -eq 'prerelease') {
    if ($Version -notmatch '-') {
      throw "Channel '$Channel' requires a prerelease version like 1.2.0-beta.1."
    }
    return
  }

  if ($Channel -eq 'beta') {
    if ($Version -notmatch '-beta(\.\d+)*$') {
      throw "Channel 'beta' requires version suffix '-beta' or '-beta.N[.N]'. Current: $Version"
    }
    return
  }

  if ($Channel -eq 'stable') {
    if ($Version -notmatch '^\d+\.\d+\.\d+$' -and $Version -notmatch '^\d+\.\d+\.\d+-\d{4}\.\d{2}\.\d{2}$') {
      throw "Channel 'stable' requires version format 'MAJOR.MINOR.PATCH' or 'MAJOR.MINOR.PATCH-YYYY.MM.DD'. Current: $Version"
    }
    return
  }
}

function Ensure-TagMissing {
  param([string]$TagName)
  git rev-parse --verify --quiet "refs/tags/$TagName" > $null
  if ($LASTEXITCODE -eq 0) {
    throw "Tag '$TagName' already exists."
  }
}

Ensure-CleanGitTree
$appVersion = Get-PubspecVersion
Validate-ChannelVersion -Version $appVersion -Channel $Channel

$tag = "v$appVersion"
Ensure-TagMissing -TagName $tag

Write-Host "Channel: $Channel"
Write-Host "Version: $appVersion"
Write-Host "Tag:     $tag"

git tag -a $tag -m "Release $tag"
if ($LASTEXITCODE -ne 0) {
  throw "Failed to create git tag."
}

if ($Push) {
  git push $Remote $tag
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to push tag '$tag' to remote '$Remote'."
  }
  Write-Host "Tag pushed. GitHub Actions release workflow should start."
} else {
  Write-Host "Tag created locally."
  Write-Host "Push it with: git push $Remote $tag"
}
