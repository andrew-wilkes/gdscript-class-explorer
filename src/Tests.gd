extends Control

func _ready():
	if Data.testing:
		do_class_details_test()


func test_class_details():
	$Result.text = "Testing Class Details"
	Data.testing = true
	Data.test_item_index = -1
	do_class_details_test()


func do_class_details_test():
	Data.test_item_index += 1
	if Data.test_item_index < Data.classes.size():
		var cname = Data.classes.keys()[Data.test_item_index]
		Data.selected_class = cname
		var _e = get_tree().change_scene("res://ClassDetails.tscn")
	else:
		Data.testing = false
		$Result.text = "Passed"


func _on_TestDetails_pressed():
	test_class_details()
