(** Multi-Word Compare-and-Swap (MCAS) for persistent memory.
    This interface separates the core MCAS API from crash-recovery concerns. *)

(** The type of a persistent MCAS-capable memory reference holding a value of
    type ['a]. Internally, this may hold either a value or a descriptor. *)
type 'a ref

(** [ref v] creates a new persistent MCAS reference initialized to [v]. *)
val ref : 'a -> 'a ref

(** [get r] safely reads the current logical value of [r].
    If an in-progress descriptor is encountered, the read may help complete it
    before returning. *)
val get : 'a ref -> 'a

(** [set r v] forcibly updates [r] to [v].
    This bypasses the MCAS protocol and should generally only be used during
    initialization, recovery, or controlled single-threaded setup. *)
val set : 'a ref -> 'a -> unit

(** An abstract type representing one CAS participant in a persistent MCAS
    operation. *)
type cas_op

(** [make_cas r ~expected ~desired] constructs one CAS step to be included in
    a persistent MCAS operation. *)
val make_cas : 'a ref -> expected:'a -> desired:'a -> cas_op

(** [mcas ops] attempts to atomically apply all operations in [ops].

    Returns [true] on success and [false] if some expected value does not
    match. *)
val mcas : cas_op list -> bool

(** [recover ()] performs any post-crash recovery required to restore the
    persistent MCAS metadata to a consistent state before normal operation
    resumes. *)
val recover : unit -> unit
