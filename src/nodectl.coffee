# Dependencies

fs = require 'fs'
path = require 'path'
util = require 'util'
cluster = require 'cluster'
{spawn} = require 'child_process'

mkdirp = require 'mkdirp'
coffee = require 'coffee-script'
stylus = require 'stylus'
jade = require 'jade'
uglify = require 'uglify-js'
sqwish = require 'sqwish'
markup = require 'html-minifier'

process.env.__nodectl or= 'master'

# Variables

NC = {}
STDOUT = fs.createWriteStream '/dev/null'
STDERR = fs.createWriteStream '/dev/null'
ROOTCTL = path.join (path.dirname process.mainModule.filename), '..'
NODECTL = require path.join ROOTCTL, 'package.json'

# Environments

( ->
  NC.ROOTDIR = '/'
  for dir, i in process.cwd().split(path.sep)
    trace = ''; trace += "..#{path.sep}" for j in Array i
    if fs.existsSync path.resolve trace, 'package.json'
      NC.ROOTDIR = path.resolve trace

  NC.PKGINFO = {}
  NC.PKGINFO.PROJECT = try require path.join NC.ROOTDIR, 'package.json' catch e then {}
  NC.PKGINFO.RCNAMES = path.join NC.ROOTDIR, (NC.PKGINFO.PROJECT.nodectlrc || '.nodectl.json')
  NC.PKGINFO.NODECTL = try (-> JSON.parse fs.readFileSync NC.PKGINFO.RCNAMES, 'utf-8')() catch e then {}

  NC.DEFAULT = (key, val) ->
    if typeof NC.PKGINFO.NODECTL['switch_env'] isnt 'undefined'
      NODE_ENV = process.env.NODE_ENV || NC.PKGINFO.NODECTL['env'] || 'development'
      if typeof NC.PKGINFO.NODECTL['switch_env'][NODE_ENV] isnt 'undefined'
        for k, v of NC.PKGINFO.NODECTL['switch_env'][NODE_ENV]
          NC.PKGINFO.NODECTL[key] = v if k is key
    return NC.PKGINFO.NODECTL[key] || NC.PKGINFO.PROJECT[key] || val

  NC.SYMBOLS = 'start'

  NC.ACTIONS =
    start:   yes
    stop:    no
    restart: no
    status:  no
    debug:   no
    version: no
    help:    no

  NC.OPTIONS =
    port:    NC.DEFAULT 'port',    3000
    env:     NC.DEFAULT 'env',     'development'
    cluster: NC.DEFAULT 'cluster', (require 'os').cpus().length
    delay:   NC.DEFAULT 'delay',   250
    exec:    NC.DEFAULT 'exec',    ''
    setenv:  NC.DEFAULT 'setenv',  {}
    log:     NC.DEFAULT 'log',     ''
    stdout:  NC.DEFAULT 'stdout',  ''
    stderr:  NC.DEFAULT 'stderr',  ''
    assets:  NC.DEFAULT 'assets',  ''
    output:  NC.DEFAULT 'output',  ''
    minify:  NC.DEFAULT 'minify',  no
    daemon:  NC.DEFAULT 'daemon',  no
    watch:   NC.DEFAULT 'watch',   no
    nocolor: NC.DEFAULT 'nocolor', no

  NC.PROJECT =
    name:    NC.DEFAULT 'name',    no
    main:    NC.DEFAULT 'main',    no
    version: NC.DEFAULT 'version', no
    running: path.join NC.ROOTDIR, '.nodectl.run'

  NC.PROCESS =
    id: "#{NC.PROJECT.name}/#{NC.PROJECT.version}"
    pid: null
    wid: []
    xid: null

  NC.DELETES = ->
    NC.IMPORTS()
    try
      process.kill NC.PROCESS.pid, 'SIGINT'
      console.warn "#{NC.PROCESS.id} stopped."
    catch e
      console.error "ProcessError: #{e.message}"
    try
      process.kill NC.PROCESS.xid, 'SIGINT'
      console.warn "#{NC.PROCESS.id} exec process stopped."
    catch e
      console.warn "#{NC.PROCESS.id} exec process already stopped."
    finally
      fs.unlinkSync NC.PROJECT.running if fs.existsSync NC.PROJECT.running

  NC.EXPORTS = ->
    try
      if NC.ACTIONS.debug
        fs.writeFileSync NC.PROJECT.running, JSON.stringify NC, null, '  '
      else
        fs.writeFileSync NC.PROJECT.running, JSON.stringify NC
    catch e
      console.error e
    finally
      return NC

  NC.IMPORTS = ->
    try
      if fs.existsSync NC.PROJECT.running
        json = JSON.parse fs.readFileSync NC.PROJECT.running, 'utf-8'
        NC[k] = v for k, v of json
    catch e
      console.error e
    finally
      return NC

  NC.IMPORTS() if fs.existsSync NC.PROJECT.running
)()

