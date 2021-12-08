extends Control

enum { ABOUT, DOCS, QA, LICENCES }

const ICONS_PATH = "res://assets/icons/"

var list: VBoxContainer
var list_button = preload("res://ListButton.tscn")
var button_color: Color
var item_desc = {}
var class_details_scene = preload("res://ClassDetails.tscn")
var grid
var b_container
var link_icon = preload("res://assets/icons/icon_instance.svg")
var icons = {}
var icon_files = {}

func _ready():
	var hm = $VBox/Menu/Help.get_popup()
	hm.add_icon_item(link_icon, "Online Documentation", DOCS)
	hm.add_icon_item(link_icon, "Questions & Answers", QA)
	hm.add_separator()
	hm.add_item("About", ABOUT, KEY_MASK_CTRL | KEY_A)
	hm.add_item("Licences", LICENCES)
	hm.connect("id_pressed", self, "_on_HelpMenu_id_pressed")
	var h = InputEventKey.new()
	h.alt = true
	h.scancode = KEY_H
	$VBox/Menu/Help.shortcut = h
	grid = $VBox/BC/Grid
	b_container = $VBox/BC
	# Add buttons and build icon list
	for cname in Data.classes.keys():
		var button = list_button.instance()
		grid.add_child(button)
		button.connect("pressed", self, "item_pressed", [button])
		icons[cname] = cname.to_lower() # Use this value to compare to icon file names
	get_icon_files()
	map_icons("Object")
	map_other_icons()
	button_color = grid.get_child(0).modulate
	update_labels()
	clear_search_box()
	grid.columns = 1
	call_deferred("arrange_controls")


func get_icon_files():
	var files = Data.get_file_list(ICONS_PATH)
	for fn in files:
		var file_name: String = fn
		if file_name.get_extension() == "svg":
			icon_files[file_name.get_basename().to_lower().replace("icon", "").replace("_", "")] = load(ICONS_PATH + file_name)


# Traverse the tree
func map_icons(cname):
	if icon_files.get(cname.to_lower()): # Check for matching icon file
		icons[cname] = icon_files[cname.to_lower()]
	else:
		# Use same icon as parent
		icons[cname] = icons[Data.class_tree[cname][0]]
	var idx = 0
	for child in Data.class_tree[cname]:
		if idx > 0:
			map_icons(child)
		idx += 1


func map_other_icons():
	for cname in Data.classes.keys():
		if cname.begins_with("@"):
			icons.erase(cname)
		elif Data.class_tree[cname][0].length() == 0:
			map_icons(cname)


func arrange_controls():
	var w_size = OS.window_size.x
	var b_size = grid.get_child(0).rect_size.x
	var n_cols = int(floor(w_size / b_size))
	if n_cols != grid.columns:
		grid.columns = n_cols


func clear_search_box():
	$VBox/SS.grab_focus()
	$VBox/SS.text = ""


func item_pressed(button):
	clear_search_box()
	$VBox/BC.scroll_vertical = 0
	for class_item in Data.settings.class_list:
		if class_item.keyword == button.text:
			class_item.weight += 1
			Data.settings_changed = true
			break
	Data.selected_class = button.text
	var _e = get_tree().change_scene("res://ClassDetails.tscn")
	update_labels()


func update_labels():
	var weights = []
	var weighted_items = []
	var unweighted_items = []
	for class_item in Data.settings.class_list:
		var weight = class_item.weight
		if weight > 0:
			weights.append(weight)
			weighted_items.append(class_item.duplicate())
		else:
			unweighted_items.append(class_item)
	weights.sort()
	weights.invert()
	var i = 0
	for weight in weights:
		for item in weighted_items: # Find first item with this weight
			if item.weight == weight:
				var button: Button = grid.get_child(i)
				button.text = item.keyword
				button.hint_tooltip = get_brief_description(item.keyword)
				button.modulate = button_color.lightened(0.2)
				button.icon = icons.get(item.keyword)
				item.weight = 0 # Skip this item for this weight from now on
				break
		i += 1
	for item in unweighted_items:
		var button: Button = grid.get_child(i)
		button.text = item.keyword
		button.hint_tooltip = get_brief_description(item.keyword)
		button.modulate = button_color
		button.icon = icons.get(item.keyword)
		i += 1
	for item in grid.get_children():
		item.visible = true


func _on_SS_text_changed(new_text: String):
	var matches = []
	if new_text.length() > 1:
		# Find close matches
		var idx = 0
		for item in grid.get_children():
			if new_text.to_lower() in item.text.to_lower():
				matches.append(idx)
			idx += 1
	# Make all visible or just those matched
	for i in grid.get_child_count():
		var vis = true if matches.size() == 0 else i in matches
		grid.get_child(i).visible = vis


func get_brief_description(key):
	if not item_desc.has(key):
		item_desc[key] = Data.classes[key].get_string_from_ascii().split("brief_description")[1].split("\n")[1].dedent().replace("[", "").replace("]", "")
	return item_desc[key]


func _on_ClassExplorer_pressed():
	var _e = get_tree().change_scene("res://ClassList.tscn")


func _on_HelpMenu_id_pressed(id):
	match id:
		ABOUT:
			$c/About.popup_centered()
		LICENCES:
			$c/Licences.popup_centered()
		DOCS:
			var _e = OS.shell_open("https://docs.godotengine.org/en/stable/")
		QA:
			var _e = OS.shell_open("https://godotengine.org/qa/")


func _on_ok_pressed():
	$c/Licences.hide()


func _on_Timer_timeout():
	call_deferred("arrange_controls")


func _on_Main_resized():
	if grid:
		grid.columns = 1
		if $Timer.is_stopped():
			$Timer.start(0.5)
