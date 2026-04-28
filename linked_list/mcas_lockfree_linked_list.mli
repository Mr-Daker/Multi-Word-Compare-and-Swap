(** Lock-free sorted linked-list set using volatile MCAS. *)

type t

val create : unit -> t
val insert : t -> int -> bool
val delete : t -> int -> bool
val member : t -> int -> bool
val to_list : t -> int list
