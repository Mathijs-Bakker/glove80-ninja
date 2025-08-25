extends Node

# Save with automatic directory creation
func save_data(p_path: String, p_data: Dictionary, p_pretty: bool = true) -> bool:
    # Ensure directory exists first
    var dir_path = p_path.get_base_dir()
    if not DirAccess.dir_exists_absolute(dir_path):
        var error = DirAccess.make_dir_recursive_absolute(dir_path)
        if error != OK:
            push_error("Failed to create directory: " + dir_path)
            return false
    
    var file = FileAccess.open(p_path, FileAccess.WRITE)
    if file == null:
        push_error("Error opening file for writing: " + p_path)
        return false
    
    # Use if/else for compatibility
    var indent: String
    if p_pretty:
        indent = "\t"
    else:
        indent = ""
    
    var json_string = JSON.stringify(p_data, indent)
    
    if json_string.is_empty():
        push_error("Failed to stringify JSON data")
        file.close()
        return false
    
    file.store_string(json_string)
    file.close()
    return true


# Load data with fallback
func load_data(p_path: String, p_default_data: Dictionary = {}) -> Dictionary:
    if not FileAccess.file_exists(p_path):
        return p_default_data.duplicate(true)
    
    var file = FileAccess.open(p_path, FileAccess.READ)
    if file == null:
        push_error("Error opening file for reading: " + p_path)
        return p_default_data.duplicate(true)
    
    var json_string = file.get_as_text()
    file.close()
    
    if json_string.is_empty():
        return p_default_data.duplicate(true)
    
    var json = JSON.new()
    var error = json.parse(json_string)
    
    if error != OK:
        push_error("JSON parse error: " + json.get_error_message())
        return p_default_data.duplicate(true)
    
    return json.data


# Create backup
func create_backup(p_original_path: String) -> bool:
    if not FileAccess.file_exists(p_original_path):
        return false
    
    # Ensure backup directory exists
    if not DirAccess.dir_exists_absolute(FilePaths.BACKUPS_DIR):
        DirAccess.make_dir_recursive_absolute(FilePaths.BACKUPS_DIR)
    
    var backup_path = FilePaths.get_backup_path(p_original_path)
    
    return DirAccess.copy_absolute(p_original_path, backup_path) == OK


# Get list of files in directory
func list_files(p_directory: String, p_extension_filter: String = "json") -> Array:
    var files = []
    var dir = DirAccess.open(p_directory)
    
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir() and file_name.get_extension() == p_extension_filter:
                files.append(p_directory.path_join(file_name))
            file_name = dir.get_next()
    
    return files


# Validate JSON data structure
func validate_schema(p_data: Dictionary, p_required_keys: Array) -> bool:
    for key in p_required_keys:
        if not p_data.has(key):
            push_error("Missing required key in JSON data: " + str(key))
            return false
    return true


# Merge two JSON objects (deep merge)
func merge_json(p_target: Dictionary, p_source: Dictionary) -> Dictionary:
    var result = p_target.duplicate(true)
    
    for key in p_source:
        if result.has(key) and result[key] is Dictionary and p_source[key] is Dictionary:
            result[key] = merge_json(result[key], p_source[key])
        else:
            result[key] = p_source[key]
    
    return result
