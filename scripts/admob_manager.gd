class_name AdMobManager
extends CanvasLayer

## Google AdMob Manager for ArrowFlow ("Clear The Path")
## Full monetization lifecycle: Banner Ads, Rewarded Ads, and App Open Ads.
## Configured with official Google AdMob test IDs for Android and iOS.
## Bridges to Godot Android/iOS AdMob plugins, with high-fidelity visual simulation
## for Desktop, Editor, and test automation.

signal banner_loaded
signal banner_hidden
signal rewarded_ad_loaded
signal rewarded_ad_earned(reward_type: String, amount: int)
signal rewarded_ad_closed(reward_granted: bool)
signal app_open_ad_loaded
signal app_open_ad_opened
signal app_open_ad_closed

static var instance: AdMobManager

# =========================================================================
# OFFICIAL GOOGLE ADMOB TEST APP & AD UNIT IDS
# Reference: https://developers.google.com/admob/android/test-ads
# =========================================================================
const TEST_APP_ID_ANDROID: String = "ca-app-pub-3940256099942544~3347511713"
const TEST_APP_ID_IOS: String = "ca-app-pub-3940256099942544~1458002511"

const TEST_BANNER_ANDROID: String = "ca-app-pub-3940256099942544/6300978111"
const TEST_BANNER_IOS: String = "ca-app-pub-3940256099942544/2934735716"

const TEST_REWARDED_ANDROID: String = "ca-app-pub-3940256099942544/5224354917"
const TEST_REWARDED_IOS: String = "ca-app-pub-3940256099942544/1712485313"

const TEST_APP_OPEN_ANDROID: String = "ca-app-pub-3940256099942544/9257376440"
const TEST_APP_OPEN_IOS: String = "ca-app-pub-3940256099942544/5662856169"

const TEST_INTERSTITIAL_ANDROID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_INTERSTITIAL_IOS: String = "ca-app-pub-3940256099942544/4411468910"

var is_native_admob: bool = false
var native_admob: Object = null

# State tracking
var is_banner_visible: bool = false
var is_rewarded_ready: bool = true
var is_app_open_ready: bool = true
var is_showing_ad: bool = false
var is_gameplay_active: bool = false

# Frequency capping & cold start tracking
var last_app_open_time_msec: int = 0
const APP_OPEN_COOLDOWN_MSEC: int = 30000 # 30 seconds minimum between App Open Ads
var has_shown_cold_start_ad: bool = false
var enable_app_open_ads: bool = false # Disabled to remove unwanted popup screen

# UI elements for high-fidelity visual mock display
var mock_banner_panel: PanelContainer
var mock_ad_overlay: Control
var current_reward_callback: Callable
var current_fail_callback: Callable

# Rewarded timer
var rewarded_countdown_tween: Tween
var rewarded_seconds_remaining: int = 5
var rewarded_granted: bool = false

func _enter_tree() -> void:
	instance = self
	layer = 120 # Always on top of UI screens

func _ready() -> void:
	_init_native_plugin()
	_create_mock_ui()
	set_process_input(true)
	# Cold-start App Open Ad removed to provide clean, uninterrupted game experience

func _notification(what: int) -> void:
	# Google AdMob App Open Ad: only trigger if explicitly enabled
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		if enable_app_open_ads and not is_gameplay_active and not is_showing_ad:
			show_app_open_ad()

