fs = require 'fs'
path = require 'path'
{print} = require 'util'
{spawn, exec} = require 'child_process'

option '-w', '--watch', 'Recompile CoffeeScript source file when modified'

task 'build', 'Compile CoffeeScript source file', (options) ->

  opt = ['-b', '-c', '-o', 'lib', 'src']
  opt.unshift '-w' if options.watch

  coffee = spawn (path.resolve 'node_modules', '.bin', 'coffee'), opt
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
