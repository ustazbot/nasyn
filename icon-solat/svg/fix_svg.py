#!/usr/bin/env python3
"""Fix SVG syntax issue (missing closing quote on height attribute) and minify."""
import os
import re

svg_dir = "/home/astro/hermes-project/02-PROJECTS/AlatBantuSolat/icon-solat/svg"

for fname in sorted(os.listdir(svg_dir)):
    if not fname.endswith(".svg"):
        continue
    
    path = os.path.join(svg_dir, fname)
    content = open(path).read()
    
    # Fix: height="400> -> height="400">
    content = content.replace('height="400>', 'height="400">')
    # Also fix any similar issues
    content = content.replace('width="400>', 'width="400">')
    
    # Parse it to validate
    import xml.etree.ElementTree as ET
    try:
        ET.fromstring(content)
        print(f"  ✅ Valid XML: {fname}")
    except ET.ParseError as e:
        print(f"  ❌ Invalid XML {fname}: {e}")
        # Try harder fix
        content = re.sub(r'(height="\d+)>', r'\1">', content)
        content = re.sub(r'(width="\d+)>', r'\1">', content)
        try:
            ET.fromstring(content)
            print(f"     Fixed after re.sub")
        except ET.ParseError as e2:
            print(f"     Still broken: {e2}")
            continue
    
    open(path, 'w').write(content)
    print(f"     Size: {len(content)} bytes")