func _init_native_plugin() -> void:
	if Engine.has_singleton("AdMob"):
		native_admob = Engine.get_singleton("AdMob")
		is_native_admob = true
	elif Engine.has_singleton("GodotAdMob"):
		native_admob = Engine.get_singleton("GodotAdMob")
		is_native_admob = true

	if is_native_admob and native_admob:
		print("[AdMobManager] Connected to native AdMob plugin. Initializing with test mode...")
		# Initialize plugin
		if native_admob.has_method("initialize"):
			native_admob.initialize()
		elif native_admob.has_method("init"):
			native_admob.init(false, false, false, "G") # is_real = false (test mode)

		# Banner signals
		if native_admob.has_signal("on_banner_ad_loaded"):
			native_admob.on_banner_ad_loaded.connect(func(): banner_loaded.emit())
		elif native_admob.has_signal("banner_loaded"):
			native_admob.banner_loaded.connect(func(): banner_loaded.emit())

		# Rewarded signals
		if native_admob.has_signal("on_rewarded_video_ad_loaded"):
			native_admob.on_rewarded_video_ad_loaded.connect(func(): rewarded_ad_loaded.emit())
		elif native_admob.has_signal("rewarded_video_loaded"):
			native_admob.rewarded_video_loaded.connect(func(): rewarded_ad_loaded.emit())

		if native_admob.has_signal("on_rewarded_video_ad_closed"):
			native_admob.on_rewarded_video_ad_closed.connect(_on_native_rewarded_closed)
		elif native_admob.has_signal("rewarded_video_closed"):
			native_admob.rewarded_video_closed.connect(_on_native_rewarded_closed)

		if native_admob.has_signal("on_rewarded_user_earned_reward"):
			native_admob.on_rewarded_user_earned_reward.connect(func(type, amount):
				rewarded_ad_earned.emit(str(type), int(amount))
			)
		elif native_admob.has_signal("rewarded_user_earned_reward"):
			native_admob.rewarded_user_earned_reward.connect(func(type, amount):
				rewarded_ad_earned.emit(str(type), int(amount))
			)
	else:
		print("[AdMobManager] Running with interactive AdMob simulator (Desktop/Editor mode).")

# =========================================================================
# BANNER AD (Requirement 2)
# =========================================================================

func show_banner() -> void:
	is_banner_visible = true
	var banner_id = TEST_BANNER_IOS if OS.has_feature("ios") else TEST_BANNER_ANDROID

	if is_native_admob and native_admob:
		if native_admob.has_method("load_banner"):
			native_admob.load_banner(banner_id, false, "BOTTOM")
			native_admob.show_banner()
		elif native_admob.has_method("loadBanner"):
			native_admob.loadBanner(banner_id, false)
			native_admob.showBanner()
	elif mock_banner_panel:
		mock_banner_panel.show()

	banner_loaded.emit()

func hide_banner() -> void:
	is_banner_visible = false

	if is_native_admob and native_admob:
		if native_admob.has_method("hide_banner"):
			native_admob.hide_banner()
		elif native_admob.has_method("hideBanner"):
			native_admob.hideBanner()
	elif mock_banner_panel:
		mock_banner_panel.hide()

	banner_hidden.emit()

# =========================================================================
# REWARDED AD (Requirement 1)
# =========================================================================

func show_rewarded_ad(on_success: Callable, on_fail: Callable = Callable()) -> void:
	current_reward_callback = on_success
	current_fail_callback = on_fail
	is_showing_ad = true
	var rewarded_id = TEST_REWARDED_IOS if OS.has_feature("ios") else TEST_REWARDED_ANDROID

	if is_native_admob and native_admob:
		if native_admob.has_method("show_rewarded_video"):
			native_admob.load_rewarded_video(rewarded_id)
			native_admob.show_rewarded_video()
		elif native_admob.has_method("showRewardedVideo"):
			native_admob.loadRewardedVideo(rewarded_id)
			native_admob.showRewardedVideo()
	else:
		_show_mock_rewarded_dialog()

func _on_native_rewarded_closed() -> void:
	is_showing_ad = false
	if current_reward_callback.is_valid():
		if current_reward_callback.get_argument_count() > 0:
			current_reward_callback.call(true)
		else:
			current_reward_callback.call()
		rewarded_ad_earned.emit("extra_life", 1)
		rewarded_ad_closed.emit(true)
	current_reward_callback = Callable()
	current_fail_callback = Callable()

# =========================================================================
# APP OPEN AD (Requirement 3)
# =========================================================================

func show_app_open_ad(force: bool = false) -> void:
	if not force and not enable_app_open_ads:
		return
	var now = Time.get_ticks_msec()
	if not force:
		if now - last_app_open_time_msec < APP_OPEN_COOLDOWN_MSEC:
			return
		if is_showing_ad or is_gameplay_active:
			return

	last_app_open_time_msec = now
	is_showing_ad = true
	app_open_ad_opened.emit()
	var app_open_id = TEST_APP_OPEN_IOS if OS.has_feature("ios") else TEST_APP_OPEN_ANDROID

	if is_native_admob and native_admob:
		if native_admob.has_method("show_app_open_ad"):
			native_admob.load_app_open_ad(app_open_id)
			native_admob.show_app_open_ad()
		elif native_admob.has_method("showAppOpen"):
			native_admob.loadAppOpen(app_open_id)
			native_admob.showAppOpen()
	else:
		_show_mock_app_open_dialog()

