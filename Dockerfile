# Calibre-Web Long Node - Custom Docker Image
# Extends the official LinuxServer.io Calibre-Web image with Long Node customizations

FROM lscr.io/linuxserver/calibre-web:latest

LABEL maintainer="longnode"
LABEL description="Calibre-Web Long Node - Custom fork with enhanced UI/UX based on LinuxServer.io image"

# Copy our customized files over the upstream defaults
# This preserves all the LinuxServer.io goodness (s6-overlay, PUID/PGID handling, etc.)
# and just adds our Long Node customizations

# Copy modified Python code
COPY --chown=abc:abc cps/__init__.py /app/calibre-web/cps/__init__.py
COPY --chown=abc:abc cps/db.py /app/calibre-web/cps/db.py
COPY --chown=abc:abc cps/render_template.py /app/calibre-web/cps/render_template.py
COPY --chown=abc:abc cps/web.py /app/calibre-web/cps/web.py

# Copy modified templates
COPY --chown=abc:abc cps/templates/ /app/calibre-web/cps/templates/

# Copy Long Node static assets (CSS, JS, fonts, favicons)
COPY --chown=abc:abc cps/static/css/longnode.css /app/calibre-web/cps/static/css/longnode.css
COPY --chown=abc:abc cps/static/js/longnode.js /app/calibre-web/cps/static/js/longnode.js
COPY --chown=abc:abc cps/static/fonts/ /app/calibre-web/cps/static/fonts/
COPY --chown=abc:abc cps/static/favicon.ico /app/calibre-web/cps/static/favicon.ico
COPY --chown=abc:abc cps/static/favicon-16x16.png /app/calibre-web/cps/static/favicon-16x16.png
COPY --chown=abc:abc cps/static/favicon-32x32.png /app/calibre-web/cps/static/favicon-32x32.png
COPY --chown=abc:abc cps/static/android-chrome-192x192.png /app/calibre-web/cps/static/android-chrome-192x192.png
COPY --chown=abc:abc cps/static/android-chrome-512x512.png /app/calibre-web/cps/static/android-chrome-512x512.png
COPY --chown=abc:abc cps/static/apple-touch-icon.png /app/calibre-web/cps/static/apple-touch-icon.png
COPY --chown=abc:abc cps/static/site.webmanifest /app/calibre-web/cps/static/site.webmanifest

# That's it! Everything else (init system, user handling, etc.) comes from LinuxServer.io
