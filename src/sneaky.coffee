Mentor = require './mentor'
Task = require './task'

_mentors = {}

module.exports = sneaky = (appName, appStatement) ->
  unless _mentors[appName]
    _mentors[appName] = new Mentor appName, appStatement
  _mentors[appName]

sneaky.Mentor = Mentor
sneaky.Task = Task

sneaky.registerStep = (stepName, step, options) -> Task.registerStep.apply this, arguments

# Load build-in steps
sneaky.registerStep 'prepare', require './steps/prepare'
sneaky.registerStep 'transport', require './steps/transport'
sneaky.registerStep 'switch', require './steps/switch'
