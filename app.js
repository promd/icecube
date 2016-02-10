var express = require('express');
var path = require('path');
var favicon = require('serve-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');

// DB connection
var OrientDB = require('orientjs'); 
var server = OrientDB({ host: 'localhost', port: 2424, username: 'root', password: 'raspberry' });
var db = server.use('icecube');

var app = express();
var httpsrv = require('http').Server(app);

var io = require('socket.io')(httpsrv);

var port = process.env.PORT || 3000;
httpsrv.listen(port, function () {
  console.log('Server listening at port %d', port);
});

var routes = require('./routes/index');
var users = require('./routes/users');
var cubes = require('./routes/cubes');
var rooms = require('./routes/rooms');
var tracking = require('./routes/tracking.js');

io.on('connection', function (socket) {
  console.log('Socket connection');
});


// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

/*
app.use(function(req, res, next) {
  req.rawBody = '';
  req.setEncoding('utf8');

  req.on('data', function(chunk) { 
    req.rawBody += chunk;
    console.log(chunk);
  });

  req.on('end', function() {
    next();
  });
});
*/
// uncomment after placing your favicon in /public
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use(function(err, req, res, next) {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});


// Make our db accessible to our router
app.use(function(req,res,next){
    req.db = db;
    next();
});

app.use('/', routes);
app.use('/users', users);
app.use('/cubes',cubes);
app.use('/rooms',rooms);
app.use('/tracking',tracking);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
  app.use(function(err, req, res, next) {
    res.status(err.status || 500);
    res.render('error', {
      message: err.message,
      error: err
    });
  });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
  res.status(err.status || 500);
  res.render('error', {
    message: err.message,
    error: {}
  });
});


module.exports = app;
