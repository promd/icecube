var express = require('express');
var router = express.Router();

/*
 * GET cubelist.
 */
router.get('/', function(req, res) {
    var db = req.db;


    db.query('select * from history', {
        limit: 10
    }).then(function (results){
      res.json(results);
      console.log(results);
    });
});

/*
 * Receive updates from cubes
 */
router.post('/:id', function(req, res) {    
    db = req.db;
    // { "temp": "28", "voltage": "3945", "humidity": "60", "event" : "scheduled" }
    var content = req.body;
    content.cube = req.params.id;
    content.time = Date.now();
    console.log(req.body);

    if (content.event == 'motion') {
         // movement, room is blocked
         db.select().from('rooms').containsText({cubes: content.cube}).all()
         .then(function (rooms) {
             console.log('busy room(s)', rooms);
	     for (var i in rooms) {
                // change the status to busy
	     }
         });
    }

    db.insert().into('history').set(content).one()
    .then(function (user) {
        res.json({"status" : "ok"});
    });
});

module.exports = router;
