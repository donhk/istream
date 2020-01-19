var onvif = require('node-onvif');

module.exports = function () {
    console.log('finding cameras');
    onvif.startProbe().then((device_info_list) => {
        console.log(device_info_list.length + ' devices found');
    }).catch((error) => {
        console.error(error);
    });
};