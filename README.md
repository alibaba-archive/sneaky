Sneaky
=======

Teambition 部署及检测系统

[![build status](https://api.travis-ci.org/sailxjx/sneaky.png)](https://travis-ci.org/sailxjx/sneaky)

## Feature

* configuate with ini (~/.sneakyrc)
* archive with git
* transport with rsync
* encrypt with ssh
* local pre-hook (before rsync)
* remote post-hook (after rsync)

## Example

~/.sneakyrc file

```ini
[project: template]
source = test/ini
destinations = jarvis@192.168.0.1:/tmp/ini
excludes = node_modules, .git

[project: async]
source = test/async
destinations = /tmp/async
excludes = node_modules, .git
```

deploy all projects defined in configure file
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

put .sneakyrc in your repository

and enter your repository directory

typein `sneaky d`

or `sneaky d [project]`

will deploy with your local configure file

## Change Log

###v0.4.2
1. remove `servers`,`user`,`autoTag` configuration fields, rename `destination` to `destinations`
2. destinations can use the ssh path `user@server:/path/to/directory` or local path `/path/to/directory`
3. support deploy from remote git repositories, e.g. `source = https://github.com/sailxjx/sneaky`

###v0.3.0
1. support use `.sneakyrc` file in current pwd

## LICENSE
MIT
