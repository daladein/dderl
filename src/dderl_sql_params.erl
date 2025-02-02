%% -----------------------------------------------------------------------------
%%
%% dderl_sql_params.erl: SQL - filtering the parameters
%%                             of a SQL statement.
%%
%% Copyright (c) 2012-18 Konnexions GmbH.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -----------------------------------------------------------------------------

-module(dderl_sql_params).

-export([
    finalize/2,
    fold/5,
    get_params/2,
    init/1
]).

get_params(Sql, RegEx) ->
    sqlparse_fold:top_down(dderl_sql_params, Sql, RegEx).

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setting up parameters.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-spec init(RegEx :: iodata() | unicode:charlist()) ->
    {re_pattern, term(), term(), term(), term()} | list().
init(RegEx) when is_list(RegEx) ->
    case length(RegEx) > 0 of
        true -> {ok, MP_I} = re:compile(RegEx),
            MP_I;
        _ -> []
    end.

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Postprocessing of the result.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-spec finalize(Params :: any(), Ctx :: [binary()]|tuple()) ->
    Ctx :: [binary()]|tuple().
finalize(_MP, CtxIn) when is_list(CtxIn) ->
    lists:usort(CtxIn).

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Layout method for processing the various parser subtrees
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-spec fold(string(), FunState :: tuple(), Ctx :: [binary()],
    PTree :: list()|tuple(), FoldState :: tuple()) -> Ctx :: list().

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% param
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fold(MP, _FunState, Ctx, {param, Param} = _PTree, FoldState)
    when element(2, FoldState) == start ->
    add_param(MP, Param, Ctx);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% {param, _}
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fold(MP, _FunState, Ctx, {{param, Param}, _} = _PTree, FoldState)
    when element(2, FoldState) == start ->
    add_param(MP, Param, Ctx);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% {atom, param, param}
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fold(MP, _FunState, Ctx, {Op, {param, Param1}, {param, Param2}} =
    _PTree, FoldState)
    when is_atom(Op), element(2, FoldState) == start ->
    add_param(MP, Param2, add_param(MP, Param1, Ctx));

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% {atom, param, _}
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fold(MP, _FunState, Ctx, {Op, {param, Param}, _} = _PTree, FoldState)
    when is_atom(Op), element(2, FoldState) == start ->
    add_param(MP, Param, Ctx);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% {atom, _, param}
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fold(MP, _FunState, Ctx, {Op, _, {param, Param}} = _PTree, FoldState)
    when is_atom(Op), element(2, FoldState) == start ->
    add_param(MP, Param, Ctx);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NO ACTION.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fold(_MP, _FunState, Ctx, _PTree, _FoldState) ->
    Ctx.

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper functions.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

add_param(MP, Param, Ctx) ->
    case MP of
        [] -> [Param | Ctx];
        _ -> case re:run(Param, MP, [global, {capture, [0, 1, 2], binary}]) of
                 {match, Prms} -> Prms ++ Ctx;
                 _ -> Ctx
             end
    end.
