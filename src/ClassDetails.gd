extends Control

enum { RAW, FORMATTED }

var desc: RichTextLabel
var descbox
var notes
var desc_button
var notes_button
var ih
var ihby
var bdescbox
var history = []
var stepping_back = false
var back_button
var tab_list = [
	"constructors",
	"methods",
	"properties",
	"signals",
	"constants",
	"tutorials",
	"theme_items",
	"operators",
]
var current_tab_list = []
var tabs
var anchors = {} 
var anchor_map = {
	"constructors": "constructors",
	"methods": "methods",
	"members": "properties",
	"signals": "signals",
	"constants": "constants",
	"enums": "constants",
	"operators": "operators",
}
var weight
var current_class: ClassItem

func _ready():
	desc = find_node("Desc")
	descbox = find_node("DescBox")
	notes = find_node("Notes")
	desc_button = find_node("DescButton")
	notes_button = find_node("NotesButton")
	back_button = find_node("BackButton")
	tabs = find_node("TabContainer")
	ih = find_node("Inherits")
	ihby = find_node("Inherited")
	weight = find_node("HSlider")
	bdescbox = find_node("BDescBox")
	back_button.disabled = true
	descbox.hide()
	notes.get_parent().hide()
	if Data.selected_class == "":
		update_content("Object")
	else:
		update_content(Data.selected_class)
	check_if_testing()


func set_chain_text(rtl, txt):
	if txt.length() > 0:
		rtl.show()
		rtl.bbcode_text = rtl.add_links(txt)
		rtl.get_parent().get_child(0).show()
	else:
		rtl.bbcode_text = txt
		rtl.get_parent().get_child(0).hide()
		rtl.hide()


func update_content(cname, new = true):
	if new:
		stepping_back = false
		history.append(cname)
		if history.size() > 1:
			back_button.disabled = false
	else:
		if not stepping_back:
			stepping_back = true
			# Get previous value but preserve the first item
			cname = history[0]
			if history.size() > 1:
				cname = history.pop_back()
	current_class = Data.get_user_class(cname)

	set_chain_text(ih, Data.get_inheritance_chain(cname))
	set_chain_text(ihby, Data.get_inheritor_chain(cname))

	var info = get_info(cname)
	find_node("ClassName").text = cname
	if info.brief_description.length() > 0:
		bdescbox.show()
		find_node("BDesc").set_content(info.brief_description)
		desc.set_content(info.description)
		find_node("Icon").texture = Data.icons.get(cname)
	else:
		bdescbox.hide()
	weight.value = current_class.weight
	weight.hint_tooltip = String(int(weight.value))
	notes.text = current_class.notes
	set_notes_visibility(notes.text.length() > 0)

	# Set up tabs
	anchors = {}
	current_tab_list = []
	tabs.set_current_tab(0) # Switch to first tab
	var remove = false
	for tab in tabs.get_children():
		if remove:
			# Avoid problem of duplicate names
			tab.name = "x"
			tab.queue_free()
		else:
			tab.scroll_to_line(0) # Reset 1st tab's scroll position
		remove = true
	var add = false
	var tab = tabs.get_child(0)
	for key in tab_list:
		if info.has(key) and not info[key].empty():
			if add:
				tab = tab.duplicate()
				tabs.add_child(tab)
			current_tab_list.append(key)
			tab.name = key.capitalize()
			add = true
			add_items_to_tab(key, tab, info[key])


func add_anchor(tab, tab_name, item_name, line_number, idx = -1):
	if not anchors.has(tab_name):
		anchors[tab_name] = {}
	if idx >= 0:
		item_name = item_name + "-" + str(idx)
	anchors[tab_name][item_name] = {
		"tab": tab,
		"line": line_number
	}


