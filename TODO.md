* [ ] Deploy with setup file Skyfile/skyfile
* [ ] Each task return a stream
* [ ] Use glob pattern to filter the files
* [ ] Deploy by version
* [ ] Use the --exclude-from and --include-from options of rsync

* Prepare working directory of deployment
* Execute before scripts (on localhost by default)
* Deploy files to remote server
* Execute after scripts (on remote server by default)

rsync -az

core  --> /usr/local/teambition/core

core --> /usr/local/teambition/core/
  -> current -> 20141215
  -> 20141215/
  -> 20141225/

web -> status success: error
  histroy 1,2,3,

workstation -> compile

web -> start -> workstation -> git -> `compile` ->
rsync -> version/ -> ln -s current version/ ->
restart

rollback -> ln -s current -> restart

web

history -> automatic -> web interface -> wait 10s, 20s, 30s, status


```
$ sneaky --help

  sneaky deploy [appName:]env

  sneaky deploy talk:beta
```
