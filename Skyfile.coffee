#######################################################
# Skyfile: setup your deploy tasks
########################################################
sneaky 'sneaky:test', ->

  # # Description show in `sneaky -T`
  # @description = 'Deploy to test environment'

  @user = 'username'

  @host = 'your.server'

  @path = '/your/destination'

  # # Ignore the src directory
  # # Filter pattern
  # @filter = '''
  # - src
  # - node_modules
  # '''

  # # Execute before transporting files to server
  # @before 'coffee -o lib -c src'

  # # Execute after transporting files to server and link to the current directory
  # # This script will be executed through ssh command
  # @after 'npm install --ignore-scripts'

  # # Normally, sneaky will create a new directory for each deployment
  # # If you do not need this feature, set `overwrite` to true
  # @overwrite = true

  # # In the `prepare` step, Sneaky archive the git repos and unarchive files to
  # # a temporary directory located in $HOME/.sneaky/$APP_NAME, and chdir to this directory.
  # # If you do not need this feature and want to execute this task in the current directory,
  # # set `nochdir` to true
  # @nochdir = true
