var express = require('express');
var router = express.Router();
var request= require('request');

/*
 * Receive updates from cubes
 */
router.post('/:id', function(req, res) {    
    db = req.db;

    var resbody = { "status" : "ok"};

    var content = req.body;
    content.cube = req.params.id;
    content.time = Date.now();
    console.log(content);
    db.insert().into('moni').set(content).one()
    .then(function (user) {
        res.json(resbody);
    });
});

module.exports = router;
