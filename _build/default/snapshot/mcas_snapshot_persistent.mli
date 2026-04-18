(** Atomic snapshot implemented using persistent MCAS. *)

type 'a t

(** [init n v] creates a snapshot with [n] slots initialized to [v]. *)
val init : int -> 'a -> 'a t

(** Alias for [init], matching the older snapshot module naming. *)
val create : int -> 'a -> 'a t

(** [update t i v] atomically updates slot [i] to [v]. *)
val update : 'a t -> int -> 'a -> unit

(** [scan t] returns a linearizable snapshot of all slots. *)
val scan : 'a t -> 'a array

(** [size t] returns the number of slots. *)
val size : 'a t -> int

(** [recover ()] runs persistent-MCAS recovery before normal use resumes. *)
val recover : unit -> unit