# Argument Parser

( ->
  ARGS = [].concat process.argv
  ARGS.splice 0, 2

  try
    while arg = ARGS.shift()
      unless '-' is arg.substr 0, 1
        switch arg
          when 'start'
            NC.SYMBOLS = arg
            NC.ACTIONS.start   = yes
            NC.ACTIONS.stop    = no
            NC.ACTIONS.restart = no
            NC.ACTIONS.status  = no

          when 'stop'
            NC.SYMBOLS = arg
            NC.ACTIONS.start   = no
            NC.ACTIONS.stop    = yes
            NC.ACTIONS.restart = no
            NC.ACTIONS.status  = no

          when 'restart'
            NC.SYMBOLS = arg
            NC.ACTIONS.start   = no
            NC.ACTIONS.stop    = no
            NC.ACTIONS.restart = yes
            NC.ACTIONS.status  = no

          when 'status'
            NC.SYMBOLS = arg
            NC.ACTIONS.start   = no
            NC.ACTIONS.stop    = no
            NC.ACTIONS.restart = no
            NC.ACTIONS.status  = yes

          when 'version'
            NC.SYMBOLS = arg
            NC.ACTIONS.version = yes

          when 'help'
            NC.SYMBOLS = arg
            NC.ACTIONS.help    = yes

          else
            NC.PROJECT.main = arg
            unless fs.existsSync NC.PROJECT.main
              throw new Error "unrecognized action: #{arg}"

      else
        switch arg
          when '-p', '-port', '--port'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.port = parseInt next, 10

          when '-e', '-env', '--env'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.env = String next

          when '-c', '-cluster', '--cluster'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.cluster = parseInt next, 10

          when '-d', '-delay', '--delay'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.delay = parseInt next, 10

          when '-s', '-setenv', '--setenv'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            envs = (String next).split '='
            envs[1] = (parseFloat envs[1], 10) if /^[1-9][0-9\.]*$/.test envs[1]
            NC.OPTIONS.setenv[envs[0]] = envs[1]

          when '-x', '-exec', '--exec'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.exec = path.join NC.ROOTDIR, next

          when '-l', '-log', '--log'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.log = path.join NC.ROOTDIR, next

          when '-1', '-stdout', '--stdout'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.stdout = path.join NC.ROOTDIR, next

          when '-2', '-stderr', '--stderr'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.stderr = path.join NC.ROOTDIR, next

          when '-a', '-assets', '--assets'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.assets = path.join NC.ROOTDIR, next

          when '-o', '-output', '--output'
            if typeof (next = ARGS.shift()) is 'undefined' or '-' is next.substr 0, 1
              throw new Error "option '#{arg}' requires parameter"
            NC.OPTIONS.output = path.join NC.ROOTDIR, next

          when '-M', '-minify', '--minify'
            NC.OPTIONS.minify = yes

          when '-D', '-daemon', '--daemon'
            NC.OPTIONS.daemon = yes

          when '-W', '-watch', '--watch'
            NC.OPTIONS.watch = yes

          when '-N', '-nocolor', '--nocolor'
            NC.OPTIONS.nocolor = yes

          when '-v', '-version', '--version'
            NC.ACTIONS.version = yes

          when '-h', '-help', '--help'
            NC.ACTIONS.help = yes

          when '-debug', '--debug'
            NC.ACTIONS.debug = yes

          else
            throw new Error "unrecognized option: #{arg}"

    # Fix
    if NC.OPTIONS.exec and '/' isnt NC.OPTIONS.exec.substr 0, 1
      NC.OPTIONS.exec = path.join NC.ROOTDIR, NC.OPTIONS.exec

    for key in ['log', 'stdout', 'stderr', 'assets', 'output']
      if NC.OPTIONS[key] and '/' isnt NC.OPTIONS[key].substr 0, 1
        NC.OPTIONS[key] = path.join NC.ROOTDIR, NC.OPTIONS[key]
      if '/' is NC.OPTIONS[key].substr -1
        NC.OPTIONS[key] = NC.OPTIONS[key].substr 0, NC.OPTIONS[key].length - 1

    # Check
    if !(NC.OPTIONS.setenv instanceof Object) and NC.OPTIONS.setenv.toString() isnt '[object Object]'
      envs = NC.OPTIONS.setenv.split '='
      NC.OPTIONS.setenv = {}
      NC.OPTIONS.setenv[envs[0]] = envs[1]

    if isNaN NC.OPTIONS.port
      throw new Error "option '-p, port' parameter should number"

    if 1 > NC.OPTIONS.env.length
      throw new Error "option '-e, env' parameter should string"

    if isNaN NC.OPTIONS.cluster
      throw new Error "option '-c, cluster' parameter should number"

    if isNaN NC.OPTIONS.delay
      throw new Error "option '-d, delay' parameter should number"

    if NC.OPTIONS.exec
      if !fs.existsSync NC.OPTIONS.exec or !(fs.statSync NC.OPTIONS.exec).isFile()
        throw new Error "option '-x, exec' parameter should file"

    if NC.OPTIONS.log
      unless fs.existsSync path.dirname NC.OPTIONS.log
        mkdirp.sync path.dirname NC.OPTIONS.log
      unless fs.existsSync NC.OPTIONS.log
        fs.writeFileSync NC.OPTIONS.log, ''
      unless (fs.statSync NC.OPTIONS.log).isFile()
        throw new Error "option '-l, log' parameter should file"
      NC.OPTIONS.stdout = NC.OPTIONS.stderr = NC.OPTIONS.log

    if NC.OPTIONS.stdout
      unless fs.existsSync path.dirname NC.OPTIONS.stdout
        fs.mkdirSync path.dirname NC.OPTIONS.stdout
      unless fs.existsSync NC.OPTIONS.stdout
        fs.writeFileSync NC.OPTIONS.stdout, ''
      unless (fs.statSync NC.OPTIONS.stdout).isFile()
        throw new Error "option '-1, stdout' parameter should file"
      STDOUT = fs.createWriteStream NC.OPTIONS.stdout, flags: 'a'

    if NC.OPTIONS.stderr
      unless fs.existsSync path.dirname NC.OPTIONS.stderr
        fs.mkdirSync path.dirname NC.OPTIONS.stderr
      unless fs.existsSync NC.OPTIONS.stderr
        fs.writeFileSync NC.OPTIONS.stderr, ''
      unless (fs.statSync NC.OPTIONS.stderr).isFile()
        throw new Error "option '-2, stderr' parameter should file"
      STDERR = fs.createWriteStream NC.OPTIONS.stderr, flags: 'a'

    if NC.OPTIONS.assets
      if !fs.existsSync NC.OPTIONS.assets or !(fs.statSync NC.OPTIONS.assets).isDirectory()
        throw new Error "option '-a, assets' parameter should directory"
      if !NC.OPTIONS.output
        throw new Error "--assets requires --output"

    if NC.OPTIONS.output
      if !fs.existsSync NC.OPTIONS.output or !(fs.statSync NC.OPTIONS.output).isDirectory()
        throw new Error "option '-o, output' parameter should directory"
      if !NC.OPTIONS.assets
        throw new Error "--output requires --assets"

  catch e
    console.error "\x1b[31mArgumentError: #{e.message}\x1b[0m"
    process.exit 1

  finally
    process.env.PORT = NC.OPTIONS.port
    process.env.NODE_ENV = NC.OPTIONS.env
    process.env.NODECTL_NAME = NODECTL.name
    process.env.NODECTL_VERSION = NODECTL.version
    process.env.PROJECT_NAME = NC.PROJECT.name
    process.env.PROJECT_VERSION = NC.PROJECT.version

)()

