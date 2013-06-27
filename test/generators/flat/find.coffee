util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'

runTests = (options, cache) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  MODELS_JSON = null

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: _.defaults({
      boolean: 'Boolean'
    }, BASE_SCHEMA)
    sync: SYNC(Flat, cache)

  describe "Model.find (cache: #{cache})", ->

    beforeEach (done) ->
      queue = new Queue(1)

      queue.defer (callback) -> Flat.destroy callback

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
        boolean: true
      }, (err, models) ->
        return callback(err) if err
        MODELS_JSON = _.map(models, (test) -> test.toJSON())
        callback()
      )

      queue.await done

    it 'Handles a limit query', (done) ->
      Flat.find {$limit: 3}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(models.length, 3, 'found the right number of models')
        done()

    it 'Handles a find id query', (done) ->
      Flat.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        Flat.find test_model.get('id'), (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(model, 'gets a model')
          assert.equal(model.get('id'), test_model.get('id'), 'model has the correct id')
          done()


    it 'Handles another find id query', (done) ->
      Flat.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.find test_model.get('id'), (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(model, 'gets a model')
          assert.equal(model.get('id'), test_model.get('id'), 'model has the correct id')
          done()


    it 'Handles a find by query id', (done) ->
      Flat.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.find {id: test_model.get('id')}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, 1, 'finds the model')
          assert.equal(models[0].get('id'), test_model.get('id'), 'model has the correct id')
          done()


    it 'Handles a name find query', (done) ->
      Flat.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.find {name: test_model.get('name')}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models.length, 'gets models')
          for model in models
            assert.equal(model.get('name'), test_model.get('name'), 'model has the correct name')
          done()

    it 'Handles a find $in query', (done) ->
      Flat.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        $in = ['random_string', 'some_9', test_model.get('name')]

        Flat.find {name: {$in: $in}}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models.length, 'finds one model')
          for model in models
            assert.equal(test_model.get('name'), model.get('name'), "Names match:\nExpected: #{test_model.get('name')}, Actual: #{model.get('name')}")
          done()

    it 'Find can retrieve a boolean as a boolean', (done) ->
      Flat.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        assert.equal(typeof test_model.get('boolean'), 'boolean', "Is a boolean:\nExpected: 'boolean', Actual: #{typeof test_model.get('boolean')}")
        assert.deepEqual(true, test_model.get('boolean'), "Bool matches:\nExpected: #{true}, Actual: #{test_model.get('boolean')}")
        done()


# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)
