extends WindowDialog

signal dowloaded_file(filename)

var download_status = OK

func _on_OK_pressed():
	url_selected($VBox/HBox/LineEdit.text)


func _on_Master_pressed():
	url_selected($VBox/Master.text)


func _on_LineEdit_text_entered(new_text):
	if new_text.begins_with("http"):
		url_selected(new_text)


func _on_LineEdit_text_changed(new_text: String):
	if new_text.begins_with("http"):
		$VBox/HBox/OK.disabled = false
	else:
		$VBox/HBox/OK.disabled = true


func url_selected(url: String):
	var file = File.new()
	var target_filename = url.get_file().get_basename() + ".zip"
	if file.file_exists(target_filename):
		alert("Refused: the file already exists.")
		return
	alert("Downloading ...")
	if OS.execute("curl", [url, "-L", "-o", target_filename]) != OK:
		alert("There was an error running curl on your computer.")
		return
	if file.file_exists(target_filename):
		alert("Done")
		download_status = OK
		emit_signal("dowloaded_file", target_filename)
	else:
		alert("There was an error downloading the file from:\n" + url)
		download_status = -1


func alert(msg):
	var alert = get_node("Alert")
	alert.dialog_text = msg
	if not alert.visible:
		alert.popup_centered()


func _on_Alert_popup_hide():
	if download_status == OK:
		hide()
