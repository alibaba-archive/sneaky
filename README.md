Sneaky
=======

Teambition 部署及检测系统

## feature

* configuate with ini (~/.sneakyrc)
* archive with git
* transport with rsync
* encrypt with ssh
* local pre-hook (before rsync)
* remote post-hook (after rsync)
* record daily action logs

## ~/.sneakyrc.example

```ini
user = jarvis
servers = 192.168.0.1

[project: template]
name = template
user = jarvis
servers = 192.168.0.1
source = test/ini
version = HEAD
destination = /tmp/ini
excludes = node_modules, .git

[project: async]
name = async
user = jarvis
servers = 192.168.0.1
source = test/async
version = HEAD
destination = /tmp/async
excludes = node_modules, .git
```

## options


## example

Deploy all projects defined in configure file
```
$ sneaky deploy
```

Deploy chosen projects
```
$ sneaky deploy async
```

Configure sneaky
```
$ sneaky config
```
