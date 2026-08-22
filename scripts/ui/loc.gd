class_name Loc
extends RefCounted

static func ru() -> bool:
	return GameState.effective_language().begins_with("ru")