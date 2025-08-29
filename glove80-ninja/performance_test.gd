extends Node

## Performance test script for measuring typing response times and system performance
## Run this to verify the optimization improvements

class_name PerformanceTest

signal test_completed(results: Dictionary)

# Test configuration
const TEST_DURATION: float = 10.0
const KEYSTROKES_PER_SECOND: float = 5.0
const TEST_TEXT: String = "The quick brown fox jumps over the lazy dog. This is a performance test to measure typing response times and overall system performance during high-frequency input events."

# Performance metrics
var keystroke_times: Array[float] = []
var frame_times: Array[float] = []
var memory_snapshots: Array[int] = []
var node_count_snapshots: Array[int] = []

# Test state
var test_active: bool = false
var start_time: float = 0.0
var keystroke_count: int = 0
var current_char_index: int = 0

# Components under test
var text_display: TextDisplay
var input_handler: InputHandler

# Timers
var keystroke_timer: Timer
var metrics_timer: Timer


func _ready() -> void:
	_setup_test()


## Start the performance test
func start_test(p_text_display: TextDisplay, p_input_handler: InputHandler) -> void:
	if test_active:
		return

	text_display = p_text_display
	input_handler = p_input_handler

	print("[PerformanceTest] Starting performance test...")
	print("Duration: %.1fs" % TEST_DURATION)
	print("Target keystrokes/sec: %.1f" % KEYSTROKES_PER_SECOND)
	print("Test text length: %d characters" % TEST_TEXT.length())

	_reset_metrics()
	_start_test_sequence()


## Stop the performance test
func stop_test() -> void:
	if not test_active:
		return

	test_active = false
	keystroke_timer.stop()
	metrics_timer.stop()

	var results = _calculate_results()
	_print_results(results)
	test_completed.emit(results)


# Private methods

func _setup_test() -> void:
	# Create keystroke simulation timer
	keystroke_timer = Timer.new()
	keystroke_timer.wait_time = 1.0 / KEYSTROKES_PER_SECOND
	keystroke_timer.timeout.connect(_simulate_keystroke)
	add_child(keystroke_timer)

	# Create metrics collection timer
	metrics_timer = Timer.new()
	metrics_timer.wait_time = 0.1  # Collect metrics every 100ms
	metrics_timer.timeout.connect(_collect_metrics)
	add_child(metrics_timer)


func _reset_metrics() -> void:
	keystroke_times.clear()
	frame_times.clear()
	memory_snapshots.clear()
	node_count_snapshots.clear()
	keystroke_count = 0
	current_char_index = 0


func _start_test_sequence() -> void:
	test_active = true
	start_time = Time.get_ticks_msec() / 1000.0

	# Setup text display with test text
	if text_display:
		text_display.set_text(TEST_TEXT)

	if input_handler:
		input_handler.set_target_text(TEST_TEXT)

	# Start timers
	keystroke_timer.start()
	metrics_timer.start()

	# Schedule test completion
	await get_tree().create_timer(TEST_DURATION).timeout
	stop_test()


func _simulate_keystroke() -> void:
	if not test_active or current_char_index >= TEST_TEXT.length():
		stop_test()
		return

	var keystroke_start = Time.get_ticks_usec()

	# Simulate typing the next character
	var char_to_type = TEST_TEXT[current_char_index]
	var event = _create_key_event(char_to_type)

	# Process input through the system
	if input_handler:
		input_handler.handle_input(event)

	# Measure response time
	var keystroke_end = Time.get_ticks_usec()
	var response_time = (keystroke_end - keystroke_start) / 1000.0  # Convert to milliseconds

	keystroke_times.append(response_time)
	keystroke_count += 1
	current_char_index += 1

	# Add some randomness to simulate human typing
	keystroke_timer.wait_time = (1.0 / KEYSTROKES_PER_SECOND) + randf_range(-0.02, 0.02)


