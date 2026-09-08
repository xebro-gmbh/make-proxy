#!/bin/sh
# Collect templates before the image's 20-envsubst-on-templates.sh runs.
# Sources are mounted read-only at neutral paths — a nested mount into
# /etc/nginx/templates/routes would fail (cannot create a mountpoint inside
# a read-only bind mount), so we copy into the writable container rootfs.
set -e
mkdir -p /etc/nginx/templates/routes
cp /templates-src/*.template /etc/nginx/templates/ 2>/dev/null || true
cp /routes-src/*.template /etc/nginx/templates/routes/ 2>/dev/null || true
