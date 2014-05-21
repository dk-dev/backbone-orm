###
  backbone-orm.js 0.5.15
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

_ = require 'underscore'
Backbone = require 'backbone'
Utils = require '../utils'

collection_type = Backbone.Collection

overrides =
  fetch: (options) ->
    # callback signature
    if _.isFunction(callback = arguments[arguments.length-1])
      switch arguments.length
        when 1 then options = Utils.wrapOptions({}, callback)
        when 2 then options = Utils.wrapOptions(options, callback)

    return collection_type::_orm_original_fns.fetch.call(@, Utils.wrapOptions(options, (err, model, resp, options) =>
      return options.error?(@, resp, options) if err
      options.success?(model, resp, options)
    ))

  _prepareModel: (attrs, options) ->
    if not Utils.isModel(attrs) and (id = Utils.dataId(attrs))
      is_new = !!@model.cache.get(id) if @model.cache
      model = Utils.updateOrNew(attrs, @model)
      if is_new and not model._validate(attrs, options)
        this.trigger('invalid', @, attrs, options)
        return false
      return model

    return collection_type::_orm_original_fns._prepareModel.call(@, attrs, options)

if not collection_type::_orm_original_fns
  collection_type::_orm_original_fns = {}
  for key, fn of overrides
    collection_type::_orm_original_fns[key] = collection_type::[key]
    collection_type::[key] = fn
