#!/bin/bash
# Batch convert PNG line-art icons to clean IoT-friendly SVGs
# Step 1: PNG -> BMP (potrace needs BMP)
# Step 2: BMP -> SVG (potrace)
# Step 3: Optimise SVG (remove metadata, compact paths)

SRC_DIR="/home/astro/hermes-project/02-PROJECTS/AlatBantuSolat/icon-solat"
OUT_DIR="$SRC_DIR/svg"

mkdir -p "$OUT_DIR"

for png in "$SRC_DIR"/*.png; do
    name=$(basename "$png" .png)
    bmp="/tmp/${name}.bmp"
    raw_svg="$OUT_DIR/${name}-raw.svg"
    final_svg="$OUT_DIR/${name}.svg"

    echo "--- Processing $name ---"

    # Step 1: Convert PNG to BMP (black & white, resize to reasonable size)
    # Using -negate because potrace expects black-on-white (our PNG is black-on-white already)
    convert "$png" -resize 400x400 -negate -threshold 50% -negate "$bmp"

    # Step 2: Potrace - optimise for curves (-u for unit, -t for turdsize)
    # -t 2: remove speckles smaller than 2px
    # -a 1.0: curve optimisation (higher = smoother but more points)
    # --opttolerance 0.2: how tightly to follow the bitmap
    # -u 1: 1 pixel = 1 unit in SVG
    potrace "$bmp" \
        -b svg \
        -t 2 \
        -a 1.0 \
        --opttolerance 0.3 \
        -u 1 \
        --longcoding \
        -o "$raw_svg"

    # Step 3: Clean SVG - remove potrace metadata, add viewBox properly
    python3 -c "
import re
with open('$raw_svg', 'r') as f:
    content = f.read()

# Remove XML declaration
content = re.sub(r'<\?xml[^>]*\?>', '', content)

# Remove potrace comments/metadata
content = re.sub(r'<!--[^>]*-->', '', content)

# Remove empty defs
content = re.sub(r'<defs/>', '', content)

# Clean up whitespace
content = re.sub(r'\n\s*\n', '\n', content)
content = content.strip()

with open('$final_svg', 'w') as f:
    f.write(content)
"

    # Get file size
    size=$(stat -c%s "$final_svg")
    echo "  -> $final_svg (${size} bytes)"

    rm -f "$bmp" "$raw_svg"
done

echo ""
echo "=== DONE ==="
ls -la "$OUT_DIR"/*.svg 2>/dev/null
