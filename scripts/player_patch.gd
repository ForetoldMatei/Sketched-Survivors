
# Merge into your player script

@export var camera_limits: Rect2

func apply_bounds():
    global_position.x = clamp(global_position.x, camera_limits.position.x, camera_limits.end.x)
    global_position.y = clamp(global_position.y, camera_limits.position.y, camera_limits.end.y)
