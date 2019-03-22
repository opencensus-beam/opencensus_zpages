%%%-------------------------------------------------------------------
%% @doc opencensus_zpages top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(opencensus_zpages_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: #{id => Id, start => {M, F, A}}
%% Optional keys are restart, shutdown, type, modules.
%% Before OTP 18 tuples must be used to specify a child. e.g.
%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
  ok = internal_measurements(),
  ok = register_listeners(),
  Registry = #{id => registry,
               start => {opencensus_zpages_registry, start_link, []}},
  {ok, {{one_for_all, 0, 1}, [Registry]}}.

%%====================================================================
%% Internal functions
%%====================================================================

internal_measurements() ->
  Requests = oc_stat_measure:new('opencensus.io/zpages/request',
                                 "Requests duration",
                                 millisecond),
  {ok, _View} = oc_stat_view:subscribe('opencensus.io/zpages/request',
                                       Requests,
                                       "Request duration",
                                       [endpoint, type],
                                       oc_stat_aggregation_distribution),
  ok.

register_listeners() ->
  oc_stat_exporter:register(opencensus_zpages_exporter),
  ok.
