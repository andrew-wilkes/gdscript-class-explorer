extends Control

enum { ABOUT, DOCS, QA, LICENCES, GODOT, DOWNLOAD, EXTRACT, SELECT }

enum LIST_MODE { ALPHA, TREE, GROUP, RAND }
enum SORT_ORDER { AZ, ZA }

const GROUP_NODES = ["Node2D", "Node3D", "Spatial", "Control", "Viewport", "Others"]
const DEFAULT_ICON_KEY = "arrowright"

export(Color) var class_text_highlight_color = Color.green
export(Color) var class_text_normal_color = Color.white

var list: VBoxContainer
var list_button = preload("res://ListButton.tscn")
var item_desc = {}
var class_details_scene = preload("res://ClassDetails.tscn")
var grid
var the_tree: Tree
var b_container
var link_icon = preload("res://assets/icons/icon_instance.svg")
var download_icon = preload("res://assets/icons/icon_asset_lib.svg")
var extract_icon = preload("res://assets/icons/icon_distraction_free.svg")
var select_icon = preload("res://assets/icons/icon_loop.svg")
var icon_files = {}
var tree_map = {}
var sort_reversed = false
var default_icon
var group_nodes = []

func _ready():
	show_version("")
	var fm = $VBox/Menu/File.get_popup()
	fm.add_icon_item(download_icon, "Download Source Code", DOWNLOAD)
	fm.add_icon_item(extract_icon, "Extract Data", EXTRACT)
	fm.add_icon_item(select_icon, "Select Data File", SELECT)
	fm.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	var hm = $VBox/Menu/Help.get_popup()
	hm.add_icon_item(link_icon, "Online Documentation", DOCS)
	hm.add_icon_item(link_icon, "Questions & Answers", QA)
	hm.add_icon_item(link_icon, "Godot Engine", GODOT)
	hm.add_separator()
	hm.add_item("About", ABOUT, KEY_MASK_CTRL | KEY_A)
	hm.add_item("Licences", LICENCES)
	hm.connect("id_pressed", self, "_on_HelpMenu_id_pressed")
	var h = InputEventKey.new()
	h.alt = true
	h.scancode = KEY_H
	$VBox/Menu/Help.shortcut = h
	grid = $VBox/BC/Grid
	the_tree = find_node("Tree")
	b_container = $VBox/BC
	
	if Data.settings.data_file != "":
		if Data.data_ok:
			setup_class_view()
		else:
			bad_data()
	else:
		disable_class_button_menu_items()
		$c/Welcome.popup_centered()


func disable_class_button_menu_items(disabled = true):
	for item in get_tree().get_nodes_in_group("class_buttons"):
		item.disabled = disabled


func show_version(txt):
	$VBox/Menu/Version.text = txt


func setup_class_view():
	show_version(Data.version)
	# Form base node list for the current version of classes
	group_nodes.clear()
	for node in GROUP_NODES:
		if node in Data.classes.keys():
			group_nodes.append(node)
	# Add buttons and build icon list
	for cname in Data.classes.keys():
		var button = list_button.instance()
		grid.add_child(button)
		button.connect("gui_input", self, "_on_Button_gui_input", [button])
		Data.icons[cname] = cname.to_lower() # Use this value to compare to icon file names
	get_icon_files()
	map_icons("Object")
	map_other_icons()
	default_icon = icon_files.get(DEFAULT_ICON_KEY)
	
	# Create Tree
	tree_map.clear()
	var root = the_tree.create_item()
	# Build the Object branch first since this contains the more interesting nodes to show at the top
	build_tree(the_tree, root, "Object")
	# Now start from classes that have no parent and no children
	for key in Data.class_tree.keys():
		if Data.class_tree[key].size() == 1 and Data.class_tree[key][0].length() == 0:
			build_tree(the_tree, root, key)
	
	update_weighted_labels()
	
	match Data.settings.list_mode:
		LIST_MODE.ALPHA:
			set_visibility(false, false, false)
		LIST_MODE.GROUP:
			update_labels_by_group()
			set_visibility(false, false, true)
		LIST_MODE.RAND:
			randomize_buttons()
			set_visibility(false, false, true)
		LIST_MODE.TREE:
			set_visibility(true, true, true)
	clear_search_box()
	grid.columns = 1
	call_deferred("arrange_controls")


func set_visibility(show_tree, rand_disabled, reset_disabled):
	$VBox/Tree.visible = show_tree
	$VBox/BC.visible = not show_tree
	$VBox/Menu/Random.disabled = rand_disabled
	$VBox/Menu/Reset.disabled = reset_disabled


