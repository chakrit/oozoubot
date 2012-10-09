

var _ = require('underscore')
  , fs = require('fs')
  , detective = require('detective')
  , files = fs.readdirSync('scripts');

// filter only js files
var stringEndsWith = function(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1;
};

files = _(files).reject(function(file) {
  return !stringEndsWith(file, '.js');
});


// read file contents and analyze requirements
var requires = [];
for (var i in files) {
  var content = fs.readFileSync(__dirname + '/scripts/' + files[i])
    , requires_ = detective(content.toString());

  requires.push.apply(requires, requires_);
}

requires.sort();
requires = _(requires).uniq();


// test for existing dependencies
requires = _(requires).reject(function(dep) {
  try {
    require(dep);
    return true;
  }
  catch (e) {
    return false;
  }
});


// output to stdout
for (var i in requires) {
  console.log(requires[i]);
}

