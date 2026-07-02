#!/usr/bin/env python3
"""
Smart SVG tracer for line-art icons.
Detects edges from PNG line art and produces clean SVG paths.
IoT friendly — minimal file size, no metadata, pure SVG primitives.
"""

from PIL import Image, ImageFilter
import numpy as np
import os
import re

def png_to_binary_array(png_path, target_size=400):
    """Load PNG, detect edges from line art, return binary edge array."""
    img = Image.open(png_path).convert("L")  # Greyscale
    img = img.resize((target_size, target_size), Image.LANCZOS)

    arr = np.array(img, dtype=np.uint8)

    # Invert: our line art has black lines on white background
    # After invert: white lines on black background (255=line, 0=bg)
    # We want to detect the edges of the black lines
    # Simple threshold: anything < 200 is a line pixel
    binary = (arr < 200).astype(np.uint8) * 255

    return binary, target_size

def trace_skeleton(binary):
    """Trace the skeleton of the binary image to get centerlines.
    Returns list of path segments as (x,y) coordinate lists."""
    from skimage import morphology
    skeleton = morphology.skeletonize(binary > 0)
    
    # Convert skeleton to paths
    # Simple approach: find connected components in skeleton and trace them
    from skimage import measure
    paths = []
    
    # Get coordinates of all skeleton pixels
    coords = np.column_stack(np.where(skeleton > 0))
    
    if len(coords) == 0:
        return paths
    
    # Label connected components
    from scipy import ndimage
    labeled, num_features = ndimage.label(skeleton)
    
    for label_id in range(1, num_features + 1):
        points = np.column_stack(np.where(labeled == label_id))
        if len(points) < 5:  # Skip tiny fragments
            continue
        paths.append(points.tolist())
    
    return paths

def paths_to_svg(paths, img_size):
    """Convert traced paths to SVG path strings with stroke styling.
    Returns clean SVG content."""
    
    if not paths:
        return None
    
    svg_paths = []
    for path_points in paths:
        if len(path_points) < 2:
            continue
        
        # Sort points to make a continuous path (simple approach)
        # For better results, we'd need proper path ordering
        # But for now, just use them as-is
        d_parts = []
        first = True
        for px, py in path_points:
            # Flip Y for SVG coordinate system
            sy = img_size - py
            if first:
                d_parts.append(f"M{px} {sy}")
                first = False
            else:
                d_parts.append(f"L{px} {sy}")
        
        if len(d_parts) > 1:
            svg_paths.append('<path d="' + ' '.join(d_parts) + '"/>')
    
    if not svg_paths:
        return None
    
    svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {img_size} {img_size}" width="{img_size}" height="{img_size}">
<g fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
{chr(10).join(svg_paths)}
</g>
</svg>'''
    
    return svg_content


def trace_with_opencv(png_path, target_size=400):
    """Use OpenCV's findContours for better line-art tracing.
    This traces the OUTLINE of black regions, which for line art
    gives us the actual line paths."""
    import cv2
    
    img = cv2.imread(png_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return None, "Cannot read image"
    
    img = cv2.resize(img, (target_size, target_size), interpolation=cv2.INTER_AREA)
    
    # Threshold to binary
    _, binary = cv2.threshold(img, 200, 255, cv2.THRESH_BINARY_INV)
    
    # Find contours - this traces the OUTLINES of black shapes
    contours, hierarchy = cv2.findContours(binary, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    
    if len(contours) == 0:
        return None, "No contours found"
    
    # For stroke-based SVG, we use the contours directly as paths
    # Each contour is a closed outline of a black region
    
    # But for line art, we want the MEDIAL AXIS (centerline)
    # Contour tracing will give us the outline of each line stroke
    # which means double-lines for each stroke
    
    # Alternative: use the contour as stroke path
    # Filter small contours
    valid_contours = [c for c in contours if cv2.arcLength(c, False) > 20]
    
    if not valid_contours:
        return None, "No valid contours"
    
    # Simplify contours for smaller SVG
    svg_paths = []
    for contour in valid_contours:
        # Approximate contour to reduce points
        epsilon = 1.5
        approx = cv2.approxPolyDP(contour, epsilon, True)
        
        if len(approx) < 3:
            continue
        
        d_parts = []
        first = True
        for pt in approx:
            x, y = pt[0][0], pt[0][1]
            sy = target_size - y  # Flip Y
            if first:
                d_parts.append(f"M{x} {sy}")
                first = False
            else:
                d_parts.append(f"L{x} {sy}")
        
        if len(d_parts) > 1:
            d_parts.append("Z")  # Close the path
            svg_paths.append('<path d="' + ' '.join(d_parts) + '"/>')
    
    if not svg_paths:
        return None, "No SVG paths generated"
    
    # Count total coordinate pairs
    total_coords = sum(len(s.split()) for s in svg_paths)
    
    svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {target_size} {target_size}" width="{target_size}" height="{target_size}>
<g fill="none" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
{chr(10).join(svg_paths)}
</g>
</svg>'''
    
    return svg_content, {"contours": len(valid_contours), "coords": total_coords, "svg_chars": len(svg_content)}

