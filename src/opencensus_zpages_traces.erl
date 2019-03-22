-module(opencensus_zpages_traces).

-export([init/2, view/1, stream/1, info/3]).

-include_lib("kernel/include/logger.hrl").

-define(TEMPLATE, opencensus_zpages_traces_dtl).

init(Req, Func) ->
  Start = erlang:monotonic_time(),
  Return = ?MODULE:Func(Req),
  Duration = erlang:monotonic_time() - Start,
  oc_stat:record(#{endpoint => traces,
                   type => Func},
                 'opencensus.io/zpages/request',
                 erlang:convert_time_unit(Duration, native, millisecond)),
  Return.

view(Req0) ->
  {ok, Data} = ?TEMPLATE:render([]),
  Req = cowboy_req:reply(200, #{
          <<"content-type">> => <<"text/html">>
         }, Data, Req0),
  {ok, Req, []}.

stream(Req0) ->
  self() ! ping,
  Req = cowboy_req:stream_reply(200, #{
          <<"content-type">> => <<"text/event-stream">>
         }, Req0),
  {cowboy_loop, Req, 0}.

info(ping, Req, State) ->
  ?LOG_NOTICE("Ping"),
  Data = integer_to_binary(State),
  cowboy_req:stream_events(#{
   id => Data,
   event => <<"pong">>,
   data => Data}, nofin, Req),
  erlang:send_after(1000, self(), ping),
  {ok, Req, State + 1}.
