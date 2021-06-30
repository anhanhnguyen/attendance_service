data_gen
=====

An OTP application to populate fake data when server is running 
by sending HTTP requests

Build
-----

You need to stand where the rebar.config file is placed.

    $ rebar3 compile

Run
-----

You need to stand where the rebar.config file is placed.

The server URL default is http://localhost:4000/api/.

Please update the correct URL for your environment in

    src/url.hrl

before continuing. Note: Please keep the ending "/"

To start the application run:

    $ rebar3 shell

To create schools run:

    1> data_gen:schools().

To create users run:

    2> data_gen:users().

To create attendances run:

    3> data_gen:attendance().

It will take some times to complete all the requests. For safety reason, please be patient and wait for a few seconds before running the next execution.

To exit the shell press "Ctrl + C"