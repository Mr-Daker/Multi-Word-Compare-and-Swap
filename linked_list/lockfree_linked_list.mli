(** Lock-free sorted linked-list set using ordinary single-word CAS. *)

type t

(** [create ()] creates an empty integer set. *)
val create : unit -> t

(** [insert t key] inserts [key] if it is absent.
    Returns [true] when the set changed. *)
val insert : t -> int -> bool

(** [delete t key] removes [key] if present.
    Returns [true] when the set changed. *)
val delete : t -> int -> bool

(** [member t key] returns whether [key] is currently present. *)
val member : t -> int -> bool

(** [to_list t] returns the live keys in sorted order. *)
val to_list : t -> int list
