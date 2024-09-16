+++
title = 'A simple data structure in Odin'
date = 2024-09-16T14:38:39+02:00
draft = true
+++

The goal of this article is to explore how we can use some of Odins more advanced features, like Generics, `where` clauses, iterators and `#soa` to build a simple map data structure.
The goal is not to invent a perfect data structure to replace the builtin `map` type (the builtin map is great, there is no need to replace it).

The map will simply store an array of Key-Value-Pairs like so:
```go
Small_Map :: struct($K, $V: typeid, $N: int) {
	entries: [N]struct {
		key:   K,
		value: V,
	},
	len:     int,
}
```
Note that the 3 parameters to our map struct have to be known at compile time (signified by the `$`).

So let's get our map to actually do something! How about we start with initializing it?
```go
small_map: Small_Map(int, int, 64)
```
Thats it! Since odin initializes everything to zero by default, our map already has a `len` of zero and is ready to be used (This is an example of Zero is Initialization or "ZII").

Now it's time to write our first procedure that actually does something with the map, I think `insert` is pretty reasonable choice:
```go
small_map_insert :: proc(sm: ^Small_Map($K, $V, $N), key: K, value: V) -> (ok: bool) {
	for &e in sm.entries[:sm.len] {
		if key == e.key {
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

small_map: Small_Map(int, int, 64)
small_map_insert(&small_map, 1, 2)
```
The algorithm should be pretty self explanatory, we just loop over all the entries in the map to see wether we have already inserted this key. If we have, we just update its value. If we haven't, we check if the map is full and then increment its length and put the KV-Pair at the end.
What might be a bit more challenging to understand is the function signature. Whats up with those `$` again? These again declare variables that are known at compile time and are iferred from the type we pass in as the first argument. From then on we can use K and V as normal types, even for the other arguments of our procedure.

The other operations are pretty simple as well, they all come down to iterating through the array and compare keys. For the `remove` we do a simple a tail swap and for the `get` we iterate by reference to get the address of the value.
```go
small_map_remove :: proc(sm: ^Small_Map($K, $V, $N), key: K) -> (ok: bool) {
	for e, i in sm.entries[:sm.len] {
		if e.key == key {
			sm.len -= 1
			sm.entries[i] = sm.entries[sm.len]
			return true
		}
	}

	return false
}

@(require_results)
small_map_get :: proc(sm: ^Small_Map($K, $V, $N), key: K) -> (value: ^V) {
	// note that the `&` causes the e to be addressable, allowing us to get a pointer to the actual value
	for &e in sm.entries[:sm.len] {
		if e.key == key {
			return &e.value
		}
	}

	return nil
}

// this attribute will cause a compiler error if the results go unused
@(require_results)
small_map_contains :: proc(sm: ^Small_Map($K, $V, $N), key: K) -> bool {
	for e in sm.entries[:sm.len] {
		if e.key == key {
			return true
		}
	}

	return false
}

small_map: Small_Map(int, int, 64)
small_map_insert(&small_map, 1, 2)
small_map_remove(&small_map, 1)
assert(small_map_get(&small_map, 1) == nil)
assert(!small_map_contains(&small_map, 1))
```

And that's all the basic stuff done! However we can this improve/extend this implementation in a few ways, the first being that we can leverage Odins "core:testing" package to verify our implementation is correct:
```go
import "core:testing"

// Every test needs both the @(test) attribute and has to take in a pointer to a `testing.T` as its only argument
@(test)
test_small_map :: proc(t: ^testing.T) {
	sm: Small_Map(int, int, 128)

	testing.expect(t, small_map_insert(&sm, 0, 5))
	testing.expect(t, small_map_insert(&sm, 1, 2))
	testing.expect(t, small_map_insert(&sm, 2, 3))
	testing.expect(t, small_map_insert(&sm, 69, 420))

	testing.expect(t, small_map_get(&sm, 0 )^ == 5)
	testing.expect(t, small_map_get(&sm, 1 )^ == 2)
	testing.expect(t, small_map_get(&sm, 2 )^ == 3)
	testing.expect(t, small_map_get(&sm, 69)^ == 420)

	testing.expect(t, small_map_remove(&sm, 0))
	testing.expect(t, small_map_get(&sm, 0) == nil)

	testing.expect(t, small_map_insert(&sm, 0, 123))
	testing.expect(t, small_map_get(&sm, 0)^ == 123)

	testing.expect(t, small_map_insert(&sm, 0, 69))
	testing.expect(t, small_map_get(&sm, 0)^ == 69)
}
```

Now we can verify that we haven't screwed up anything by invoking `odin test`.
