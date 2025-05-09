%
% This file is part of AtomVM.
%
% Copyright 2019-2021 Fred Dushin <fred@dushin.net>
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% SPDX-License-Identifier: Apache-2.0 OR LGPL-2.1-or-later
%

-module(test_io_lib).

-export([test/0]).

-include("etest.hrl").

-define(FLT(L), lists:flatten(L)).

test() ->
    ok = test_format(),
    ok = test_latin1_char_list(),
    ok = test_write(),
    ok = test_write_atom(),
    ok = test_write_string(),
    ok = test_chars_length(),
    ok = test_printable_list(),
    ok.

test_format() ->
    ?ASSERT_MATCH(?FLT(io_lib:format("", [])), ""),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo", [])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format(<<"foo">>, [])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format(foo, [])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:fwrite("foo", [])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:fwrite(<<"foo">>, [])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:fwrite(foo, [])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo~n", [])), "foo\n"),
    % atom
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [bar])), "foo: bar\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~s~n", [bar])), "foo: bar\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [bar])), "foo: bar\n"),
    % strings
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", ["bar"])), "foo: \"bar\"\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~s~n", ["bar"])), "foo: bar\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", ["bar"])), "foo: [98,97,114]\n"),
    % printable binaries
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [<<"bar">>])), "foo: <<\"bar\">>\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~s~n", [<<"bar">>])), "foo: bar\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [<<"bar">>])), "foo: <<98,97,114>>\n"),
    % unprintable binaries
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [<<1, 2, 3>>])), "foo: <<1,2,3>>\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~s~n", [<<1, 2, 3>>])), ?FLT(["foo: ", 1, 2, 3, "\n"])),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [<<1, 2, 3>>])), "foo: <<1,2,3>>\n"),
    % unprintable strings
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [[1, 2, 3]])), "foo: [1,2,3]\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~s~n", [[1, 2, 3]])), "foo: \1\2\3\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [[1, 2, 3]])), "foo: [1,2,3]\n"),
    % unprintable lists
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [[-1]])), "foo: [-1]\n"),
    ?ASSERT_ERROR(io_lib:format("foo: ~s~n", [[-1]]), badarg),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [[-1]])), "foo: [-1]\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [[256]])), "foo: [256]\n"),
    ?ASSERT_ERROR(io_lib:format("foo: ~s~n", [[256]]), badarg),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [[256]])), "foo: [256]\n"),
    % escapable strings
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~p~n", ["bar\b\t\n\v\f\r\e"])),
        "foo: \"bar\\b\\t\\n\\v\\f\\r\\e\"\n"
    ),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~s~n", ["bar\b\t\n\v\f\r\e"])), "foo: bar\b\t\n\v\f\r\e\n"
    ),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~w~n", ["bar\b\t\n\v\f\r\e"])),
        "foo: [98,97,114,8,9,10,11,12,13,27]\n"
    ),
    % escapable binaries
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~p~n", [<<"bar\b\t\n\v\f\r\e">>])),
        "foo: <<\"bar\\b\\t\\n\\v\\f\\r\\e\">>\n"
    ),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~s~n", [<<"bar\b\t\n\v\f\r\e">>])), "foo: bar\b\t\n\v\f\r\e\n"
    ),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~w~n", [<<"bar\b\t\n\v\f\r\e">>])),
        "foo: <<98,97,114,8,9,10,11,12,13,27>>\n"
    ),
    % nested lists of strings and chars
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~p~n", [[["hello", " "], "world"]])),
        "foo: [[\"hello\",\" \"],\"world\"]\n"
    ),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~s~n", [[["hello", " "], "world"]])), "foo: hello world\n"
    ),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~w~n", [[["hello", " "], "world"]])),
        "foo: [[[104,101,108,108,111],[32]],[119,111,114,108,100]]\n"
    ),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [[1, 2, 3]])), "foo: [1,2,3]\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~s~n", [[1, 2, 3]])), "foo: \1\2\3\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [[1, 2, 3]])), "foo: [1,2,3]\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [[1, 2, [3]]])), "foo: [1,2,[3]]\n"),
    % integers
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [123])), "foo: 123\n"),
    ?ASSERT_ERROR(io_lib:format("foo: ~s~n", [123]), badarg),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [123])), "foo: 123\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [-123])), "foo: -123\n"),
    ?ASSERT_ERROR(io_lib:format("foo: ~s~n", [-123]), badarg),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~w~n", [-123])), "foo: -123\n"),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~p~n", [[65, 116, 111, 109, 86, 77]])), "foo: \"AtomVM\"\n"
    ),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~s~n", [[65, 116, 111, 109, 86, 77]])), "foo: AtomVM\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [{bar, tapas}])), "foo: {bar,tapas}\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [{bar, "tapas"}])), "foo: {bar,\"tapas\"}\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [#{}])), "foo: #{}\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p~n", [#{a => 1}])), "foo: #{a => 1}\n"),
    % OTP-26+ can return either map representations
    % https://www.erlang.org/patches/otp-26.0#OTP-18414
    ?ASSERT_TRUE(
        lists:member(?FLT(io_lib:format("foo: ~p", [#{a => 1, b => 2}])), [
            "foo: #{a => 1,b => 2}", "foo: #{b => 2,a => 1}"
        ])
    ),
    ?ASSERT_TRUE(
        lists:member(?FLT(io_lib:format("foo: ~p", [#{b => 2, a => 1}])), [
            "foo: #{a => 1,b => 2}", "foo: #{b => 2,a => 1}"
        ])
    ),
    HasKModifier =
        case erlang:system_info(machine) of
            "BEAM" ->
                erlang:system_info(version) >= "14.";
            "ATOM" ->
                true
        end,
    case HasKModifier of
        true ->
            ?ASSERT_MATCH(
                ?FLT(io_lib:format("foo: ~kp~n", [#{a => 1, b => 2}])), "foo: #{a => 1,b => 2}\n"
            );
        false ->
            ok
    end,
    ?ASSERT_MATCH(?FLT(io_lib:format("foo: ~p", [#{{x, y} => z}])), "foo: #{{x,y} => z}"),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("foo: ~p", [#{"foo" => "bar"}])), "foo: #{\"foo\" => \"bar\"}"
    ),

    ?ASSERT_MATCH(?FLT(io_lib:format("~p", [foo])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~p", ['-foo'])), "'-foo'"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~p", ['try'])), "'try'"),
    MaybeAtomStr =
        case erlang:system_info(machine) of
            "BEAM" ->
                case erlang:system_info(version) >= "15." of
                    true -> "'maybe'";
                    false -> "maybe"
                end;
            "ATOM" ->
                "'maybe'"
        end,
    ?ASSERT_MATCH(?FLT(io_lib:format("~p", ['maybe'])), MaybeAtomStr),
    ?ASSERT_MATCH(?FLT(io_lib:format("~w", [foo])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~w", ['-foo'])), "'-foo'"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~w", ['try'])), "'try'"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~w", ['maybe'])), MaybeAtomStr),
    ?ASSERT_MATCH(?FLT(io_lib:format("~s", [foo])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~s", ['-foo'])), "-foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~s", ['try'])), "try"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~s", ['maybe'])), "maybe"),

    ?ASSERT_MATCH(?FLT(io_lib:format("\t~p", [bar])), "\tbar"),

    ?ASSERT_MATCH(
        ?FLT(io_lib:format("a ~p ~p of ~p patterns", [small, number, interesting])),
        "a small number of interesting patterns"
    ),
    ?ASSERT_MATCH(?FLT(io_lib:format("escape ~~p~n", [])), "escape ~p\n"),

    ?ASSERT_ERROR(io_lib:format("no pattern", id([foo])), badarg),
    ?ASSERT_ERROR(io_lib:format("too ~p many ~p patterns", id([foo])), badarg),
    ?ASSERT_ERROR(io_lib:format("not enough ~p patterns", id([foo, bar])), badarg),

    %   ?ASSERT_MATCH(?FLT(io_lib:format("~*.*.0f~n", [9, 5, 3.14159265])), "003.14159\n"),
    %   ?ASSERT_MATCH(?FLT(io_lib:format("~*.*.*f~n", [9, 5, $*, 3.14159265])), "**3.14159\n"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~~", [])), "~"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~c", [$a])), "a"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~5s", ["a"])), "    a"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~5..zs", ["a"])), "zzzza"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~-5s", ["a"])), "a    "),
    ?ASSERT_MATCH(?FLT(io_lib:format("~-5..zs", ["a"])), "azzzz"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~3w", ["foobar"])), "***"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~-3w", ["foobar"])), "***"),
    %   ?ASSERT_MATCH(?FLT(io_lib:format("~3p", ["foobar"])), "foo"),
    %   ?ASSERT_MATCH(?FLT(io_lib:format("~-3p", ["foobar"])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~3s", ["foobar"])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~s", [<<"hé"/utf8>>])), [104, 195, 169]),
    ?ASSERT_MATCH(?FLT(io_lib:format("~ts", [<<"hé"/utf8>>])), [104, 233]),
    ?ASSERT_MATCH(?FLT(io_lib:format("~ts", [<<"hé"/utf8, 223>>])), [104, 195, 169, 223]),
    ?ASSERT_MATCH(?FLT(io_lib:format("~-3s", ["foobar"])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~3s", ["foo"])), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~-3s", ["foo"])), "foo"),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("|~10.5c|~-10.5c|~5c|~n", [$a, $b, $c])),
        "|     aaaaa|bbbbb     |ccccc|\n"
    ),
    ?ASSERT_MATCH(?FLT(io_lib:format("~tc~n", [1024])), [1024, 10]),
    ?ASSERT_MATCH(?FLT(io_lib:format("~c~n", [1024])), [0, 10]),
    ?ASSERT_MATCH(?FLT(io_lib:format("~f", [3.14])), "3.140000"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~f", [-3.14])), "-3.140000"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.4f", [3.14])), "3.1400"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.4f", [-3.14])), "-3.1400"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~e", [3.14])), "3.14000e+0"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.4e", [3.14])), "3.140e+0"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~g", [3.14])), "3.14000"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~g", [0.00314])), "3.14000e-3"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.4g", [3.14])), "3.140"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.4g", [0.00314])), "3.140e-3"),
    ?ASSERT_MATCH(?FLT(io_lib:format("|~10w|", [{hey, hey, hey}])), "|**********|"),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("|~10s|", [io_lib:format("~p", [{hey, hey, hey}])])), "|{hey,hey,h|"
    ),
    ?ASSERT_MATCH(
        ?FLT(io_lib:format("|~-10.8s|", [io_lib:format("~p", [{hey, hey, hey}])])), "|{hey,hey  |"
    ),
    ?ASSERT_MATCH(?FLT(io_lib:format("~ts~n", [[1024]])), [1024, 10]),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.16B", [31])), "1F"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.2B", [-19])), "-10011"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.36B", [5 * 36 + 35])), "5Z"),
    %   ?ASSERT_MATCH(?FLT(io_lib:format("~X", [31,"10#"])), "10#31"),
    %   ?ASSERT_MATCH(?FLT(io_lib:format("~.16X", [-31,"0x"])), "-0x1F"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~#", [31])), "10#31"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.16#", [-31])), "-16#1F"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.16b", [31])), "1f"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.2b", [-19])), "-10011"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.36b", [5 * 36 + 35])), "5z"),
    %   ?ASSERT_MATCH(?FLT(io_lib:format("~x", [31,"10#"])), "10#31"),
    %   ?ASSERT_MATCH(?FLT(io_lib:format("~.16x", [-31,"0x"])), "-0x1f"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~+", [31])), "10#31"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~.16+", [-31])), "-16#1f"),
    ?ASSERT_MATCH(?FLT(io_lib:format("~i~n", [foo])), "\n"),

    ok.

test_latin1_char_list() ->
    true = io_lib:latin1_char_list([]),
    false = io_lib:latin1_char_list(foo),
    false = io_lib:latin1_char_list(<<>>),
    false = io_lib:latin1_char_list(<<"hello">>),
    true = io_lib:latin1_char_list("hello"),
    true = io_lib:latin1_char_list("été"),
    false = io_lib:latin1_char_list(["hello"]),
    false = io_lib:latin1_char_list([$h, $e, $l, $l | $o]),
    ok.

test_write() ->
    ?ASSERT_MATCH(?FLT(io_lib:write(foo)), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:write(42)), "42"),
    ?ASSERT_MATCH(?FLT(io_lib:write("*")), "[42]"),
    ?ASSERT_MATCH(?FLT(io_lib:write(<<42>>)), "<<42>>"),
    ok.

test_write_atom() ->
    ?ASSERT_MATCH(?FLT(io_lib:write_atom(foo)), "foo"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom(bar)), "bar"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('bar')), "bar"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('if')), "'if'"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('_')), "'_'"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('!hello')), "'!hello'"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('.hello')), "'.hello'"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('@hello')), "'@hello'"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom(hello@world)), "hello@world"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('0hello')), "'0hello'"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom(hello0world)), "hello0world"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('Hello')), "'Hello'"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom(helloWorld)), "helloWorld"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom(hello_world)), "hello_world"),
    ?ASSERT_MATCH(?FLT(io_lib:write_atom('hello\'world')), "'hello\\'world'"),
    ok.

