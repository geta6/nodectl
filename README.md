# nodectl

A simple CLI tool for ensuring that a given node.js application runs conveniently and continuously.

## Updates

`v0.3.x`: change options

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

## Requirement

nodectl requires `package.json` includes the key named __name__ and __version__.

`<script>` is omissible if the key named __main__ exists in either `package.json` or `.nodectl.json`.

### .nodectl.json

When `.nodectl.json` is placed in `PROJECT_ROOT`, load the value for key named __long-option-name__ and set to a `[options]` default value.

See [Recipes](#Recipes) section for how to write json file.

### .nodectl.run

Do not touch `${PROJECT_ROOT}/.nodectl.run` manually.

`${PROJECT_ROOT}/.nodectl.run` use for app state management.

## Synopsis - actions

current working directory should be under the project root.

### show help and exit

```
nodectl -h
nodectl --help
```

### show version and exit

```
nodectl -v
nodectl --version
```

### start application

default action, only `javascript` or `coffee-script` runnable.

```
nodectl start app.js
nodectl app.js
nodectl app.coffee
```

### stop application

```
nodectl stop
```

### restart application

restart application workers

```
nodectl restart app.js
```

### check application status

```
nodectl status app.js
```

## Synopsis - options

### -p, --port

set listening port with `process.env.PORT`

```
nodectl app.js -p 3000
```

### -e, --env

set application environment with `process.env.NODE_ENV`

```
nodectl app.js -e production
```

### -c, --cluster

number of process concurrents

```
nodectl app.js -c 1
```

### -d, --delay

interval time on forking worker

```
nodectl app.js -d 250
```

### -s, --setenv

set custom envs

```
nodectl app.js -s ROOTDIR=/opt -s COEFFICIENT=3.6
```

### -x, --exec

execute job script on launch

```
nodectl app.js -x clock.js
```

### -l, --log

logs stdout and stderr to file

```
nodectl app.js -l app.log
```

### -1, --stdout

overwrite stdout log file

```
nodectl app.js -1 app.out
```

`app.log` logs stderr only:
```
nodectl app.js -l app.log -1 app.out
```

### -2, --stderr

overwrite stderr log file

```
nodectl app.js -2 app.err
```

### -a, --assets

set asset directory __Note:__ required -o option

compiles automatically on change assets

compilable: js, css, html, coffee, stylus, jade

```
nodectl app.js -a assets -o public
```

### -o, --output

set output directory __Note:__ required -a option

compiles automatically on change assets

```
nodectl app.js -a assets -o public
```

### -M, --minify

minify code on compiles assets

```
nodectl app.js -M -a assets -o public
```

### -D, --daemon

daemonize app

```
nodectl app.js -D
```

### -W, --watch

watch code changes, auto reload programs

```
nodectl app.js -W
```

### -N, --nocolor

stop colorize console

```
nodectl app.js -N
```

### --debug

show debug info

```
nodectl app.js --debug
```

<a name='Recipes'></a>
## Recipes

### Project on Development

#### .nodectl.json
```
{
  "main": "app.coffee",
  "env": "development",
  "cluster": 1,
  "watch": true,
  "assets": "assets",
  "output": "public",
  "minify": true
}
```
#### equals to
```
nodectl start app.coffee -e development -c 1 -W -a assets -o public -M
```

#### start app

```
cd $PROJECT_ROOT
nodectl
```


### Project on Production

#### .nodectl.json
```
{
  "main": "app.coffee",
  "env": "production",
  "assets": "assets",
  "output": "public",
  "minify": true,
  "daemon": true
}
```
#### equals to
```
nodectl start app.coffee -e production -a assets -o output -M -D
```

### Set Environment

#### .nodectl.json
```
{
  "main": "app.coffee",
  "assets": "assets",
  "output": "public",
  "minify": true,
  "setenv": {
    "ROOTDIR": "/opt",
    "COEFFICIENT": 3.6
  }
}
```

#### equals to
```
nodectl start app.coffee -a assets -o output -M -s ROOTDIR=/opt -s COEFFICIENT=3.6
```

## crontab action

* use `--exec`

#### script.coffee

```
setInterval ->
  /* some action */
, 5000
```

#### .nodectl.json

```
{
  "main": "app.coffee",
  "env": "production",
  "assete": "assets",
  "output": "public",
  "minify": true,
  "daemon": true,
  "exec": "script.coffee"
}
```

## MIT LICENSE
Copyright &copy; 2013 geta6 licensed under [MIT](http://opensource.org/licenses/MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