func _check_cold_start_app_open() -> void:
	# Cold start App Open Ad removed to prevent interrupting the player
	pass

func set_gameplay_active(active: bool) -> void:
	is_gameplay_active = active

# =========================================================================
# HIGH-FIDELITY VISUAL SIMULATION (Proper AdMob Ad Rendering)
# =========================================================================

func _create_mock_ui() -> void:
	# 1. Full-Width Bottom Banner Ad (Standard 320x50 / Adaptive 720x64)
	mock_banner_panel = PanelContainer.new()
	mock_banner_panel.name = "MockBannerAd"
	mock_banner_panel.custom_minimum_size = Vector2(720, 64)
	mock_banner_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mock_banner_panel.offset_top = -66.0

	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color("#161922")
	b_style.border_width_top = 2
	b_style.border_color = Color("#2D3342")
	b_style.shadow_size = 12
	b_style.shadow_color = Color(0, 0, 0, 0.35)
	b_style.content_margin_left = 14
	b_style.content_margin_right = 14
	b_style.content_margin_top = 6
	b_style.content_margin_bottom = 6
	mock_banner_panel.add_theme_stylebox_override("panel", b_style)
	add_child(mock_banner_panel)

	var b_vbox = VBoxContainer.new()
	b_vbox.add_theme_constant_override("separation", 2)
	mock_banner_panel.add_child(b_vbox)

	# Ad Tag & Test ID watermark
	var tag_bar = HBoxContainer.new()
	b_vbox.add_child(tag_bar)

	var badge = Label.new()
	badge.text = "Ad"
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color("#FBBF24"))
	var badge_sb = StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.24, 0.20, 0.08)
	badge_sb.corner_radius_top_left = 3
	badge_sb.corner_radius_top_right = 3
	badge_sb.corner_radius_bottom_left = 3
	badge_sb.corner_radius_bottom_right = 3
	badge_sb.content_margin_left = 4
	badge_sb.content_margin_right = 4
	badge.add_theme_stylebox_override("normal", badge_sb)
	tag_bar.add_child(badge)

	var ad_source = Label.new()
	ad_source.text = "Google AdMob • Test Ad Unit: " + TEST_BANNER_ANDROID
	ad_source.add_theme_font_size_override("font_size", 10)
	ad_source.add_theme_color_override("font_color", Color("#94A3B8"))
	tag_bar.add_child(ad_source)

	var spacer_tag = Control.new()
	spacer_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_bar.add_child(spacer_tag)

	var ad_choices = Label.new()
	ad_choices.text = "ⓘ AdChoices"
	ad_choices.add_theme_font_size_override("font_size", 10)
	ad_choices.add_theme_color_override("font_color", Color("#64748B"))
	tag_bar.add_child(ad_choices)

	# Main Banner Content
	var content_bar = HBoxContainer.new()
	content_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	content_bar.add_theme_constant_override("separation", 12)
	b_vbox.add_child(content_bar)

	# App Icon
	var app_icon = Label.new()
	app_icon.text = "🧩"
	app_icon.add_theme_font_size_override("font_size", 28)
	content_bar.add_child(app_icon)

	# Text details
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 1)
	content_bar.add_child(text_vbox)

	var ad_title = Label.new()
	ad_title.text = "Woody Puzzle Odyssey: Escape Quest"
	ad_title.add_theme_font_size_override("font_size", 13)
	ad_title.add_theme_color_override("font_color", Color("#FFFFFF"))
	text_vbox.add_child(ad_title)

	var ad_meta = Label.new()
	ad_meta.text = "★ 4.9 (1.2M Reviews) • Free on Google Play"
	ad_meta.add_theme_font_size_override("font_size", 11)
	ad_meta.add_theme_color_override("font_color", Color("#FBBF24"))
	text_vbox.add_child(ad_meta)

	# CTA Install button
	var btn_install = Button.new()
	btn_install.text = "INSTALL"
	btn_install.custom_minimum_size = Vector2(96, 32)
	btn_install.focus_mode = Control.FOCUS_NONE
	var inst_sb = StyleBoxFlat.new()
	inst_sb.bg_color = Color("#1A73E8")
	inst_sb.corner_radius_top_left = 16
	inst_sb.corner_radius_top_right = 16
	inst_sb.corner_radius_bottom_left = 16
	inst_sb.corner_radius_bottom_right = 16
	btn_install.add_theme_stylebox_override("normal", inst_sb)
	btn_install.add_theme_font_size_override("font_size", 12)
	btn_install.add_theme_color_override("font_color", Color.WHITE)
	btn_install.pressed.connect(func():
		print("[AdMobManager] Banner CTA clicked. Test Unit ID: ", TEST_BANNER_ANDROID)
	)
	content_bar.add_child(btn_install)

	mock_banner_panel.hide()

	# 2. Mock Fullscreen Ad Container (for Rewarded & App Open)
	mock_ad_overlay = Control.new()
	mock_ad_overlay.name = "MockAdOverlay"
	mock_ad_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	mock_ad_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(mock_ad_overlay)
	mock_ad_overlay.hide()

