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
