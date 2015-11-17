# pp_record

Pretty prints records using record definitions with help of epp.
Almost all of the code is taken from shell.erl where shell commands
`rp` and `rr` are defined.


## How to use it

You read record definitions by using `pp_print:read/1,2` and format an
output with `pp_record:print(Data, Defs)`.

## How to build it

build with `make all`

## Example

Running an example project with a Pooler pool running Riak client
connections. Instead of printing the formatted output in the shell one can simply write it to a file. This is how I normally use it.

```erlang
1> {ok, Defs} = pp_record:read("deps/pooler/src/pooler.erl").
{ok,[{pool,{attribute,24,record,
                      {pool,[{record_field,25,{atom,25,name}},
                             {record_field,26,{atom,26,group}},
                             {record_field,27,{atom,27,max_count},{integer,27,100}},
                             {record_field,28,{atom,28,init_count},{integer,28,10}},
                             {record_field,29,{atom,29,start_mfa}},
                             {record_field,30,{atom,30,free_pids},{nil,30}},
                             {record_field,31,{atom,31,in_use_count},{integer,31,0}},
                             {record_field,32,{atom,32,free_count},{integer,32,0}},
                             {record_field,39,{atom,39,add_member_retry},{integer,39,1}},
                             {record_field,44,
                                           {atom,44,cull_interval},
                                           {tuple,44,[{...}|...]}},
                             {record_field,46,{atom,46,max_age},{tuple,46,[...]}},
                             {record_field,49,{atom,49,member_sup}},
                             {record_field,53,{atom,53,...}},
                             {record_field,62,{atom,...},{...}},
                             {record_field,68,{...},...},
                             {record_field,74,...},
                             {record_field,...},
                             {...}|...]}}}]}
2> io:format("~s~n", [pp_record:print(sys:get_state(whereis(pool)), Defs)]).
#pool{name = pool,group = undefined,max_count = 2000,
      init_count = 10,
      start_mfa = {apa,riak_worker_start_link,[]},
      free_pids = [<0.77.0>,<0.76.0>,<0.75.0>,<0.74.0>,<0.73.0>,
                   <0.72.0>,<0.71.0>,<0.70.0>,<0.69.0>,<0.66.0>],
      in_use_count = 0,free_count = 10,add_member_retry = 1,
      cull_interval = {1,min},
      max_age = {30,sec},
      member_sup = pooler_pool_member_sup,starter_sup = undefined,
      all_members = {dict,10,16,16,8,80,48,
                          {[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]},
                          {{[],[],
                            [[<0.66.0>|{#Ref<0.0.0.126>,free,{1447,782741,842698}}]],
                            [],[],
                            [[<0.69.0>|{#Ref<0.0.0.133>,free,{1447,782741,843147}}]],
                            [[<0.70.0>|{#Ref<0.0.0.140>,free,{1447,782741,843615}}]],
                            [[<0.71.0>|{#Ref<0.0.0.147>,free,{1447,782741,844130}}]],
                            [[<0.72.0>|{#Ref<0.0.0.154>,free,{1447,782741,844611}}]],
                            [[<0.73.0>|{#Ref<0.0.0.161>,free,{1447,782741,845061}}]],
                            [[<0.74.0>|{#Ref<0.0.0.168>,free,{1447,782741,845501}}]],
                            [[<0.75.0>|{#Ref<0.0.0.175>,free,{1447,782741,845909}}]],
                            [[<0.76.0>|{#Ref<0.0.0.182>,free,{1447,782741,846342}}]],
                            [[<0.77.0>|{#Ref<0.0.0.189>,free,{1447,782741,846792}}]],
                            [],[]}}},
      consumer_to_pid = {dict,0,16,16,8,80,48,
                              {[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]},
                              {{[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]}}},
      starting_members = [],
      member_start_timeout = {1,min},
      auto_grow_threshold = undefined,
      stop_mfa = {erlang,exit,['$pooler_pid',kill]},
      metrics_mod = pooler_no_metrics,metrics_api = folsom,
      queued_requestors = {[],[]},
      queue_max = 50}
```