# --- REWARDED VIDEO AD (FULL SCREEN PLAYABLE / VIDEO SIMULATOR) ---

func _show_mock_rewarded_dialog() -> void:
	for c in mock_ad_overlay.get_children():
		c.queue_free()

	mock_ad_overlay.show()
	rewarded_seconds_remaining = 5
	rewarded_granted = false

	# Background backdrop
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.07, 0.98)
	mock_ad_overlay.add_child(bg)

	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	mock_ad_overlay.add_child(root_vbox)

	# --- TOP ADMOB HEADER ---
	var top_panel = PanelContainer.new()
	var tp_sb = StyleBoxFlat.new()
	tp_sb.bg_color = Color("#12141C")
	tp_sb.content_margin_left = 18
	tp_sb.content_margin_right = 18
	tp_sb.content_margin_top = 14
	tp_sb.content_margin_bottom = 12
	top_panel.add_theme_stylebox_override("panel", tp_sb)
	root_vbox.add_child(top_panel)

	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_panel.add_child(top_hbox)

	var test_ad_badge = Label.new()
	test_ad_badge.text = "TEST AD"
	test_ad_badge.add_theme_font_size_override("font_size", 11)
	test_ad_badge.add_theme_color_override("font_color", Color.BLACK)
	var tsb = StyleBoxFlat.new()
	tsb.bg_color = Color.WHITE
	tsb.corner_radius_top_left = 3
	tsb.corner_radius_top_right = 3
	tsb.corner_radius_bottom_left = 3
	tsb.corner_radius_bottom_right = 3
	tsb.content_margin_left = 5
	tsb.content_margin_right = 5
	test_ad_badge.add_theme_stylebox_override("normal", tsb)
	top_hbox.add_child(test_ad_badge)

	var top_title = Label.new()
	top_title.text = "  Google AdMob Rewarded Video (" + TEST_REWARDED_ANDROID + ")"
	top_title.add_theme_font_size_override("font_size", 11)
	top_title.add_theme_color_override("font_color", Color("#94A3B8"))
	top_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(top_title)

	var lbl_timer = Label.new()
	lbl_timer.text = "Reward in 5s ⏳"
	lbl_timer.add_theme_font_size_override("font_size", 13)
	lbl_timer.add_theme_color_override("font_color", Color("#FBBF24"))
	top_hbox.add_child(lbl_timer)

	var btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(36, 36)
	btn_close.focus_mode = Control.FOCUS_NONE
	var c_sb = StyleBoxEmpty.new()
	btn_close.add_theme_stylebox_override("normal", c_sb)
	btn_close.add_theme_font_size_override("font_size", 18)
	btn_close.add_theme_color_override("font_color", Color("#94A3B8"))
	top_hbox.add_child(btn_close)

	# Progress Bar
	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(0, 4)
	pbar.max_value = 5.0
	pbar.value = 0.0
	pbar.show_percentage = false
	var pb_fg = StyleBoxFlat.new()
	pb_fg.bg_color = Color("#22C55E")
	pbar.add_theme_stylebox_override("fill", pb_fg)
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color("#1E293B")
	pbar.add_theme_stylebox_override("background", pb_bg)
	root_vbox.add_child(pbar)

	# --- HERO VIDEO CREATIVE SIMULATION ---
	var hero_center = CenterContainer.new()
	hero_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(hero_center)

	var creative_panel = PanelContainer.new()
	creative_panel.custom_minimum_size = Vector2(480, 520)
	var cr_sb = StyleBoxFlat.new()
	cr_sb.bg_color = Color("#171A23")
	cr_sb.border_width_left = 2
	cr_sb.border_width_top = 2
	cr_sb.border_width_right = 2
	cr_sb.border_width_bottom = 2
	cr_sb.border_color = Color("#22C55E")
	cr_sb.corner_radius_top_left = 20
	cr_sb.corner_radius_top_right = 20
	cr_sb.corner_radius_bottom_left = 20
	cr_sb.corner_radius_bottom_right = 20
	cr_sb.shadow_size = 24
	cr_sb.shadow_color = Color(0, 0, 0, 0.6)
	creative_panel.add_theme_stylebox_override("panel", cr_sb)
	hero_center.add_child(creative_panel)

	var cr_vbox = VBoxContainer.new()
	cr_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cr_vbox.add_theme_constant_override("separation", 18)
	creative_panel.add_child(cr_vbox)

	var tv_icon = Label.new()
	tv_icon.text = "📺"
	tv_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv_icon.add_theme_font_size_override("font_size", 54)
	cr_vbox.add_child(tv_icon)

	var cr_title = Label.new()
	cr_title.text = "GOOGLE ADMOB REWARDED VIDEO"
	cr_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr_title.add_theme_font_size_override("font_size", 20)
	cr_title.add_theme_color_override("font_color", Color.WHITE)
	cr_vbox.add_child(cr_title)

	var cr_desc = Label.new()
	cr_desc.text = "Playing sponsored gameplay ad...\nWatch until the countdown finishes to earn +1 Extra Drop!"
	cr_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cr_desc.add_theme_font_size_override("font_size", 14)
	cr_desc.add_theme_color_override("font_color", Color("#94A3B8"))
	cr_vbox.add_child(cr_desc)

	var status_lbl = Label.new()
	status_lbl.text = "Video Playing • 5s remaining"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 15)
	status_lbl.add_theme_color_override("font_color", Color("#FBBF24"))
	cr_vbox.add_child(status_lbl)

	# --- BOTTOM STORE CARD ---
	var btm_panel = PanelContainer.new()
	var bp_sb = StyleBoxFlat.new()
	bp_sb.bg_color = Color("#12141C")
	bp_sb.border_width_top = 1
	bp_sb.border_color = Color("#2D3342")
	bp_sb.content_margin_left = 24
	bp_sb.content_margin_right = 24
	bp_sb.content_margin_top = 16
	bp_sb.content_margin_bottom = 20
	btm_panel.add_theme_stylebox_override("panel", bp_sb)
	root_vbox.add_child(btm_panel)

	var btm_vbox = VBoxContainer.new()
	btm_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btm_vbox.add_theme_constant_override("separation", 10)
	btm_panel.add_child(btm_vbox)

	var btn_action = Button.new()
	btn_action.text = "COMPLETE AD & CONTINUE PLAYING ▶"
	btn_action.custom_minimum_size = Vector2(320, 50)
	btn_action.focus_mode = Control.FOCUS_NONE
	var act_sb = StyleBoxFlat.new()
	act_sb.bg_color = Color("#2E7D32")
	act_sb.corner_radius_top_left = 14
	act_sb.corner_radius_top_right = 14
	act_sb.corner_radius_bottom_left = 14
	act_sb.corner_radius_bottom_right = 14
	btn_action.add_theme_stylebox_override("normal", act_sb)
	btn_action.add_theme_font_size_override("font_size", 15)
	btn_action.add_theme_color_override("font_color", Color.WHITE)
	btn_action.pressed.connect(func():
		_close_mock_rewarded(true)
	)
	btm_vbox.add_child(btn_action)

	btn_close.pressed.connect(func():
		_close_mock_rewarded(rewarded_granted)
	)

	# Real countdown simulation
	rewarded_countdown_tween = create_tween()
	rewarded_countdown_tween.tween_method(func(v: float):
		if not is_instance_valid(pbar): return
		pbar.value = v
		var rem = maxi(0, 5 - int(v))
		if rem > 0:
			lbl_timer.text = "Reward in %ds ⏳" % rem
			status_lbl.text = "Video Playing • %ds remaining" % rem
		else:
			rewarded_granted = true
			lbl_timer.text = "Reward Granted! ✓"
			lbl_timer.add_theme_color_override("font_color", Color("#22C55E"))
			status_lbl.text = "🎉 Reward Granted! (+1 Extra Drop Earned)"
			status_lbl.add_theme_color_override("font_color", Color("#22C55E"))
			btn_action.text = "CLAIM +1 DROP & RESUME GAME ▶"
			btn_close.add_theme_color_override("font_color", Color("#22C55E"))
	, 0.0, 5.0, 5.0)

