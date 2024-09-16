package small_map

import "core:fmt"
import "core:testing"

@(test)
test_iterator :: proc(t: ^testing.T) {
	sm: Small_Map(int, int, 128)

	testing.expect(t, small_map_insert(&sm, 0, 5))
	testing.expect(t, small_map_insert(&sm, 1, 2))
	testing.expect(t, small_map_insert(&sm, 2, 3))
	testing.expect(t, small_map_insert(&sm, 69, 420))

	found: int

	iter := small_map_iterator(&sm)
	for k, v in small_map_iter(&iter) {
		switch k {
		case 0:
			testing.expect(t, v == 5)
		case 1:
			testing.expect(t, v == 2)
		case 2:
			testing.expect(t, v == 3)
		case 69:
			testing.expect(t, v == 420)
		case:
			testing.fail(t)
		}
		found += 1
	}

	testing.expect(t, found == 4)
}

@(test)
test_small_map :: proc(t: ^testing.T) {
	sm: Small_Map(int, int, 128)

	testing.expect(t, small_map_insert(&sm, 0, 5))
	testing.expect(t, small_map_insert(&sm, 1, 2))
	testing.expect(t, small_map_insert(&sm, 2, 3))
	testing.expect(t, small_map_insert(&sm, 69, 420))

	testing.expect(t, small_map_get(&sm, 0)^ == 5)
	testing.expect(t, small_map_get(&sm, 1)^ == 2)
	testing.expect(t, small_map_get(&sm, 2)^ == 3)
	testing.expect(t, small_map_get(&sm, 69)^ == 420)

	testing.expect(t, small_map_remove(&sm, 0))
	testing.expect(t, small_map_get(&sm, 0) == nil)

	testing.expect(t, small_map_insert(&sm, 0, 123))
	testing.expect(t, small_map_get(&sm, 0)^ == 123)

	testing.expect(t, small_map_insert(&sm, 0, 69))
	testing.expect(t, small_map_get(&sm, 0)^ == 69)
}

