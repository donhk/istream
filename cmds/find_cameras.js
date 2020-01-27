/* ------------------------------------------------------------------
* istream - find_cameras.js
*
* Copyright (c) 2020 Frederick Alvarez, All rights reserved.
* Released under the MIT license
* Date: 2020-01-26
* ---------------------------------------------------------------- */
var onvif = require('node-onvif');
const match_ip = require('../cmds/match_ip');
var propertiesReader = require('properties-reader');
var path = require('path');
var appDir = path.dirname(require.main.filename);
var properties = propertiesReader(appDir + '/.app.properties');

const nic = (properties.get('BROADCAST_NIC') === 'all' || properties.get('BROADCAST_NIC') === null) ? undefined : properties.get('BROADCAST_NIC');

module.exports = function () {
    let bind_address = undefined;
    if (nic !== undefined) {
        bind_address = match_ip(nic);
        console.log('looking for cameras on ' + bind_address);
    } else {
        console.log('looking for cameras on 0.0.0.0');
    }
    console.log('finding cameras');
    onvif.startProbe({ "bind_address": bind_address }).then((device_info_list) => {
        console.log(device_info_list.length + ' devices found');
    }).catch((error) => {
        console.error(error);
    });
};