func _close_mock_rewarded(grant_reward: bool) -> void:
	if rewarded_countdown_tween and rewarded_countdown_tween.is_valid():
		rewarded_countdown_tween.kill()

	mock_ad_overlay.hide()
	is_showing_ad = false

	if grant_reward:
		if current_reward_callback.is_valid():
			if current_reward_callback.get_argument_count() > 0:
				current_reward_callback.call(true)
			else:
				current_reward_callback.call()
		rewarded_ad_earned.emit("extra_life", 1)
		rewarded_ad_closed.emit(true)
	else:
		if current_fail_callback.is_valid():
			if current_fail_callback.get_argument_count() > 0:
				current_fail_callback.call(false)
			else:
				current_fail_callback.call()
		rewarded_ad_closed.emit(false)

	current_reward_callback = Callable()
	current_fail_callback = Callable()

# --- APP OPEN AD (FULL SCREEN HIGH IMPACT SPLASH FORMAT) ---

func _show_mock_app_open_dialog() -> void:
	for c in mock_ad_overlay.get_children():
		c.queue_free()

	mock_ad_overlay.show()

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.08, 0.98)
	mock_ad_overlay.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	mock_ad_overlay.add_child(center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 380)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#171A21")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#0284C7")
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_left = 20
	sb.corner_radius_bottom_right = 20
	sb.shadow_size = 24
	sb.shadow_color = Color(0, 0, 0, 0.6)
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var ad_tag_box = HBoxContainer.new()
	ad_tag_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(ad_tag_box)

	var ad_badge = Label.new()
	ad_badge.text = "Ad"
	ad_badge.add_theme_font_size_override("font_size", 11)
	ad_badge.add_theme_color_override("font_color", Color("#38BDF8"))
	var ad_sb = StyleBoxFlat.new()
	ad_sb.bg_color = Color(0.08, 0.20, 0.32)
	ad_sb.corner_radius_top_left = 4
	ad_sb.corner_radius_top_right = 4
	ad_sb.corner_radius_bottom_left = 4
	ad_sb.corner_radius_bottom_right = 4
	ad_sb.content_margin_left = 6
	ad_sb.content_margin_right = 6
	ad_badge.add_theme_stylebox_override("normal", ad_sb)
	ad_tag_box.add_child(ad_badge)

	var ad_tag = Label.new()
	ad_tag.text = "  Google AdMob • App Open Ad (" + TEST_APP_OPEN_ANDROID + ")"
	ad_tag.add_theme_font_size_override("font_size", 11)
	ad_tag.add_theme_color_override("font_color", Color("#38BDF8"))
	ad_tag_box.add_child(ad_tag)

	var splash_logo = Label.new()
	splash_logo.text = "➔ ArrowFlow ➔"
	splash_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_logo.add_theme_font_size_override("font_size", 34)
	splash_logo.add_theme_color_override("font_color", Color("#F28C28"))
	vbox.add_child(splash_logo)

	var subtitle = Label.new()
	subtitle.text = "Welcome back! Resume your peaceful, zen puzzle journey."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#94A3B8"))
	vbox.add_child(subtitle)

	var app_info = Label.new()
	app_info.text = "★ 4.9 • 50 Challenging Progressive Levels"
	app_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_info.add_theme_font_size_override("font_size", 12)
	app_info.add_theme_color_override("font_color", Color("#FBBF24"))
	vbox.add_child(app_info)

	var btn_dismiss = Button.new()
	btn_dismiss.text = "CONTINUE TO GAME ▶"
	btn_dismiss.custom_minimum_size = Vector2(280, 50)
	var d_sb = StyleBoxFlat.new()
	d_sb.bg_color = Color("#0284C7")
	d_sb.corner_radius_top_left = 14
	d_sb.corner_radius_top_right = 14
	d_sb.corner_radius_bottom_left = 14
	d_sb.corner_radius_bottom_right = 14
	btn_dismiss.add_theme_stylebox_override("normal", d_sb)
	btn_dismiss.add_theme_font_size_override("font_size", 15)
	btn_dismiss.add_theme_color_override("font_color", Color.WHITE)
	btn_dismiss.pressed.connect(_close_mock_app_open)
	vbox.add_child(btn_dismiss)

func _close_mock_app_open() -> void:
	mock_ad_overlay.hide()
	is_showing_ad = false
	app_open_ad_closed.emit()
