const winston = require('winston');
var waitUntil = require('wait-until');
const ping = require('../cmds/ping');
var onvif = require('node-onvif');
const stream = require('../cmds/start_stream');
const fspace = require('../cmds/fs_space');
var PropertiesReader = require('properties-reader');

const logger = winston.createLogger({
    format: winston.format.simple(),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'logs/ignite.log' })
    ]
});

var properties = PropertiesReader('.app.properties');
const clean_dir_interval = 10000; // seconds
const max_used_space = 15; // in MB
const reconnect_interval = 1000; //seconds
const segment_duration = 60; // seconds
const storage_path = '/tmp/temfiles/'; // remote location
const cam_auth = 'rtsp://admin:frederick27@'; // cam user and pass

module.exports = async function () {
    logger.info('checking internet connectivity');
    let internet = false;
    waitUntil(reconnect_interval, Infinity, () => {
        ping().then((result) => {
            internet = result;
            return result;
        });
        return internet;
    }, () => {
        logger.info('looking for cameras');
        onvif.startProbe().then((device_info_list) => {
            logger.info(device_info_list.length + ' devices found');
            let camera_id = 0;
            device_info_list.map((info) => {
                camera_id++;
                let device = new onvif.OnvifDevice({
                    xaddr: info.xaddrs[0],
                    user: 'admin', // this comes from the manual
                    pass: 'admin'  // this comes from the manual
                });
                logger.debug(JSON.stringify(device));
                device.init().then(() => {
                    logger.debug(JSON.stringify(device));
                    logger.info(device.profile_list[0].stream.rtsp);
                    const stream_url = cam_auth + device.profile_list[0].stream.rtsp.substring(7);
                    const spath = storage_path + "cam" + camera_id;
                    logger.debug(stream_url);
                    //run cleaner every x time
                    setInterval(() => {
                        fspace.listDir(storage_path, max_used_space);
                    }, clean_dir_interval);
                    //save stream into file
                    stream(stream_url, spath, segment_duration);
                });
            });
        }).catch((error) => {
            logger.error(error);
        });
    });
};