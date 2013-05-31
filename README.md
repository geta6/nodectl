# nodectl

supervisor sctipt for nodejs.

## 日本語による解説

* CPUのスレッド数に応じて自動的にプロセスをフォーク、応答性能を向上させます
* コードを変更したら子プロセスを自動的にリロード、変更を浸透させます
* 単独でのデーモン化能力を有しています
* メインプロセスを維持したまま、子プロセスのみをリロードする能力を有しています
* `console`にフックして自動的に色分けして出力する機能を有しています
* `start-stop-daemon`のような命令系統を持ちます
* 親ディレクトリから最近傍の`package.json`を探索、`name`, `version`, `main`と言った情報を取得します
* `PORT`や`NODE_ENV`などの環境変数値を`undefined`のまま実行しません
* だいたいの操作は自動・手動、両方で実行可能です
* 手動で設定する場合は`action`を用い、自動で設定する場合は`option`を用います

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
pid file location
#### -D, --delay [NUMBER]
default 250, delay time on re-fork children
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
  * [options] default from `${HOME}/.noserc.json`
  * <program> default from `package.json: main`

## package.json search
  nodectl automatically search nearest `package.json` form parent directories.

  * application name from `package.json: name`
  * application version from `package.json: version`
  * application main script from `package.json: main`
