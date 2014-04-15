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
{
  "sneaky": {
    "name": "sneaky",
    "version": "HEAD",
    "destinations": [
      "/tmp/sneaky1",
      "/tmp/sneaky2"
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
      "/tmp/sneaky2"
    ],
    "before": "npm i --production",
    "after": "cd /tmp/sneaky2; ls"
  }
}
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

###v0.5.0
1. change configure file's format from ini to json
2. add `includes`/`only` options to fit different situations, `includes` is an array mapping to rsync's `--include`, as the same as `excludes`, `only` is a alias of `includes` and `excludes`, `only: [lib/]` is the same as `includes: [lib/], excludes: *`. (ignore all files except lib directory)
3. add `nochdir` flag, set this flag to true will deploy the current directory and use all the local files (not only files in git repositories)
4. fix temp directory name's bug

###v0.4.2
1. remove `servers`,`user`,`autoTag` configuration fields, rename `destination` to `destinations`
2. destinations can use the ssh path `user@server:/path/to/directory` or local path `/path/to/directory`
3. support deploy from remote git repositories, e.g. `source = https://github.com/sailxjx/sneaky`

###v0.3.0
1. support use `.sneakyrc` file in current pwd

## LICENSE
MIT