# Detect Helper

( ->
  if NC.ACTIONS.version or NC.ACTIONS.help
    console.log "nodectl version: #{NODECTL.name}/#{NODECTL.version}"
    if NC.ACTIONS.help
      console.log """
        Usage: #{NODECTL.name} [action] [options] <script>

        Action:
          start   : start <script> as a node.js app
          stop    : stop the <script>
          restart : restart the <script>
          status  : check the <program> running or not

        Options:
          -p, --port    : set process.env.PORT        #{process.env.PORT}
          -e, --env     : set process.env.NODE_ENV    #{process.env.NODE_ENV}
          -c, --cluster : number of concurrents       #{NC.OPTIONS.cluster}
          -d, --delay   : delay time for refork       #{NC.OPTIONS.delay}
          -s, --setenv  : set custom env (k=v)        #{(util.inspect NC.OPTIONS.setenv).replace(/\n/g, '').replace(/\s\s*/g, ' ')}
          -x, --exec    : exec job script             #{NC.OPTIONS.exec}
          -l, --log     : stdout+stderr log file      #{NC.OPTIONS.log}
          -1, --stdout  : stdout log file             #{NC.OPTIONS.stdout}
          -2, --stderr  : stderr log file             #{NC.OPTIONS.stderr}
          -a, --assets  : dir for assets              #{NC.OPTIONS.assets}
          -o, --output  : dir for assets output       #{NC.OPTIONS.output}
          -M, --minify  : minify compiled assets      #{NC.OPTIONS.minify}
          -D, --daemon  : daemonize process           #{NC.OPTIONS.daemon}
          -W, --watch   : restart app on code change  #{NC.OPTIONS.watch}
          -N, --nocolor : disable custom console      #{NC.OPTIONS.nocolor}
          -v, --version : show version and exit
          -h, --help    : show this message and exit
          --debug       : show debug information

        """
    process.exit 0
)()

