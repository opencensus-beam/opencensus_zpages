%%%-------------------------------------------------------------------
%% @doc opencensus_zpages public API
%% @end
%%%-------------------------------------------------------------------

-module(opencensus_zpages_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-include_lib("kernel/include/logger.hrl").

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
  Dispatch = cowboy_router:compile([{'_', routes()}]),
  {ok, CowboyConfig} = application:get_env(cowboy),
  cowboy:start_clear(opencensus_zpages_listener,
                     CowboyConfig,
                     #{env => #{dispatch => Dispatch}}
                    ),
  opencensus_zpages_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
  ok.

%%====================================================================
%% Internal functions
%%====================================================================

routes() ->
  [{"/assets/[...]", cowboy_static, {priv_dir, opencensus_zpages, "static"}},
   {"/metricz/stream", opencensus_zpages_metrics, stream},
   {"/metricz", opencensus_zpages_metrics, view},
   {"/tracez/stream", opencensus_zpages_traces, stream},
   {"/tracez", opencensus_zpages_traces, view}].
