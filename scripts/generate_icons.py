import os
from PIL import Image, ImageDraw

def create_tether_icon(size=1024):
    # Supersampling for ultra-crisp anti-aliasing
    scale = 4
    canvas_size = size * scale
    
    # Background: Warm neutral (#F7F7F4)
    bg_color = (247, 247, 244, 255)
    
    # Primary accent: Tether teal (#3F756B)
    teal_color = (63, 117, 107, 255)
    
    img = Image.new("RGBA", (canvas_size, canvas_size), bg_color)
    
    # Let's create an RGBA overlay for the tether links
    overlay = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    # Center of canvas
    cx = canvas_size / 2.0
    cy = canvas_size / 2.0
    
    # Geometry of each link (a rounded rectangular pill):
    # Length ~ 460px, width ~ 240px, corner radius ~ 120px, stroke width ~ 64px (scaled by 4)
    # Link 1 tilted at -45 deg, centered slightly offset to top-left (-60, -60)
    # Link 2 tilted at -45 deg, centered slightly offset to bottom-right (+60, +60)
    # They interlock seamlessly.
    
    link_w = int(240 * scale)
    link_h = int(460 * scale)
    corner_r = int(120 * scale)
    stroke_w = int(68 * scale)
    
    # Create single link template image in local coords
    pad = stroke_w + 20
    link_img_w = link_w + pad * 2
    link_img_h = link_h + pad * 2
    
    single_link = Image.new("RGBA", (link_img_w, link_img_h), (0, 0, 0, 0))
    link_draw = ImageDraw.Draw(single_link)
    
    rect_box = [pad, pad, pad + link_w, pad + link_h]
    
    # Draw outer filled rounded rectangle
    link_draw.rounded_rectangle(rect_box, radius=corner_r, fill=teal_color)
    
    # Cut out inner hole
    inner_box = [
        pad + stroke_w,
        pad + stroke_w,
        pad + link_w - stroke_w,
        pad + link_h - stroke_w
    ]
    inner_r = max(10, corner_r - stroke_w)
    link_draw.rounded_rectangle(inner_box, radius=inner_r, fill=(0, 0, 0, 0))
    
    # Rotate link by -45 degrees
    rotated_link = single_link.rotate(45, resample=Image.Resampling.BICUBIC, expand=True)
    rw, rh = rotated_link.size
    
    # Offsets for interlocking placement
    offset = int(72 * scale)
    
    # Link 1 (top-left)
    pos1 = (int(cx - rw / 2 - offset), int(cy - rh / 2 - offset))
    # Link 2 (bottom-right)
    pos2 = (int(cx - rw / 2 + offset), int(cy - rh / 2 + offset))
    
    # Paste Link 1
    overlay.paste(rotated_link, pos1, rotated_link)
    
    # To create true interlocking: Link 2 is drawn over Link 1, but we mask one overlapping corner
    # Or cleaner: Link 1 and Link 2 overlap, and we clip the underpass portion:
    # Notice: In minimal Apple icon aesthetics, interlocking chain links with a clean background gap (cutout) look exceptionally premium!
    # Let's create a cutout mask of Link 2 enlarged by a small margin (bg_color stroke) so they distinctively separate!
    
    # Cutout buffer around Link 2:
    buffer_w = int(16 * scale)
    single_link_cutout = Image.new("RGBA", (link_img_w, link_img_h), (0, 0, 0, 0))
    cutout_draw = ImageDraw.Draw(single_link_cutout)
    cutout_rect = [pad - buffer_w, pad - buffer_w, pad + link_w + buffer_w, pad + link_h + buffer_w]
    cutout_draw.rounded_rectangle(cutout_rect, radius=corner_r + buffer_w, fill=bg_color)
    inner_cutout_rect = [
        pad + stroke_w + buffer_w,
        pad + stroke_w + buffer_w,
        pad + link_w - stroke_w - buffer_w,
        pad + link_h - stroke_w - buffer_w
    ]
    cutout_draw.rounded_rectangle(inner_cutout_rect, radius=max(5, inner_r - buffer_w), fill=(0, 0, 0, 0))
    
    rotated_cutout = single_link_cutout.rotate(45, resample=Image.Resampling.BICUBIC, expand=True)
    
    # Crop the cutout so it only cuts where Link 2 passes under Link 1 on one side (interlocking effect)
    # Let's make half of the cutout mask active:
    half_mask = Image.new("L", rotated_cutout.size, 0)
    mask_draw = ImageDraw.Draw(half_mask)
    # Upper right half
    mask_draw.polygon([(0, 0), (rw, 0), (rw, rh)], fill=255)
    
    # Apply gap cutout where Link 1 meets Link 2
    gap_layer = Image.new("RGBA", rotated_cutout.size, (0, 0, 0, 0))
    gap_layer.paste(rotated_cutout, (0, 0), half_mask)
    
    # Composite:
    # 1. Base bg
    final_img = img.copy()
    # 2. Paste Link 1
    final_img.paste(rotated_link, pos1, rotated_link)
    # 3. Paste Gap layer at pos2
    final_img.paste(gap_layer, pos2, gap_layer)
    # 4. Paste Link 2
    final_img.paste(rotated_link, pos2, rotated_link)
    
    # Resize down to target size with high-quality Lanczos filter
    final_icon = final_img.resize((size, size), resample=Image.Resampling.LANCZOS)
    return final_icon

def generate_all_icons():
    icon_1024 = create_tether_icon(1024)
    
    # Android resolutions
    android_res = {
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    }
    
    for path, sz in android_res.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = icon_1024.resize((sz, sz), resample=Image.Resampling.LANCZOS)
        resized.save(path, 'PNG')
        print(f'Saved {path} ({sz}x{sz})')
        
    # iOS resolutions
    ios_base = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    ios_res = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    
    for filename, sz in ios_res.items():
        path = os.path.join(ios_base, filename)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = icon_1024.resize((sz, sz), resample=Image.Resampling.LANCZOS)
        # iOS icons must not have alpha channel on app store icon
        if sz == 1024:
            rgb_icon = Image.new("RGB", (sz, sz), (247, 247, 244))
            rgb_icon.paste(resized, mask=resized.split()[3])
            rgb_icon.save(path, 'PNG')
        else:
            resized.save(path, 'PNG')
        print(f'Saved {path} ({sz}x{sz})')

if __name__ == '__main__':
    generate_all_icons()
