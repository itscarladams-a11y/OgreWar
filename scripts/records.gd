class_name OgreWarRecords
extends RefCounted

const RECORD_PATH := "user://ogre_war_records.json"

static func empty() -> Dictionary:
	return {
		"battles": 0, "wins": 0, "losses": 0, "best_score": 0,
		"fastest_win": 0, "ogres_defeated": 0, "human_losses": 0,
		"best_age": 0, "last_result": "NO BATTLES YET", "last_score": 0
	}

static func load_records(path: String = RECORD_PATH) -> Dictionary:
	var records := empty()
	if not FileAccess.file_exists(path):
		return records
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return records
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return records
	for key in records.keys():
		if key == "last_result":
			if parsed.has(key) and parsed[key] is String:
				records[key] = str(parsed[key]).substr(0, 48)
		elif parsed.has(key) and (parsed[key] is int or parsed[key] is float):
			records[key] = clampi(int(parsed[key]), 0, 100000000)
	return records

static func score_for(won: bool, seconds: float, human_losses: int, ogre_losses: int, age_reached: int, keep_hp: float) -> int:
	var base := 1000 if won else 0
	var speed := maxi(0, 600 - floori(seconds / 2.0)) if won else 0
	var keep_bonus := maxi(0, floori(keep_hp / 4.0)) if won else 0
	return maxi(0, base + speed + keep_bonus + ogre_losses * 35 + age_reached * 120 - human_losses * 20)

static func record_match(won: bool, seconds: float, human_losses: int, ogre_losses: int, age_reached: int, keep_hp: float, path: String = RECORD_PATH) -> int:
	var score := score_for(won, seconds, human_losses, ogre_losses, age_reached, keep_hp)
	var records := load_records(path)
	records["battles"] = int(records["battles"]) + 1
	records["ogres_defeated"] = int(records["ogres_defeated"]) + ogre_losses
	records["human_losses"] = int(records["human_losses"]) + human_losses
	records["best_age"] = maxi(int(records["best_age"]), age_reached)
	records["last_result"] = "VICTORY" if won else "DEFEAT"
	records["last_score"] = score
	if won:
		records["wins"] = int(records["wins"]) + 1
		records["best_score"] = maxi(int(records["best_score"]), score)
		var duration := maxi(1, ceili(seconds))
		if int(records["fastest_win"]) == 0 or duration < int(records["fastest_win"]):
			records["fastest_win"] = duration
	else:
		records["losses"] = int(records["losses"]) + 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save Ogre War records: %s" % error_string(FileAccess.get_open_error()))
	else:
		file.store_string(JSON.stringify(records))
		file.close()
	return score
