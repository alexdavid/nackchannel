#!/usr/bin/env node
// Generated by CoffeeScript 1.4.0
(function() {
  var callout, charm, client, color, colors, config, dgram, iron, msgLine, nick, parseMsg, password, port, positionForInput, presence, present, printNewMessage, randomColor, see, send, sendRaw, server, stdin, stylize;

  charm = require('charm')();

  dgram = require("dgram");

  iron = require("iron");

  password = process.argv[2];

  present = {};

  config = {};

  try {
    config = require("" + process.env.HOME + "/.nackchannelrc.json");
  } catch (_error) {}

  nick = config.nick || process.env.USER;

  nick += "{reset}";

  colors = ["blue", "cyan", "green", "magenta", "red", "white", "yellow"];

  randomColor = colors[Math.floor(Math.random() * colors.length)];

  color = randomColor;

  if (typeof config.color !== 'undefined') {
    color = config.color;
  }

  server = dgram.createSocket("udp4");

  client = dgram.createSocket("udp4");

  port = 41234;

  server.bind(port);

  server.addMembership('224.0.0.0');

  charm.pipe(process.stdout);

  charm.reset();

  stylize = function(msg) {
    var matcher, styles;
    styles = {
      reset: 0,
      blink: 5,
      bold: 1,
      underline: 4,
      black: 30,
      blue: 34,
      cyan: 36,
      green: 32,
      magenta: 35,
      red: 31,
      white: 37,
      yellow: 33
    };
    matcher = /{([a-z]+)}/gi;
    return msg.replace(matcher, function(match, idx) {
      return "[" + styles[idx] + "m";
    });
  };

  callout = function(msg) {
    return msg.replace(new RegExp("@" + nick + "\\b", 'g'), function(match) {
      return "{magenta}" + match + "{reset}";
    });
  };

  msgLine = 0;

  printNewMessage = function(obj) {
    var msg;
    if (msgLine > process.stdout.getWindowSize()[1] - 4) {
      msgLine = 0;
      charm.erase('screen');
    }
    msg = callout(obj.payload);
    charm.position(0, ++msgLine);
    charm.write('\u0007');
    if (obj.nick === nick) {
      charm.write(stylize("[{" + obj.color + "}{bold}" + obj.nick + "{reset}] " + obj.payload));
    } else {
      charm.write(stylize("[{" + obj.color + "}" + obj.nick + "{reset}] " + obj.payload));
    }
    charm.display('reset');
    return positionForInput();
  };

  positionForInput = function() {
    charm.position(0, process.stdout.getWindowSize()[1] - 2);
    charm.background('blue');
    charm.erase('end');
    charm.position(0, process.stdout.getWindowSize()[1] - 1);
    return charm.background('black');
  };

  presence = function() {
    var i, line, n, obj, size, _i;
    line = 0;
    size = process.stdout.getWindowSize();
    for (i = _i = 0; _i <= 10; i = ++_i) {
      charm.position(size[0] - 10, line);
      charm.write("         ");
      line++;
    }
    line = 0;
    for (n in present) {
      if ((new Date() - present[n].when) < 5000) {
        line++;
        charm.position(size[0] - 10, line);
        charm.write(stylize("{" + present[n].color + "}" + n + "{reset}"));
      }
    }
    positionForInput();
    obj = {
      nick: nick,
      presence: true,
      color: color
    };
    return send(obj);
  };

  see = function(obj) {
    return present[obj.nick] = {
      when: new Date(),
      color: obj.color
    };
  };

  sendRaw = function(msg) {
    msg = new Buffer(msg);
    return client.send(msg, 0, msg.length, port, '224.0.0.0', function(err, bytes) {
      positionForInput();
      return charm.erase('end');
    });
  };

  send = function(obj) {
    var msg;
    if (password) {
      return iron.seal(obj, password, iron.defaults, function(err, sealed) {
        return sendRaw(sealed);
      });
    } else {
      msg = JSON.stringify(obj);
      return sendRaw(msg);
    }
  };

  positionForInput();

  setInterval(presence, 5000);

  stdin = process.openStdin();

  stdin.on('data', function(msg) {
    var obj;
    obj = {
      payload: msg.toString(),
      nick: nick,
      color: color
    };
    return send(obj);
  });

  parseMsg = function(obj) {
    var msg;
    if (obj.payload != null) {
      printNewMessage(obj);
    } else if (obj.presence != null) {
      see(obj);
    }
    if (password) {
      return iron.seal(obj, password, iron.defaults, function(err, sealed) {
        return send(sealed);
      });
    } else {
      msg = JSON.stringify(obj);
      return send(msg);
    }
  };

  server.on('message', function(str, rinfo) {
    var obj;
    if (password) {
      return iron.unseal(str.toString(), password, iron.defaults, function(err, obj) {
        if (obj == null) {
          return;
        }
        return parseMsg(obj);
      });
    } else {
      try {
        obj = JSON.parse(str);
        return parseMsg(obj);
      } catch (_error) {}
    }
  });

}).call(this);
