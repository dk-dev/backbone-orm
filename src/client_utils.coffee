isArray = require('../node/util').isArray

module.exports = class ClientUtils
  @loadDependencies: (info) ->
    return unless window?.require.register

    info = [info] unless isArray(info)
    for item in info
      do (item) ->
        try return if dep = require(item.path) catch err then
        unless dep = @[item.symbol]
          return if item.optional
          throw new Error("Missing dependency: #{item.path}")
        window.require.register item.path, (exports, require, module) -> module.exports = dep
    return