# Check Project Info

( ->
  try
    unless NC.PROJECT.name
      throw new Error "application `name` unknown"
    unless NC.PROJECT.version
      throw new Error "application `version` unknown"
    unless NC.PROJECT.main
      throw new Error "application `main` script unknown"

  catch e
    console.error "\x1b[31mProjectError: #{e.message}\x1b[0m"
    console.error "\x1b[31mInformation must be described by package.json or #{path.basename NC.PKGINFO.RCNAMES}\x1b[0m"
    process.exit 1
)()

# Env Setter

( ->
  if NC.OPTIONS.setenv
    for _envkey, _envval of NC.OPTIONS.setenv
      process.env[_envkey] = _envval
)()

# Custom Console

( ->
  console.debug = ->
    if NC.ACTIONS.debug
      msg = '\x1b[37m'
      for arg, i in arguments
        msg+= if typeof arg is 'string' then arg else util.inspect arg
        msg+= ' ' if arguments.length > i + 1
      util.print "#{msg}\x1b[0m\n"

  if !NC.OPTIONS.nocolor
    colorized = {}
    for f in ['log', 'info', 'warn', 'error']
      do (f) ->
        colorized[f] = console[f]
        console[f] = ->
          msg= switch f
            when 'info'  then '\x1b[34m'
            when 'warn'  then '\x1b[33m'
            when 'error' then '\x1b[31m'
            else              '\x1b[0m'
          arguments[0] = "#{msg}#{arguments[0]}"
          colorized[f].apply @, arguments
)()

