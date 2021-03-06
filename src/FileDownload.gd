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
	# The url may or may not end in .zip
	var target_filename = url.get_file().replace(".zip", "") + ".zip"
	if file.file_exists(target_filename):
		alert("Refused: the file already exists.")
		return
	$VBox/HBox/OK.disabled = true
	$Downloading.rect_size = $Alert.rect_size
	$Downloading.popup_centered()
	# Allow the alert to be seen before the blocking process runs
	yield(get_tree().create_timer(0.5), "timeout")
	# Ignore result code
	# Credit to: Mounir Tohami: Add --ssl-no-revoke parameter to fix download issue on some Windows PCs
	var _result = OS.execute("curl", [url, "--ssl-no-revoke", "-L", "-o", target_filename])
	$Downloading.hide()
	$VBox/HBox/OK.disabled = false
	if file.file_exists(target_filename):
		alert("Done")
		download_status = OK
		emit_signal("dowloaded_file", target_filename)
	else:
		alert("There was an error downloading the file from:\n" + url)
		download_status = -1


func _ready():
	rect_size = $VBox.rect_size + Vector2(15, 15)


func alert(msg):
	var alert = get_node("Alert")
	alert.dialog_text = msg
	if not alert.visible:
		alert.popup_centered()


func _on_Alert_popup_hide():
	if download_status == OK:
		hide()
