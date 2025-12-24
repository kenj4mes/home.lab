# ==============================================================================
# Superchain Dashboard - Static HTML Dashboard
# ==============================================================================
# Simple nginx container serving the Superchain status dashboard
# ==============================================================================

FROM nginx:alpine

LABEL maintainer="HomeLab"
LABEL description="Superchain Ecosystem Status Dashboard"

# Copy static files
COPY html/ /usr/share/nginx/html/

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80
