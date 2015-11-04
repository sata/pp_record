# pp_record

Pretty prints records using record definitions with help of epp.
Almost all of the code is taken from shell.erl where shell commands
`rp` and `rr` are defined.


## How to use it
You read record definitions by using `pp_print:read/1,2` and format an output with `pp_record:print(Data, Defs)`.

## How to build it
build with `make all`