func add_items_to_tab(prop: String, tab: RichContent, items):
	var content = PoolStringArray([])
	var line_number = 0
	match prop:
		"methods", "constructors", "operators":
			content.append("[table=2]")
			var description_groups = []
			for key in items.keys():
				var mstrs = get_method_strings(prop, key, items[key])
				content.append(mstrs[0])
				description_groups.append([key, mstrs[1]])
			content.append("[/table]\n")
			content.append("[b]%s Descriptions[/b]\n" % [prop.capitalize().trim_suffix("s")])
			line_number += 4
			for description_group in description_groups:
				# Add base method anchor point
				add_anchor(tab, prop, description_group[0], line_number)
				# Add descriptions and indexed anchor points
				var idx = 0
				for d in description_group[1]:
					add_anchor(tab, prop, description_group[0], line_number, idx)
					content.append(d)
					line_number += d.split("\n").size()
					idx += 1
		"properties":
			content.append("[table=2]")
			var descriptions = []
			for key in items.keys():
				var pstrs = get_property_strings(key, items[key])
				content.append(pstrs[0])
				descriptions.append([key, pstrs[1]])
			content.append("[/table]\n")
			content.append("[b]Property Descriptions[/b]\n")
			line_number += 4
			for d in descriptions:
				add_anchor(tab, prop, d[0], line_number)
				content.append(d[1])
				line_number += d[1].split("\n").size()
		"theme_items":
			content.append("[table=2]")
			for item in items:
				add_anchor(tab, prop, item, line_number)
				content.append(get_theme_item_string(item))
				line_number += 1
			content.append("[/table]")
		"signals":
			for item in items:
				add_anchor(tab, prop, item.name, line_number)
				var code = item.name + "(" + get_args(item.args) + ")\n[indent]" + item.get("description", "") + "[/indent]\n"
				content.append(code)
				line_number += code.split("\n").size()
		"constants":
			var enums = {}
			for item in items:
				var args = item.args[0]
				args.description = item.get("description", "")
				if args.has("enum"):
					if enums.has(args.enum):
						enums[args.enum].append(args)
					else:
						enums[args.enum] = [args]
				else: # Constant
					add_anchor(tab, prop, args.name, line_number)
					var code = "\u2022 " + args.name + " = " + args.value + " - " + item.get("description", "")
					content.append(code)
					line_number += code.split("\n").size()
			for ename in enums.keys():
				add_anchor(tab, prop, ename, line_number)
				content.append("[code]enum[/code]\t" + ename)
				var vals = {}
				for item in enums[ename]:
					vals[item.value] = item
				var keys = vals.keys()
				keys.sort()
				for key in keys:
					add_anchor(tab, prop, vals[key].name, line_number)
					var code = "\t\u2022 " + vals[key].name + " = " + vals[key].value + " - " + vals[key].description + "\n"
					content.append(code)
					line_number += code.split("\n").size()
		"tutorials":
			for link in items:
				content.append("\t" + get_link_string(link))
	tab.set_content(content.join("\n"))


func get_link_string(link):
	var url = ""
	if link.title == "":
		link.title = link.url
	else:
		url = link.url
	return "[url=%s]%s[/url] - %s" % [link.url, link.title, url]


func get_theme_item_string(attribs: Dictionary):
	var args = attribs.args[0]
	return "[cell][right]%s[/right]\t[/cell][cell]%s %s\t%s[/cell]" %  [get_return_type_string(args.type), args.name, get_default_property_value(args), attribs.get("description", "")]


func get_signal_string(sname, attribs):
	return "[cell][signal %s] (%s)[/cell]" % [sname, get_args(attribs.args)]


func get_property_strings(pname, attribs: Dictionary):
	var type = get_return_type_string(attribs.type)
	var ps = "[cell][right]%s[/right]\t[/cell][cell]%s %s[/cell]" % [type, bbcode_url(pname, "members"), get_default_property_value(attribs)]
	var pds = "\u2022 %s %s %s\n" % [type, pname, get_default_property_value(attribs)]
	if attribs.get("setter").length() > 0:
		pds += "\t%s setter\n" % [attribs.setter]
	if attribs.get("getter").length() > 0:
		pds += "\t%s getter\n\n" % [attribs.getter]
	if attribs.get("description", "").length() > 0:
		pds += "\t" + attribs.description + "\n"
	return [ps, pds]


