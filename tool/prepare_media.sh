#!/usr/bin/env bash
# Prepares bundled exercise media:
#   - copies images from data/images/ -> assets/exercises/images/
#   - copies ONLY the curated videos (tool/video_allowlist.txt) from
#     data/videos/ -> assets/exercises/videos/ and prunes any non-allowlisted
#     video already bundled there (360p transcode via ffmpeg when available;
#     plain copy otherwise)
# Run from the project root: tool/prepare_media.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SRC_IMG="data/images"
SRC_VID="data/videos"
DST_IMG="assets/exercises/images"
DST_VID="assets/exercises/videos"

mkdir -p "$DST_IMG" "$DST_VID"

echo "==> Copying images ($SRC_IMG -> $DST_IMG)"
cp -n "$SRC_IMG/"*.png "$DST_IMG/"

# Curated video allowlist (one slug per line; # comments allowed).
mapfile -t ALLOWED < <(grep -vE '^\s*(#|$)' tool/video_allowlist.txt)

echo "==> Pruning non-allowlisted videos from $DST_VID"
for f in "$DST_VID"/*.mp4; do
  [ -e "$f" ] || continue
  slug="$(basename "$f" .mp4)"
  if ! grep -qxF "$slug" <(printf '%s\n' "${ALLOWED[@]}"); then
    rm -f "$f"
    echo "    removed $slug.mp4"
  fi
done

if command -v ffmpeg >/dev/null 2>&1; then
  echo "==> ffmpeg found: transcoding allowlisted videos to 360p ($SRC_VID -> $DST_VID)"
  for slug in "${ALLOWED[@]}"; do
    src="$SRC_VID/$slug.mp4"
    [ -f "$src" ] || { echo "    WARN no video for $slug"; continue; }
    out="$DST_VID/$slug.mp4"
    [ -f "$out" ] && continue
    ffmpeg -loglevel error -i "$src" -vf "scale=-2:360" -c:v libx264 \
      -preset veryfast -crf 28 -movflags +faststart -an "$out"
  done
else
  echo "==> ffmpeg not found: copying allowlisted videos as-is ($SRC_VID -> $DST_VID)"
  for slug in "${ALLOWED[@]}"; do
    src="$SRC_VID/$slug.mp4"
    [ -f "$src" ] || { echo "    WARN no video for $slug"; continue; }
    cp -n "$src" "$DST_VID/"
  done
fi

echo "==> Media prep done:"
echo "    images: $(find "$DST_IMG" -name '*.png' | wc -l)"
echo "    videos: $(find "$DST_VID" -name '*.mp4' | wc -l)"
