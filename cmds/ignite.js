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
    waitUntil(10000, Infinity, () => {
        ping().then((result) => {
            internet = result;
            return result;
        });
        return internet;
    }, () => {
        logger.info('looking for cameras');
        onvif.startProbe().then((device_info_list) => {
            logger.info(device_info_list.length + ' devices found');
            
        }).catch((error) => {
            logger.error(error);
        });
    });
};