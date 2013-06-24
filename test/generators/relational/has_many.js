// Generated by CoffeeScript 1.6.2
(function() {
  var Backbone, Fabricator, JSONUtils, Queue, Utils, adapters, assert, runTests, util, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('util');

  assert = require('assert');

  _ = require('underscore');

  Backbone = require('backbone');

  Queue = require('queue-async');

  Fabricator = require('../../../fabricator');

  Utils = require('../../../lib/utils');

  JSONUtils = require('../../../lib/json_utils');

  adapters = Utils.adapters;

  runTests = function(options, cache, embed) {
    var BASE_COUNT, BASE_SCHEMA, DATABASE_URL, Flat, Owner, Reverse, SYNC, _ref, _ref1, _ref2;

    DATABASE_URL = options.database_url || '';
    BASE_SCHEMA = options.schema || {};
    SYNC = options.sync;
    BASE_COUNT = 1;
    Flat = (function(_super) {
      __extends(Flat, _super);

      function Flat() {
        _ref = Flat.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Flat.prototype.urlRoot = "" + DATABASE_URL + "/flats";

      Flat.schema = BASE_SCHEMA;

      Flat.prototype.sync = SYNC(Flat, cache);

      return Flat;

    })(Backbone.Model);
    Reverse = (function(_super) {
      __extends(Reverse, _super);

      function Reverse() {
        _ref1 = Reverse.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      Reverse.prototype.urlRoot = "" + DATABASE_URL + "/reverses";

      Reverse.schema = _.defaults({
        owner: function() {
          return ['belongsTo', Owner];
        }
      }, BASE_SCHEMA);

      Reverse.prototype.sync = SYNC(Reverse, cache);

      return Reverse;

    })(Backbone.Model);
    Owner = (function(_super) {
      __extends(Owner, _super);

      function Owner() {
        _ref2 = Owner.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      Owner.prototype.urlRoot = "" + DATABASE_URL + "/owners";

      Owner.schema = _.defaults({
        flats: function() {
          return ['hasMany', Flat];
        },
        reverses: function() {
          return ['hasMany', Reverse];
        }
      }, BASE_SCHEMA);

      Owner.prototype.sync = SYNC(Owner, cache);

      return Owner;

    })(Backbone.Model);
    return describe("hasMany (cache: " + cache + " embed: " + embed + ")", function() {
      beforeEach(function(done) {
        var MODELS, queue;

        MODELS = {};
        queue = new Queue(1);
        queue.defer(function(callback) {
          var destroy_queue;

          destroy_queue = new Queue();
          destroy_queue.defer(function(callback) {
            return Flat.destroy(callback);
          });
          destroy_queue.defer(function(callback) {
            return Reverse.destroy(callback);
          });
          destroy_queue.defer(function(callback) {
            return Owner.destroy(callback);
          });
          return destroy_queue.await(callback);
        });
        queue.defer(function(callback) {
          var create_queue;

          create_queue = new Queue();
          create_queue.defer(function(callback) {
            return Fabricator.create(Flat, 2 * BASE_COUNT, {
              name: Fabricator.uniqueId('flat_'),
              created_at: Fabricator.date
            }, function(err, models) {
              MODELS.flat = models;
              return callback(err);
            });
          });
          create_queue.defer(function(callback) {
            return Fabricator.create(Reverse, 2 * BASE_COUNT, {
              name: Fabricator.uniqueId('reverse_'),
              created_at: Fabricator.date
            }, function(err, models) {
              MODELS.reverse = models;
              return callback(err);
            });
          });
          create_queue.defer(function(callback) {
            return Fabricator.create(Owner, BASE_COUNT, {
              name: Fabricator.uniqueId('owner_'),
              created_at: Fabricator.date
            }, function(err, models) {
              MODELS.owner = models;
              return callback(err);
            });
          });
          return create_queue.await(callback);
        });
        queue.defer(function(callback) {
          var owner, save_queue, _fn, _i, _len, _ref3;

          save_queue = new Queue();
          _ref3 = MODELS.owner;
          _fn = function(owner) {
            owner.set({
              flats: [MODELS.flat.pop(), MODELS.flat.pop()],
              reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]
            });
            return save_queue.defer(function(callback) {
              return owner.save({}, adapters.bbCallback(callback));
            });
          };
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            owner = _ref3[_i];
            _fn(owner);
          }
          return save_queue.await(callback);
        });
        return queue.await(done);
      });
      it('Handles a get query for a hasMany relation', function(done) {
        return Owner.find({
          $one: true
        }, function(err, test_model) {
          assert.ok(!err, "No errors: " + err);
          assert.ok(test_model, 'found model');
          return test_model.get('flats', function(err, flats) {
            assert.ok(!err, "No errors: " + err);
            assert.equal(2, flats.length, "Expected: " + 2 + ". Actual: " + flats.length);
            if (test_model.relationIsEmbedded('flats')) {
              assert.deepEqual(test_model.toJSON().flats[0], flats[0].toJSON(), "Serialized embedded. Expected: " + (test_model.toJSON().flats[0]) + ". Actual: " + (flats[0].toJSON()));
            }
            return done();
          });
        });
      });
      it('Handles an async get query for ids', function(done) {
        return Owner.find({
          $one: true
        }, function(err, test_model) {
          assert.ok(!err, "No errors: " + err);
          assert.ok(test_model, 'found model');
          return test_model.get('flat_ids', function(err, ids) {
            assert.ok(!err, "No errors: " + err);
            assert.equal(2, ids.length, "Expected count: " + 2 + ". Actual: " + ids.length);
            return done();
          });
        });
      });
      it('Handles a synchronous get query for ids after the relations are loaded', function(done) {
        return Owner.find({
          $one: true
        }, function(err, test_model) {
          assert.ok(!err, "No errors: " + err);
          assert.ok(test_model, 'found model');
          return test_model.get('flats', function(err, flats) {
            assert.ok(!err, "No errors: " + err);
            assert.equal(test_model.get('flat_ids').length, flats.length, "Expected count: " + (test_model.get('flat_ids').length) + ". Actual: " + flats.length);
            assert.deepEqual(test_model.get('flat_ids')[0], flats[0].get('id'), "Serialized id only. Expected: " + (test_model.get('flat_ids')[0]) + ". Actual: " + (flats[0].get('id')));
            return done();
          });
        });
      });
      it('Handles a get query for a hasMany and belongsTo two sided relation', function(done) {
        return Owner.find({
          $one: true
        }, function(err, test_model) {
          assert.ok(!err, "No errors: " + err);
          assert.ok(test_model, 'found model');
          return test_model.get('reverses', function(err, reverses) {
            var reverse;

            assert.ok(!err, "No errors: " + err);
            assert.ok(reverses, 'found models');
            assert.equal(2, reverses.length, "Expected: " + 2 + ". Actual: " + reverses.length);
            if (test_model.relationIsEmbedded('reverses')) {
              assert.deepEqual(test_model.toJSON().reverses[0], reverses[0].toJSON(), 'Serialized embedded');
            }
            assert.deepEqual(test_model.get('reverse_ids')[0], reverses[0].get('id'), 'serialized id only');
            reverse = reverses[0];
            return reverse.get('owner', function(err, owner) {
              assert.ok(!err, "No errors: " + err);
              assert.ok(owner, 'found owner models');
              if (reverse.relationIsEmbedded('owner')) {
                assert.deepEqual(reverse.toJSON().owner_id, owner.get('id'), "Serialized embedded. Expected: " + (util.inspect(reverse.toJSON().owner_id)) + ". Actual: " + (util.inspect(owner.get('id'))));
              }
              assert.deepEqual(reverse.get('owner_id'), owner.get('id'), "Serialized id only. Expected: " + (reverse.toJSON().owner) + ". Actual: " + (owner.get('id')));
              if (Owner.cache()) {
                assert.deepEqual(JSON.stringify(test_model.toJSON()), JSON.stringify(owner.toJSON()), "\nExpected: " + (util.inspect(test_model.toJSON())) + "\nActual: " + (util.inspect(test_model.toJSON())));
              } else {
                assert.equal(test_model.get('id'), owner.get('id'), "\nExpected: " + (test_model.get('id')) + "\nActual: " + (owner.get('id')));
              }
              return done();
            });
          });
        });
      });
      return it('Appends json for a related model', function(done) {
        return Owner.find({
          $one: true
        }, function(err, test_model) {
          var json;

          assert.ok(!err, "No errors: " + err);
          assert.ok(test_model, 'found model');
          json = {};
          return JSONUtils.appendRelatedJSON(json, test_model, 'reverses', ['id', 'created_at'], function(err) {
            var reverse, _i, _len, _ref3;

            assert.ok(!err, "No errors: " + err);
            assert.ok(json.reverses.length, "json has a list of reverses");
            assert.equal(2, json.reverses.length, "Expected: " + 2 + ". Actual: " + json.reverses.length);
            _ref3 = json.reverses;
            for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
              reverse = _ref3[_i];
              assert.ok(reverse.id, "reverse has an id");
              assert.ok(reverse.created_at, "reverse has a created_at");
              assert.ok(!reverse.updated_at, "reverse doesn't have updated_at");
            }
            return done();
          });
        });
      });
    });
  };

  module.exports = function(options) {
    runTests(options, false, false);
    runTests(options, true, false);
    if (options.embed) {
      runTests(options, false, true);
    }
    if (options.embed) {
      return runTests(options, true, true);
    }
  };

}).call(this);

/*
//@ sourceMappingURL=has_many.map
*/
