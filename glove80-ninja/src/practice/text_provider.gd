class_name TextProvider
extends RefCounted

const TEXT_SAMPLES := [
	"The quick brown fox jumps over the lazy dog.",
	"Programming is the process of creating a set of instructions that tell a computer how to perform a task.",
	"Touch typing is typing without using the sense of sight to find the keys.",
	"Practice makes perfect. The more you type, the better you will become.",
	"A good programmer is someone who looks both ways before crossing a one-way street."
]

static func get_random_sample() -> String:
	return TEXT_SAMPLES.pick_random()

static func get_sample_by_difficulty(_p_difficulty: String) -> String:
	# Implement difficulty-based text selection
	return get_random_sample()
