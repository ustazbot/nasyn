#!/usr/bin/env python3
"""
Proper SVG conversion for line-art prayer icons.
The images are black line strokes on white background.
Strategy: 
1. Detect edge pixels (black lines)
2. Use morphological thinning to get centerlines
3. Convert to SVG path strokes
"""

from PIL import Image, ImageFilter
import numpy as np
import os

def extract_line_art_svg(png_path, target_size=400, stroke_width=3.0):
    """
    Convert line-art PNG to clean SVG.
    Uses edge detection + medial axis to produce stroke-based SVG paths.
    """
    img = Image.open(png_path).convert("L")  # Greyscale
    img = img.resize((target_size, target_size), Image.LANCZOS)
    arr = np.array(img, dtype=np.uint8)
    
    # Threshold: detect black lines (pixel value < 200)
    # Line pixels = 1, background = 0
    lines = (arr < 200).astype(np.uint8)
    
    # Find all line pixels
    line_pixels = np.column_stack(np.where(lines > 0))
    
    if len(line_pixels) < 10:
        return None
    
    # Group pixels into connected components
    # Use simple grid-based clustering
    from scipy import ndimage
    
    labeled, num_features = ndimage.label(lines, structure=np.ones((3,3)))
    
    svg_paths = []
    
    for label_id in range(1, num_features + 1):
        mask = labeled == label_id
        pix_count = np.sum(mask)
        
        if pix_count < 10:  # Skip noise
            continue
        
        # Get coordinates
        coords = np.column_stack(np.where(mask))
        
        # For each region, compute a simplified contour/path
        # We trace the boundary of each black region
        from skimage import measure
        
        contours = measure.find_contours(mask.astype(float), level=0.5)
        
        for contour in contours:
            if len(contour) < 5:
                continue
            
            # Simplify contour
            # Keep every 3rd point for simplicity, ensure closure
            simplified = contour[::2]
            
            if len(simplified) < 3:
                continue
            
            d_parts = []
            for i, (y, x) in enumerate(simplified):
                # Ensure valid range
                x = max(0, min(target_size - 1, x))
                y = max(0, min(target_size - 1, y))
                
                sy = target_size - y  # Flip Y for SVG
                
                if i == 0:
                    d_parts.append(f"M{x:.1f} {sy:.1f}")
                else:
                    d_parts.append(f"L{x:.1f} {sy:.1f}")
            
            if len(d_parts) > 1:
                d_parts.append("Z")
                svg_paths.append('<path d="' + ' '.join(d_parts) + '"/>')
    
    if not svg_paths:
        return None
    
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {target_size} {target_size}" width="{target_size}" height="{target_size}">
<g fill="none" stroke="#000000" stroke-width="{stroke_width}" stroke-linecap="round" stroke-linejoin="round">
{chr(10).join(svg_paths)}
</g>
</svg>'''
    
    return svg

def convert_via_edge_detection(png_path, target_size=400, stroke_width=2.5):
    """
    Alternative: Canny edge detection on the line art.
    Detects edges of black lines, outputs as stroke paths.
    This gives nice thin outlines that preserve the shape.
    """
    import cv2
    
    img = cv2.imread(png_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return None
    
    img = cv2.resize(img, (target_size, target_size), interpolation=cv2.INTER_AREA)
    
    # Invert: we want edges of black lines on white bg
    # Canny works on light-on-dark better, so invert
    inverted = 255 - img
    
    # Apply Canny edge detection
    edges = cv2.Canny(inverted, 30, 100)
    
    # Find contours from edges
    contours, _ = cv2.findContours(edges, cv2.RETR_LIST, cv2.CHAIN_APPROX_TC89_KCOS)
    
    svg_paths = []
    for contour in contours:
        length = cv2.arcLength(contour, False)
        if length < 15:
            continue
        
        # Simplify
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
<g fill="none" stroke="#000000" stroke-width="{stroke_width}" stroke-linecap="round" stroke-linejoin="round">
{chr(10).join(svg_paths)}
</g>
</svg>'''
    
    return svg

def convert_as_silhouette(png_path, target_size=400):
    """
    Convert the black line art as FILLED shapes.
    For IoT displays (e-paper, OLED), filled shapes render better.
    """
    import cv2
    
    img = cv2.imread(png_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        return None
    
    img = cv2.resize(img, (target_size, target_size), interpolation=cv2.INTER_AREA)
    
    # Threshold to get black regions
    _, binary = cv2.threshold(img, 200, 255, cv2.THRESH_BINARY_INV)
    
    # Find contours of black regions
    contours, _ = cv2.findContours(binary, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    
    svg_paths = []
    for contour in contours:
        area = cv2.contourArea(contour)
        if area < 20:
            continue
        
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


def convert_smart(png_path, target_size=400):
    """
    Smart converter: detect whether image is line art or silhouette,
    choose best method. Returns SVG content.
    """
    from PIL import Image
    import cv2
    
    img = Image.open(png_path).convert("L")
    img = img.resize((target_size, target_size), Image.LANCZOS)
    arr = np.array(img, dtype=np.uint8)
    
    # Analyse: what percentage of pixels are "line" pixels?
    line_pixels = np.sum(arr < 200)
    total_pixels = target_size * target_size
    line_ratio = line_pixels / total_pixels
    
    print(f"  Line pixel ratio: {line_ratio:.3f} ({line_pixels}/{total_pixels})")
    
    # If very sparse (< 15% black pixels), it's line art → use silhouette fill
    # If more filled, it might be a silhouette
    if line_ratio < 0.25:
        print(f"  -> Line art detected, using silhouette fill")
        result = convert_as_silhouette(png_path, target_size)
        if result:
            # Also verify visually
            pass
        return result
    else:
        print(f"  -> Silhouette detected, using fill approach")
        return convert_as_silhouette(png_path, target_size)


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
        
        # Use smart detection
        svg_content = convert_smart(png_path, target_size=400)
        
        if svg_content:
            svg_path = os.path.join(out_dir, f"{name}.svg")
            with open(svg_path, 'w') as f:
                f.write(svg_content)
            
            size_bytes = os.path.getsize(svg_path)
            print(f"  ✅ Saved: {svg_path}")
            print(f"  Size: {size_bytes} bytes")
        else:
            print(f"  ❌ Failed to convert {name}")
    
    print("\n=== FINAL RESULTS ===")
    print(f"Output: {out_dir}")
    for f in sorted(os.listdir(out_dir)):
        if f.endswith(".svg"):
            path = os.path.join(out_dir, f)
            content = open(path).read()
            # Count path commands
            path_count = content.count('<path')
            coord_count = len([c for c in content if c == 'M'])
            print(f"  {f}: {os.path.getsize(path)} bytes | {path_count} paths")
