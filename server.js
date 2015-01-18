#!/usr/bin/env node

require('coffee-script/register');
NackChannel = require('./nackchannel');

if(!process.argv[2]) {
  throw 'Usage: nackchannel <passowrd>'
}

nackChannel = new NackChannel(process.env.USER, process.argv[2]);
nackChannel.start()
