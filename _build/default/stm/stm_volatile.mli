(** Simple STM-style atomic multi-update interface for volatile memory. *)

type 'a ref
type txn_op

val ref : 'a -> 'a ref
val get : 'a ref -> 'a
val set : 'a ref -> 'a -> unit
val make_op : 'a ref -> expected:'a -> desired:'a -> txn_op
val commit : txn_op list -> bool
