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
 * Receive uüdates from cubes
 */
router.post('/:id', function(req, res) {
    console.log(req.body);    
    res.json({"status" : "ok"});
});

module.exports = router;
