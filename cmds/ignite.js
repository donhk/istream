const winston = require('winston');
var waitUntil = require('wait-until');
const ping = require('../cmds/ping');
var onvif = require('node-onvif');
const ss = require('../cmds/start_stream');
const fspace = require('../cmds/fs_space');

const logger = winston.createLogger({
    format: winston.format.simple(),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'logs/ignite.log' })
    ]
});

module.exports = async function () {
    logger.info('checking internet connectivity');
    let internet = false;
    waitUntil(1000, Infinity, () => {
        ping().then((result) => {
            internet = result;
            return result;
        });
        return internet;
    }, () => {
        logger.info('looking for cameras');
        onvif.startProbe().then((device_info_list) => {
            logger.info(device_info_list.length + ' devices found');
            device_info_list.map((info) => {
                let device = new onvif.OnvifDevice({
                    xaddr: info.xaddrs[0],
                    user: 'admin', // this comes from the manual
                    pass: 'admin'  // this comes from the manual
                });
                logger.debug(JSON.stringify(device));
                device.init().then(() => {
                    logger.debug(JSON.stringify(device));
                    logger.info(device.profile_list[0].stream.rtsp);
                    const stream_url = 'rtsp://admin:frederick27@' + device.profile_list[0].stream.rtsp.substring(7); // this needs to be known in advance
                    logger.info(stream_url);
                    
                });
            });
        }).catch((error) => {
            logger.error(error);
        });
    });
};