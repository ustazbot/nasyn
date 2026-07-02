#!/usr/bin/env python3
"""Debug script: inspect actual pixel values of the PNG icons."""
from PIL import Image
import numpy as np
import os

src_dir = "/home/astro/hermes-project/02-PROJECTS/AlatBantuSolat/icon-solat"

for fname in sorted(os.listdir(src_dir)):
    if not fname.endswith(".png"):
        continue
    
    png_path = os.path.join(src_dir, fname)
    name = os.path.splitext(fname)[0]
    
    img = Image.open(png_path).convert("L")
    arr = np.array(img, dtype=np.uint8)
    
    print(f"\n=== {name} ===")
    print(f"  Size: {arr.shape[0]}x{arr.shape[1]}")
    print(f"  Min pixel: {arr.min()}, Max pixel: {arr.max()}, Mean: {arr.mean():.1f}")
    print(f"  Pixels < 50 (black): {np.sum(arr < 50)} ({np.sum(arr < 50)/arr.size*100:.1f}%)")
    print(f"  Pixels < 128 (dark): {np.sum(arr < 128)} ({np.sum(arr < 128)/arr.size*100:.1f}%)")
    print(f"  Pixels > 200 (white): {np.sum(arr > 200)} ({np.sum(arr > 200)/arr.size*100:.1f}%)")
    print(f"  Unique pixel values: {len(np.unique(arr))}")
    
    # Check if image has an alpha channel
    img_rgba = Image.open(png_path)
    print(f"  Mode: {img_rgba.mode}")
    
    # Show a sample of corner pixels
    print(f"  Top-left 5x5 corner:")
    print(arr[:5, :5])
