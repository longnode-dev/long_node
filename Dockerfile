# Calibre-Web Long Node - Custom Docker Image
# Extends the official LinuxServer.io Calibre-Web image with Long Node customizations

FROM lscr.io/linuxserver/calibre-web:latest

LABEL maintainer="longnode"
LABEL description="Calibre-Web Long Node - Custom fork with enhanced UI/UX based on LinuxServer.io image"

# Build arguments for version info (passed by build script)
ARG BUILD_TIMESTAMP="unknown"
ARG BUILD_GIT_HASH="unknown"

# Copy our customized files over the upstream defaults
# This preserves all the LinuxServer.io goodness (s6-overlay, PUID/PGID handling, etc.)
# and just adds our Long Node customizations

# IMPORTANT: Copy ENTIRE DIRECTORIES, not individual files.
# This ensures any modified file is automatically included in the build.
# Never cherry-pick individual files - that leads to forgotten files and broken deployments.

# Copy all Python code in cps/ (top-level .py files)
COPY --chown=abc:abc cps/*.py /app/calibre-web/cps/

# Copy all templates
COPY --chown=abc:abc cps/templates/ /app/calibre-web/cps/templates/

# Copy all static assets (CSS, JS, fonts, images, etc.)
COPY --chown=abc:abc cps/static/ /app/calibre-web/cps/static/

# Generate build_info.py with actual build timestamp and git hash
# This overwrites the placeholder file copied above
RUN echo "# -*- coding: utf-8 -*-" > /app/calibre-web/cps/build_info.py && \
    echo "# Build information - Auto-generated at Docker build time" >> /app/calibre-web/cps/build_info.py && \
    echo "# DO NOT EDIT - This file is generated during docker build" >> /app/calibre-web/cps/build_info.py && \
    echo "" >> /app/calibre-web/cps/build_info.py && \
    echo "BUILD_TIMESTAMP = '${BUILD_TIMESTAMP}'" >> /app/calibre-web/cps/build_info.py && \
    echo "BUILD_GIT_HASH = '${BUILD_GIT_HASH}'" >> /app/calibre-web/cps/build_info.py

# That's it! Everything else (init system, user handling, etc.) comes from LinuxServer.io
