(*
  A queue interface for the CAN translator.
*)
absviewt@ype queue(a:t@ype, count: int, max: int)

fun {a:t@ype} queue_push {max:pos} {cnt:nat | cnt < max} (
  q : &queue(a, cnt, max) >> queue(a, cnt+1, max), itm : a
) : void 

fun {a:t@ype} queue_pop {max: pos} {cnt: pos | cnt <= max} (
  q : &queue(a, cnt, max) >> queue(a, cnt-1, max), itm: &a? >> a
) : void

fun {a:t@ype} queue_peek {max: pos} {cnt: pos | cnt <= max} (
  q : !queue(a, cnt, max), itm: &a? >> a
) : void

fun {a:t@ype} queue_init {max: pos} {cnt: nat | cnt <= max} (
  q : &queue(a, cnt, max)? >> queue(a, cnt, max)
) : void

fun {a:t@ype} queue_length {max: pos} {cnt: nat | cnt <= max} (
  q : !queue(a, cnt, max)
) : int cnt

fun {a:t@ype} queue_available {max: pos} {cnt: nat | cnt <= max} (
  q : !queue(a, cnt, max)
) : bool (cnt < max)

fun {a:t@ype} queue_full {max: pos} {cnt: nat | cnt <= max} (
  q : !queue(a, cnt, max)
) : bool (cnt == max)

fun {a:t@ype} queue_empty {max: pos} {cnt: nat | cnt <= max} (
  q : !queue(a, cnt, max)
) : bool (cnt == 0)

fun {a:t@ype} queue_snapshot{max: pos} {cnt,snap:nat | cnt <= max; cnt <= snap} (
  q: !queue(a, cnt, max) , snapshot : &(@[a][snap])
) : void
