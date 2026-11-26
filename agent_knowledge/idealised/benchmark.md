# Best case

The best case is the sample the other times are read against. It is a tree that has already settled, asked to settle again, with nothing new to write and one event that the front record takes.

The count of responders stays the axis the two bench scripts already walk. The best case holds the other axes at the cheap end.

## A settled tree

The root holds the stock map. A few children sit under it, and the last child is in front. Each child contributes one map, and the names it writes are few. The first compose has already run, so the table exists. Stock rows share the stock map's events. Each gameplay row still holds the copy made while the source action held those same event objects.

That shape is a menu or a sheet in front of play, in front of the stock map. A thousand distinct names is a different question.

## One patch that matches

The timed call is one patch of the names the front layer owns. Those names already match the stored row: the same deadzone, the same event objects. The patch leaves the row in place. It does not allocate an action, and it does not write the engine. The stock names are not visited, because a patch rewrites only the names it was given.

This is the cost of a frame that asked again after the table was already right.

## The full compose of that tree

`{gdscript} _rebuild_input_map` on the same settled tree is the best case of walking every name. An unchanged row stays, stock rows stay shared, and the engine is left as it is. The work is the walk over the names and the comparison. `bench/responder_rebuild.gd` times this call, after `build()` has composed the table once.

A full compose is a heavier question than a patch. It answers "what does it cost to look at every name." The patch answers "what does it cost when one layer asks again."

## The front record handles the event

One slot is filled, `{gdscript} _input`. The other three walks are empty, because an empty slot is left off its list. The front record's callable marks the viewport handled.

The pass copies the walk and the callables before the first call. A handler may add or remove a responder before it returns, and this event still belongs to the responders that were in front when it arrived. The best case pays that copy, calls the front record, and returns. The records behind it are in the copy and are not called.

The walk sample in the bench calls every record. That is the far end of the same axis: the copy, and then a call for each responder.

## Reading a slower sample

A slower sample is a named step away from this case. The first compose creates the rows and writes the engine. A source event that changed misses the copy and writes again. A name whose front layer left falls through to stock, or leaves the table and is erased from the engine. A chain walks deeper than a flat list of children. A row with several events makes the match and the copy walk that list. A walk that nobody handles calls every copied callable. Several edits before idle are still one deferred compose, which is the call the game makes. The synchronous full compose is the call the bench makes.
