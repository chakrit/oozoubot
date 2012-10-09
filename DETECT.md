
# detect.js

Detect missing require('') in scripts.

### HOWTO:
1. Install CoffeeScript if you havn't already: `npm install -g coffee-script`
2. Compile all `.coffee` files into `js` since our require detector doesn't work with CoffeeScript.
3. Run `node detect.js`

Each line of output is an unlisted or broken package (error on `require`).

### FULL RUN

This script should adds all missing packages to package.json for you:

    npm install --save
    coffee --compile scripts
    node detect.js | xargs -P 1 npm install --save

I havn't thoroughly tested this so make sure you understand what it is doing.

