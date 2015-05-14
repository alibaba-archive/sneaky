Sneaky
=======

Teambition 部署及检测系统

[![build status](https://api.travis-ci.org/teambition/sneaky.png)](https://travis-ci.org/teambition/sneaky)

## Feature

* configuate with json (.sneakyrc.json.example)
* archive with git
* transport with rsync
* encrypt with ssh
* local pre-hook (before rsync)
* remote post-hook (after rsync)

## Example

~/.sneakyrc.json file

```json
{
  "sneaky": {
    "name": "sneaky",
    "version": "HEAD",
    "destinations": [
      "git@server:/tmp/sneaky1",
      "git@server:/tmp/sneaky2"
    ],
    "excludes": [
      ".git",
      "node_modules"
    ],
    "before": "npm i --production",
    "after": "cd /tmp/sneaky; ls"
  },
  "sneaky-remote": {
    "name": "sneaky-remote",
    "source": "http://github.com/sailxjx/sneaky",
    "destinations": [
      "www@server:/tmp/sneaky1"
    ],
    "before": "npm i --production",
    "after": "cd /tmp/sneaky2; ls"
  }
}
```

deploy all projects defined in configuration file
```
$ sneaky deploy
```

deploy chosen projects
```
$ sneaky deploy async
```

configure sneaky
```
$ sneaky config
```

## Use Local Configure File

put .sneakyrc.json in your repository

and enter your repository directory

typein `sneaky d`

or `sneaky d [project]`

will deploy with your local configuration file

## Options

* `name` (string) project name
* `version` (string) project version, sneaky will use the version the checkout the correct git branch
* `source` (string) source directory
* `destinations` (array) deploy to these destinations, the style of destinations is the same in `rsync`
* `excludes` (array) exclude paths
* `includes` (array) include these paths, these paths will not be affected by `excludes` options
* `only` (array) only include these paths, the others will be discarded
* `nochdir` (boolean) if this option is true, sneaky will skip the archive step and directly use the current directory as the source directory

## Change Log

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
