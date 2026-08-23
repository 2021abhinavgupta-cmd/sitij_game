# Builds the Godot Web (HTML5/WASM) export and serves it as a static site.
# Godot itself + its export templates are downloaded during this build step
# (not committed to git) so the repo stays lean.

FROM ubuntu:22.04 AS export

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG GODOT_VERSION=4.4.1-stable

WORKDIR /godot
RUN curl -sL -o godot.zip \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
    && unzip -q godot.zip && rm godot.zip \
    && chmod +x Godot_v${GODOT_VERSION}_linux.x86_64 \
    && ln -s Godot_v${GODOT_VERSION}_linux.x86_64 godot

RUN curl -sL -o templates.tpz \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz" \
    && mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION} \
    && unzip -q templates.tpz -d /tmp/tpl \
    && mv /tmp/tpl/templates/* /root/.local/share/godot/export_templates/${GODOT_VERSION}/ \
    && rm -rf templates.tpz /tmp/tpl

WORKDIR /app
COPY game/ ./game/

RUN mkdir -p /app/web-build \
    && /godot/godot --headless --path /app/game --export-release "Web" /app/web-build/index.html

FROM caddy:2-alpine AS runtime
COPY --from=export /app/web-build /srv
COPY Caddyfile /etc/caddy/Caddyfile
