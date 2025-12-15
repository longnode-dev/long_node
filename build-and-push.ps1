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

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$imageBase = "longnode/calibre-web-longnode"

Write-Host "Git Hash: $gitHash" -ForegroundColor Green
Write-Host "Timestamp: $timestamp" -ForegroundColor Green
Write-Host "Image: $imageBase" -ForegroundColor Green
Write-Host ""

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
Write-Host "Platform: linux/amd64 (for Synology DS1522+)" -ForegroundColor Gray
Write-Host ""

docker build --platform linux/amd64 -t "${imageBase}:${gitHash}" .

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
Write-Host "Images available at:" -ForegroundColor White
Write-Host "  - ${imageBase}:${gitHash}" -ForegroundColor Cyan
Write-Host "  - ${imageBase}:latest" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open Portainer on Synology" -ForegroundColor White
Write-Host "  2. Go to Images -> Pull image" -ForegroundColor White
Write-Host "  3. Pull: ${imageBase}:latest" -ForegroundColor White
Write-Host "  4. Go to Containers -> calibre-web -> Recreate" -ForegroundColor White
Write-Host "  5. Enable 'Pull latest image' checkbox" -ForegroundColor White
Write-Host "  6. Deploy!" -ForegroundColor White
Write-Host ""
Write-Host "Or run this command via SSH on Synology:" -ForegroundColor Yellow
Write-Host "  docker pull ${imageBase}:latest && docker restart calibre-web" -ForegroundColor Gray
Write-Host ""