# Logger

( ->
  _stdout = process.stdout.write
  _stderr = process.stdout.write
  trim = (str) -> str.replace(/^[ \n\r\t]+|[ \n\r\t]+$/g, '')
  process.stdin.resume()

  process.stdout.write = ->
    STDOUT.write arguments[0].replace /\x1b.*?m/g, ''
    msg = switch yes
      when process.env.__nodectl is 'master' then '\x1b[32m'
      when /worker/.test process.env.__nodectl then '\x1b[33m'
      when process.env.__nodectl is 'exec' then '\x1b[34m'
      else '\x1b[35m'
    now = new Date()
    now = "#{('00'+now.getHours()).slice(-2)}:#{('00'+now.getMinutes()).slice(-2)}:#{('00'+now.getSeconds()).slice(-2)}"
    msg+= head = now + ' ' + process.env.__nodectl
    msg+= ' ' for i in Array(20 - head.length)
    arguments[0] = "#{msg}|\x1b[0m #{arguments[0]}"
    _stdout.apply @, arguments
  process.stderr.write = ->
    STDERR.write arguments[0].replace /\x1b.*?m/g, ''
    msg = switch yes
      when process.env.__nodectl is 'master' then '\x1b[32m'
      when /worker/.test process.env.__nodectl then '\x1b[33m'
      when process.env.__nodectl is 'exec' then '\x1b[34m'
      else '\x1b[35m'
    now = new Date()
    now = "#{('00'+now.getHours()).slice(-2)}:#{('00'+now.getMinutes()).slice(-2)}:#{('00'+now.getSeconds()).slice(-2)}"
    msg+= head = now + ' ' + process.env.__nodectl
    msg+= ' ' for i in Array(20 - head.length)
    arguments[0] = "#{msg}|\x1b[0m #{arguments[0]}"
    _stderr.apply @, arguments
)()

# Events Emitter

( ->

  process.stdout.pipe STDOUT
  process.stderr.pipe STDERR

  if cluster.isMaster

    process.on 'SIGINT', ->
      console.debug 'Master trap SIGINT'
      NC.DELETES()
      process.exit 1

    process.on 'nodectl:restart', ->
      console.debug "Restart all workers (delay: #{NC.OPTIONS.delay} ms)"
      console.info "#{NC.PROCESS.id} restart."
      for wid, i in NC.PROCESS.wid
        do (wid, i) ->
          console.debug "Send SIGINT to ##{wid}"
          setTimeout ->
            try
              process.kill wid, 'SIGINT'
            catch e
              console.error "ProcessError: #{e.message}"
          , NC.OPTIONS.delay * i

    process.on 'nodectl:rebuild', (src, dst) ->
      try
        console.debug "Build assets < #{src}"
        console.debug "Build assets > #{dst}"
        startTime = new Date
        unless fs.exists path.dirname dst
          mkdirp.sync path.dirname dst
        code = fs.readFileSync src, 'utf-8'
        code = switch path.extname src
          when '.coffee'
            coffee.compile code
          when '.styl'
            stylus(code).set('paths', [(path.join NC.ROOTDIR, 'node_modules'), (path.dirname src)]).define('url', stylus.url()).render()
          when '.jade'
            jade.compile(code)()
          else code
        if NC.OPTIONS.minify
          len = code.length
          switch path.extname dst
            when '.js'
              tmp = path.join '/tmp', new Date().toString()
              fs.writeFileSync tmp, code
              {code} = uglify.minify tmp
              fs.unlinkSync tmp
            when '.css'
              code = sqwish.minify code
            when '.html'
              code = markup.minify code
          console.debug "Minified #{parseInt(code.length / len * 1000) / 10} %"
        console.debug "Elapsed time #{new Date - startTime} ms"
        fs.writeFileSync dst, code, 'utf-8'
        console.log "Build assets (#{path.basename src} > #{path.basename dst})"
        return yes

      catch e
        console.error "Build assets failure. (#{src})"
        if /\.coffee$/.test src
          lines = []
          for line, i in (fs.readFileSync src, 'utf-8').split '\n'
            if i+1 > e.location.first_line - 5
              len or= (String i+1).length + 2
              if e.location.first_line <= i + 1 <= e.location.last_line
                msg = ' >'
                msg += ' ' for f in Array(len - (String i+1).length)
              else
                msg = '  '
                msg += ' ' for f in Array(len - (String i+1).length)
              lines.push "#{msg}#{i+1}| #{line}"
            break if i + 1 >= e.location.last_line + 3
          console.error """
            coffee:#{e.location.first_line}:#{e.location.first_column} #{e.message}
            #{lines.join('\n')}
            """
        else
          console.error e.message
        return no

    if (path.basename NC.PKGINFO.RCNAMES) isnt '.nodectl.json'
      console.debug "Using custom rc file name (#{path.basename NC.PKGINFO.RCNAMES})"

    if typeof NC.PKGINFO.NODECTL['switch_env'] isnt 'undefined'
      if typeof NC.PKGINFO.NODECTL['switch_env'][process.env.NODE_ENV] isnt 'undefined'
        console.debug "Using env switcher (#{process.env.NODE_ENV})"
)()

