package small_map

Small_Map_Iterator :: struct {
	index: int,
}

small_map_iter :: proc(
	small_map: ^$SM/Small_Map($K, $V, $N),
	iter: ^Small_Map_Iterator,
) -> (
	key: K,
	value: ^V,
	cond: bool,
) {
	if iter.index >= small_map.len {
		return
	}

	key = small_map.entries[iter.index].key
	value = &small_map.entries[iter.index].value
	cond = true

	iter.index += 1
	return
}

