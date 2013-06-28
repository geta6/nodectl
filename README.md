# nodectl

A simple CLI tool for ensuring that a given node.js application runs conveniently and continuously.

## Features

* start-stop interface
* set envs
* clustering
* daemonize
* job script
* stdout and stderr logger
* watch script changes
* watch assets changes
* compile and minify assets

## Installation

```
npm i nodectl -g
```

## Usage

You can use nodectl to run javascript or coffee-script.

```
nodectl [action] [options] <script>
```
The option of a lower case requires a parameter, an upper case is Boolean.

```
Usage: nodectl [action] [options] <script>

Action:
    start   : start <script> as a node.js app
    stop    : stop the <script>
    restart : restart the <script>
    status  : check the <program> running or not

Options:
    -p, --port    : set process.env.PORT        3000
    -e, --env     : set process.env.NODE_ENV    development
    -c, --cluster : number of concurrents       CPU_THREAD_LENGTH
    -d, --delay   : delay time for refork       250
    -s, --setenv  : set custom env (k=v)        {}
    -x, --exec    : exec job script             null
    -l, --log     : stdout+stderr log file      null
    -1, --stdout  : stdout log file             null
    -2, --stderr  : stderr log file             null
    -a, --assets  : dir for assets              null
    -o, --output  : dir for assets output       null
    -M, --minify  : minify compiled assets      false
    -D, --daemon  : daemonize process           false
    -W, --watch   : restart app on code change  false
    -N, --nocolor : disable custom console      false
    -v, --version : show version and exit
    -h, --help    : show this message and exit
    --debug       : show debug information
```

## Synopsis

### show help

```
nodectl -h
nodectl --help
```

### start application

* default action, only `javascript` or `coffee-script` runnable.

```
nodectl start app.js
nodectl app.js
nodectl app.coffee
```

### stop application

* stop

```sh
nodectl stop app.js
```

## restart application

* restart application master process

```sh
nodectl restart app.js
```

## reload application

* restart only application child processes

```sh
nodectl reload app.js
```

## check application status

* application running or not

```sh
nodectl status app.js
```

## force-clear pid

* fix a problem application not running but `nodectl start` saids `already running`

```sh
nodectl force-clear app.js
```

# Synopsis - Option:

## `-p`, `--port`

* set listening port with `process.env.PORT`
* default `3000`

```sh
nodectl start app.js -p 3000
```

## `-e`, `--env`

* set application environment with `process.env.NODE_ENV`
* default `development`

```sh
nodectl start app.js -e production
```

## `-c`, `--cluster`

* concurrent application child process
* nodectl uses `cluster` native module forking with
* default cpu thread length

```sh
nodectl start app.js -c 1
```

## `-d`, `--daemon`

* daemonize application
* default `false`

```sh
nodectl start app.js -d
```

## `-w`, `--watch`

* watch code changes, auto reload programs
* default `false`

```sh
nodectl start app.js -w
```

## `-D`, `--delay`

* on reload, set interval time(ms) for children re-fork
* default `250`

```sh
nodectl restart app.js -D 1000
```

## `-n`, `--nocolor`

* stop colorize console
* nodectl defaults colorize `console.{log,info,warn,error}`
* default `false`

```sh
nodectl start app.js -n
```

## `-P`, `--pidpath`

* specified the directory pid file will be placed
* default `\`which nodectl\`/../tmp/${APPNAME}.pid`

```sh
nodectl start app.js -P tmp
```

## `-l`, `--logpath`

* specified the directory log files will be placed
* default `null` (no log)

```sh
nodectl start app.js -l tmp
```

## `-x`, `--execmaster`

* execute script with master process context
* script will be spawn in order to prevent a master process down
* specifiable `coffee-script`
* default `null`

```sh
nodectl start app.js -x script/cron.js
```

## `-a`, `--assets`

* see the following section

## `-o`, `--output`

* watch assets changes, auto compile
* assets directory specified with `-a`
* output directory specified with `-o`
* `-a` and `-o`, both are required to perform correctly
* css, [styl](http://learnboost.github.io/stylus/), js, [coffee](http://coffeescript.org), html, [jade](http://jade-lang.com) enable
* keeping directory structure and file name
* default `null`

```sh
nodectl start app.js -a assets -o public
```

#### compile from:

```
assets
 `- css
     `- style.styl
 `- js
     `- script.coffee
```

#### compile to:

```
public
 `- css
     `- style.css
 `- js
     `- script.js
```

## `-m`, `--minify`

* minify compiled assets

```sh
nodectl start app.js -a assets -o public -m
```

## `-V`, `--verbose`

* show verbose information

```sh
nodectl start app.js -V
```

## `-v`, `--version`

* show `nodectl` version info



## Parameter

### .nodectl.json, package.json

The key named __name__ and __version__ are required in either `package.json` or `.nodectl.json`.

`<program>` is omissible if the key named __main__ exists in either `package.json` or `.nodectl.json`.

`[options]` is omissible if the key __long-option-named__ exists in either `package.json` or `.nodectl.json`.

See [Recipes](#Recipes) section for how to write json file.

### .nodectl.run

Do not touch `${PROJECT_ROOT}/.nodectl.run` manually.

`${PROJECT_ROOT}/.nodectl.run` use for app state management.





<a name='Recipes'></a>
# Recipes:

* nodectl behavior can be changed by editing a `.nodectl.json` file.
* `.nodectl.json` should be placed in PROJECT_ROOT

## project on development

```json
{
  "main": "app.coffee",
  "env": "development",
  "cluster": "1",
  "watch": true,
  "assete": "assets",
  "output": "public",
  "minify": true,
  "daemon": false,
  "pidpath": "tmp",
  "logpath": "tmp",
  "verbose": true
}
```

## project on production

```json
{
  "main": "app.coffee",
  "env": "production",
  "assete": "assets",
  "output": "public",
  "minify": true,
  "daemon": true,
  "pidpath": "tmp",
  "logpath": "tmp"
}
```

## crontab action

* use `--execmaster`

#### script.coffee

```coffee
setInterval ->
  /* some action */
, 5000
```

#### .nodect.json

```json
{
  "main": "app.coffee",
  "env": "production",
  "assete": "assets",
  "output": "public",
  "minify": true,
  "daemon": true,
  "pidpath": "tmp",
  "logpath": "tmp",
  "execmaster": "script.coffee"
}
```

## MIT LICENSE
Copyright &copy; 2013 geta6 licensed under [MIT](http://opensource.org/licenses/MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
