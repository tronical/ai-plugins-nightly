#!/usr/bin/env bash
# Packs mcp/slint-preview into mcp/slint-preview.mcpb, the MCP bundle that
# .claude-plugin/plugin.json points at. Run it from anywhere after changing
# the server, the view or the plugin version.
#
# The bundle keeps the repo layout, so that server.mjs finds the plugin
# version and the icon at the same relative paths as in the unpacked plugin.
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
out="$root/mcp/slint-preview.mcpb"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

version=$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$root/.claude-plugin/plugin.json")

mkdir -p "$stage/.claude-plugin" "$stage/assets" "$stage/mcp/slint-preview"
# server.mjs only reads the version from the plugin manifest.
printf '{ "name": "slint", "version": "%s" }\n' "$version" > "$stage/.claude-plugin/plugin.json"
cp "$root/assets/slint.svg" "$stage/assets/"
cp -R "$root/mcp/slint-preview/server.mjs" "$root/mcp/slint-preview/view.html.in" \
    "$root/mcp/slint-preview/channel.json" "$root/mcp/slint-preview/assets" \
    "$stage/mcp/slint-preview/"

cat > "$stage/manifest.json" <<JSON
{
  "manifest_version": "0.3",
  "name": "slint-preview",
  "display_name": "Slint Preview",
  "version": "$version",
  "description": "Live-preview Slint GUIs inline as an MCP App",
  "author": {
    "name": "Slint",
    "email": "info@slint.dev",
    "url": "https://slint.dev"
  },
  "homepage": "https://slint.dev",
  "repository": {
    "type": "git",
    "url": "https://github.com/slint-ui/slint"
  },
  "license": "GPL-3.0-only OR LicenseRef-Slint-Royalty-free-2.0 OR LicenseRef-Slint-Software-3.0",
  "server": {
    "type": "node",
    "entry_point": "mcp/slint-preview/server.mjs",
    "mcp_config": {
      "command": "node",
      "args": ["\${__dirname}/mcp/slint-preview/server.mjs"]
    }
  },
  "tools": [
    { "name": "preview_slint", "description": "Show a live preview of Slint code" },
    { "name": "get_preview_screenshot", "description": "Capture the current state of a preview as a PNG" }
  ],
  "compatibility": {
    "runtimes": { "node": ">=18.0.0" }
  }
}
JSON

rm -f "$out"
(cd "$stage" && find . -exec touch -t 198001010000 {} + && zip -q -X -r "$out" .)
echo "Wrote $out ($(wc -c < "$out" | tr -d ' ') bytes)"
