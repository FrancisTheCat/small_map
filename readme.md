### What this is

The goal of this article is to explore how we can use some of Odins more advanced features, like generics, `where` clauses, iterators and `#soa` to build a simple map data structure.
The goal is not to invent a perfect data structure to replace the builtin `map` type (the builtin map is great, there is no need to replace it).

## The Foundation

### The Data Structure

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

So let's get our map to actually do something. How about we start with initializing it?
```go
small_map: Small_Map(int, int, 64)
```
Thats it! Since odin initializes everything to zero by default, our map already has a `len` of zero and is ready to be used (This is an example of Zero is Initialization or "ZII").

### Insert

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

### Basic Operations

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

## Bells and Whistles

### Testing
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

### Type Specialization
One of the really cool features that Odins type system has is `distinct` types, which allow us to convey more information with our types, but currently we are not prepared to handle them:
```go
Int_Map :: distinct Small_Map(int, int, 64)
int_map: Int_Map
// This does not compile
small_map_insert(&int_map, 1, 1)
```

It is very inconvenient to cast to a `^Small_Map` every time: `small_map_insert(cast(^Small_Map(int, int, 64))(&int_map), 1, 1)`. That's where type specialization comes into play:
```go
// old
small_map_insert :: proc(sm: ^Small_Map($K, $V, $N), key: K, value: V) -> (ok: bool)
// new
small_map_insert :: proc(sm: ^$SM/Small_Map($K, $V, $N), key: K, value: V) -> (ok: bool)
```
Adding the `$SM/` in front of the type allows users to pass in any type that is a `distinct` variant of `Small_Map`. We can do the same for all procedures of course.

### Iteration
Custom iterators in Odin are very simple: They are just procedures, that return a bool as their last return value indicating wether the iterator should keep going. However since we are going to need state in our iterator, to know where in the map we currently are. For this we will add a struct called `Small_Map_Iterator`:
```go
Small_Map_Iterator :: struct {
	index: int,
}
```
This struct doesn't need an initialization proc either since an index of 0 does seem like a pretty reasonable place to start.

The actual iteration proc is pretty trivial, since we are just iterating through an array:
```go
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

sm: Small_Map(int, int, 32)
iter: Small_Map_Iter
for k, v in small_map_iter(&sm, &iter) {
	...
}
```

### Final touches
I think we have arrived at a simple, but nice to use data structure by now, that works pretty well if you use it as intended, however there are still some minor tweaks that will make it a bit better.
You might wonder what happens if a user plugs in a key that is not comparable and the result is not exactly nice:
```
/Dev/odin/small_map/small_map.odin(15:6) Error: Cannot compare expression, operator '==' not defined between the types '[]u8' and '[]u8'
        if e.key == key {
           ^~~~~~~~~~~^
```
That's not as clear as it could be and we also don't want the error to be in our implementation, especially since the error only gets caught if the procedure gets called, since its polymorphic.
Luckily we can leverage a `where` clause and the "base:intrinsics" package to restrict the types we accept as keys to only allow comparable types.
```go
import "base:intrinsics"

Small_Map :: struct($K, $V: typeid, $N: int) where intrinsics.type_is_comparable(K) {
	entries: [N]struct {
		key:   K,
		value: V,
	},
	len:     int,
}
```

And there is also one final 4 letter change we can do to improve the performance of our map a little bit. For that we will have to think about how our data is actually laid out in memory: We store the keys and the values in one array so there might be padding inserted after every key to align the value properly. This wastes memory and makes the prefetchers job harder, which will probably slow us down. We can also see that our most common operation is iterating through the entries and only looking at the keys, meaning it would be beneficial to have the keys and values in two separate arrays. Amazingly this can be achieved by just adding the `#soa` (Structure Of Arrays) directive to the entries array and the compiler will do the rest for us. We dont have to change a single other line of code for this to work.
```go
Small_Map :: struct($K, $V: typeid, $N: int) where intrinsics.type_is_comparable(K) {
	entries: #soa[N]struct {
		key:   K,
		value: V,
	},
	len:     int,
}
```

## Conclusion
I hope you enjoyed this small exploration of some advanced Odin features and got something out of it. If you want see some more complex, but still very readable, examples I would encourage you to look into Odins "core" library.
