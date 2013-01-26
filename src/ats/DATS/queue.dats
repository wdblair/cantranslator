(*
  Queue Implementation - Circular Buffer
*)

#define ATS_DYNLOADFLAG 0

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

 typedef struct {
   int head;
   int tail;
   char elements[];
 } queue_t;
%}

%{
  ats_ptr_type get_queue() {
    return NULL;
  }
%}

(* Start implementation. *)

assume queue (a:t@ype) =
  [head, tail:nat ; max:pos | head < max; tail < max]
  $extype_struct "queue_t" of {
    head= int head,
    tail= int tail,
    elements= @[a][max]
  }
  
extern
castfn  max_length_int{a:t@ype} {n:nat} (
  n: int n
) : max_length(a, n)

implement {a} queue_push (q, itm) = let
  val len = queue_max_length()
  prval () = array_length_lemma(len, q.elements)
  val max = length_to_int(len)
  val nxt = (q.head + 1) nmod (max)
in
  if nxt = q.tail then
    false
  else true where {
    val () = q.elements.[q.head] := itm
    val () = q.head := nxt
  }
end

implement {a} queue_pop (q) = itm where {
  val len = queue_max_length()
  prval () = array_length_lemma(len, q.elements)
  val max = length_to_int(len)
  val nxt = (q.tail + 1) nmod (max)
  val itm = q.elements.[q.tail]
  val () = q.tail := nxt
}

implement {a} queue_peek (q) = itm where {
  val itm = q.elements.[q.tail]
}

implement {a} queue_init (q) = {
  val () = q.tail := 0
  val () = q.head := 0
}

implement {a} queue_length (q) = len where {
  val len = queue_max_length()
  prval () = array_length_lemma(len, q.elements)
  val max = length_to_int(len)
  val diff = q.head - q.tail
  val len = (max + diff) nmod max
}

implement {a} queue_empty (q) =
  queue_length(q) = 0
  
implement {a} queue_full (q) = let
  val len = queue_max_length()
  prval () = array_length_lemma(len, q.elements)
  val max = length_to_int(len)
in
  queue_length(q) = (max - 1)
end

implement {a} queue_available (q) = let
  val len = queue_max_length()
  prval () = array_length_lemma(len, q.elements)
  val max = length_to_int(len)
in
  (max - 1) - queue_length(q)
end

implement {a} queue_snapshot {snap} (
  q, snapshot
) = {
    //Need to assume the array we were given has enough space.
    //Using assure would be better.
    extern
    praxi array_equal_lemma {a:t@ype} {stored, orig, snap:int} (
      q: queue(a), m: max_length(a, orig),
      len: int stored, snap: @[a?][snap]
    ) : [snap >= orig ; stored < orig] void
    val len = queue_length(q)
//    
    fun loop {index: nat | index < snap} (
      i: int index, q: &queue(a), arr: &(@[a?][snap])
    ) : void = let
        val len = queue_length(q)
        val capacity = queue_max_length()
        val max = length_to_int(capacity)
        prval () =
          array_length_lemma(capacity, q.elements)
        prval () = array_equal_lemma(q, capacity, len, arr)
        val nxt = (q.tail + i) nmod max
        val () =  arr.[i] := q.elements.[nxt]
    in
      if i+1 >= len then
        ()
      else
        loop(i+1, q, arr)
    end
    val () = loop(0, q, snapshot)
}

(* End of Queue Implementation. *)


extern
fun get_queue{a:t@ype} () 
  : [l:addr] (queue(a) @ l -<> void, queue(a) @ l | ptr l) = 
    "get_queue"

abst@ype uint8_t = $extype "uint8_t"

abst@ype normal_int = $extype "int"

abst@ype can_message = $extype "CanMessage"

abst@ype test_t = $extype "test_t"

//It'd be nice to defere these functions to C.

implement queue_max_length<uint8_t>() = max_length_int(513)

implement queue_max_length<can_message>() = max_length_int(17)

extern
castfn uint8_t_int {n:nat} (i: int n) : uint8_t

extern
castfn normal_int {n:nat} (i: int n) : normal_int

extern
castfn uint32_t {n:nat} (i: int n) : uint32

extern
castfn uint64_t {n:nat} (i: int n) : uint64

(* Need a way for it to generate the templates we want to call from C. *)
fun dummy () : void = {
  val (free, pf | q) = get_queue{uint8_t}()
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
  extern
  praxi bless{a:t@ype}(msg: &a? >> a) : void
  val (free, pf | q) = get_queue{can_message}()
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
}