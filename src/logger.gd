extends Node

var the_log = PoolStringArray([])
var data = {}

func add(txt):
	the_log.append(txt)

func save_log():
	Data.save_string(the_log.join("\n"), "log.txt")
	the_log.resize(0)