func get_icon_files():
	var image = Image.new()
	for path in Data.get_icon_paths():
		var files = Data.get_file_list(path)
		if files.size() == 0:
			continue
		var imports = []
		for file_name in files:
			# Detect imported images
			if file_name.get_extension() == "import":
				# store name.svg
				imports.append(get_icon_key(file_name))
		for file_name in files:
			if file_name.get_extension() == "svg":
				var texture
				var icon_key = get_icon_key(file_name)
				var icon_path = path + file_name
				if icon_key in imports:
					# Use load for imported images
					texture = load(icon_path)
				else:
					# External image
					texture = ImageTexture.new()
					image.load(icon_path)
					texture.create_from_image(image)
				icon_files[icon_key] = texture


func get_icon_key(file_name):
	return file_name.get_basename().to_lower().replace("icon", "").replace("_", "")


# Traverse the tree
func map_icons(cname):
	if icon_files.get(cname.to_lower()): # Check for matching icon file
		Data.icons[cname] = icon_files[cname.to_lower()]
	else:
		# Use same icon as parent
		Data.icons[cname] = Data.icons.get(Data.class_tree[cname][0], default_icon)
	var idx = 0
	for child in Data.class_tree[cname]:
		if idx > 0:
			map_icons(child)
		idx += 1


func map_other_icons():
	for cname in Data.classes.keys():
		if cname.begins_with("@"):
			Data.icons[cname] = icon_files.get("arrowright")
		elif Data.class_tree[cname][0].length() == 0:
			map_icons(cname)


# Credit to: Mounir Tohami "fixed the maximize issue when the grid is empty"
func arrange_controls():
	var w_size = OS.window_size.x
	var b_size = 1.0
	if grid.get_child_count() > 0:
		b_size = grid.get_child(0).rect_size.x
	var n_cols = int(floor(w_size / b_size))
	if n_cols != grid.columns:
		grid.columns = n_cols


func clear_search_box():
	$VBox/SS.grab_focus()
	$VBox/SS.text = ""
	$VBox/BC.scroll_vertical = 0


func _on_Button_gui_input(event, button):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				$VBox/BC.scroll_vertical = 0
				show_details(button.text)
			BUTTON_RIGHT:
				# Reset the weight
				update_weight(button.text, 0)


func show_details(cname):
	Data.selected_class = cname
	clear_search_box()
	update_weight(cname)
	var _e = get_tree().change_scene("res://ClassDetails.tscn")


func update_weight(cname, n = 1):
	for class_item in Data.settings.class_list:
		if class_item.keyword == cname:
			if n == 0:
				class_item.weight = 0
			else:
				class_item.weight += n
			Data.settings_changed = true
			update_weighted_labels()
			return


func update_weighted_labels():
	var weights = []
	var weighted_items = []
	var unweighted_items = []
	for class_item in Data.settings.class_list:
		# Skip saved class info for classes not in this version of Godot
		if not class_item.keyword in Data.classes.keys():
			continue
		var weight = class_item.weight
		if weight > 0:
			weights.append(weight)
			weighted_items.append(class_item.duplicate())
		else:
			unweighted_items.append(class_item)
	weights.sort()
	weights.invert()
	var idx = 0
	for weight in weights:
		for item in weighted_items: # Find first item with this weight
			if item.weight == weight:
				configure_button(grid.get_child(idx), item, class_text_highlight_color)
				item.weight = 0 # Skip this item for this weight from now on
				break
		idx += 1
	if sort_reversed:
		unweighted_items.invert()
	for item in unweighted_items:
		configure_button(grid.get_child(idx), item)
		idx += 1


func update_labels_by_group():
	var idx = 0
	for i in group_nodes.size():
		var group_node = group_nodes[posmod(Data.settings.group_mode + i, group_nodes.size())]
		var others = false
		if group_node != "Others":
			idx = configure_button_tree(group_node, idx, others)
		else:
			others = true
			for key in Data.class_tree.keys():
				if Data.class_tree[key][0].length() == 0:
					idx = configure_button_tree(key, idx, others)


func randomize_buttons():
	var items = Data.classes.keys().duplicate()
	items.shuffle() # Cannot store seed for shuffle
	var idx = 0
	for item in items:
		configure_button(grid.get_child(idx), Data.get_user_class(item))
		idx += 1

var tree_item_count = 0

func build_tree(tree: Tree, tree_item: TreeItem, cname: String):
	var item = tree.create_item(tree_item)
	tree_item_count += 1
	tree_map[cname.to_lower()] = item # Used for search
	item.set_text(0, cname)
	item.set_icon(0, Data.icons[cname])
	item.set_text(1, get_brief_description(cname).trim_prefix("</")) # Trim garbage from empty text
	var tool_tip_text = "Double click to see details"
	item.set_tooltip(0, tool_tip_text)
	item.set_tooltip(1, tool_tip_text)
	# List child nodes that have children first
	var a_nodes = []
	var b_nodes = []
	var idx = 0
	for child in Data.class_tree[cname]:
		if idx > 0:
			if Data.class_tree[child].size() > 1:
				a_nodes.append(child)
			else:
				b_nodes.append(child)
		idx += 1
	a_nodes.append_array(b_nodes)
	for child in a_nodes:
		build_tree(tree, item, child)


