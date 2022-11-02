# Quake 1 Enhanced Custom Mod Server

Scripts and instructions for getting a custom mod server up and running for Quake (2021 re-release).

All of the scripts are written in bash and are tested on Ubuntu 20.04.

I haved also tested the server and all of the mods are working with Quake through Proton.

# Dependencies

- jq
- cmake (for building `qpakman`)
- python3 (for local servers)

## Using `apt`

``` bash
apt install jq cmake python3
```

# Getting it

``` bash
git clone --recursive --depth 1 https://github.com/RamblingMadMan/q1mods.git
```

# Running it

## Local server

> NOTE: Running a local server will mean you have a duplicate copy of every mod on your computer.

Simply run this command from the source directory:

``` bash
./run.sh
```

Then add this to your Quake launch options:

```
+ui_addonsBaseURL "http://0.0.0.0/"
```

## Web server

Follow a basic guide to installing nginx/apache/whatever and create a site pointing to `q1mods/q1mods`.

Then run the following in the root `q1mods` dir:

``` bash
./run.sh setup
```

Then add this to your Quake launch options:

``` bash
+ui_addonsBaseURL "http://my.domain/"
```