test_write_string() ->
    ?ASSERT_MATCH(?FLT(io_lib:write_string("foo")), "\"foo\""),
    ?ASSERT_MATCH(?FLT(io_lib:write_string([42])), "\"*\""),
    ?ASSERT_MATCH(?FLT(io_lib:write_string([])), "\"\""),
    ?ASSERT_MATCH(?FLT(io_lib:write_string("アトム")), "\"アトム\""),
    ok.

test_chars_length() ->
    ?ASSERT_MATCH(io_lib:chars_length("foo"), 3),
    ?ASSERT_MATCH(io_lib:chars_length("アトム"), 3),
    ?ASSERT_MATCH(io_lib:chars_length([$f, [$o, [$o]]]), 3),
    ok.

test_printable_list() ->
    UnicodeRange = io:printable_range() =:= unicode,
    ?ASSERT_MATCH(io_lib:printable_list("foo"), true),
    ?ASSERT_MATCH(io_lib:printable_list([$f, [$o, [$o]]]), false),
    ?ASSERT_MATCH(io_lib:printable_list("アトム"), UnicodeRange),
    ?ASSERT_MATCH(io_lib:printable_list([1, 2, 3]), false),
    ?ASSERT_MATCH(io_lib:printable_list([1, 2, -3]), false),
    ?ASSERT_MATCH(io_lib:printable_list(foo), false),
    ok.

id(X) ->
    X.
