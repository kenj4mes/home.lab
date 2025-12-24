# ==============================================================================
# Creative Dashboard - Unified UI for All Creative Services
# ==============================================================================
# A simple web dashboard providing access to all creative AI services.
#
# Build:
#   docker build -t homelab/creative-dashboard .
#
# Run:
#   docker run -p 80:80 homelab/creative-dashboard
# ==============================================================================

FROM nginx:alpine

LABEL maintainer="HomeLab"
LABEL description="Creative AI Dashboard"
LABEL version="1.0.0"

# Copy dashboard files
COPY index.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