func get_method_strings(tab, mname, attribs):
	var ms = PoolStringArray([])
	var mds = PoolStringArray([])
	var idx = 0
	for attrib in attribs:
		var ret_type = get_return_type_string(attrib.return_type)
		ms.append("[cell][right]%s[/right]\t[/cell][cell]%s(%s) %s[/cell]" % [ret_type, bbcode_url(mname, tab, idx), get_args(attrib.args), attrib.qualifiers])
		mds.append("\u2022 %s %s(%s) %s\n\n\t%s\n" % [ret_type, mname, get_args(attrib.args), attrib.qualifiers, attrib.description])
		idx += 1
	return [ms.join("\n"), mds]


func get_default_property_value(item: Dictionary):
	var ds = item.get("default", "")
	return "[default: %s]" % [ds] if ds.length() > 0 else ""


func get_return_type_string(type: String):
	if type.length() == 0:
		type = "void"
	return bbcode_url(type) if type != "void" else type


# Add index to name if it has a target such as method
func bbcode_url(mname, target = "", idx = -1):
	if target.length() > 0:
		target = target + " " + mname
	else:
		target = mname
	if idx >= 0:
		target = target + "-" + str(idx)
	return '[url=%s]%s[/url]' % [target, mname]


func get_args(args: Array):
	var astr = PoolStringArray([])
	var dict = {}
	for arg in args:
		dict[arg.index] = arg
	var keys = dict.keys()
	keys.sort()
	for key in keys:
		astr.append("%s: [%s]%s" % [dict[key].name, dict[key].type, get_default_arg_value(dict[key])])
	return astr.join(", ")


func get_default_arg_value(arg: Dictionary):
	if arg.has("default"):
		return " = " + arg["default"]
	else:
		return ""


func get_info(cname) -> Dictionary:
	var info = { "brief_description": "", "description": "" }
	var node_name = ""
	var group_name = ""
	var member_name = ""
	var text_target
	var dict_target
	var text_node_name
	var text_mode
	var parser = XMLParser.new()
	if parser.open_buffer(Data.classes[cname]) == OK:
		while true:
			if parser.read() != OK:
				return info
			match parser.get_node_type():
				parser.NODE_ELEMENT:
					node_name = parser.get_node_name()
					match node_name:
						"brief_description":
							text_mode = RAW
							text_target = info
							text_node_name = node_name
						"description":
							if group_name == "":
								text_mode = RAW
								text_target = info
								text_node_name = node_name
						"tutorials":
							info[node_name] = []
							group_name = node_name
						"link":
							var link = {
								"title": parser.get_named_attribute_value_safe("title")
							}
							info[group_name].append(link)
							text_target = link
							text_node_name = "url"
						"methods", "constructors", "operators":
							info[node_name] = {} # These items may have variants with the same name but various input parameters like method overrides
							group_name = node_name
							text_node_name = "description"
						"method", "constructor", "operator":
							var method_name = parser.get_named_attribute_value("name")
							var method = {
								"qualifiers": parser.get_named_attribute_value_safe("qualifiers"),
								"args": [],
								"return_type": "",
								"description": "",
							}
							if info[group_name].has(method_name):
								info[group_name][method_name].append(method)
							else:
								info[group_name][method_name] = [method]
							dict_target = method
							text_target = method
							text_mode = RAW
						"return":
							dict_target["return_type"] = get_type(parser)
						"argument":
							add_arg(parser, dict_target)
						"members":
							info["properties"] = {}
							group_name = "properties"
						"member":
							var keys = ["type", "setter", "getter", "default"]
							member_name = add_member(parser, info, group_name, keys)
							text_target = info[group_name][member_name]
							text_mode = RAW
						"theme_items":
							info[node_name] = []
							group_name = node_name
						"theme_item":
							var dict = {
								"args": [],
							}
							add_arg(parser, dict)
							info[group_name].append(dict)
							text_target = dict
							text_mode = RAW
							dict_target = dict
						"signals":
							info[node_name] = []
							group_name = node_name
						"signal":
							var dict = {
								"name": parser.get_named_attribute_value("name"),
								"args": [],
							}
							info[group_name].append(dict)
							text_target = dict
							text_mode = RAW
							dict_target = dict
						"constants":
							info[node_name] = []
							group_name = node_name
						"constant":
							var dict = {
								"args": [],
							}
							info[group_name].append(dict)
							text_target = dict
							text_mode = RAW
							dict_target = dict
							add_arg(parser, dict_target)
				parser.NODE_TEXT:
					if text_target != null:
						var txt = get_node_text(parser.get_node_data())
						# We get unexpected blank text nodes, so ignore them
						if txt.length() > 0:
							if text_mode == FORMATTED:
								txt = remove_square_braces(txt)
							text_target[text_node_name] = txt
							text_target = null
	return info


