(*
  Queue Implementation - Circular Buffer
  
*)

staload "SATS/queue.sats"

staload "prelude/SATS/unsafe.sats"
staload "prelude/DATS/unsafe.dats"

%{^
#include "ats/basics.h"

typedef struct {
    void *bus;
    uint32_t id;
    uint64_t data;
} CanMessage;

typedef struct {
    int i;
    char bytes[8];
} test_t;
%}

(* Start implementation. *)

assume queue (a:t@ype, max:int) =
  [head,tail:nat | head < max + 1; tail < max + 1]
  @{
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

(* End of Queue Implementation. *)

extern
fun get_queue{a:t@ype}{m:pos} () 
  : [l:addr] (queue(a,m) @ l -<> void, queue(a,m) @ l | ptr l) = 
    "get_queue"

abst@ype uint8_t = $extype "uint8_t"

abst@ype normal_int = $extype "int"

abst@ype can_message = $extype "CanMessage"

abst@ype test_t = $extype "test_t"

extern
castfn uint8_t_int {n:nat} (i: int n): uint8_t

extern
castfn normal_int {n:nat} (i: int n): normal_int

extern
castfn uint32_t {n:nat} (i: int n): uint32

extern
castfn uint64_t {n:nat} (i: int n): uint64

(* Need a way for it to generate the templates we want to call from C. *)
fun dummy () : void = {
  val (free, pf | q) = get_queue{uint8_t}{10}()
  val _ = queue_init(!q)
  val _ = queue_push(!q, uint8_t_int(10))
  val _ = queue_pop(!q)
  val _ = queue_full(!q)
  val _ = queue_length(!q)
  val _ = queue_available(!q)
  val _ = queue_full(!q)
  val _ = queue_empty(!q)
  var !buf = @[uint8_t][10]()
  val _ = queue_snapshot(!q, !buf)
  val _ = queue_peek(!q)
  prval () = free(pf)
//
  val (free, pf | q) = get_queue{normal_int}{10}()
  val _ = queue_init(!q)
  val _ = queue_push(!q, normal_int(10))
  val _ = queue_pop(!q)
  val _ = queue_full(!q)
  val _ = queue_length(!q)
  val _ = queue_available(!q)
  val _ = queue_full(!q)
  val _ = queue_empty(!q)
  var !buf = @[normal_int][10]()
  val _ = queue_snapshot(!q, !buf)
  val _ = queue_peek(!q)
  prval () = free(pf)
//
  extern
  praxi bless{a:t@ype}(msg: &a? >> a) : void
  val (free, pf | q) = get_queue{can_message}{10}()
  val _ = queue_init(!q)
  var msg : can_message
  prval () = bless{can_message}(msg)
  val _ = queue_push(!q, msg)
  val _ = queue_pop(!q)
  val _ = queue_full(!q)
  val _ = queue_length(!q)
  val _ = queue_available(!q)
  val _ = queue_full(!q)
  val _ = queue_empty(!q)
  var !buf = @[can_message][10]()
  val _ = queue_snapshot(!q, !buf)
  val _ = queue_peek(!q)
  prval () = free(pf)
//
  val (free, pf | q) = get_queue{test_t}{10}()
  val _ = queue_init(!q)
  var msg : test_t
  prval () = bless{test_t}(msg)
  val _ = queue_push(!q, msg)
  val _ = queue_pop(!q)
  val _ = queue_full(!q)
  val _ = queue_length(!q)
  val _ = queue_available(!q)
  val _ = queue_full(!q)
  val _ = queue_empty(!q)
  var !buf = @[test_t][10]()
  val _ = queue_snapshot(!q, !buf)
  val _ = queue_peek(!q)
  prval () = free(pf)
}
