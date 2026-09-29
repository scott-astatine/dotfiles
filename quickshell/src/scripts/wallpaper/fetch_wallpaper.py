#!/usr/bin/env python3
import sys
import os
import urllib.request
import urllib.parse
import json
import random
import hashlib
from PIL import Image

def calculate_sha256(file_path):
    """
    Calculates the SHA-256 hash of a file.
    """
    if not os.path.exists(file_path):
        return None
    sha256 = hashlib.sha256()
    try:
        with open(file_path, 'rb') as f:
            while chunk := f.read(8192):
                sha256.update(chunk)
        return sha256.hexdigest()
    except Exception as e:
        print(f"Warning: Failed to calculate SHA-256 for {file_path}: {e}", file=sys.stderr)
        return None

def is_dark_image(image_path, threshold=130):
    """
    Checks if the image is suitable for dark/vibrant desktop themes.
    Calculates average relative luminance (L = 0.299*R + 0.587*G + 0.114*B).
    Returns True if avg_luminance < threshold.
    """
    try:
        with Image.open(image_path) as img:
            if img.mode != 'RGB':
                img = img.convert('RGB')
            small_img = img.resize((100, 100))
            img_bytes = small_img.tobytes()
            total_luminance = 0
            
            for i in range(0, len(img_bytes), 3):
                r = img_bytes[i]
                g = img_bytes[i+1]
                b = img_bytes[i+2]
                luminance = 0.299 * r + 0.587 * g + 0.114 * b
                total_luminance += luminance
                
            num_pixels = len(img_bytes) // 3
            avg_luminance = total_luminance / num_pixels
            print(f"  - Calculated average image luminance: {avg_luminance:.2f}")
            return avg_luminance < threshold
    except Exception as e:
        print(f"Warning: Failed to check image brightness: {e}", file=sys.stderr)
        return True

def is_unique_wallpaper(image_path, output_path, backup_dir):
    """
    Checks if the downloaded image is unique by comparing SHA-256 hashes.
    """
    candidate_hash = calculate_sha256(image_path)
    if not candidate_hash:
        return True
        
    print(f"  - Candidate SHA-256: {candidate_hash}")
    
    current_wall_path = os.path.expanduser("~/.cache/current_wallpaper.jpg")
    if os.path.exists(current_wall_path):
        current_hash = calculate_sha256(current_wall_path)
        if current_hash == candidate_hash:
            print("  - Duplicate detected: matches current active wallpaper.")
            return False
            
    if os.path.exists(output_path) and output_path != current_wall_path:
        out_hash = calculate_sha256(output_path)
        if out_hash == candidate_hash:
            print("  - Duplicate detected: matches output path wallpaper.")
            return False
            
    if os.path.exists(backup_dir):
        for filename in os.listdir(backup_dir):
            file_path = os.path.join(backup_dir, filename)
            if os.path.isfile(file_path):
                if filename.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
                    existing_hash = calculate_sha256(file_path)
                    if existing_hash == candidate_hash:
                        print(f"  - Duplicate detected: matches backup image {filename}.")
                        return False
                        
    return True

def fetch_retro_anime_urls():
    """
    Scrapes Wallhaven and Konachan specifically for Retro Anime wallpapers.
    """
    queries = [
        "retro anime",
        "90s anime",
        "retro anime aesthetic",
        "retro artstyle",
        "cyberpunk anime retro",
        "synthwave anime",
        "lo-fi retro anime",
        "vintage anime"
    ]
    query = random.choice(queries)
    headers = {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    urls = []
    
    # 1. Query Wallhaven API (Category: Anime 010, SFW 100, Widescreen 16x9/16x10/21x9)
    try:
        wallhaven_url = f"https://wallhaven.cc/api/v1/search?q={urllib.parse.quote(query)}&categories=010&purity=100&sorting=random&ratios=16x9,16x10,21x9"
        print(f"Scouring Wallhaven for Retro Anime ({query})...")
        req = urllib.request.Request(wallhaven_url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data.get('data'):
                found_urls = [item['path'] for item in data['data'] if 'path' in item]
                urls.extend(found_urls)
    except Exception as e:
        print(f"Wallhaven fetch warning: {e}", file=sys.stderr)
        
    # 2. Query Konachan API (Safe rating, retro tags)
    try:
        page = random.randint(1, 50)
        konachan_url = f"https://konachan.net/post.json?tags=rating:safe+retro_artstyle&limit=25&page={page}"
        print(f"Scouring Konachan for Retro Anime wallpapers...")
        req = urllib.request.Request(konachan_url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            if isinstance(data, list):
                found_urls = [item['file_url'] for item in data if 'file_url' in item]
                urls.extend(found_urls)
    except Exception as e:
        print(f"Konachan fetch warning: {e}", file=sys.stderr)

    # 3. Fallback query if list is short
    if len(urls) < 5:
        try:
            wallhaven_url_fallback = "https://wallhaven.cc/api/v1/search?q=anime&categories=010&purity=100&sorting=random&ratios=16x9,16x10,21x9"
            req = urllib.request.Request(wallhaven_url_fallback, headers=headers)
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode('utf-8'))
                if data.get('data'):
                    urls.extend([item['path'] for item in data['data'] if 'path' in item])
        except Exception:
            pass

    random.shuffle(urls)
    return urls

def main():
    if len(sys.argv) < 2:
        print("Usage: fetch_wallpaper.py <output_path>")
        sys.exit(1)
        
    output_path = os.path.expanduser(sys.argv[1])
    temp_path = output_path + ".tmp"
    backup_dir = os.path.expanduser("~/.cache/wallpaper_backups")
    
    candidate_urls = fetch_retro_anime_urls()
    if not candidate_urls:
        print("Error: Could not retrieve any retro anime wallpaper URLs.", file=sys.stderr)
        sys.exit(1)
        
    headers = {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    max_attempts = 15
    for attempt, img_url in enumerate(candidate_urls[:max_attempts]):
        print(f"Attempt {attempt + 1}/{max_attempts}: Downloading {img_url}")
        try:
            req_img = urllib.request.Request(img_url, headers=headers)
            with urllib.request.urlopen(req_img, timeout=15) as response, open(temp_path, 'wb') as out_file:
                out_file.write(response.read())
                
            if is_dark_image(temp_path, threshold=130):
                if is_unique_wallpaper(temp_path, output_path, backup_dir):
                    print("  - Candidate accepted: Image is Retro Anime and unique.")
                    if os.path.exists(output_path):
                        os.remove(output_path)
                    os.rename(temp_path, output_path)
                    print("Download completed successfully.")
                    sys.exit(0)
                else:
                    print("  - Candidate rejected: Image is a duplicate.")
            else:
                print("  - Candidate rejected: Image is too bright.")
                
            if os.path.exists(temp_path):
                os.remove(temp_path)
        except Exception as e:
            print(f"  - Error on attempt {attempt + 1}: {e}", file=sys.stderr)
            if os.path.exists(temp_path):
                os.remove(temp_path)
            continue
            
    # Fallback to last downloaded temp if retries exhausted
    if os.path.exists(temp_path):
        if os.path.exists(output_path):
            os.remove(output_path)
        os.rename(temp_path, output_path)
        print("Fallback candidate accepted.")
        sys.exit(0)
    else:
        print("Error: Exceeded max retries without successfully saving image.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
