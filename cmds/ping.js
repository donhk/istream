/* ------------------------------------------------------------------
* istream - ping.js
*
* Copyright (c) 2020 Frederick Alvarez, All rights reserved.
* Released under the MIT license
* Date: 2020-01-26
* ---------------------------------------------------------------- */

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