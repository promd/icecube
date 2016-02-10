var express = require('express');
var router = express.Router();
var push   = require('request');

/*
 * GET roomlist.
 */
router.get('/', function(req, res) {
    var db = req.db;

    db.query('select * from rooms', {
        limit: 100
    }).then(function (results){
      res.json(results);
      console.log(results);
    });
});

// open push-channel for all rooms (possible ???)
router.get('/feed', function(req, res) {
        console.log("c2");
        res.type('html');
        res.status(200).send('Hello world');
});

// Get room status
router.get('/:id', function(req, res) {
    var db = req.db;

    db.query('select * from rooms where name = :name', {
	params: { name: req.params.id },
        limit: 100
    }).then(function (results){
      for (var room in results) {
         var cubes = results[room].cubes;
         for (var i in cubes) {
             console.log(cubes[i]);
             db.query('select * from history where cube = :cube', {
                 params: { cube: cubes[i] },
                 limit: 100
             }).then(function (results){
                 console.log(results);
             });
         }
      }
      res.json(results);
      //console.log(results);
    });
});

// open push-channel for one room (possible ???)
router.get('/:id/feed', function(req, res) { });

module.exports = router;
