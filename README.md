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
  source: ~/coding/teambition/Project1  # source code repos
  version: HEAD  # git version or tag name or branch name
  destination: /tmp/sneaky  # deploy to destination
  servers: [summer]
  rsyncCmd:
  before: npm install; npm prune;
  autoTag: false
  excludes: [config.coffee]
  after: source /etc/profile; coffee /tmp/sneaky/Core/app.coffee &
- name: Project2
  source: ~/coding/teambition/Project2
  destination: /tmp/sneaky
  servers: [summer]
```