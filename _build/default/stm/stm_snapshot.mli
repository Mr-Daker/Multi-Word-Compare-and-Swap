(** Snapshot implemented on top of the STM-style volatile interface. *)

type 'a t

val init : int -> 'a -> 'a t
val create : int -> 'a -> 'a t
val update : 'a t -> int -> 'a -> unit
val scan : 'a t -> 'a array
val size : 'a t -> int