def trace_simple_fill(png_path, target_size=200):
    """Simplest approach: use the black filled regions as SVG paths.
    This works best for line art that's actually filled shapes (silhouettes)."""
    import cv2
    
    img = cv2.imread(png_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return None, "Cannot read image"
    
    img = cv2.resize(img, (target_size, target_size), interpolation=cv2.INTER_AREA)
    
    # Threshold: black regions become white (fill)
    _, binary = cv2.threshold(img, 200, 255, cv2.THRESH_BINARY)
    
    # Find contours of black regions
    contours, _ = cv2.findContours(255 - binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    svg_paths = []
    for contour in contours:
        area = cv2.contourArea(contour)
        if area < 10:  # Skip tiny specks
            continue
        
        epsilon = 1.0
        approx = cv2.approxPolyDP(contour, epsilon, True)
        
        d_parts = []
        for i, pt in enumerate(approx):
            x, y = pt[0][0], pt[0][1]
            sy = target_size - y
            if i == 0:
                d_parts.append(f"M{x} {sy}")
            else:
                d_parts.append(f"L{x} {sy}")
        
        if d_parts:
            d_parts.append("Z")
            svg_paths.append('<path d="' + ' '.join(d_parts) + '"/>')
    
    if not svg_paths:
        return None, "No paths generated"
    
    svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {target_size} {target_size}" width="{target_size}" height="{target_size}>
<g fill="#000000">
{chr(10).join(svg_paths)}
</g>
</svg>'''
    
    return svg_content, {"contours": len(svg_paths), "svg_chars": len(svg_content)}


if __name__ == "__main__":
    src_dir = "/home/astro/hermes-project/02-PROJECTS/AlatBantuSolat/icon-solat"
    out_dir = os.path.join(src_dir, "svg")
    os.makedirs(out_dir, exist_ok=True)
    
    for fname in sorted(os.listdir(src_dir)):
        if not fname.endswith(".png"):
            continue
        
        png_path = os.path.join(src_dir, fname)
        name = os.path.splitext(fname)[0]
        
        print(f"\n=== {name} ===")
        
        # Method 1: Fill-based (silhouette approach) - best for line art!
        result, info = trace_simple_fill(png_path, target_size=200)
        
        if result:
            svg_path = os.path.join(out_dir, f"{name}.svg")
            with open(svg_path, 'w') as f:
                f.write(result)
            
            size_bytes = os.path.getsize(svg_path)
            print(f"  SVG: {svg_path}")
            print(f"  Size: {size_bytes} bytes")
            print(f"  Paths: {info['contours']}")
        else:
            print(f"  FAILED: {info}")
    
    print("\n=== DONE ===")
    print(f"\nOutput directory: {out_dir}")
    for f in sorted(os.listdir(out_dir)):
        if f.endswith(".svg"):
            path = os.path.join(out_dir, f)
            print(f"  {f}: {os.path.getsize(path)} bytes")
