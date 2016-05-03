var express = require('express');
var router = express.Router();
var request= require('request');
var dateFormat = require('dateformat');

/*
 * GET cubelist.
 */
router.get('/:id', function(req, res) {
    var db = req.db;
    console.log("Data received from " + req.params.id);
    console.log(req.query);
    res.send();
/*
    db.query('select * from history', {
        limit: 10
    }).then(function (results){
      res.json(results);
      console.log(results);
    });
*/
});

/*
 * Receive updates from cubes
 */
router.post('/:id', function(req, res) {    
    db = req.db;

    var resbody = { "status" : "ok"};
    // { "temp": "28", "voltage": "3945", "humidity": "60", "event" : "scheduled" }
    var content = req.body;
    console.log(req);
    content.cube = req.params.id;
    content.time = Date.now();
    content.timestr = dateFormat(content.time, "dd.mm.yy HH:MM:ss");
    

    // get associated rooms
    var rooms = db.select().from('rooms').containsText({cubes: content.cube}).all()
    var upd   = false;

    //translation logic
    if (content.event == 'used') {
	content.event = 'occupied';
    } else if (content.event == 'powr') {
	content.event = 'startup';
    }


    if (content.event == 'occupied') {
	// cube sends occupied event
        upd = true;
    } else if (content.event == 'free') {
	// cube sends free event
        upd = true;
    } else if (content.event == 'blocked') {
        // cube sends blocked event
        upd = true;
    } else {
        // other event
    }

    db.insert().into('history').set(content).one();

    if (upd) {
	rooms.then(function (rs) {
		for (var i in rs) {
			rid = rs[i].name;
			rid = rid.replace(/\s/g,"_");
			console.log(rid);
			msg = '{ "auth_token": "stcs", "text" : "' + content.event  +  '", "status" : "' + content.event + '", "moreinfo" : "' + content.temp  + ' Celsius" }';
			console.log(msg);
			request.post(
        			'http://143.39.231.107:3030/widgets/' + rid,
                		{ form : msg },
        	        	function (error, response, body) {
	        	           if (!error && response.statusCode == 200) {
        	        	      console.log(body);
	                	   } else {
				      console.log("Error:" + response.statusCode);
				   }
				   res.json(resbody);
		                }
			);
		}
	});
    }
});

module.exports = router;