func _create_key_event(character: String) -> InputEventKey:
	var event = InputEventKey.new()
	event.pressed = true
	event.unicode = character.unicode_at(0)
	event.keycode = character.unicode_at(0)
	return event


func _collect_metrics() -> void:
	if not test_active:
		return

	# Collect frame time
	var current_fps = Engine.get_frames_per_second()
	if current_fps > 0:
		frame_times.append(1000.0 / current_fps)  # Convert to milliseconds

	# Collect memory usage
	memory_snapshots.append(OS.get_static_memory_usage())

	# Collect node count
	node_count_snapshots.append(get_tree().get_node_count())


func _calculate_results() -> Dictionary:
	var results = {}

	# Keystroke response times
	if keystroke_times.size() > 0:
		results["avg_response_time"] = _calculate_average(keystroke_times)
		results["max_response_time"] = keystroke_times.max()
		results["min_response_time"] = keystroke_times.min()
		results["response_time_95th"] = _calculate_percentile(keystroke_times, 95)
	else:
		results["avg_response_time"] = 0.0
		results["max_response_time"] = 0.0
		results["min_response_time"] = 0.0
		results["response_time_95th"] = 0.0

	# Frame performance
	if frame_times.size() > 0:
		results["avg_frame_time"] = _calculate_average(frame_times)
		results["max_frame_time"] = frame_times.max()
		results["frame_time_95th"] = _calculate_percentile(frame_times, 95)
	else:
		results["avg_frame_time"] = 0.0
		results["max_frame_time"] = 0.0
		results["frame_time_95th"] = 0.0

	# Memory usage
	if memory_snapshots.size() > 1:
		results["initial_memory"] = memory_snapshots[0]
		results["final_memory"] = memory_snapshots[-1]
		results["memory_growth"] = memory_snapshots[-1] - memory_snapshots[0]
		results["max_memory"] = memory_snapshots.max()
	else:
		results["initial_memory"] = 0
		results["final_memory"] = 0
		results["memory_growth"] = 0
		results["max_memory"] = 0

	# Node count
	if node_count_snapshots.size() > 1:
		results["initial_nodes"] = node_count_snapshots[0]
		results["final_nodes"] = node_count_snapshots[-1]
		results["node_growth"] = node_count_snapshots[-1] - node_count_snapshots[0]
		results["max_nodes"] = node_count_snapshots.max()
	else:
		results["initial_nodes"] = 0
		results["final_nodes"] = 0
		results["node_growth"] = 0
		results["max_nodes"] = 0

	# Test summary
	results["total_keystrokes"] = keystroke_count
	results["test_duration"] = TEST_DURATION
	results["actual_keystrokes_per_sec"] = keystroke_count / TEST_DURATION
	results["target_keystrokes_per_sec"] = KEYSTROKES_PER_SECOND

	return results


func _print_results(results: Dictionary) -> void:
	print("\n" + "=".repeat(50))
	print("PERFORMANCE TEST RESULTS")
	print("=".repeat(50))

	print("\n📊 KEYSTROKE RESPONSE TIMES:")
	print("  Average: %.2f ms" % results.avg_response_time)
	print("  Maximum: %.2f ms" % results.max_response_time)
	print("  Minimum: %.2f ms" % results.min_response_time)
	print("  95th percentile: %.2f ms" % results.response_time_95th)

	print("\n🖼️  FRAME PERFORMANCE:")
	print("  Average frame time: %.2f ms" % results.avg_frame_time)
	print("  Maximum frame time: %.2f ms" % results.max_frame_time)
	print("  95th percentile: %.2f ms" % results.frame_time_95th)
	print("  Estimated FPS: %.1f" % (1000.0 / results.avg_frame_time))

	print("\n💾 MEMORY USAGE:")
	print("  Initial: %.2f MB" % (results.initial_memory / 1048576.0))
	print("  Final: %.2f MB" % (results.final_memory / 1048576.0))
	print("  Growth: %.2f MB" % (results.memory_growth / 1048576.0))
	print("  Maximum: %.2f MB" % (results.max_memory / 1048576.0))

	print("\n🌳 NODE COUNT:")
	print("  Initial: %d nodes" % results.initial_nodes)
	print("  Final: %d nodes" % results.final_nodes)
	print("  Growth: %d nodes" % results.node_growth)
	print("  Maximum: %d nodes" % results.max_nodes)

	print("\n⚡ TYPING PERFORMANCE:")
	print("  Total keystrokes: %d" % results.total_keystrokes)
	print("  Target rate: %.1f keystrokes/sec" % results.target_keystrokes_per_sec)
	print("  Actual rate: %.1f keystrokes/sec" % results.actual_keystrokes_per_sec)
	print("  Test duration: %.1f seconds" % results.test_duration)

	print("\n🎯 PERFORMANCE ASSESSMENT:")
	_assess_performance(results)

	print("=".repeat(50))


