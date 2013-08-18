exportsAll = (list, postfix) ->
  modules = {}
  list.forEach (name) ->
    className = "#{name[0].toUpperCase()}#{name[1..]}#{postfix}"
    modules[className] = require("./#{name}")
    modules["#{className[0].toLowerCase()}#{className[1..]}"] = new modules[className]
  return modules

module.exports = exportsAll(['user', 'base'], 'Controller')