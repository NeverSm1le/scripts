import os
import cv2
import numpy as np

# ─────────────── tweak these ───────────────
MIN_AREA_RATIO = 0.01    # ignore blobs smaller than 1% of page
MORPH_KERNEL   = (5,5)   # for closing tiny gaps
PADDING        = 5       # px padding around final crop
# ────────────────────────────────────────────

INPUT_DIR  = "input"
OUTPUT_DIR = "output"

for root, dirs, files in os.walk(INPUT_DIR):
    # Compute the path relative to raw_pages/
    rel_path = os.path.relpath(root, INPUT_DIR)
    # Create the matching output directory
    out_dir = os.path.join(OUTPUT_DIR, rel_path)
    os.makedirs(out_dir, exist_ok=True)

    # Print the folder being processed
    print(f"Processing folder: {root}")

    for fname in files:
        if not fname.lower().endswith((".png", ".jpg", ".jpeg")):
            continue

        src_path = os.path.join(root, fname)
        img      = cv2.imread(src_path)
        gray     = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        H, W     = gray.shape
        min_area = MIN_AREA_RATIO * (H * W)

        # 1) Otsu binarize and invert: ink=255, paper=0
        _, bw = cv2.threshold(
            gray, 0, 255,
            cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU
        )

        # 2) Close small holes so each panel+balloon is one blob
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, MORPH_KERNEL)
        clean  = cv2.morphologyEx(bw, cv2.MORPH_CLOSE, kernel)

        # 3) Find contours (external blobs)
        contours, _ = cv2.findContours(
            clean, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )

        # 4) Keep only "big" blobs (throws out tiny watermarks)
        big_blobs = [c for c in contours if cv2.contourArea(c) >= min_area]
        if not big_blobs:
            print(f"⚠️  No big blobs in {src_path}, skipping.")
            continue

        # 5) Merge all big-blob points & get their bounding box
        all_pts = np.vstack(big_blobs).squeeze()
        x, y, w, h = cv2.boundingRect(all_pts)

        # 6) Pad & clamp to page bounds
        x1 = max(0, x - PADDING)
        y1 = max(0, y - PADDING)
        x2 = min(W, x + w + PADDING)
        y2 = min(H, y + h + PADDING)

        # 7) Crop and save into the mirrored folder
        crop = img[y1:y2, x1:x2]
        dst_path = os.path.join(out_dir, fname)
        cv2.imwrite(dst_path, crop)

print("✅ All done – check your mirrored structure under", OUTPUT_DIR)
