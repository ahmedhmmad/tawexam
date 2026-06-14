<#
.SYNOPSIS
  Build the Flutter Web admin panel, commit the bundle, and push to main.

.DESCRIPTION
  The admin panel is served from the committed build/web/ directory, so merging
  Dart source is NOT enough — the bundle must be rebuilt and pushed for changes
  to appear. This script does build -> force-add -> commit -> push in one step,
  with a sanity check that the new bundle actually contains the compiled code,
  so the deployed bundle can never silently lag the source again.

  After this runs, deploy on the server with:
    cd /opt/tawjihi && git pull origin main && cp -r build/web/* admin-web/

.PARAMETER ApiBaseUrl
  The backend API base URL compiled into the bundle.

.PARAMETER Message
  The git commit message.

.PARAMETER SkipPush
  Build and commit but do not push (for local verification).

.EXAMPLE
  ./scripts/deploy-admin-web.ps1 -Message "Add user roles UI"
#>
[CmdletBinding()]
param(
  [string]$ApiBaseUrl = "https://tawjihi.megaserv.xyz/api/v1",
  [string]$Message = "Build admin web",
  [switch]$SkipPush
)

$ErrorActionPreference = "Stop"
# Run from the repo root regardless of where the script is invoked.
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host "==> Building admin web (API_BASE_URL=$ApiBaseUrl)..." -ForegroundColor Cyan
flutter build web --release `
  --base-href="/admin/" `
  --dart-define=API_BASE_URL=$ApiBaseUrl `
  --target=lib/main_admin.dart
if ($LASTEXITCODE -ne 0) { throw "flutter build web failed" }

$bundle = "build/web/main.dart.js"
if (-not (Test-Path $bundle)) { throw "Expected $bundle was not produced" }

# Sanity check: the compiled bundle must reference a known admin route. Catches
# the case where the build was run against stale/wrong source.
if (-not (Select-String -Path $bundle -Pattern "admin/auth/login" -Quiet)) {
  throw "Sanity check failed: '$bundle' does not contain the admin login route. Aborting."
}
Write-Host "==> Bundle sanity check passed." -ForegroundColor Green

Write-Host "==> Committing build/web..." -ForegroundColor Cyan
# build/ is gitignored, so force-add the web output.
git add -f build/web
if (git diff --cached --quiet) {
  Write-Host "No bundle changes to commit (source already built)." -ForegroundColor Yellow
  exit 0
}
git commit -m $Message

if ($SkipPush) {
  Write-Host "==> -SkipPush set; committed but not pushed." -ForegroundColor Yellow
  exit 0
}

Write-Host "==> Pushing to origin/main..." -ForegroundColor Cyan
git push origin main
if ($LASTEXITCODE -ne 0) { throw "git push failed (pull/rebase and retry)" }

Write-Host ""
Write-Host "Done. Deploy on the server with:" -ForegroundColor Green
Write-Host "  cd /opt/tawjihi && git pull origin main && cp -r build/web/* admin-web/" -ForegroundColor Green
