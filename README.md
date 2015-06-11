Sneaky
=======

Deployment suite

[![NPM version][npm-image]][npm-url]
[![Build Status][travis-image]][travis-url]

## Feature

* configuate with js/coffee script (Skyfile.js|Skyfile.coffee)
* archive with git
* transport with rsync
* encrypt with ssh
* customized pre hooks and post hooks

## Example

```coffeescript
sneaky 'sneaky:test', ->

  @description = 'Deploy to test environment'

  # Version of your project
  @version = "v0.0.1"

  @user = 'username'

  @host = 'your.server'

  @path = '/your/destination'

  # Ignore the src directory
  # Filter pattern
  @filter = '''
  - src
  - node_modules
  '''

  # Execute before transporting files to server
  @before 'coffee -o lib -c src'

  # Execute after transporting files to server and link to the current directory
  # This script will be executed through ssh command
  @after 'npm install --ignore-scripts'
```

## Help
```

  Usage: sneaky <command> taskName


  Commands:

    deploy     deploy application to server
    history    display previous deploy histories
    rollback   rollback to the previous version
    d          alias of deploy
    h          alias of history
    r          alias of rollback

  Options:

    -h, --help     output usage information
    -v, --version  output the version number
    -T, --tasks    display the tasks

```

## ChangeLog

###v1.1.0
1. Add `forward` command

###v1.0.0
1. Configuate with js/coffee script
2. Deploy to sub directory with version and timestamp prefix

###v0.5.4
1. fix load js config file bug
2. expand destination option to user,host,port,destination properties

###v0.5.3
1. auto convert string typed options to array type
2. add option descriptions in readme

###v0.5.2
1. support for .json and .js configuration file
2. remove in denpendence

###v0.5.0
1. change configuration file's format from ini to json
2. add `includes`/`only` options to fit different situations, `includes` is an array mapping to rsync's `--include`, as the same as `excludes`, `only` is a alias of `includes` and `excludes`, `only: [lib/]` is the same as `includes: [lib/], excludes: *`. (ignore all files except lib directory)
3. add `nochdir` flag, set this flag to true will deploy the current directory and use all the local files (not only files in git repositories)
4. fix temp directory name's bug

###v0.4.2
1. remove `servers`,`user`,`autoTag` configuration fields, rename `destination` to `destinations`
2. destinations can use the ssh path `user@server:/path/to/directory` or local path `/path/to/directory`
3. support deploy from remote git repositories, e.g. `source = https://github.com/sailxjx/sneaky`

###v0.3.0
1. support use `.sneakyrc` file in current pwd

## TIPS

1. If you are unfamiliar with rsync's filter rules, read [this answer](http://unix.stackexchange.com/questions/2161/rsync-filter-copying-one-pattern-only#answer-2503)

## LICENSE
MIT

[npm-url]: https://npmjs.org/package/sneaky
[npm-image]: http://img.shields.io/npm/v/sneaky.svg

[travis-url]: https://travis-ci.org/teambition/sneaky
[travis-image]: http://img.shields.io/travis/teambition/sneaky.svg
