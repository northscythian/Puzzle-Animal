# Интерьерные варианты 1.3

Способ: встроенная генерация изображений imagegen, без API/CLI.

Файлы: botanical_atlas.png и lavender_atlas.png. Каждый атлас: 2 столбца × 3 строки, используются первые 5 ячеек — кафе, мастерская, домик, теплица, обсерватория. Шестая ячейка не используется. Классическое оформление остаётся исходным. Атласы выводятся через AtlasTexture без дублирования текстур. Сюжетные фоны используются как визуальные референсы; это художественные варианты, не точные геометрические копии.

## Botanical prompt

Use case: precise-object-edit. Create ONE game environment texture atlas, an exact borderless 2 columns by 3 rows grid of six equal landscape panels, overall square 1536x1536 or larger square. Images 1–5 are edit targets and style anchors for panels 1–5 in reading order: cafe, kite workshop, canal cottage, greenhouse, observatory. Panel 6 repeat cottage detail. Keep each room's recognizable architecture, camera, focal objects (coffee grinder, bird kite, fireplace, water tank, telescope). Redesign furnishings, wall treatments, window trim and lighting into a rich botanical mint-green theme: ivory-painted wood, sage walls, wicker chairs, leaf-pattern cushions, brass pendant lamps, abundant tasteful plants. This must be visible integrated room decoration, not tint overlay. Match cozy hand-painted cartoon game backgrounds from references. No people, no text, no labels, no logos, no margins, no gutters. Six exact equal rectangular panels at x=0/halfwidth and y=0/one-third/two-thirds.

## Lavender prompt

Use case: precise-object-edit. ONE game environment texture atlas. EXACT 2 columns x 3 rows, six EQUAL landscape rectangles, overall square, no gutters or border. Images 1–5 are edit targets in reading order: top-left cafe, top-right kite workshop, middle-left canal cottage, middle-right greenhouse, bottom-left observatory. Bottom-right repeat cottage. Preserve recognizable architecture, viewpoint and focal objects: grinder, bird kite, fireplace, water tank, telescope. Redesign real furniture, wall finishes, windows, upholstery and lamps as a playful lavender-and-plum artisan style with cream painted wood, violet velvet cushions, stained glass accents, curved furniture, warm brass lanterns. Beautiful integrated detailed room changes, NOT color filter and NOT simple overlays. Match the cozy high-quality hand-painted cartoon game backgrounds. No people, lettering, labels, watermarks or UI. EXACT six equal panels: vertical division at half width, horizontal at one-third and two-thirds height.

