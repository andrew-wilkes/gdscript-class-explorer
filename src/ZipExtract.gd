extends WindowDialog

var unzipped = OK

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
	var class_folder = "godot-" + version + "/doc/classes/"
	var files = [file, class_folder + "*", "godot-" + version + "/editor/icons/*"]
# TAR.exe was added to Windows 10 (1903) from build 17063 or later.
	if OS.get_name() == "Windows":
		cmd = "tar"
		args = ["-xf"]
	else:
		cmd = "unzip" # Linux and Mac support unzip
		args = ["-u"]
	args.append_array(files)
	unzipped = OS.execute(cmd, args)
	if unzipped != OK:
		alert("There was an error running " + cmd + " on your computer.")
		return
	create_class_data_file(class_folder, version + ".dat")


func create_class_data_file(source_folder: String, dest_folder: String):
	var files = Data.get_file_list(source_folder)
	var data = PoolStringArray([])
	for file_name in files:
		var xml = get_file_bytes(source_folder + file_name)
		data.append(String(xml.size())) # Buffer size
		data.append(file_name.get_basename()) # Class name
		data.append(xml.compress(File.COMPRESSION_DEFLATE).hex_encode())
	if Data.save_string(data.join("\n"), dest_folder) == OK:
		alert("Created class data file: " + dest_folder)
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


func _on_ZipExtract_about_to_show():
	show_files()
