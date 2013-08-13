Sneaky
=======

teambition 部署及检测系统

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
  version: HEAD  # git version or tag name or branch name, is use autoTag, this option will not work
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