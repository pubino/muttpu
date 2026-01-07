#!/usr/bin/env python3
"""
Generate app icon for MuttPU.
Creates a simple envelope icon representing email/mail.
"""

import sys
import subprocess
from pathlib import Path

def create_icon_svg(size=1024):
    """Create SVG icon with envelope design"""
    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" xmlns="http://www.w3.org/2000/svg">
  <!-- Background gradient -->
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4A90E2;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#357ABD;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="envelope" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#FFFFFF;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#E8E8E8;stop-opacity:1" />
    </linearGradient>
  </defs>

  <!-- Rounded background -->
  <rect width="{size}" height="{size}" rx="{size//5}" fill="url(#bg)"/>

  <!-- Envelope -->
  <g transform="translate({size//2}, {size//2})">
    <!-- Envelope body -->
    <rect x="-300" y="-200" width="600" height="400" rx="20" fill="url(#envelope)" stroke="#333333" stroke-width="8"/>

    <!-- Envelope flap (top triangle) -->
    <path d="M -300,-200 L 0,50 L 300,-200 Z" fill="#FFFFFF" stroke="#333333" stroke-width="8" stroke-linejoin="round"/>

    <!-- Envelope flap shadow -->
    <path d="M -300,-200 L 0,50 L 300,-200" fill="none" stroke="#CCCCCC" stroke-width="6" stroke-linejoin="round"/>

    <!-- Letter peeking out -->
    <rect x="-250" y="-150" width="500" height="280" rx="10" fill="#F9F9F9" stroke="#DDDDDD" stroke-width="4"/>

    <!-- Letter lines (text simulation) -->
    <line x1="-200" y1="-100" x2="200" y2="-100" stroke="#BBBBBB" stroke-width="6" stroke-linecap="round"/>
    <line x1="-200" y1="-50" x2="200" y2="-50" stroke="#BBBBBB" stroke-width="6" stroke-linecap="round"/>
    <line x1="-200" y1="0" x2="150" y2="0" stroke="#BBBBBB" stroke-width="6" stroke-linecap="round"/>
  </g>
</svg>'''
    return svg

def main():
    print("🎨 Generating MuttPU app icon...")

    # Create Resources directory
    resources_dir = Path(__file__).parent.parent / "MuttPU.app" / "Resources"
    resources_dir.mkdir(exist_ok=True)

    # Create temporary SVG
    svg_path = resources_dir / "icon_temp.svg"
    svg_content = create_icon_svg(1024)
    svg_path.write_text(svg_content)
    print(f"✓ Created SVG template: {svg_path}")

    # Check if we have tools to convert SVG to PNG
    try:
        # Try using rsvg-convert (from librsvg)
        subprocess.run(["which", "rsvg-convert"], check=True, capture_output=True)
        has_rsvg = True
    except:
        has_rsvg = False

    if has_rsvg:
        print("✓ Found rsvg-convert, generating PNGs...")

        # Generate different sizes
        sizes = [16, 32, 64, 128, 256, 512, 1024]
        png_files = []

        for size in sizes:
            png_path = resources_dir / f"icon_{size}x{size}.png"
            subprocess.run([
                "rsvg-convert",
                "-w", str(size),
                "-h", str(size),
                str(svg_path),
                "-o", str(png_path)
            ], check=True)
            png_files.append(str(png_path))
            print(f"  ✓ Generated {size}x{size} icon")

        # Create .icns file using iconutil
        iconset_dir = resources_dir / "AppIcon.iconset"
        iconset_dir.mkdir(exist_ok=True)

        # Copy PNGs to iconset with proper naming
        size_map = {
            16: ["icon_16x16.png"],
            32: ["icon_16x16@2x.png", "icon_32x32.png"],
            64: ["icon_32x32@2x.png"],
            128: ["icon_128x128.png"],
            256: ["icon_128x128@2x.png", "icon_256x256.png"],
            512: ["icon_256x256@2x.png", "icon_512x512.png"],
            1024: ["icon_512x512@2x.png"]
        }

        for size, names in size_map.items():
            src = resources_dir / f"icon_{size}x{size}.png"
            for name in names:
                dst = iconset_dir / name
                subprocess.run(["cp", str(src), str(dst)], check=True)

        # Convert to .icns
        icns_path = resources_dir / "AppIcon.icns"
        subprocess.run([
            "iconutil",
            "-c", "icns",
            str(iconset_dir),
            "-o", str(icns_path)
        ], check=True)

        print(f"\n✅ App icon created: {icns_path}")
        print("   Icon will be used on next build.")

        # Cleanup
        subprocess.run(["rm", "-rf", str(iconset_dir)])
        for size in sizes:
            subprocess.run(["rm", str(resources_dir / f"icon_{size}x{size}.png")])
        subprocess.run(["rm", str(svg_path)])

        return 0
    else:
        print("\n⚠️  rsvg-convert not found.")
        print(f"   SVG template saved to: {svg_path}")
        print("\nTo complete icon generation, install librsvg:")
        print("   brew install librsvg")
        print("\nThen run this script again:")
        print("   python3 scripts/generate_icon.py")
        return 1

if __name__ == "__main__":
    sys.exit(main())
