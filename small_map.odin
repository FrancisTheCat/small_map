package small_map

import "base:intrinsics"

Small_Map :: struct($K, $V: typeid, $N: int) {
	entries: #soa[N]struct {
		key:   K,
		value: V,
	},
	len:     int,
}

small_map_insert :: proc(sm: ^Small_Map($K, $V, $N), key: K, value: V) -> (ok: bool) {
	for &e in sm.entries[:sm.len] {
		if e.key == key {
			e.value = value
			return true
		}
	}

	if sm.len >= N {
		return
	}

	sm.entries[sm.len] = {
		key   = key,
		value = value,
	}
	sm.len += 1

	return true
}

small_map_remove :: proc(sm: ^Small_Map($K, $V, $N), key: K) -> (ok: bool) {
	key := key
	for &e, i in sm.entries[:sm.len] {
		if e.key == key {
			sm.len -= 1
			sm.entries[i] = sm.entries[sm.len]
			return true
		}
	}

	return false
}

small_map_get :: proc(sm: ^$SM/Small_Map($K, $V, $N), key: K) -> (value: ^V) {
	key := key
	for &e in sm.entries[:sm.len] {
		if e.key == key {
			return &e.value
		}
	}

	return nil
}

small_map_contains :: proc(sm: ^$SM/Small_Map($K, $V, $N), key: K) -> bool {
	key := key
	for e in sm.entries[:sm.len] {
		if e.key == key {
			return true
		}
	}

	return false
}

