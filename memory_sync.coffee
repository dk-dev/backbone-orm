util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

MemoryCursor = require './lib/memory_cursor'
Schema = require './lib/schema'
Utils = require './lib/utils'
QueryCache = require './lib/query_cache'

DESTROY_BATCH_LIMIT = 1000
STORES = {}

# Backbone Sync for in-memory models.
#
# @example How to configure using a model name
#   class Thing extends Backbone.Model
#     @model_name: 'Thing'
#     sync: require('backbone-orm/memory_sync')(Thing)
#
# @example How to configure using a url
#   class Thing extends Backbone.Model
#     url: '/things'
#     sync: require('backbone-orm/memory_sync')(Thing)
#
class MemorySync
  # @private
  constructor: (@model_type) ->
    @model_type.model_name = Utils.findOrGenerateModelName(@model_type)
    @schema = new Schema(@model_type)
    @store = @model_type.store = STORES[@model_type.model_name] or= {}

  # @private
  initialize: ->
    return if @is_initialized; @is_initialized = true
    @schema.initialize()

  # @private
  read: (model, options) ->
    options.success(if model.models then (Utils.deepClone(model_json) for id, model_json of @store) else Utils.deepClone(@store[model.id]))

  # @private
  create: (model, options) ->
    QueryCache.reset(@model_type)
    model.set(id: Utils.guid())
    model_json = @store[model.id] = model.toJSON()
    options.success(Utils.deepClone(model_json))

  # @private
  update: (model, options) ->
    QueryCache.reset(@model_type)
    @store[model.id] = model_json = model.toJSON()
    options.success(Utils.deepClone(model_json))

  # @private
  delete: (model, options) ->
    QueryCache.reset(@model_type)
    return options.error(new Error('Model not found')) unless @store[model.id]
    delete @store[model.id]
    options.success()

  ###################################
  # Backbone ORM - Class Extensions
  ###################################

  # @private
  resetSchema: (options, callback) ->
    QueryCache.reset(@model_type)
    @destroy({}, callback)

  # @private
  cursor: (query={}) -> return new MemoryCursor(query, _.pick(@, ['model_type', 'store']))

  # @private
  destroy: (query, callback) ->
    QueryCache.reset(@model_type)
    @model_type.batch query, {$limit: DESTROY_BATCH_LIMIT, method: 'toJSON'}, callback, (model_json, callback) =>
      Utils.patchRemoveByJSON @model_type, model_json, (err) =>
        delete @store[model_json.id] unless err
        callback(err)

module.exports = (type) ->
  if Utils.isCollection(new type()) # collection
    model_type = Utils.configureCollectionModelType(type, module.exports)
    return type::sync = model_type::sync

  sync = new MemorySync(type)
  type::sync = sync_fn = (method, model, options={}) -> # save for access by model extensions
    sync.initialize()
    return module.exports.apply(null, Array::slice.call(arguments, 1)) if method is 'createSync' # create a new sync
    return sync if method is 'sync'
    return false if method is 'isRemote'
    return sync.schema if method is 'schema'
    return undefined if method is 'tableName'
    return if sync[method] then sync[method].apply(sync, Array::slice.call(arguments, 1)) else undefined

  require('./lib/model_extensions')(type)
  return require('./lib/cache').configureSync(type, sync_fn)