func _assess_performance(results: Dictionary) -> void:
	var score = 100.0
	var issues: Array[String] = []

	# Check response time (should be < 5ms for optimized version)
	if results.avg_response_time > 10.0:
		score -= 30
		issues.append("HIGH response time (%.1fms avg)" % results.avg_response_time)
	elif results.avg_response_time > 5.0:
		score -= 15
		issues.append("MODERATE response time (%.1fms avg)" % results.avg_response_time)

	# Check frame consistency (95th percentile should be < 20ms for 60fps)
	if results.frame_time_95th > 33.0:  # 30fps threshold
		score -= 25
		issues.append("LOW frame rate consistency")
	elif results.frame_time_95th > 20.0:  # Below 60fps threshold
		score -= 10
		issues.append("MODERATE frame rate drops")

	# Check memory growth (should be minimal)
	var memory_growth_mb = results.memory_growth / 1048576.0
	if memory_growth_mb > 10.0:
		score -= 20
		issues.append("HIGH memory growth (%.1fMB)" % memory_growth_mb)
	elif memory_growth_mb > 2.0:
		score -= 10
		issues.append("MODERATE memory growth (%.1fMB)" % memory_growth_mb)

	# Check node growth (should be zero for optimized version)
	if results.node_growth > 50:
		score -= 25
		issues.append("HIGH node count growth (%d nodes)" % results.node_growth)
	elif results.node_growth > 10:
		score -= 15
		issues.append("MODERATE node count growth (%d nodes)" % results.node_growth)

	# Overall assessment
	if score >= 90:
		print("  ✅ EXCELLENT (Score: %.0f/100)" % score)
		print("     Performance is optimal for smooth typing experience")
	elif score >= 75:
		print("  ✅ GOOD (Score: %.0f/100)" % score)
		print("     Performance is acceptable with minor issues")
	elif score >= 60:
		print("  ⚠️  FAIR (Score: %.0f/100)" % score)
		print("     Performance has noticeable issues but is usable")
	else:
		print("  ❌ POOR (Score: %.0f/100)" % score)
		print("     Performance needs significant optimization")

	if issues.size() > 0:
		print("\n  Issues detected:")
		for issue in issues:
			print("    • %s" % issue)


# Utility functions

func _calculate_average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0

	var sum = 0.0
	for value in values:
		sum += value
	return sum / values.size()


func _calculate_percentile(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0

	var sorted_values = values.duplicate()
	sorted_values.sort()

	var index = int((percentile / 100.0) * (sorted_values.size() - 1))
	return sorted_values[index]


## Static method to run a quick test
static func run_quick_test(text_display: TextDisplay, input_handler: InputHandler) -> void:
	var test = PerformanceTest.new()
	text_display.get_tree().current_scene.add_child(test)
	test.start_test(text_display, input_handler)

	await test.test_completed
	test.queue_free()
