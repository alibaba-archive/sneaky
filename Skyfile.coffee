#######################################################
# Skyfile: setup your deploy tasks
########################################################
sneaky = require './'

sneaky 'sneaky:test', ->

  @description = 'Deploy to test environment'

  @user = 'username'

  @host = 'your.server'

  @path = '/your/destination'

  # Ignore the src directory
  # Filter pattern
  @filter = '''
  - src
  - node_modules
  '''

  # Execute before transporting files to server
  @before 'coffee -o lib -c src'

  # Execute after transporting files to server and link to the current directory
  # This script will be executed through ssh command
  @after 'npm install --ignore-scripts'
