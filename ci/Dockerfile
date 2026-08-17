# syntax=docker/dockerfile:1.7
# =============================================================================
#  Builds a WSL2-importable root filesystem for the dev environment.
#
#  This is the CI counterpart to setup.sh. GitHub Actions builds this image and
#  runs `docker export` on it to produce a tarball that `wsl --import` accepts.
#
#  setup.sh remains the single source of truth: this Dockerfile only bootstraps
#  a normal user + passwordless sudo, then runs setup.sh exactly as it would run
#  on a real WSL distro.
# =============================================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

# Don't let any package postinst scripts try to start services during the build
RUN printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Bootstrap: a normal user with passwordless sudo, so setup.sh runs as it would
# in WSL. Everything gets installed into /home/dev.
RUN apt-get update \
 && apt-get install -y --no-install-recommends sudo \
 && useradd -m -s /bin/bash dev \
 && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
 && rm -rf /var/lib/apt/lists/*

USER dev
WORKDIR /tmp/dev-container

# Only the files setup.sh needs (it copies profile.sh into ~/.profile.d)
COPY --chown=dev:dev setup.sh profile.sh ./

# Installs system packages + nvm/node/pnpm/bun + global tools into /home/dev
RUN bash setup.sh

# Boot straight into the dev user; enable systemd (matches the local setup)
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends systemd \
 && printf '[boot]\nsystemd=true\n\n[user]\ndefault=dev\n' > /etc/wsl.conf \
 && rm -rf /var/lib/apt/lists/*

USER dev
WORKDIR /home/dev/projects
CMD ["bash", "-l"]
