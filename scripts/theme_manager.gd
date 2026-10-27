class_name ThemeManager
extends Node

## Centralized Theme Manager for ArrowFlow ("Clear The Path").
## Supplies 5 curated eye-comfort themes, broadcasts changes, and syncs with SaveManager.

signal theme_changed(theme: Dictionary)

static var instance: ThemeManager

const THEMES: Array[Dictionary] = [
	# 0: Warm Paper (Original Eye Comfort)
	{
		"id": "warm_paper",
		"name": "Eye Comfort",
		"bg": Color("#FAF4E8"),
		"dots": Color(0.75, 0.68, 0.58, 0.45),
		"arrow_line": Color("#4A3525"),
		"arrow_head": Color("#4A3525"),
		"arrow_blocked": Color("#E53935"),
		"arrow_hint": Color("#FFB300"),
		"guide_clear": Color("#2E7D32"),
		"guide_blocked": Color("#E53935"),
		"header_accent": Color("#B37B24"),
		"subtitle": Color("#8D6E63"),
		"card_bg": Color("#FFFDF9"),
		"card_border": Color("#E0D5C1"),
		"banner_bg": Color("#D8C3A5"),
		"banner_border": Color("#B89F7D"),
		"banner_text": Color("#5D4037"),
		"btn_bg": Color("#FFFFFF"),
		"btn_icon": Color("#5D4037")
	},
	# 1: Midnight Zen (Dark Mode)
	{
		"id": "dark_slate",
		"name": "Midnight Zen",
		"bg": Color("#181A20"),
		"dots": Color(0.35, 0.40, 0.48, 0.4),
		"arrow_line": Color("#E2E8F0"),
		"arrow_head": Color("#E2E8F0"),
		"arrow_blocked": Color("#FF5252"),
		"arrow_hint": Color("#FFD54F"),
		"guide_clear": Color("#48BB78"),
		"guide_blocked": Color("#FF5252"),
		"header_accent": Color("#FFD54F"),
		"subtitle": Color("#94A3B8"),
		"card_bg": Color("#1E222B"),
		"card_border": Color("#334155"),
		"banner_bg": Color("#282D37"),
		"banner_border": Color("#334155"),
		"banner_text": Color("#E2E8F0"),
		"btn_bg": Color("#282D37"),
		"btn_icon": Color("#E2E8F0")
	},
	# 2: Matcha Garden (Sage & Olive)
	{
		"id": "matcha",
		"name": "Matcha Garden",
		"bg": Color("#EDF4EE"),
		"dots": Color(0.60, 0.72, 0.62, 0.45),
		"arrow_line": Color("#2D4A3E"),
		"arrow_head": Color("#2D4A3E"),
		"arrow_blocked": Color("#E53935"),
		"arrow_hint": Color("#F6AD55"),
		"guide_clear": Color("#2F855A"),
		"guide_blocked": Color("#E53935"),
		"header_accent": Color("#4C7B5D"),
		"subtitle": Color("#6B8E78"),
		"card_bg": Color("#F6FAF7"),
		"card_border": Color("#C6DCC8"),
		"banner_bg": Color("#D5E4D7"),
		"banner_border": Color("#B5CBB8"),
		"banner_text": Color("#2D4A3E"),
		"btn_bg": Color("#FFFFFF"),
		"btn_icon": Color("#2D4A3E")
	},
	# 3: Nordic Frost (Cool Slate Blue)
	{
		"id": "nordic",
		"name": "Nordic Frost",
		"bg": Color("#EEF2F6"),
		"dots": Color(0.65, 0.72, 0.78, 0.45),
		"arrow_line": Color("#2C3E50"),
		"arrow_head": Color("#2C3E50"),
		"arrow_blocked": Color("#E53935"),
		"arrow_hint": Color("#ED8936"),
		"guide_clear": Color("#3182CE"),
		"guide_blocked": Color("#E53935"),
		"header_accent": Color("#34495E"),
		"subtitle": Color("#7F8C8D"),
		"card_bg": Color("#F7FAFC"),
		"card_border": Color("#CBD5E0"),
		"banner_bg": Color("#D6E0EA"),
		"banner_border": Color("#BDC3C7"),
		"banner_text": Color("#2C3E50"),
		"btn_bg": Color("#FFFFFF"),
		"btn_icon": Color("#2C3E50")
	},
	# 4: Sunset Clay (Warm Terracotta)
	{
		"id": "sunset",
		"name": "Sunset Clay",
		"bg": Color("#FDF5F0"),
		"dots": Color(0.78, 0.68, 0.62, 0.45),
		"arrow_line": Color("#6E3826"),
		"arrow_head": Color("#6E3826"),
		"arrow_blocked": Color("#D32F2F"),
		"arrow_hint": Color("#DD6B20"),
		"guide_clear": Color("#C05621"),
		"guide_blocked": Color("#D32F2F"),
		"header_accent": Color("#C05621"),
		"subtitle": Color("#9C6652"),
		"card_bg": Color("#FFF9F6"),
		"card_border": Color("#EAD2C5"),
		"banner_bg": Color("#EAD7CD"),
		"banner_border": Color("#D1B9AC"),
		"banner_text": Color("#6E3826"),
		"btn_bg": Color("#FFFFFF"),
		"btn_icon": Color("#6E3826")
	}
]

var current_theme_idx: int = 0

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	if SaveManager.instance:
		current_theme_idx = clampi(SaveManager.instance.theme_idx, 0, THEMES.size() - 1)

func get_current_theme() -> Dictionary:
	return THEMES[current_theme_idx % THEMES.size()]

func next_theme() -> Dictionary:
	current_theme_idx = (current_theme_idx + 1) % THEMES.size()
	if SaveManager.instance:
		SaveManager.instance.theme_idx = current_theme_idx
		SaveManager.instance.save_data()
	var th = get_current_theme()
	theme_changed.emit(th)
	return th

func set_theme_by_idx(idx: int) -> Dictionary:
	current_theme_idx = clampi(idx, 0, THEMES.size() - 1)
	if SaveManager.instance:
		SaveManager.instance.theme_idx = current_theme_idx
		SaveManager.instance.save_data()
	var th = get_current_theme()
	theme_changed.emit(th)
	return th
