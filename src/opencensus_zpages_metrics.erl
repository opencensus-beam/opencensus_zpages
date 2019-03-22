-module(opencensus_zpages_metrics).

-export([init/2, view/1, stream/1]).

-export([websocket_init/1, websocket_handle/2, websocket_info/2]).

-include_lib("kernel/include/logger.hrl").

-define(TEMPLATE, opencensus_zpages_metrics_dtl).

init(Req, Func) ->
  Start = erlang:monotonic_time(),
  Return = ?MODULE:Func(Req),
  Duration = erlang:monotonic_time() - Start,
  oc_stat:record(#{endpoint => metrics,
                   type => Func},
                 'opencensus.io/zpages/request',
                 erlang:convert_time_unit(Duration, native, millisecond)),
  Return.

view(Req0) ->
  Metrics = normalize(oc_stat:export()),
  {ok, Data} = ?TEMPLATE:render([{metrics, Metrics}]),
  Req = cowboy_req:reply(200, #{
          <<"content-type">> => <<"text/html">>
         }, Data, Req0),
  {ok, Req, []}.

stream(Req) ->
  {cowboy_websocket, Req, 0}.

websocket_init(State) ->
  opencensus_zpages_registry:register(metrics),
  {ok, State}.

websocket_handle(_InFrame, State) -> {ok, State}.

websocket_info(Metrics, State) ->
  Data = jsx:encode(Msg),
  {reply, {text, Data}, State}.
