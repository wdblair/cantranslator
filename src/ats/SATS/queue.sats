(*
  A queue interface for the CAN translator.
*)
absviewt@ype queue(a:t@ype, max: int)

fun {a:t@ype} queue_max_length {max: nat} (
  q: &queue(a, max)
) : int max

fun {a:t@ype} queue_push {max:pos} (
  q : &queue(a, max) , itm : a
) : bool

fun {a:t@ype} queue_pop {max: pos} (
  q : &queue(a, max)
) : a

fun {a:t@ype} queue_peek {max: pos} (
  q : &queue(a, max)
) : a

fun {a:t@ype} queue_init {max: pos} (
  q : &queue(a, max)
) : void

fun {a:t@ype} queue_length {max: pos} (
  q : &queue(a, max)
) : [n:nat | n <= max] int n

fun {a:t@ype} queue_available {max: pos} (
  q : &queue(a, max)
) : bool

fun {a:t@ype} queue_full {max: pos} (
  q : &queue(a, max)
) : bool

fun {a:t@ype} queue_empty {max: pos} (
  q : &queue(a, max)
) : bool 

fun {a:t@ype} queue_snapshot{max: pos} {snap:nat | snap >= max} (
  q: &queue(a, max) , snapshot : &(@[a][snap])
) : void
