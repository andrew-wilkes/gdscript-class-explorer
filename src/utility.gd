extends Node

### Stopwatch

const START = true
const STOP = false

var t1

func stopwatch(start):
	if start:
		t1 = OS.get_system_time_msecs()
	else:
		print("Duration: ", OS.get_system_time_msecs() - t1, "ms")

"""
	Utility.stopwatch(Utility.START)
	Utility.stopwatch(Utility.STOP)
"""


### Logger

var the_log = PoolStringArray([])

func add_to_log(txt):
	the_log.append(txt)


func add_array_to_log(arr):
	add_to_log(PoolStringArray(arr).join(" "))


func clear_log():
	the_log.resize(0)


func save_log():
	Data.save_string(the_log.join("\n"), "log.txt")
	clear_log()
