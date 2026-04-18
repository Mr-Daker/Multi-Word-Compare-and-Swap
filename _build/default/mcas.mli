(** Multi-Word Compare-and-Swap (MCAS) 
    Implementation based on the Harris-Fraser-Pratt algorithm. *)

(** The type of an MCAS-capable memory reference holding a value of type ['a]. 
    Internally, this will hold either a value or a descriptor. *)
type 'a ref

(** [ref v] creates a new MCAS reference initialized to value [v]. *)
val ref : 'a -> 'a ref

(** [get r] safely reads the current value of the reference [r].
    Crucially, if [get] encounters an in-progress MCAS descriptor on [r], 
    it will "help" complete that operation before returning the stable value. *)
val get : 'a ref -> 'a

(** [set r v] forcibly updates the reference [r] to [v].
    Warning: This bypasses the MCAS protocol and should generally only 
    be used during initialization or when single-threaded. *)
val set : 'a ref -> 'a -> unit

(** An abstract type representing a single Compare-And-Swap operation.
    This acts as an existential wrapper, allowing you to put operations on 
    different types of references (e.g., an int ref and a string ref) 
    into the same list for a multi-word update. *)
type cas_op

(** [make_cas r ~expected ~desired] constructs a single CAS operation.
    It dictates that reference [r] should be updated to [desired], but 
    only if its current value is physically equal (==) to [expected]. *)
val make_cas : 'a ref -> expected:'a -> desired:'a -> cas_op

(** [mcas ops] attempts to perform all CAS operations in the [ops] list atomically.
    
    @return [true] if all locations contained their expected values and were 
    successfully updated to their desired values. 
    @return [false] if any location did not match its expected value. In this case, 
    no references are permanently modified (the operation rolls back). *)
val mcas : cas_op list -> bool