// Require node js dgram module.
var os = require('os');

module.exports = function (nic) {
    const interfaces = os.networkInterfaces();
    nic = undefined || nic;
    var address;
    Object.keys(interfaces).forEach((netInterface) => {
        let obj = interfaces[netInterface];
        if (netInterface !== nic) {
            return;
        }
        obj.forEach((inic) => {
            if (inic.family === 'IPv4') {
                address = inic.address;
                return;
            }
        });
    });
    return address;
};