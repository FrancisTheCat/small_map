package small_map

Small_Map_Iterator :: struct($K, $V: typeid, $N: int) {
	small_map: ^Small_Map(K, V, N),
	index:     int,
}

small_map_iterator :: proc(sm: ^$SM/Small_Map($K, $V, $N)) -> Small_Map_Iterator(K, V, N) {
	return {small_map = sm}
}

small_map_iter :: proc(iter: ^Small_Map_Iterator($K, $V, $N)) -> (key: K, value: V, cond: bool) {
	if iter.index >= iter.small_map.len {
		return
	}

	key   = iter.small_map.entries[iter.index].key
	value = iter.small_map.entries[iter.index].value
	cond  = true

	iter.index += 1
	return
}

