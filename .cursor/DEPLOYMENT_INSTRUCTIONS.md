# Long Node Deployment Guide

Complete guide for building and deploying Long Node (custom Calibre-Web) to Synology NAS.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Building Docker Images](#building-docker-images)
3. [Pushing to Docker Hub](#pushing-to-docker-hub)
4. [Deploying to Synology](#deploying-to-synology)
5. [Automatic Updates with Watchtower](#automatic-updates-with-watchtower)
6. [Troubleshooting](#troubleshooting)
7. [Quick Reference](#quick-reference)

---

## Architecture Overview

### Development (Windows)
- **Location**: `c:\github\long_node\repo`
- **Python**: 3.11.9 (virtual environment)
- **Dev Server**: Direct Python execution on port 8083
- **Calibre Library**: `c:\github\long_node\dev\calibre` (local copy for testing)

### Production (Synology DS1522+)
- **Container**: Custom Docker image based on LinuxServer.io Calibre-Web
- **Registry**: Docker Hub → `longnode/calibre-web-longnode:latest`
- **Network**: `calibre-web_default` (shared with cloudflared container)
- **Volumes**:
  - `/volume1/docker/calibre-web/config` → `/config` (settings, users, theme config)
  - `/volume1/Media/Books/calibre` → `/books` (Calibre library with metadata.db)
- **Port**: 8083:8083
- **Domain**: `https://books.waqasahmed.com` (via Cloudflare Tunnel)

### Key Design Decision: Why LinuxServer Base Image?

**We extend the official LinuxServer.io Calibre-Web image** instead of building from scratch:

✅ **Proven PUID/PGID handling** - Permissions work correctly with Synology  
✅ **s6-overlay init system** - Robust process management  
✅ **All dependencies pre-configured** - ImageMagick, Ghostscript, etc.  
✅ **Minimal changes** - We only copy our customized files on top  
✅ **Easy rollback** - Can revert to upstream if needed  

Our Dockerfile simply does:
```dockerfile
FROM lscr.io/linuxserver/calibre-web:latest
COPY cps/ /app/calibre-web/cps/  # Our customizations
```

---

## Building Docker Images

### Prerequisites

1. **Docker Desktop installed** on Windows
2. **Docker Hub account** (username: `longnode`)
3. **Logged into Docker Hub**: Run `docker login` once

### Build Process

The build process is fully automated via PowerShell script:

```powershell
cd c:\github\long_node\repo
.\build-and-push.ps1
```

### What the Script Does

1. **Gets git hash** for version tagging (e.g., `d1ad73e7`)
2. **Builds Docker image** for `linux/amd64` platform (DS1522+ architecture)
3. **Tags image** with both git hash and `:latest`
4. **Pushes to Docker Hub**:
   - `longnode/calibre-web-longnode:d1ad73e7` (specific version)
   - `longnode/calibre-web-longnode:latest` (always newest)
5. **Displays next steps** for Synology deployment

### Build Output Example

```
Git Hash: d1ad73e7
Building Docker image...
Platform: linux/amd64 (for Synology DS1522+)

Build successful!
Images created:
  - longnode/calibre-web-longnode:d1ad73e7
  - longnode/calibre-web-longnode:latest

Pushing to Docker Hub...
SUCCESS! Images pushed to Docker Hub
```

### Build Efficiency Tips

**Docker Layer Caching**: Subsequent builds are FAST (~10 seconds) because:
- Base LinuxServer image is cached
- Only changed files are re-copied
- Most layers are reused

**If build is slow**:
- First build downloads ~213 MB base image (one-time)
- Check Docker Desktop is running
- Check internet connection to Docker Hub

**Testing locally before pushing**:
```powershell
# Build without pushing
docker build --platform linux/amd64 -t longnode-test:local .

# Test locally
docker run -d --name longnode-test -p 8084:8083 \
  -e PUID=1027 -e PGID=100 -e TZ=America/Los_Angeles \
  -v "c:/github/long_node/dev/calibre:/books" \
  longnode-test:local

# Test at http://localhost:8084
# Clean up when done
docker stop longnode-test && docker rm longnode-test
```

---

## Pushing to Docker Hub

### Authentication

**One-time setup**:
```powershell
docker login
# Username: longnode
# Password: [your Docker Hub password]
```

Credentials are stored in `%USERPROFILE%\.docker\config.json` and persist across sessions.

### Automated Push

The `build-and-push.ps1` script handles pushing automatically. If you need to push manually:

```powershell
docker push longnode/calibre-web-longnode:latest
docker push longnode/calibre-web-longnode:d1ad73e7  # Specific version
```

### Registry Access

- **Repository**: https://hub.docker.com/r/longnode/calibre-web-longnode
- **Visibility**: Public (anyone can pull, only you can push)
- **Tags**: Automatically created by build script

---

## Deploying to Synology

### First-Time Deployment

**IMPORTANT**: Only needed once when switching from LinuxServer.io to Long Node.

#### Step 1: Pull Image to Synology

Via Portainer (http://192.168.0.10:9000):
1. Go to **Images** (left sidebar)
2. Click **Pull image** button
3. Enter: `longnode/calibre-web-longnode:latest`
4. Click **Pull the image**
5. Wait ~30 seconds for download

#### Step 2: Replace Existing Container

1. Go to **Containers** → Find `calibre-web`
2. **Stop** the container (checkbox → Stop button)
3. Click container name to see details
4. Click **Duplicate/Edit** button at top
5. Change **Image** field from:
   - OLD: `lscr.io/linuxserver/calibre-web:latest`
   - NEW: `longnode/calibre-web-longnode:latest`
6. **CRITICAL**: Verify these are preserved:
   - **Network**: `calibre-web_default` ⚠️ (Required for Cloudflare Tunnel!)
   - **Environment**: PUID=1027, PGID=100, TZ=America/Los_Angeles
   - **Volumes**: `/volume1/docker/calibre-web/config` → `/config`
   - **Volumes**: `/volume1/Media/Books/calibre` → `/books`
   - **Port**: 8083:8083
7. Click **Deploy the container**
8. Portainer will ask "Replace existing container?" → Click **Replace**
9. Wait 30-60 seconds for container to start
10. Delete the old stopped container

#### Step 3: Verify Deployment

**Internal Test** (http://192.168.0.10:8083):
- ✅ Site loads
- ✅ Long Node favicon visible (orange/purple gradient)
- ✅ Inter font throughout UI
- ✅ Purple/orange color scheme
- ✅ Custom book detail layout
- ✅ Books display correctly

**External Test** (https://books.waqasahmed.com):
- ✅ Cloudflare Access authentication works
- ✅ Email-based auto-login works
- ✅ Theme looks identical to internal
- ✅ All features functional

**If container won't start**: Wait 60 seconds. Container startup takes time.

---

## Future Updates (After First Deployment)

### The Simple Way

Once Long Node is deployed, future updates are easy:

#### On Windows (Build & Push):
```powershell
cd c:\github\long_node\repo
.\build-and-push.ps1
# Takes ~30 seconds
```

#### On Synology (Deploy):

**Method 1: Quick Recreate** (Fastest - 2 clicks):
1. Go to **Containers** in Portainer
2. Select `calibre-web` checkbox
3. Click **Recreate** button at top
4. Check **Re-pull image** checkbox
5. Click **Recreate**
6. Wait 60 seconds
7. Done! ✅

**Method 2: Manual Pull then Recreate**:
1. **Images** → Pull `longnode/calibre-web-longnode:latest`
2. **Containers** → Select `calibre-web` → **Recreate**
3. Done!

**Total time**: 2-3 minutes from code change to live on Synology.

---

## Automatic Updates with Watchtower

### What is Watchtower?

Watchtower automatically monitors Docker Hub for new images and updates your containers.

**With Watchtower**: Push to Docker Hub → Wait 5 minutes → Synology auto-updates  
**Without Watchtower**: Push to Docker Hub → Manually recreate in Portainer

### Setup Watchtower

#### Option A: Via Portainer Stacks

1. Go to **Stacks** → **Add stack**
2. Name: `watchtower`
3. Paste this docker-compose:

```yaml
version: "2.1"
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_POLL_INTERVAL=300      # Check every 5 minutes
      - WATCHTOWER_CLEANUP=true           # Remove old images
      - WATCHTOWER_INCLUDE_STOPPED=false  # Only monitor running containers
      - WATCHTOWER_NO_STARTUP_MESSAGE=true
    command: calibre-web  # Only monitor calibre-web container
```

4. Click **Deploy the stack**

#### Option B: Add to Existing docker-compose.yml

If you manage calibre-web via docker-compose, add watchtower service to the same file:

```yaml
version: "2.1"
services:
  calibre-web:
    image: longnode/calibre-web-longnode:latest
    container_name: calibre-web
    # ... existing config ...

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_POLL_INTERVAL=300
      - WATCHTOWER_CLEANUP=true
    command: calibre-web
```

### How Watchtower Works

1. **Every 5 minutes**: Checks Docker Hub for new `longnode/calibre-web-longnode:latest`
2. **Detects new image**: Compares image digest (not just tag)
3. **Pulls new image**: Downloads latest version
4. **Stops old container**: Gracefully stops calibre-web
5. **Starts new container**: With same config (network, volumes, env, ports)
6. **Removes old image**: Cleans up disk space

### The "Magic Push" Workflow

Once Watchtower is set up:

```powershell
# On Windows
cd c:\github\long_node\repo
.\build-and-push.ps1

# That's it! Wait ~5 minutes and Synology auto-updates.
```

**Timeline**:
- T+0: Push to Docker Hub completes
- T+1 to T+5: Watchtower detects new image
- T+5: Container automatically updates
- T+6: New version live at books.waqasahmed.com

**No manual Portainer steps needed!**

### Disable Watchtower

If you want manual control:
```bash
# Via SSH or Portainer
docker stop watchtower
docker rm watchtower
```

---

## Troubleshooting

### Container Won't Start

**Check logs**:
- Portainer: Container → **Logs** button
- SSH: `docker logs calibre-web`

**Common issues**:
1. **"Connection reset"**: Container starting, wait 60 seconds
2. **Port already in use**: Another service using 8083
3. **Permission denied**: Check PUID=1027, PGID=100
4. **Volume mount errors**: Verify paths exist on Synology

### Site Loads But Wrong Theme

**Symptoms**: Site works but shows standard Calibre-Web theme, not Long Node.

**Fixes**:
1. Verify correct image:
   ```bash
   docker inspect calibre-web | grep -i image
   # Should show: longnode/calibre-web-longnode
   ```
2. Check theme setting in Admin → UI Configuration → Theme = 2 (Long Node)
3. Hard refresh browser: Ctrl+F5 or Cmd+Shift+R
4. Check container built correctly:
   ```bash
   docker exec calibre-web ls /app/calibre-web/cps/static/css/longnode.css
   # Should exist
   ```

### Cloudflare Tunnel Not Working (502 Bad Gateway)

**Symptoms**: Internal `http://192.168.0.10:8083` works, but `https://books.waqasahmed.com` shows 502.

**Fixes**:
1. **Check network** (MOST COMMON):
   - Container MUST be on `calibre-web_default` network
   - Portainer → Container → Network tab
   - If wrong network, recreate container with correct network
   
2. **Check cloudflared is running**:
   ```bash
   docker ps | grep cloudflared
   # Should show running container
   ```

3. **Test connectivity**:
   ```bash
   docker exec cloudflared ping calibre-web
   # Should succeed
   ```

4. **Check cloudflared logs**:
   ```bash
   docker logs cloudflared
   # Look for "connection refused" or "unable to reach" errors
   ```

### Build Fails on Windows

**"docker: command not found"**:
- Docker Desktop not running
- Check system tray for Docker whale icon
- Restart Docker Desktop

**"unauthorized: authentication required"**:
- Run `docker login` again
- Enter Docker Hub credentials

**"error during connect"**:
- Docker daemon not started
- Restart Docker Desktop
- Check Docker Desktop settings → General → "Use the WSL 2 based engine"

### Image Push Fails

**"denied: requested access to the resource is denied"**:
- Not logged in: `docker login`
- Wrong Docker Hub username
- Repository doesn't exist: Create it on hub.docker.com first

**"connection timeout"**:
- Internet connection issue
- Corporate firewall blocking Docker Hub
- Try different network

### Container Starts But App Won't Load

**Symptoms**: Container running, but http://192.168.0.10:8083 times out.

**Check startup time**: App takes 30-60 seconds to start. Wait and retry.

**Check app logs**:
```bash
docker logs calibre-web | tail -50
# Look for "Connection to localhost succeeded" - means started
# Look for Python tracebacks - means crash
```

**Check port binding**:
```bash
docker ps | grep calibre-web
# Should show: 0.0.0.0:8083->8083/tcp
```

---

## Emergency Rollback

If Long Node deployment breaks everything:

### Quick Rollback to LinuxServer.io

1. Stop `calibre-web` container in Portainer
2. Click container → **Duplicate/Edit**
3. Change image back to: `lscr.io/linuxserver/calibre-web:latest`
4. Verify network/volumes/env preserved
5. **Deploy the container**
6. **Your data is safe**: All config/users/books preserved in volumes

### Rollback to Previous Long Node Version

If latest Long Node version has a bug:

```bash
# In Portainer, change image to specific git hash:
longnode/calibre-web-longnode:d1ad73e7  # Previous working version
```

**How to find previous version hash**:
- Check git log: `git log --oneline -10`
- Check Docker Hub tags: https://hub.docker.com/r/longnode/calibre-web-longnode/tags

---

## Quick Reference

### Common Commands

```powershell
# Build and push (from Windows)
cd c:\github\long_node\repo
.\build-and-push.ps1

# Check running containers (Synology)
docker ps | grep calibre-web

# View logs
docker logs calibre-web --tail 50

# Restart container
docker restart calibre-web

# Check which image is running
docker inspect calibre-web | grep Image

# Test locally on Windows before pushing
docker build --platform linux/amd64 -t longnode-test:local .
docker run -d --name longnode-test -p 8084:8083 -v "c:/github/long_node/dev/calibre:/books" longnode-test:local
# Test at http://localhost:8084
docker stop longnode-test && docker rm longnode-test
```

### Key File Locations

**On Windows**:
- Project: `c:\github\long_node\repo`
- Dockerfile: `c:\github\long_node\repo\Dockerfile`
- Build script: `c:\github\long_node\repo\build-and-push.ps1`
- Docker compose reference: `c:\github\long_node\repo\docker-compose.synology.yml`

**On Synology**:
- Config volume: `/volume1/docker/calibre-web/config`
  - Contains: `app.db` (users, settings, theme config)
- Books volume: `/volume1/Media/Books/calibre`
  - Contains: `metadata.db` (Calibre library database)
  - Contains: All book files

**In Container**:
- App code: `/app/calibre-web/cps/`
- Config mount: `/config`
- Books mount: `/books`

### Critical Settings

**Environment Variables**:
```yaml
PUID: 1027              # Synology user "Waqas Ahmed"
PGID: 100               # Synology "users" group
TZ: America/Los_Angeles # Timezone
```

**Network**:
```yaml
Network: calibre-web_default  # MUST match cloudflared container
IP: 172.20.0.2                # Typical IP in this network
```

**Ports**:
```yaml
Host: 8083 → Container: 8083  # Must match Cloudflare Tunnel config
```

### URLs

- **Internal**: http://192.168.0.10:8083
- **External**: https://books.waqasahmed.com
- **Portainer**: http://192.168.0.10:9000
- **Docker Hub**: https://hub.docker.com/r/longnode/calibre-web-longnode

### Version Info

- **Current Image**: `longnode/calibre-web-longnode:latest`
- **Git Hash**: Check with `git rev-parse --short HEAD`
- **Base Image**: `lscr.io/linuxserver/calibre-web:latest`
- **Platform**: `linux/amd64` (for DS1522+ with AMD Ryzen)

---

## Success Checklist

After deployment, verify:

- [ ] Container shows "running" status in Portainer
- [ ] Container image is `longnode/calibre-web-longnode:latest`
- [ ] Container on `calibre-web_default` network
- [ ] Internal access works: http://192.168.0.10:8083
- [ ] External access works: https://books.waqasahmed.com
- [ ] Long Node theme visible (purple/orange, Inter font, custom favicon)
- [ ] Cloudflare Access authentication works
- [ ] Email-based auto-login works
- [ ] Books display and detail pages work
- [ ] All user accounts preserved

---

## Summary for Future AI Sessions

**What this project is**: Long Node is a customized fork of Calibre-Web with enhanced UI/UX (theme 2). It runs on Synology NAS in a Docker container accessed via Cloudflare Tunnel.

**How to deploy changes**:
1. Make code changes on Windows dev machine
2. Run `.\build-and-push.ps1` to build and push to Docker Hub
3. In Portainer on Synology: Recreate container with "re-pull image" checked
4. Wait 60 seconds for startup
5. Verify at internal and external URLs

**Critical things not to break**:
- Network MUST be `calibre-web_default` (for Cloudflare Tunnel)
- Volumes MUST be preserved (config and books data)
- PUID/PGID MUST be 1027/100 (file permissions)

**If things break**: Roll back to `lscr.io/linuxserver/calibre-web:latest` - all data preserved.

---

**Last Updated**: 2025-12-14  
**Current Version**: d1ad73e7  
**Status**: ✅ Successfully deployed to production
