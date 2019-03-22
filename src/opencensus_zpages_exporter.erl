-module(opencensus_zpages_exporter).

-behaviour(oc_stats_exporter).

-include_lib("kernel/include/logger.hrl").

-export([init/1, export/2]).

init(Opts) -> Opts.

export(Metrics, _Opts) ->
  Normailzed = normalize(Metrics),
  opencensus_zpages_registry:notify(metrics, Normalized),
  ok.

normalize(List) when is_list(List) ->
  [normalize(Item) || Item <- List];
normalize(#{
  name := Name,
  description := Description,
  data := #{
    rows := Rows,
    type := Type
   },
  ctags := Ctags,
  tags := Tags
 }) ->
  #{name => Name,
    description => Description,
    type => Type,
    data => [build_row(Row, Ctags, Tags) || Row <- Rows]}.

build_row(#{tags := TagsV, value := Value}, Ctags, TagsN) ->
  Tags = maps:to_list(maps:merge(Ctags, maps:from_list(lists:zip(TagsN, TagsV)))),
  #{tags => Tags, value => values(Value)}.

values(#{buckets := Buckets} = Values) ->
  Values#{buckets => [tuple_to_list(Bucket) || Bucket <- Buckets]}.
