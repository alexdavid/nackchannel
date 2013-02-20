all: 
	coffee -c server.coffee
	echo "#!/usr/bin/env node" > server.tmp
	cat server.js > server.tmp
	rm server.js
	mv server.tmp server.js
	
