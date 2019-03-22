-module(opencensus_zpages_registry).

-behaviour(gen_server).

-export([register/1, notify/2]).

-export([start_link/0,
        init/1,
        handle_call/3,
        handle_info/2,
        handle_cast/2]).

register(Type) ->
  gen_server:call(?MODULE, {register, Type, self()}).

notify(Type, Msg) ->
  gen_server:call(?MODULE, {notify, Type, Msg}).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, #{}, []).

init(_State) ->
  {ok, #{}}.

handle_cast(_, State) -> {noreply, State}.

handle_call({register, Type, Pid}, _From, State0) ->
  State = maps:update_with(Type,
                           fun (Pids) -> lists:umerge([Pid], Pids) end,
                           [Pid],
                           State0),
  erlang:monitor(process, Pid),
  {reply, ok, State};
handle_call({notify, Type, Message}, _From, State) ->
  [Pid ! Message || Pid <- maps:get(Type, State, [])],
  {reply, ok, State}.

handle_info({'DOWN', _Ref, process, Pid, _Reason}, State0) ->
  State = maps:map(fun (_Key, Pids) ->
                       lists:filter(fun (Val) -> Val =/= Pid end, Pids)
                   end, State0),
  {noreply, State}.
