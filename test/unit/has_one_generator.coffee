util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

JSONUtils = require '../../lib/json_utils'
Fabricator = require '../../fabricator'
Utils = require '../../utils'
adapters = Utils.adapters

class Flat extends Backbone.Model
  url: '/flats'
  sync: require('../../memory_backbone_sync')(Flat)

class Reverse extends Backbone.Model
  url: '/reverses'
  @schema:
    owner: -> ['belongsTo', Owner]
  sync: require('../../memory_backbone_sync')(Reverse)

class Owner extends Backbone.Model
  url: '/owners'
  @schema:
    flat: -> ['belongsTo', Flat]
    reverse: -> ['hasOne', Reverse]
  sync: require('../../memory_backbone_sync')(Owner)

Flat.initialize()
Reverse.initialize()
Owner.initialize()

BASE_COUNT = 5

test_parameters =
  model_type: Owner
  route: 'mocks'
  beforeEach: (callback) ->
    MODELS = {}

    queue = new Queue(1)

    # destroy all
    queue.defer (callback) ->
      destroy_queue = new Queue()

      destroy_queue.defer (callback) -> Flat.destroy callback
      destroy_queue.defer (callback) -> Reverse.destroy callback
      destroy_queue.defer (callback) -> Owner.destroy callback

      destroy_queue.await callback

    # create all
    queue.defer (callback) ->
      create_queue = new Queue()

      create_queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.flat = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(Reverse, BASE_COUNT, {
        name: Fabricator.uniqueId('reverse_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.reverse = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
        name: Fabricator.uniqueId('owner_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.one = models; callback(err))

      create_queue.await callback

    # link and save all
    queue.defer (callback) ->
      save_queue = new Queue(1)

      for one in MODELS.one
        do (one) ->
          one.set({flat: MODELS.flat.pop(), reverse: MODELS.reverse.pop()})
          save_queue.defer (callback) -> one.save {}, adapters.bbCallback callback

      save_queue.await callback

    queue.await (err) ->
      callback(err, _.map(MODELS.one, (test) -> test.toJSON()))

require('../../lib/test_generators/relational/has_one')(test_parameters)