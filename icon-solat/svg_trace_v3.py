#!/usr/bin/env python3
"""
Fixed SVG converter for RGBA line-art icons.
These are PNGs with transparent background — black lines on alpha.
Proper approach: composite onto white background first, then trace.
"""

from PIL import Image
import numpy as np
import cv2
import os

def load_with_alpha(png_path, target_size=400):
    """Load RGBA PNG, composite onto white background."""
    img = Image.open(png_path).convert("RGBA")
    
    # Create white background
    bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    # Composite
    composite = Image.alpha_composite(bg, img)
    # Convert to greyscale
    grey = composite.convert("L")
    grey = grey.resize((target_size, target_size), Image.LANCZOS)
    
    return np.array(grey, dtype=np.uint8)


def convert_best(png_path, target_size=400):
    """Best approach: composite RGBA on white, then use filled contour tracing."""
    arr = load_with_alpha(png_path, target_size)
    
    print(f"  Pixel stats after compositing:")
    print(f"    Mean: {arr.mean():.1f}, Min: {arr.min()}, Max: {arr.max()}")
    print(f"    Black (<50): {np.sum(arr < 50)} ({np.sum(arr < 50)/arr.size*100:.1f}%)")
    print(f"    White (>200): {np.sum(arr > 200)} ({np.sum(arr > 200)/arr.size*100:.1f}%)")
    
    # Threshold to get black lines
    _, binary = cv2.threshold(arr, 200, 255, cv2.THRESH_BINARY)
    
    # Invert: black lines become white regions to trace
    lines = 255 - binary
    
    # Find contours of the line regions
    contours, _ = cv2.findContours(lines, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    print(f"  Raw contours: {len(contours)}")
    
    svg_paths = []
    for contour in contours:
        area = cv2.contourArea(contour)
        if area < 15:
            continue
        
        # Simplify
        epsilon = 1.5
        approx = cv2.approxPolyDP(contour, epsilon, True)
        
        d_parts = []
        for i, pt in enumerate(approx):
            x, y = pt[0][0], pt[0][1]
            sy = target_size - y
            if i == 0:
                d_parts.append(f"M{x} {sy}")
            else:
                d_parts.append(f"L{x} {sy}")
        
        if len(d_parts) > 1:
            d_parts.append("Z")
            svg_paths.append('<path d="' + ' '.join(d_parts) + '"/>')
    
    if not svg_paths:
        return None
    
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {target_size} {target_size}" width="{target_size}" height="{target_size}>
<g fill="#000000">
{chr(10).join(svg_paths)}
</g>
</svg>'''
    
    return svg


def convert_stroke_based(png_path, target_size=400):
    """Stroke-based: detect edges of black lines, output as strokes.
    Better visual result for IoT displays with thicker strokes."""
    arr = load_with_alpha(png_path, target_size)
    
    # Invert (black=255, white=0) for Canny
    inverted = 255 - arr
    
    # Edge detection
    edges = cv2.Canny(inverted, 30, 100)
    
    # Find edge contours
    contours, _ = cv2.findContours(edges, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    print(f"  Edge contours: {len(contours)}")
    
    svg_paths = []
    for contour in contours:
        length = cv2.arcLength(contour, False)
        if length < 20:
            continue
        
        epsilon = 1.0
        approx = cv2.approxPolyDP(contour, epsilon, False)
        
        d_parts = []
        for i, pt in enumerate(approx):
            x, y = pt[0][0], pt[0][1]
            sy = target_size - y
            if i == 0:
                d_parts.append(f"M{x} {sy}")
            else:
                d_parts.append(f"L{x} {sy}")
        
        if len(d_parts) > 1:
            d_parts.append("Z")
            svg_paths.append('<path d="' + ' '.join(d_parts) + '"/>')
    
    if not svg_paths:
        return None
    
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {target_size} {target_size}" width="{target_size}" height="{target_size}>
<g fill="none" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
{chr(10).join(svg_paths)}
</g>
</svg>'''
    
    return svg


if __name__ == "__main__":
    src_dir = "/home/astro/hermes-project/02-PROJECTS/AlatBantuSolat/icon-solat"
    out_dir = os.path.join(src_dir, "svg")
    os.makedirs(out_dir, exist_ok=True)
    
    for fname in sorted(os.listdir(src_dir)):
        if not fname.endswith(".png"):
            continue
        
        png_path = os.path.join(src_dir, fname)
        name = os.path.splitext(fname)[0]
        
        print(f"\n{'='*50}")
        print(f"  {name}")
        print(f"{'='*50}")
        
        # Method A: Fill-based (silhouette)
        svg_fill = convert_best(png_path, target_size=400)
        
        if svg_fill:
            svg_path = os.path.join(out_dir, f"{name}-fill.svg")
            with open(svg_path, 'w') as f:
                f.write(svg_fill)
            print(f"  ✅ FILL: {svg_path} ({os.path.getsize(svg_path)} bytes)")
        
        # Method B: Stroke-based
        svg_stroke = convert_stroke_based(png_path, target_size=400)
        
        if svg_stroke:
            svg_path = os.path.join(out_dir, f"{name}-stroke.svg")
            with open(svg_path, 'w') as f:
                f.write(svg_stroke)
            print(f"  ✅ STROKE: {svg_path} ({os.path.getsize(svg_path)} bytes)")
    
    print(f"\n{'='*50}")
    print("  FINAL OUTPUTS")
    print(f"{'='*50}")
    for f in sorted(os.listdir(out_dir)):
        if f.endswith(".svg"):
            path = os.path.join(out_dir, f)
            content = open(path).read()
            print(f"  {f}: {os.path.getsize(path)} bytes")