# Process Status

( ->
  if NC.ACTIONS.status
    if fs.existsSync NC.PROJECT.running
      util.print "#{NC.PROJECT.name} running.\n"
    else
      util.print "#{NC.PROJECT.name} not running.\n"
    process.exit 0
)()

# Process Stop

( ->
  if NC.ACTIONS.stop
    try
      if fs.existsSync NC.PROJECT.running
        process.kill NC.PROCESS.pid, 'SIGINT'
      else
        console.warn "#{NC.PROCESS.id} already stopped."
    catch e
      console.error "#{e.message}"
    finally
      if fs.existsSync NC.PROJECT.running
        fs.unlinkSync NC.PROJECT.running
      process.exit 0
)()

# Process Restart

( ->
  if NC.ACTIONS.restart
    process.emit 'nodectl:restart'
)()

# Process Start

( ->
  if NC.ACTIONS.start
    if cluster.isMaster
      if fs.existsSync NC.PROJECT.running
        console.warn "#{NC.PROCESS.id} already runninng"
        process.exit 1
      console.debug 'act', k, ':', v for k, v of NC.ACTIONS
      console.debug 'opt', k, ':', v for k, v of NC.OPTIONS
      console.info "#{NC.PROCESS.id} starting."

      NC.PROCESS.pid = process.pid

      cluster.on 'online', (worker) ->
        console.log "Worker online ##{worker.process.pid}"

      cluster.on 'listening', (worker) ->
        console.info "Worker listening ##{worker.process.pid}"

      cluster.on 'exit', (worker) ->
        console.warn "Worker exit ##{worker.process.pid} (#{if worker.suicide then 'suicide' else 'no suicide'})"
        for wid, i in NC.PROCESS.wid
          if wid is worker.process.pid
            NC.PROCESS.wid.splice i, 1
            _worker = cluster.fork({__nodectl: worker.type})
            _worker.type = worker.type
            NC.PROCESS.wid.push _worker.process.pid
        NC.EXPORTS()

      if NC.OPTIONS.daemon
        unless process.env.__daemon
          console.log "Master daemonize"
          args = [].concat process.argv
          args.shift()
          args.shift()
          process.env.__daemon = yes
          child = spawn process.mainModule.filename, args,
            stdio: 'ignore'
            env: process.env
            cwd: process.cwd()
            detached: yes
          child.unref()
          process.exit 0
        NC.PROCESS.pid = process.pid

      NC.EXPORTS()

      if NC.OPTIONS.exec
        bin = switch path.extname NC.OPTIONS.exec
          when '.coffee' then path.join ROOTCTL, 'node_modules', 'coffee-script', 'bin', 'coffee'
          else                'node'
        try
          child = spawn bin, [NC.OPTIONS.exec],
            # stdio: 'inherit'
            env: process.env
            cwd: process.cwd()
            detached: yes
          child.stdout.on 'data', (data) ->
            __pre = process.env.__nodectl
            process.env.__nodectl = 'exec'
            util.print "#{data}"
            process.env.__nodectl  = __pre
          child.stderr.on 'data', (data) ->
            __pre = process.env.__nodectl
            process.env.__nodectl = 'exec'
            util.print "\x1b[31m#{data}"
            process.env.__nodectl  = __pre
          console.log "Master spawn ##{child.pid}"
          NC.PROCESS.xid = child.pid
        catch e
          console.error e
        finally
          NC.EXPORTS()

      seekdir = (dir) ->
        res = []; return res if (fs.statSync dir).isFile()
        for rel in fs.readdirSync dir
          abs = path.join dir, rel
          if rel isnt 'node_modules' and (rel.substr 0, 1) isnt '.'
            if (fs.statSync abs).isDirectory()
              res.push abs
              res = res.concat arguments.callee abs
        return res

      if NC.OPTIONS.watch
        for dir in [NC.ROOTDIR].concat seekdir NC.ROOTDIR
          timeout = null
          do (dir) ->
            return null if NC.OPTIONS.assets and (new RegExp NC.OPTIONS.assets).test dir
            return null if NC.OPTIONS.output and (new RegExp NC.OPTIONS.output).test dir
            console.log 'Master watch', '<', dir
            fs.watch dir, (act, rel) =>
              console.debug "fs watch triggerd (#{act}, #{rel})"
              if /\.(js|coffee|json)$/.test rel
                clearTimeout timeout
                timeout = setTimeout ->
                  abs = path.join dir, rel
                  if act is 'change' or fs.existsSync abs
                    console.log "Code changed (#{rel})"
                    process.emit 'nodectl:restart', act, abs, null
                , NC.OPTIONS.delay

      if NC.OPTIONS.assets and NC.OPTIONS.output
        for dir in [NC.OPTIONS.assets].concat seekdir NC.OPTIONS.assets
          timeout = null
          do (dir) ->
            out = dir.replace NC.OPTIONS.assets, NC.OPTIONS.output
            console.log 'Master watch assets', '<', dir
            compile = (act, rel) ->
              if /\.(js|coffee|css|styl|html|jade)$/.test rel
                abs = path.join dir, rel
                dst = switch path.extname rel
                  when '.coffee' then path.join out, rel.replace /\.coffee$/, '.js'
                  when '.styl'   then path.join out, rel.replace /\.styl$/,   '.css'
                  when '.jade'   then path.join out, rel.replace /\.jade$/,   '.html'
                  else                path.join out, rel
                if fs.existsSync abs
                  process.emit 'nodectl:rebuild', abs, dst
                else
                  fs.unlinkSync dst
            fs.watch dir, compile
            setTimeout ->
              compile null, rel for rel in fs.readdirSync dir
            , 500

      ( ->
        for i in [0...NC.OPTIONS.cluster]
          worker = cluster.fork({__nodectl: "worker.#{i+1}"})
          worker.type = "worker.#{i+1}"
          NC.PROCESS.wid.push worker.process.pid
        NC.EXPORTS()
      )()

    else
      process.on 'SIGINT', ->
        console.debug 'Worker trap SIGINT'
        process.suicide = yes
        process.exit 0
      require path.join NC.ROOTDIR, NC.PROJECT.main
)()
