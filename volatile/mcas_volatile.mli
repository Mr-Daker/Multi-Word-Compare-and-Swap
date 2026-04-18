(** Multi-Word Compare-and-Swap (MCAS) for volatile memory.
    This interface models the in-memory, non-persistent variant of MCAS. *)

(** The type of an MCAS-capable memory reference holding a value of type ['a].
    Internally, this may hold either a value or a descriptor. *)
type 'a ref

(** [ref v] creates a new volatile MCAS reference initialized to value [v]. *)
val ref : 'a -> 'a ref

(** [get r] safely reads the current value of [r].
    If [get] encounters an in-progress descriptor, it may help complete that
    operation before returning a stable value. *)
val get : 'a ref -> 'a

(** [set r v] forcibly updates [r] to [v].
    This bypasses the MCAS protocol and should normally only be used during
    initialization or in a single-threaded context. *)
val set : 'a ref -> 'a -> unit

(** An abstract type representing one CAS participant in an MCAS operation. *)
type cas_op

(** [make_cas r ~expected ~desired] constructs a CAS operation on [r].
    The update succeeds only if the current value is physically equal [(==)]
    to [expected]. *)
val make_cas : 'a ref -> expected:'a -> desired:'a -> cas_op

(** [mcas ops] attempts to perform all CAS operations in [ops] atomically.

    Returns [true] if all references matched their expected values and were
    updated, or [false] if the operation failed. *)
val mcas : cas_op list -> bool
