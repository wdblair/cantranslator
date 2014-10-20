(*
  A queue interface for the CAN translator.
*)

#define ATS_STALOADFLAG 0

absviewt@ype queue(a:t@ype)

abst@ype max_length (a:t@ype, n:int) = int n

praxi  array_length_lemma {a:t@ype} {len:pos} {sz:pos} (
  max: max_length(a, len), data: @[a][sz]
) : [len == sz] void

symintr int

castfn  length_to_int {a:t@ype} {len:nat} (
  len: max_length(a, len)
) : int len

overload int with length_to_int

fun {a:t@ype} queue_max_length ()
  : [m:pos] max_length(a, m)

fun {a:t@ype} queue_push (
  q : &queue(a) , itm : a
) : bool

fun {a:t@ype} queue_pop (
  q : &queue(a)
) : a

fun {a:t@ype} queue_peek (
  q : &queue(a)
) : a

fun {a:t@ype} queue_init (
  q : &queue(a)
) : void

fun {a:t@ype} queue_length (
  q : &queue(a)
) : [n:nat] int n

fun {a:t@ype} queue_available (
  q : &queue(a)
) : [n:int] int n

fun {a:t@ype} queue_full (
  q : &queue(a)
) : bool

fun {a:t@ype} queue_empty (
  q : &queue(a)
) : bool 

fun {a:t@ype} queue_snapshot {snap:pos} (
  q: &queue(a), snapshot : &(@[a?][snap])
) : void
