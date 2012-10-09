

var _ = require('underscore')
  , fs = require('fs')
  , detective = require('detective')
  , files = fs.readdirSync('scripts');

// string utils
var stringEndsWith = function(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1;
};

// filter only js files
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
for (var i in requires) {
  try {
    require(requires[i]);
    continue; // skip deps that already exists
  }
  catch (e) {
    /* absorbed */
  }

  console.log(requires[i]);
}

