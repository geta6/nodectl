# nodectl

supervisor sctipt for nodejs.

## 日本語による解説

### 一番の目玉
* アプリケーションに関係ないレベルでの作業が不要
* httpを一本立てるだけでよい
* デーモン化やクラスタリングで頭を悩ませなくてよい

### 有している作戦能力
* CPUのスレッド数に応じて自動的にfork、応答性能を向上
* コードに変更を施したらメインプロセスを維持したまま子プロセスのみを自動的にリロード、変更を浸透
* 浸透のディレイタイムを設定可能
* 単独でのデーモン化能力
* ログのファイル出力機能
* `console`出力の自動色分け出力機能
* `start-stop-daemon`のような命令系統
* 最近傍の`package.json`を探索、`name`, `version`, `main`と言った情報を取得
* 最近傍の`package.json`からキー名を探索、ロングオプションと同値のキーをデフォルト値としてロード
* `package.json`と同一ディレクトリにある`.nodectl.json`の値を読み、設定値をロード
* オプションで渡した値が最優先され、次に`.nodectl.json`、次に`package.json`、次にデフォルト値、という順番で評価
* `PORT`や`NODE_ENV`などの環境変数値を`undefined`のまま実行しない
* 現在の引数でどのような動作が期待されるかテストするモード
* crontabのように動作するスクリプトなど、単一のインスタンスのみで実行されることを期待するスクリプトの指定

## Features

* watch code changes
* cluster
* daemonize
* colorize console
* env setter

## Install

`npm install -g nodectl`

## How to use

```
cd $HOME
express test
cd test
npm install
nodectl start app.js
```

### watch
```
nodectl -w app.js
```
### daemonise
```
nodectl -d app.js
```
### both
```
nodectl -d -w app.js
```
### clock works (ex. crontab like action)
```
nodectl -x clock.js
```
### stop daemon
```
cd ~/test
nodectl stop
```
### daemonize and..
```
cd ~/test
nodectl start -d app.js
nodectl reload
nodectl restart
nodectl status
  application running.
```

## Usage

`nodectl [action] [options] <program>`

### Action

#### start
execute program (default action)
#### stop
stop daemonized program
#### restart
restart program with daemonize mode
#### force-clear
force clear pid
#### reload
release edited javascript (restart only child processes)
#### status
check program running or not

### Options:
#### -p, --port [NUMBER]
default 3000, pass listening port (`process.env.PORT`)
#### -e, --env [STRING]
default development, pass environment (`process.env.NODE_ENV`)
#### -c, --cluster [NUMBER]
default number of cpu threads, concurrent process with cluster module
#### -P, --pidpath [STRING]
directory for pid files
#### -l, --logpath [STRING]
directory for log files
#### -D, --delay [NUMBER]
default 250, delay time for re-fork child workers
#### -x, --execmaster [STRING]
execute script on master process (single instance)
#### -n, --nocolor
stop colorize console
#### -d, --daemon
daemonize process
#### -w, --watch
watch code changes, auto reload programs
#### -t, --test
check options (not execute)
#### -v, --version
show version and exit
#### -h, --help
show help message and exit

## Defaults
  * Default option values from
    * `${PROJECT_ROOT}/.nodectl.json`
    * `${PROJECT_ROOT}/package.json`
  * Main script key is `main`

## package.json search
  nodectl automatically search nearest `package.json` form parent directories.

  * application name from `package.json: name`
  * application version from `package.json: version`
  * application main script from `package.json: main` or `.nodectl.json: main`

## Tips

### automatically setting

```sh
$ cd $PROJECT_ROOT
$ cat .nodectl.json
{
  "main": "app.coffee",
  "env": "development",
  "execmaster": "config/clock.coffee",
  "cluster": "1",
  "watch": true,
  "daemonize": false
}
```

### prevent master process down from execmaster

```coffee
$ cd $PROJECT_ROOT
$ cat config/clock.coffee

fs= require 'fs'
path = require 'path'
async = require 'async'
{spawn} = require 'child_process'

if 'nodectl' is path.basename process.argv[1]

  # Manager - spawn myself

  setInterval ->
    args = [path.join process.cwd(), 'config/clock.coffee']
    spawn './node_modules/coffee-script/bin/coffee', args,
      stdio: 'inherit'
      env: process.env
      cwd: process.cwd()
      detached: yes
  , 1000

else

  # Worker - spawned process section

  app = require './app.coffee'
  {File} = app.get 'models'

  root_dir = '/media'

  fs.readdir root_dir, (err, list) ->
    async.map list, (name, next) ->
      filepath = path.join root_dir, name
      File.find path: filepath, {}, {}, (err, file) ->
        stat = fs.statSync filepath
        unless file
          file = new File()
        if (String file.mtime) isnt (String stat.mtime)
           file.path = filepath
          file.stat = stat
        file.save next
    , (err) ->
      if err
        console.error err 
        process.exit 1
      process.exit 0
```

## release

```sh
$ cd $PROJECT_ROOT
$ cat .nodectl.json
{
  "main": "app.coffee",
  "env": "production",
  "execmaster": "config/clock.coffee",
  "daemonize": true
}
```
