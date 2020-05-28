
val main :
  string ->
  ?downgrades: (int * string list) list ->           
  ?host:string ->
  ?port:int ->
  ?user:string ->
  ?password:string ->
  upgrades:(int * (unit PGOCaml.t -> int -> unit)) list ->
  unit
