%%% -*- coding: utf-8 -*-
%%% @doc
%%%
%%% Pretty prints Erlang records using record definitions.
%%% Almost all of the code is taken from shell.erl where
%%% shell commands `rp` and `rr` are defined.
%%%
%%% @end
-module(pp_rec).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------
-export([read/1,
         read/2,
         print/2]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

-spec read(atom() | string()) -> [tuple()].
read(FileOrModule) ->
  read(FileOrModule, []).

%% reads record definitions by using epp pre processor.
%%
%% Opts are here to help eep, see pre_defs,inc_paths/1 and epp:parse_file/3.
%%
%% The return is a list of record definitions with epp convention
%% which io_lib_pretty:print/2 understands given the record_print_fun/1.
%%
%% FileOrModule argument can be either an module, path to module or
%% wildcard. In case of module name, it will ask the code server for
%% the full path to the module. see find_file/1 for details.
-spec read(atom() | string(), [tuple()]) -> [tuple()].
read(FileOrModule, Opts) ->
  stripped_read_records(FileOrModule, Opts).

%% prints Value and formats entries according to record definitions
%% found in RecDefs.
%%
%% The only difference here from shell.erl is instead of looking up
%% record definitions in shell ETS table it's done by doing keyfinds
%% on list.
-spec print(term(), atom() | string()) -> string().
print(Value, RecDefs) when is_tuple(Value) andalso
                           is_list(RecDefs) ->
  io_lib_pretty:print(Value, ([{column, 1},
                               {line_length, columns()},
                               {depth, -1},
                               {max_chars, 60},
                               {record_print_fun, record_print_fun(RecDefs)}]
                              ++ enc())).

%% -------------------------------------------------------------------
%% Internal Functions
%% -------------------------------------------------------------------
stripped_read_records(R, Opts) ->
  [{Name,D} || {attribute,_,_,{Name,_}} = D <- read_records(R, Opts)].

record_print_fun(Data) ->
    fun(Tag, NoFields) ->
            case lists:keyfind(Tag, 1, Data) of
                [{_,{attribute,_,record,{Tag,Fields}}}]
                                  when length(Fields) =:= NoFields ->
                    record_fields(Fields);
                _ ->
                    no
            end
    end.

record_fields([{record_field,_,{atom,_,Field}} | Fs]) ->
    [Field | record_fields(Fs)];
record_fields([{record_field,_,{atom,_,Field},_} | Fs]) ->
    [Field | record_fields(Fs)];
record_fields([]) ->
    [].

columns() ->
    case io:columns() of
        {ok,N} -> N;
        _ -> 80
    end.

enc() ->
    case lists:keyfind(encoding, 1, io:getopts()) of
	false -> [{encoding,latin1}]; % should never happen
	Enc -> [Enc]
    end.

%%% Read record information from file(s)
read_records(FileOrModule, Opts) ->
  case find_file(FileOrModule) of
    {files,[File]} ->
      read_file_records(File, Opts);
    {files,Files} ->
      lists:flatmap(fun(File) ->
                        case read_file_records(File, Opts) of
                          RAs when is_list(RAs) -> RAs;
                          _ -> []
                        end
                    end, Files);
    Error ->
      Error
  end.

-include_lib("kernel/include/file.hrl").

find_file(Mod) when is_atom(Mod) ->
    case code:which(Mod) of
	File when is_list(File) ->
	    {files,[File]};
	preloaded ->
	    {_M,_Bin,File} = code:get_object_code(Mod),
            {files,[File]};
        _Else -> % non_existing, interpreted, cover_compiled
            {error,nofile}
    end;
find_file(File) ->
    case catch filelib:wildcard(File) of
        {'EXIT',_} ->
            {error,invalid_filename};
        Files ->
            {files,Files}
    end.

read_file_records(File, Opts) ->
    case filename:extension(File) of
        ".beam" ->
            case beam_lib:chunks(File, [abstract_code,"CInf"]) of
                {ok,{_Mod,[{abstract_code,{Version,Forms}},{"CInf",CB}]}} ->
                    case record_attrs(Forms) of
                        [] when Version =:= raw_abstract_v1 ->
                            [];
                        [] -> 
                            %% If the version is raw_X, then this test
                            %% is unnecessary.
                            try_source(File, CB);
                        Records -> 
                            Records
                    end;
                {ok,{_Mod,[{abstract_code,no_abstract_code},{"CInf",CB}]}} ->
                    try_source(File, CB);
                Error ->
                    %% Could be that the "Abst" chunk is missing (pre R6).
                    Error
            end;
        _ ->
            parse_file(File, Opts)
    end.

%% This is how the debugger searches for source files. See int.erl.
try_source(Beam, CB) ->
    Os = case lists:keyfind(options, 1, binary_to_term(CB)) of
             false -> [];
             {_, Os0} -> Os0
	 end,
    Src0 = filename:rootname(Beam) ++ ".erl",
    case is_file(Src0) of
	true -> parse_file(Src0, Os);
	false ->
	    EbinDir = filename:dirname(Beam),
	    Src = filename:join([filename:dirname(EbinDir), "src",
				 filename:basename(Src0)]),
	    case is_file(Src) of
		true -> parse_file(Src, Os);
		false -> {error, nofile}
	    end
    end.

is_file(Name) ->
    case filelib:is_file(Name) of
	true ->
	    not filelib:is_dir(Name);
	false ->
	    false
    end.

parse_file(File, Opts) ->
    Cwd = ".",
    Dir = filename:dirname(File),
    IncludePath = [Cwd,Dir|inc_paths(Opts)],
    case epp:parse_file(File, IncludePath, pre_defs(Opts)) of
        {ok,Forms} ->
            record_attrs(Forms);
        Error ->
            Error
    end.

pre_defs([{d,M,V}|Opts]) ->
    [{M,V}|pre_defs(Opts)];
pre_defs([{d,M}|Opts]) ->
    [M|pre_defs(Opts)];
pre_defs([_|Opts]) ->
    pre_defs(Opts);
pre_defs([]) -> [].

inc_paths(Opts) ->
    [P || {i,P} <- Opts, is_list(P)].

record_attrs(Forms) ->
    [A || A = {attribute,_,record,_D} <- Forms].
