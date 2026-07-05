param(
  [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
)

$StudioDir  = Join-Path $ProjectRoot "tools\content_studio"
$KitDir     = Join-Path $StudioDir "writer_kit\Civilpedia_Writer_Kit"

Write-Host "=== Civilpedia Writer Kit Generator ===" -ForegroundColor Cyan
Write-Host "Project root : $ProjectRoot"
Write-Host "Studio dir   : $StudioDir"
Write-Host "Kit dir      : $KitDir"
Write-Host ""

# 1. Remove & recreate kit root
if (Test-Path -LiteralPath $KitDir) {
  Remove-Item -LiteralPath $KitDir -Recurse -Force
}
New-Item -ItemType Directory -Path $KitDir -Force | Out-Null

# 2. Copy index.html
Write-Host "[1/7] Copying index.html..." -NoNewline
Copy-Item -LiteralPath (Join-Path $StudioDir "index.html") -Destination $KitDir
Write-Host " OK" -ForegroundColor Green

# 3. Copy css/
Write-Host "[2/7] Copying css/ ..." -NoNewline
Copy-Item -LiteralPath (Join-Path $StudioDir "css") -Destination $KitDir -Recurse
Write-Host " OK" -ForegroundColor Green

# 4. Copy js/
Write-Host "[3/7] Copying js/ ..." -NoNewline
Copy-Item -LiteralPath (Join-Path $StudioDir "js") -Destination $KitDir -Recurse
Write-Host " OK" -ForegroundColor Green

# 5. Copy README_FOR_WRITERS.md
Write-Host "[4/7] Copying README_FOR_WRITERS.md ..." -NoNewline
Copy-Item -LiteralPath (Join-Path $StudioDir "README_FOR_WRITERS.md") -Destination $KitDir
Write-Host " OK" -ForegroundColor Green

# 6. Copy templates/
Write-Host "[5/7] Copying templates/ ..." -NoNewline
Copy-Item -LiteralPath (Join-Path $StudioDir "templates") -Destination $KitDir -Recurse
Write-Host " OK" -ForegroundColor Green

# 7. Create empty folders + .gitkeep
Write-Host "[6/7] Creating images_to_send_here/ ..." -NoNewline
New-Item -ItemType Directory -Path (Join-Path $KitDir "images_to_send_here") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path (Join-Path $KitDir "images_to_send_here") ".gitkeep") -Force | Out-Null
Write-Host " OK" -ForegroundColor Green

Write-Host "[7/7] Creating completed_drafts/ ..." -NoNewline
New-Item -ItemType Directory -Path (Join-Path $KitDir "completed_drafts") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path (Join-Path $KitDir "completed_drafts") ".gitkeep") -Force | Out-Null
Write-Host " OK" -ForegroundColor Green

Write-Host ""
Write-Host "=== Writer Kit created successfully ===" -ForegroundColor Cyan
Write-Host "Location: $KitDir"
Write-Host ""

# Show summary
Get-ChildItem -LiteralPath $KitDir -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
  Write-Host "  $($_.FullName.Replace($KitDir, ''))"
}
