# Graph Report - quickshell  (2026-09-12)

## Corpus Check
- 53 files · ~70,983 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 417 nodes · 553 edges · 68 communities (25 shown, 43 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `98ce317e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Cubic
- material-shapes.js
- Offset
- Point
- RoundedPolygon
- engine.sh
- customPolygon
- Feature
- LengthMeasurer
- Matrix
- feature-mapping.js
- fetch_wallpaper.py
- utils.js
- levendist.js
- Result
- calendar_layout.js
- hyprconfigurator.py
- least_busy_region.py
- thumbnail_folder
- DoubleMapper
- generate-thumbnails-magick.sh
- Morph
- find_regions.py
- record.sh
- apply_colors.sh
- color_scheme.py
- nova-Default.md
- circle
- Morphing rounded polygons in QML Js
- periodic_table.js
- CornerRounding
- recognize-music.sh
- text_color.py
- extract_colors.py
- w-FourPointedSparkle.md
- boom
- bun
- burst
- clover4
- clover8
- cookie4
- cookie6
- diamond
- flower
- ghostish
- pentagon
- pill
- pixelCircle
- pixelTriangle
- softBoom
- PointNRound
- layouts.js
- gemini-categorize-wallpaper.sh
- gemini-translate.sh
- show-installed-ollama-models.sh
- is_unlocked.sh
- try_lookup.sh
- unlock.sh
- thumbgen-venv.sh
- find-regions-venv.sh
- least-busy-region-venv.sh
- text-color-venv.sh
- material-code-set-color.sh
- setwallpaper.sh
- shufflewallpaper

## God Nodes (most connected - your core abstractions)
1. `customPolygon()` - 27 edges
2. `Cubic` - 26 edges
3. `Offset` - 20 edges
4. `Point` - 18 edges
5. `RoundedPolygon` - 18 edges
6. `Matrix` - 12 edges
7. `switch()` - 12 edges
8. `RoundedCorner` - 7 edges
9. `main()` - 7 edges
10. `Feature` - 6 edges

## Surprising Connections (you probably didn't know these)
- `slanted()` --calls--> `customPolygon()`  [EXTRACTED]
  src/components/shapes/material-shapes.js → src/components/shapes/material-shapes.js  _Bridges community 1 → community 6_
- `pill()` --calls--> `customPolygon()`  [EXTRACTED]
  src/components/shapes/material-shapes.js → src/components/shapes/material-shapes.js  _Bridges community 47 → community 6_
- `diamond()` --calls--> `customPolygon()`  [EXTRACTED]
  src/components/shapes/material-shapes.js → src/components/shapes/material-shapes.js  _Bridges community 43 → community 6_
- `pentagon()` --calls--> `customPolygon()`  [EXTRACTED]
  src/components/shapes/material-shapes.js → src/components/shapes/material-shapes.js  _Bridges community 46 → community 6_
- `cookie4()` --calls--> `customPolygon()`  [EXTRACTED]
  src/components/shapes/material-shapes.js → src/components/shapes/material-shapes.js  _Bridges community 41 → community 6_

## Import Cycles
- None detected.

## Communities (68 total, 43 thin omitted)

### Community 0 - "Cubic"
Cohesion: 0.07
Nodes (3): Cubic, MutableCubic, RoundedCorner

### Community 1 - "material-shapes.js"
Cohesion: 0.13
Nodes (22): arch(), cookie12(), cookie7(), cookie9(), getArch(), getCookie12Sided(), getCookie7Sided(), getCookie9Sided() (+14 more)

### Community 5 - "engine.sh"
Cohesion: 0.19
Nodes (14): categorize_wallpaper(), check_and_prompt_upscale(), create_restore_script(), handle_kde_material_you_colors(), is_video(), kill_existing_mpvpaper(), main(), post_process() (+6 more)

### Community 6 - "customPolygon"
Cohesion: 0.12
Nodes (16): arrow(), clamShell(), customPolygon(), doRepeat(), fan(), gem(), getArrow(), getClamShell() (+8 more)

### Community 7 - "Feature"
Cohesion: 0.14
Nodes (3): Corner, Edge, Feature

### Community 8 - "LengthMeasurer"
Cohesion: 0.22
Nodes (3): LengthMeasurer, MeasuredCubic, MeasuredPolygon

### Community 10 - "feature-mapping.js"
Cohesion: 0.22
Nodes (8): DistanceVertex, doMapping(), featureDistSquared(), featureMapper(), featureRepresentativePoint(), MappingHelper, ProgressableFeature, progressDistance()

### Community 11 - "fetch_wallpaper.py"
Cohesion: 0.29
Nodes (9): calculate_sha256(), fetch_retro_anime_urls(), is_dark_image(), is_unique_wallpaper(), main(), Calculates the SHA-256 hash of a file., Checks if the image is suitable for dark/vibrant desktop themes.     Calculates, Checks if the downloaded image is unique by comparing SHA-256 hashes. (+1 more)

### Community 13 - "levendist.js"
Cohesion: 0.50
Nodes (7): computeScore(), computeTextMatchScore(), levenshteinDistance(), max2(), min2(), min3(), partialRatio()

### Community 15 - "calendar_layout.js"
Cohesion: 0.46
Nodes (6): checkLeapYear(), getCalendarLayout(), getMonthDays(), getNextMonthDays(), getPrevMonthDays(), weekDays

### Community 16 - "hyprconfigurator.py"
Cohesion: 0.36
Nodes (7): build_nested_structure(), edit_hyprland_config(), format_value(), generate_config_line(), Recursively build nested structure from key parts, Generate hl.config line for given key and value, Format value: quote strings, leave numbers and booleans as-is

### Community 17 - "least_busy_region.py"
Cohesion: 0.61
Nodes (7): center_crop(), draw_largest_region(), draw_region(), find_largest_region(), find_least_busy_region(), get_dominant_color(), main()

### Community 18 - "thumbnail_folder"
Cohesion: 0.62
Nodes (6): Path, get_all_files(), get_all_images(), main(), make_thumbnail(), thumbnail_folder()

### Community 19 - "DoubleMapper"
Cohesion: 0.43
Nodes (3): DoubleMapper, linearMap(), progressInRange()

### Community 20 - "generate-thumbnails-magick.sh"
Cohesion: 0.38
Nodes (3): generate_thumbnail(), generate-thumbnails-magick.sh script, usage()

### Community 22 - "find_regions.py"
Cohesion: 0.60
Nodes (5): draw_regions(), find_regions(), iou(), main(), non_max_suppression()

### Community 24 - "apply_colors.sh"
Cohesion: 0.70
Nodes (4): apply_anyterm(), apply_kitty(), apply_term(), apply_colors.sh script

### Community 25 - "color_scheme.py"
Cohesion: 0.70
Nodes (4): image_colorfulness(), load_and_resize_image(), main(), pick_scheme()

### Community 26 - "nova-Default.md"
Cohesion: 0.50
Nodes (3): Context (ignore when irrelevant), Presentation, Style

### Community 27 - "circle"
Cohesion: 0.50
Nodes (4): circle(), getCircle(), getOval(), oval()

### Community 28 - "Morphing rounded polygons in QML Js"
Cohesion: 0.50
Nodes (3): Example, Morphing rounded polygons in QML Js, Usage

### Community 29 - "periodic_table.js"
Cohesion: 0.50
Nodes (3): elements, niceTypes, series

## Knowledge Gaps
- **25 isolated node(s):** `elements`, `series`, `niceTypes`, `weekDays`, `byName` (+20 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **43 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Point` connect `Point` to `Cubic`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `elements`, `series`, `niceTypes` to the rest of the system?**
  _25 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Cubic` be split into smaller, more focused modules?**
  _Cohesion score 0.06794871794871794 - nodes in this community are weakly interconnected._
- **Should `material-shapes.js` be split into smaller, more focused modules?**
  _Cohesion score 0.13043478260869565 - nodes in this community are weakly interconnected._
- **Should `Offset` be split into smaller, more focused modules?**
  _Cohesion score 0.09956709956709957 - nodes in this community are weakly interconnected._
- **Should `Point` be split into smaller, more focused modules?**
  _Cohesion score 0.11695906432748537 - nodes in this community are weakly interconnected._
- **Should `customPolygon` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._