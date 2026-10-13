extends RefCounted

static func subtract(regions: Array, exclusions: Array) -> Array:
	var result = regions.duplicate()
	for exclusion in exclusions:
		var next: Array = []
		for region in result:
			var overlap: Rect2 = region.intersection(exclusion)
			if not overlap.has_area():
				next.append(region)
				continue
			var pieces = [Rect2(region.position, Vector2(region.size.x, overlap.position.y - region.position.y)), Rect2(Vector2(region.position.x, overlap.end.y), Vector2(region.size.x, region.end.y - overlap.end.y)), Rect2(Vector2(region.position.x, overlap.position.y), Vector2(overlap.position.x - region.position.x, overlap.size.y)), Rect2(Vector2(overlap.end.x, overlap.position.y), Vector2(region.end.x - overlap.end.x, overlap.size.y))]
			for piece in pieces:
				if piece.has_area():
					next.append(piece)
		result = next
	return result
