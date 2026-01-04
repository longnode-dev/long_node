# Calibre-Web Long Node - Build and Push Script
# Builds Docker image and pushes to Docker Hub

# Exit on any error
$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Calibre-Web Long Node - Docker Build" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Get git commit hash for versioning
$gitHash = git rev-parse --short HEAD
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get git hash. Are you in a git repository?" -ForegroundColor Red
    exit 1
}

# Get human-readable build timestamp
$buildTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$imageBase = "longnode/calibre-web-longnode"

Write-Host "Git Hash: $gitHash" -ForegroundColor Green
Write-Host "Build Time: $buildTimestamp" -ForegroundColor Green
Write-Host "Image: $imageBase" -ForegroundColor Green
Write-Host ""

# Build the Docker image with build args for version info
Write-Host "Building Docker image..." -ForegroundColor Yellow
Write-Host "Platform: linux/amd64 (for Synology DS1522+)" -ForegroundColor Gray
Write-Host ""

docker build --platform linux/amd64 `
    --build-arg BUILD_TIMESTAMP="$buildTimestamp" `
    --build-arg BUILD_GIT_HASH="$gitHash" `
    -t "${imageBase}:${gitHash}" .

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build successful!" -ForegroundColor Green
Write-Host ""

# Tag as latest
Write-Host "Tagging as :latest..." -ForegroundColor Yellow
docker tag "${imageBase}:${gitHash}" "${imageBase}:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to tag image!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Images created:" -ForegroundColor Green
Write-Host "  - ${imageBase}:${gitHash}" -ForegroundColor White
Write-Host "  - ${imageBase}:latest" -ForegroundColor White
Write-Host ""

# Push to Docker Hub
Write-Host "Pushing to Docker Hub..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Pushing :${gitHash}..." -ForegroundColor Gray
docker push "${imageBase}:${gitHash}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to push ${gitHash} tag!" -ForegroundColor Red
    Write-Host "Make sure you're logged in: docker login" -ForegroundColor Yellow
    exit 1
}

Write-Host "Pushing :latest..." -ForegroundColor Gray
docker push "${imageBase}:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to push latest tag!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "SUCCESS! Images pushed to Docker Hub" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Build Info:" -ForegroundColor White
Write-Host "  Git Hash:    $gitHash" -ForegroundColor Cyan
Write-Host "  Build Time:  $buildTimestamp" -ForegroundColor Cyan
Write-Host ""
Write-Host "Images available at:" -ForegroundColor White
Write-Host "  - ${imageBase}:${gitHash}" -ForegroundColor Cyan
Write-Host "  - ${imageBase}:latest" -ForegroundColor Cyan
Write-Host ""

# Verification instructions
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "VERIFICATION" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "After deployment, verify the build at:" -ForegroundColor White
Write-Host "  Internal: http://192.168.0.10:8083/version" -ForegroundColor Cyan
Write-Host "  External: https://books.waqasahmed.com/version" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected response:" -ForegroundColor White
Write-Host "  {" -ForegroundColor Gray
Write-Host "    `"git_hash`": `"$gitHash`"," -ForegroundColor Gray
Write-Host "    `"build_timestamp`": `"$buildTimestamp`"" -ForegroundColor Gray
Write-Host "  }" -ForegroundColor Gray
Write-Host ""
Write-Host "Or check the About page: /stats" -ForegroundColor White
Write-Host ""

# Optional: Auto-verify after deployment (requires site to be accessible)
$verifyUrl = "https://books.waqasahmed.com/version"
Write-Host "Attempting to verify deployment..." -ForegroundColor Yellow
Write-Host "(This may fail if Watchtower hasn't updated yet)" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $verifyUrl -TimeoutSec 10 -ErrorAction SilentlyContinue
    if ($response.git_hash -eq $gitHash) {
        Write-Host "VERIFIED: Production is running $gitHash" -ForegroundColor Green
    } else {
        Write-Host "PENDING: Production is running $($response.git_hash), expected $gitHash" -ForegroundColor Yellow
        Write-Host "Wait for Watchtower to update, or manually recreate in Portainer" -ForegroundColor Gray
    }
} catch {
    Write-Host "Could not verify (site may require auth or Watchtower hasn't updated yet)" -ForegroundColor Gray
    Write-Host "Manually check: $verifyUrl" -ForegroundColor Gray
}

Write-Host ""
