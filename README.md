Sneaky
=======

Teambition 部署及检测系统

## feature

* configuate with yaml (~/.sneakyrc)
* archive with git
* transport with rsync
* encrypt with ssh
* local pre-hook (before rsync)
* remote post-hook (after rsync)
* record daily action logs

## ~/.sneakyrc.example

```
user: root
servers: [summer]

projects:
- name: Project1
  source: ~/path/to/project1  # source code repos
  version: HEAD  # git version or tag name or branch name, if use autoTag, this option will not work
  destination: /tmp/sneaky  # deploy to destination
  servers: [summer|root|22]  # deploy servers [server|user|port]
  # rsyncCmd: qrysnc  # self defined rsync function
  before: npm install; npm prune;  # hook before rsync
  autoTag: true  # auto generate tag for local repos
  # tagPrefix: release  # default tag prefix is release
  excludes: [config.coffee]  # excluded files
  # after: supervisord  # hook after rsync
- name: Project2
  source: ~/path/to/project2
  destination: /tmp/sneaky
  # before: bash install.sh
  servers: [summer]
```

## options

* `-c, --config`       define the config file path, default is ~/.sneakyrc
* `-f, --force`
  Sneaky has a daily lock on successfully deployed projects, that means same project will not be deployed twice. But if you use `-f` option, then you can redeploy the project.
* `-p, --projects`     deploy the chosen project, multi projects splited by ","

Sneaky

## example

Deploy all projects defined in configure file
```
$ cake deploy
```

Deploy chosen projects
```
$ cake -p Web deploy
```