var waitUntil = require('wait-until');
var onvif = require('node-onvif');
var propertiesReader = require('properties-reader');
const winston = require('winston');
const ping = require('../cmds/ping');
const stream = require('../cmds/start_stream');
const fspace = require('../cmds/fs_space');
const logger = winston.createLogger({
    format: winston.format.simple(),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'logs/ignite.log' })
    ]
});

var properties = propertiesReader('.app.properties');
const clean_dir_interval = 1000 * properties.get('CLEAN_DIR_INTERVAL'); // seconds
const max_used_space = properties.get('MAX_USED_SPACE'); // in MB
const reconnect_interval = properties.get('RECONNECT_INTERVAL'); //seconds
const segment_duration = properties.get('SEGMENT_DURATION'); // seconds
const storage_path = properties.get('REMOTE_SERVER_DIRECTORY'); // remote location
const cam_user = properties.get('CAM_USER');
const cam_pass = properties.get('CAM_PASS');
const cam_auth = `rtsp://${cam_user}:${cam_pass}@`; // cam user and pass

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