func get_type(parser):
	var _type = parser.get_named_attribute_value("type")
	var _enum = parser.get_named_attribute_value_safe("enum")
	if _enum.length() > 0:
		_type = _enum
	return _type


func add_member(parser: XMLParser, info: Dictionary, group_name, keys: Array) -> String:
	var member_name = parser.get_named_attribute_value("name")
	var member = {}
	for key in keys:
		member[key] = parser.get_named_attribute_value_safe(key)
	info[group_name][member_name] = member
	return member_name


func add_arg(parser: XMLParser, dict_target):
	var num_atrs = parser.get_attribute_count()
	var atrs = {}
	for idx in num_atrs:
		atrs[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
	dict_target["args"].append(atrs)


func get_node_text(txt: String):
	return txt.lstrip("\n\t ").rstrip("\n\t ").replace("\t", "")


func remove_square_braces(txt):
	return txt.replace("[", "").replace("]", "")


func _on_meta_clicked(meta):
	var url = String(meta).split(" ", false, 1)
	if url[0].begins_with("http"):
		var _e = OS.shell_open(str(meta))
	elif url.size() == 2:
		# Go to a tab and specific item
		var tab_name = anchor_map[ url[0] ] # url[0] == "method" for example
		var target = anchors[tab_name][ url[1] ] # url[1] == name of the method for example
		tabs.set_current_tab(current_tab_list.find(tab_name))
		$SC.scroll_vertical = 0
		target.tab.scroll_to_line(target.line)
	else:
		# Go to a new class details scene
		update_content(meta)
		$SC.scroll_vertical = 0


func _on_Description_pressed():
	descbox.visible = not descbox.visible
	desc_button.text = "-" if descbox.visible else "+"


func _on_NotesButton_pressed():
	set_notes_visibility(not notes.get_parent().visible)
	notes.grab_focus()


func set_notes_visibility(_visible: bool):
	notes.get_parent().visible = _visible
	notes_button.text = "-" if _visible else "+"


func _on_BackButton_pressed():
	# Preserve the first item
	var cname = history[0]
	if history.size() > 1:
		cname = history.pop_back()
	else:
		back_button.disabled = true
	update_content(cname, false)


func _on_HSlider_value_changed(value):
	current_class.weight = value
	weight.hint_tooltip = String(int(value))
	Data.settings_changed = true


func _on_Notes_text_changed():
	current_class.notes = notes.text
	Data.settings_changed = true


func _on_Classes_pressed():
	change_scene()


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			change_scene()


func change_scene():
	if Data.testing:
		var _e = get_tree().change_scene("res://Tests.tscn")
	else:
		var _e = get_tree().change_scene("res://Main.tscn")


func check_if_testing():
	if Data.testing:
		yield(get_tree(), "idle_frame")
		#yield(get_tree().create_timer(1.0), "timeout")
		var _e = get_tree().change_scene("res://Tests.tscn")
