#######################################################
# Skyfile: setup your deploy tasks
#
########################################################

fs = require 'fs'
path = require 'path'
pkg = require './package'
sneaky = require './src/sneaky'

filter = """
- .git/**
"""

sneaky 'sneaky', ->

  @filter = filter

  @path = '/tmp/sneaky'

  @pre 'rsync', -> @execCmd 'npm install'

  @post 'rsync', -> @execRemoteCmd 'npm ls'

  @pre 'link', ->

  @post 'link', ->

.env 'test', ->

  @user = 'jarvis'

  @host = '192.168.0.21'
