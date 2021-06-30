-module(data_gen).

-behaviour(gen_server).

-include("url.hrl").

-define(PROCESS_LIMIT, 1000).
-define(SAFETY_INTERVAL_MIN, 1005).
-define(SAFETY_INTERVAL_AVERAGE, 10005).
-define(SAFETY_INTERVAL_MAX, 30005).

-export([start_link/0, init/0, schools/0, users/0, attendances/0, attendance/0, state/0,
         stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
         code_change/3]).

-record(state,
        {schools = [] :: [integer()],
         users = [] :: [integer()],
         attendances = [] :: [integer()]}).

%%% Client API
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init() ->
    schools(),
    timer:sleep(3000),
    users().

schools() ->
    %% ?PROCESS_LIMIT schools will be created
    gen_server:cast(?MODULE, create_schools).

users() ->
    %% (10 * ?PROCESS_LIMIT users) will be created
    repeat(10, ?SAFETY_INTERVAL_MIN, {gen_server, cast, [?MODULE, create_users]}).

attendances() ->
    %% (1000 * 1000 * ?PROCESS_LIMIT) attendances will be created
    %% Please use with caution. This may cause crash on running shell
    repeat(1000, ?SAFETY_INTERVAL_MAX, {?MODULE, attendance, []}).

attendance() ->
    %% (100 * ?PROCESS_LIMIT) attendances will be created
    repeat(100, ?SAFETY_INTERVAL_AVERAGE, {gen_server, cast, [?MODULE, create_attendances]}).

state() ->
    gen_server:call(?MODULE, get_state).

stop() ->
    gen_server:call(?MODULE, terminate).

%%% Server functions
init([]) ->
    {ok, #state{}}. %% no treatment of info here!

handle_call(get_state, _From, State) ->
    {reply, State, State};
handle_call(get_schools, _From, State) ->
    {reply, State#state.schools, State};
handle_call(get_users, _From, State) ->
    {reply, State#state.users, State};
handle_call(terminate, _From, Cats) ->
    {stop, normal, ok, Cats}.

handle_cast(create_schools, State) ->
    multi_create(?PROCESS_LIMIT, fun create_school/0),
    {noreply, State};
handle_cast(create_users, State) ->
    multi_create(?PROCESS_LIMIT, fun create_user/0),
    {noreply, State};
handle_cast(create_attendances, State) ->
    multi_create(?PROCESS_LIMIT, fun create_attendance/0),
    {noreply, State};
handle_cast({school, School}, State) ->
    Schools = State#state.schools,
    {noreply, State#state{schools = [maps:get(<<"id">>, School) | Schools]}};
handle_cast({user, User}, State) ->
    Users = State#state.users,
    {noreply, State#state{users = [maps:get(<<"id">>, User) | Users]}};
handle_cast({attendance, Attendance}, State) ->
    Attendances = State#state.attendances,
    {noreply, State#state{attendances = [maps:get(<<"id">>, Attendance) | Attendances]}};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

terminate(normal, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    %% No change planned. The function is there for the behaviour,
    %% but will not be used. Only a version on the next
    {ok, State}.

%%% Private functions
repeat(0, _, _) ->
    ok;
repeat(Times, Interval, {M, F, A}) ->
    erlang:apply(M, F, A),
    timer:sleep(Interval),
    repeat(Times - 1, Interval, {M, F, A}).

multi_create(0, _Fun) ->
    ok;
multi_create(Count, Fun) ->
    spawn_monitor(Fun),
    multi_create(Count - 1, Fun).

create_school() ->
    School =
        #{<<"school">> => #{<<"name">> => list_to_bitstring(name:random_name() ++ " School")}},
    io:format("~p-~p:~p-~p~nSchool: ~p~n", [self(), ?MODULE, ?FUNCTION_NAME, ?LINE, School]),

    gen_server:cast(?MODULE, {school, maps:get(<<"data">>, http_post("schools", School))}).

create_user() ->
    Schools = gen_server:call(?MODULE, get_schools),
    SchoolId =
        lists:nth(
            rand:uniform(length(Schools)), Schools),

    User =
        #{<<"user">> =>
              #{<<"name">> => list_to_bitstring(name:random_name()),
                <<"school_id">> => integer_to_binary(SchoolId)}},
    io:format("~p-~p:~p-~p~nUser: ~p~n", [self(), ?MODULE, ?FUNCTION_NAME, ?LINE, User]),

    gen_server:cast(?MODULE, {user, maps:get(<<"data">>, http_post("users", User))}).

create_attendance() ->
    Schools = gen_server:call(?MODULE, get_schools),
    SchoolId =
        lists:nth(
            rand:uniform(length(Schools)), Schools),

    Users = gen_server:call(?MODULE, get_users),
    UserId =
        lists:nth(
            rand:uniform(length(Users)), Users),

    TemperatureRange = [34, 35, 36, 37, 38, 39, 40],
    Temperature =
        lists:nth(
            rand:uniform(length(TemperatureRange)), TemperatureRange),

    TypeSelection = [<<"checkin">>, <<"checkout">>],
    Type =
        lists:nth(
            rand:uniform(length(TypeSelection)), TypeSelection),

    Attendance =
        #{<<"attendance">> =>
              #{<<"user_id">> => integer_to_binary(UserId),
                <<"school_id">> => integer_to_binary(SchoolId),
                <<"temperature">> => integer_to_binary(Temperature),
                <<"type">> => Type}},
    io:format("~p-~p:~p-~p~nAttendance: ~p~n",
              [self(), ?MODULE, ?FUNCTION_NAME, ?LINE, Attendance]),

    gen_server:cast(?MODULE,
                    {attendance, maps:get(<<"data">>, http_post("attendances", Attendance))}).

http_post(Endpoint, Body) ->
    {ok, {{_, 201, _}, _, Data}} =
        httpc:request(post, {?URL ++ Endpoint, [], "application/json", jsx:encode(Body)}, [], []),
    jsx:decode(list_to_bitstring(Data)).
