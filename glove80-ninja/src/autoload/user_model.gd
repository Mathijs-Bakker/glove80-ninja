extends Node

const DEFAULT_USERS = {USERS.USER_IDS: [], USERS.LAST_LOGGED_IN: null}

const USERS = {"USER_IDS": "user_ids", "LAST_LOGGED_IN": "last_logged_in"}

# Default profile structure
const DEFAULT_PROFILE = {
	PROFILE.USERNAME: "New user",
	PROFILE.CREATED_DATE: "",
	PROFILE.LAST_LOGIN_DATE: "",
	PROFILE.LEVEL: 0,
	PROFILE.EXPERIENCE: 0,
	SETTINGS.STOP_CURSOR_ON_ERROR: true,
	SETTINGS.FORGIVE_ERRORS: false,
	SETTINGS.SPACE_SKIPS_WORDS: false,
	SETTINGS.SHOW_WHITESPACE: "bullet",
	SETTINGS.CURSOR_SHAPE: "block",
	STATS.ALL_TIME_TIME_TYPED: 0.0,
	STATS.ALL_TIME_BEST_WPM: 0.0,
	STATS.ALL_TIME_AVERAGE_WPM: 0.0,
	STATS.ALL_TIME_AVERAGE_ACCURACY: 0.0,
	STATS.ALL_TIME_SESSIONS_COMPLETED: 0.0,
	STATS.TODAY_TIME_TYPED: 0.0,
	STATS.TODAY_BEST_WPM: 0.0,
	STATS.TODAY_BEST_ACCURACY: 0.0,
	STATS.TODAY_AVERAGE_ACCURACY: 0.0,
	"achievements": [],
	"preferences": {"preferred_lessons": [], "difficulty_level": "beginner"}
}

const PROFILE = {
	"USERNAME": "username",
	"CREATED_DATE": "created_date",
	"LAST_LOGIN_DATE": "last_login_date",
	"LEVEL": "level",
	"EXPERIENCE": "experience",
}

const SETTINGS = {
	"STOP_CURSOR_ON_ERROR": "stop_cursor_on_error",
	"FORGIVE_ERRORS": "forgive_errors",
	"SPACE_SKIPS_WORDS": "space_skip_words",
	"SHOW_WHITESPACE": "show_whitespace",
	"CURSOR_SHAPE": "cursor_shape"
}

const STATS = {
	"ALL_TIME_TIME_TYPED": "all_time_time_typed",
	"ALL_TIME_BEST_WPM": "all_time_best_wpm",
	"ALL_TIME_AVERAGE_WPM": "all_time_average_wpm",
	"ALL_TIME_BEST_ACCURACY": "all_time_best_accuracy",
	"ALL_TIME_AVERAGE_ACCURACY": "all_time_average_accuracy",
	"ALL_TIME_SESSIONS_COMPLETED": "all_time_sessions_completed",
	"TODAY_TIME_TYPED": "today_time_typed",
	"TODAY_BEST_WPM": "today_best_wpm",
	"TODAY_AVERAGE_WPM": "today_average_wpm",
	"TODAY_BEST_ACCURACY": "today_best_accuracy",
	"TODAY_AVERAGE_ACCURACY": "today_average_accuracy",
	"TODAY_SESSIONS_COMPLETED": "today_sessions_completed",
}
