(*
  Queue Implementation - Circular Buffer
  
*)

staload "SATS/queue.sats"

%{^

typedef struct {
  int head; 
  int tail;
  int max;
  int elements[10];
} queue_t;

static queue_t my_queue = {0,0,10,{[0 ... 9]= 0}};
%}

assume queue (a:t@ype, max:int) =
  [head,tail:nat | head < max + 1; tail < max + 1]
  $extype_struct "queue_t" of {
    head= int head,
    tail= int tail,
    max= int max,
    elements= @[a][max+1]
}

implement {a} queue_push {max} (q, itm) = let
  val nxt = (q.head + 1) nmod (q.max + 1)
in
  if nxt = q.tail then
    false
  else true where {
    val () = q.elements.[nxt] := itm
    val () = q.head := nxt
  }
end

implement {a} queue_pop {max} (q) = itm where {
  val nxt = (q.tail + 1) nmod (q.max + 1)
  val itm = q.elements.[q.tail]
  val () = q.tail := nxt
}

implement {a} queue_peek {max} (q) = itm where {
  val itm = q.elements.[q.tail]
}

implement {a} queue_init {max} (q) = {
  val () = q.tail := 0  
}

implement {a} queue_length {max} (q) = len where {
  val max1 = q.max + 1
  val diff = q.head - q.tail
  val len = (max1 + diff) nmod max1
}

implement {a} queue_empty {max} (q) =
  queue_length(q) = 0
  
implement {a} queue_full {max} (q) =
  queue_length(q) = q.max

implement {a} queue_available {max} (q) = 
  queue_length(q) < q.max

implement {a} queue_snapshot {max}{snap}
  (q, snapshot) = let
    val len = queue_length(q)
    var i : [p:nat] int p
in
  for(i := 0; i < len; i := i + 1) {
    val nxt = (q.tail + i) nmod (q.max+1)
    val () = snapshot.[i] := q.elements.[nxt]
  }
end

abst@ype uint8_t = $extype "uint8_t"

extern
castfn uint8_t_int {n:nat} (i: int n ) : uint8_t

(* Need a way for it to generate the templates we want to call from C. *)
fun dummy () : void = {
  var q : queue(uint8_t, 10) =
    $extval(queue(uint8_t, 10), "my_queue")
  val _ = queue_init(q)
  val _ = queue_push(q, uint8_t_int(10))
  val _ = queue_pop(q)
  val _ = queue_full(q)
  val _ = queue_length(q)
  val _ = queue_available(q)
  val _ = queue_full(q)
  val _ = queue_empty(q)
  var !buf = @[uint8_t][10]((uint8_t_int)0)
  val _ = queue_snapshot(q, !buf)
  val _ = queue_peek(q)
}
