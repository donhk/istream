const dns = require('dns').promises;

module.exports = function () {
  return dns.lookup('google.com')
    .then(() => {
      console.log('connected');
      return true;
    }).catch(() => {
      console.log('not connected');
      return false;
    });
};