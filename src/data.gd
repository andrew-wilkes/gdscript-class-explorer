extends Node

const DATA_FILE = "res://classes.dat"
const SETTINGS_FILE_NAME = "user://settings.res"

var classes = {}
var settings: Settings
var settings_changed = false
var regex
var class_tree = {}
var class_list_key_map = {}
var selected_class = ""
var icons = {}

func _ready():
	load_classes()
	settings = load_settings()
	regex = RegEx.new()
	regex.compile('inherits="(\\w+)"')
	var keys = classes.keys()
	keys.sort()
	var idx = 0
	if settings.class_list.empty():
		settings_changed = true
		for key in keys:
			var class_item = ClassItem.new()
			class_item.keyword = key
			settings.class_list.append(class_item)
			class_list_key_map[key] = idx
			idx += 1
	else:
		# Add any new classes to class_list
		for cl_item in settings.class_list:
			class_list_key_map[cl_item.keyword] = idx
			idx += 1
		for key in keys:
			if not key in class_list_key_map.keys():
				var class_item = ClassItem.new()
				class_item.keyword = key
				settings.class_list.append(class_item)
				class_list_key_map[key] = idx
				idx += 1
	for key in keys:
		class_tree[key] = [get_inherited_class(classes[key])]
	# Add 'inherited by' keys
	for key in keys:
		var cname = class_tree[key][0]
		if cname.length() > 0:
			class_tree[cname].append(key)


func get_user_class(cname):
	return settings.class_list[class_list_key_map[cname]]


func get_inherited_class(xml: PoolByteArray):
	var cname = ""
	var s = xml.get_string_from_ascii()
	var result = regex.search(s)
	if result:
		cname = result.get_string(1)
	return cname


func get_inheritance_chain(cname):
	var chain = PoolStringArray([])
	chain = get_ancestor(cname, chain)
	return chain.join(" < ")


func get_ancestor(cname: String, chain: PoolStringArray):
	var cn = class_tree[cname][0]
	if cn.length() > 0:
		chain.append("[" + cn + "]")
		chain = get_ancestor(cn, chain)
	return chain


func get_inheritor_chain(cname):
	var chain = PoolStringArray([])
	var nodes: Array = class_tree[cname]
	if nodes.size() > 1:
		for idx in range(1, nodes.size()):
			chain.append("[" + nodes[idx] + "]")
	return chain.join(" , ")


# Add class info to dictionary
func load_classes():
	# var t = OS.get_system_time_msecs()
	var data: PoolStringArray = get_file_content(DATA_FILE).split("\n")
	var i = 0
	if data.size() > 2:
		while i < data.size():
			classes[data[i + 1]] = get_xml(data[i], data[i + 2])
			i += 3
	# print(OS.get_system_time_msecs() - t)


func get_xml(buffer_size, encoded_string: String) -> PoolByteArray:
	var bytes = PoolByteArray([])
	var i = 0
	while i < encoded_string.length():
		var hex = "0x" + encoded_string.substr(i, 2)
		bytes.append(hex.hex_to_int())
		i += 2
	return bytes.decompress(buffer_size, File.COMPRESSION_DEFLATE) #.get_string_from_ascii()


func get_file_content(path) -> String:
	var content = ""
	var file = File.new()
	if file.open(path, File.READ) == OK:
		content = file.get_as_text()
		file.close()
	return content


func load_settings(file_name = SETTINGS_FILE_NAME):
	var _settings = Settings.new()
	if ResourceLoader.exists(file_name):
		var data = ResourceLoader.load(file_name)
		if data is Settings: # Check that the data is valid
			_settings = data
	return _settings


func save_settings(_settings, file_name = SETTINGS_FILE_NAME):
	assert(ResourceSaver.save(file_name, _settings) == OK)
	settings_changed = false


func get_file_list(path):
	var files = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				files.append(file_name)
			file_name = dir.get_next()
		return files
	else:
		print("An error occurred when trying to access the path.")


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if settings_changed:
			save_settings(settings)
