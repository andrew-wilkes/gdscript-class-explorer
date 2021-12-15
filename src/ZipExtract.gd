extends WindowDialog

signal new_data_file(file_name)

var unzipped = OK
var dest_folder

func show_files():
	var n = 0
	var files = Data.get_file_list("")
	for b in $VBox.get_children():
		if n > 0:
			b.hide()
		n += 1
	n = 1
	for file in files:
		if file.get_extension() == "zip":
			var button: Button
			if n < $VBox.get_child_count():
				button = $VBox.get_child(n)
			else:
				button = $VBox/Button.duplicate()
				$VBox.add_child(button)
			n += 1
			button.text = file
			button.show()
			if not button.is_connected("pressed", self, "extract"):
				var _e = button.connect("pressed", self, "extract", [button])
			call_deferred("fit_content")
	if n == 1:
		$VBox/Label.text = "No ZIP file(s) found."


func fit_content():
	rect_size = $VBox.rect_size + Vector2(15, 15)


func extract(button: Button):
	var file = button.text
	var version = file.get_basename()
	var cmd
	var args
	var class_folders = ["/doc/classes/", "/modules/gdscript/doc_classes/"]
	var icon_folders = ["/editor/icons/", "/modules/gdscript/icons/"]
	var files = [file]
	add_files(files, class_folders, version)
	add_files(files, icon_folders, version)
# TAR.exe was added to Windows 10 (1903) from build 17063 or later.
	if OS.get_name() == "Windows":
		cmd = "tar"
		args = ["-xf"]
	else:
		cmd = "unzip" # Linux and Mac support unzip
		args = ["-u"]
	args.append_array(files)
	var output = []
	unzipped = OS.execute(cmd, args, true, output)
	logger.clear()
	logger.add_array(args)
	if not unzipped in [0, 1, 11]: # Acceptable return codes
		alert("There was an error " + str(unzipped) + " running " + cmd + " on your computer.\n" + output[0])
		return
	logger.add(output[0])
	logger.save_log()
	create_class_data_file(class_folders, version)


func add_files(files, paths, version):
	for path in paths:
		files.append("godot-" + version + path + "\\*")
		# The escaped * is needed to stop bash extending the path to include .import files


func create_class_data_file(source_folders: Array, version: String):
	var data = PoolStringArray([])
	dest_folder = version + ".dat"
	for dir in source_folders:
		dir = "godot-" + version + dir
		var files = Data.get_file_list(dir)
		for file_name in files:
			var xml = get_file_bytes(dir + file_name)
			data.append(String(xml.size())) # Buffer size
			data.append(file_name.get_basename()) # Class name
			data.append(xml.compress(File.COMPRESSION_DEFLATE).hex_encode())
	if Data.save_string(data.join("\n"), dest_folder) == OK:
		alert("Created class data file: " + dest_folder)
		unzipped = OK
	else:
		alert("Failed to save file: " + dest_folder)


func get_file_bytes(path) -> PoolByteArray:
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_buffer(file.get_len())
	file.close()
	return content


func alert(msg):
	get_node("Alert").dialog_text = msg
	get_node("Alert").popup_centered()


func _on_Alert_popup_hide():
	if unzipped == OK:
		hide()
		emit_signal("new_data_file", dest_folder)


func _on_ZipExtract_about_to_show():
	show_files()