func configure_button_tree(cname: String, idx: int, others: bool):
	# Skip child nodes of Node if already processed
	if others and cname in group_nodes:
		return idx
	configure_button(grid.get_child(idx), Data.get_user_class(cname))
	idx += 1
	for i in range(1, Data.class_tree[cname].size()):
		var child = Data.class_tree[cname][i]
		idx = configure_button_tree(Data.get_user_class(child).keyword, idx, others)
	return idx


func configure_button(button: Button, item: ClassItem, text_color: Color = class_text_normal_color):
	button.text = item.keyword
	button.hint_tooltip = get_brief_description(item.keyword)
	button.set("custom_colors/font_color", text_color)
	button.icon = Data.icons.get(item.keyword)
	button.visible = true


func _on_SS_text_changed(new_text: String):
	if Data.data_ok:
		if Data.settings.list_mode == LIST_MODE.TREE:
			search_tree(new_text.to_lower())
		else:
			search_grid(new_text.to_lower())


func search_tree(new_text: String):
	if new_text.length() > 1:
		# Find close match
		for cname in tree_map.keys():
			if cname.begins_with(new_text):
				the_tree.scroll_to_item(tree_map[cname])
				tree_map[cname].select(0)
				return
		for cname in tree_map.keys():
			if new_text in cname:
				the_tree.scroll_to_item(tree_map[cname])
				tree_map[cname].select(0)
				return
	the_tree.get_root().select(0)
	the_tree.scroll_to_item(the_tree.get_root())


func _on_Tree_item_activated():
	var cname = the_tree.get_selected().get_text(0)
	the_tree.get_root().select(0)
	show_details(cname)


func search_grid(new_text: String):
	var matches = []
	if new_text.length() > 1:
		# Find close matches
		var idx = 0
		for item in grid.get_children():
			if new_text in item.text.to_lower():
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
		GODOT:
			var _e = OS.shell_open("https://godotengine.org/")


func _on_ok_pressed():
	$c/Licences.hide()


func _on_Timer_timeout():
	call_deferred("arrange_controls")


# Check this on slower PC
func _on_Main_resized():
	if grid:
		grid.columns = 1
		yield(get_tree(), "idle_frame")
		call_deferred("arrange_controls")


func _on_Items_pressed():
	if Data.settings.list_mode != LIST_MODE.ALPHA:
		Data.settings.list_mode = LIST_MODE.ALPHA
		Data.settings_changed = true
		set_visibility(false, false, false)
	else:
		sort_reversed = not sort_reversed
	update_weighted_labels()
	clear_search_box()


func _on_Groups_pressed():
	if Data.settings.list_mode == LIST_MODE.GROUP:
		Data.settings.group_mode = posmod(Data.settings.group_mode + 1, group_nodes.size())
	else:
		Data.settings.list_mode = LIST_MODE.GROUP
		set_visibility(false, false, true)
	clear_search_box()
	Data.settings_changed = true
	update_labels_by_group()


func _on_Tree_pressed():
	if Data.settings.list_mode != LIST_MODE.TREE:
		Data.settings.list_mode = LIST_MODE.TREE
		Data.settings_changed = true
		set_visibility(true, true, true)
	clear_search_box()


func _on_Random_pressed():
	Data.settings.list_mode = LIST_MODE.RAND
	Data.settings_changed = true
	randomize_buttons()


func _on_Reset_pressed():
	var changed = false
	for class_item in Data.settings.class_list:
		if class_item.weight > 0:
			changed = true
			class_item.weight = 0
	if changed:
		update_weighted_labels()
		Data.settings_changed = true
	clear_search_box()


func _on_FileMenu_id_pressed(id):
	match id:
		DOWNLOAD:
			$c/FileDownload.popup_centered()
		EXTRACT:
			$c/ZipExtract.popup_centered()
		SELECT:
			$c/SelectDataFile.popup_centered()


func _on_SelectDataFile_selected_data_file(file):
	Data.settings.data_file = file
	if Data.load_classes():
		Data.settings_changed = true
		clear_scene()
		yield(get_tree(), "idle_frame")
		setup_class_view()
		disable_class_button_menu_items(false)
	else:
		bad_data()


func clear_scene():
	the_tree.clear()
	for node in grid.get_children():
		node.queue_free()


func bad_data():
	disable_class_button_menu_items()
	var bd: AcceptDialog = $c/BadData
	bd.dialog_text = bd.dialog_text.replace("FILE", Data.settings.data_file)
	bd.popup_centered()


func _on_ZipExtract_new_data_file(file_name):
	_on_SelectDataFile_selected_data_file(file_name)


func _on_about_ok_pressed():
	$c/About.hide()
