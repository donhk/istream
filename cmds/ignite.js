/* ------------------------------------------------------------------
* istream - ignite.js
*
* Copyright (c) 2020 Frederick Alvarez, All rights reserved.
* Released under the MIT license
* Date: 2020-01-26
* ---------------------------------------------------------------- */
var waitUntil = require('wait-until');
var onvif = require('node-onvif');
var propertiesReader = require('properties-reader');
var path = require('path');
var appDir = path.dirname(require.main.filename);
var properties = propertiesReader(appDir + '/.app.properties');
const winston = require('winston');
const ping = require('../cmds/ping');
const stream = require('../cmds/start_stream');
const fspace = require('../cmds/fs_space');
const logger = winston.createLogger({
    format: winston.format.simple(),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: appDir + '/logs/ignite.log' })
    ]
});

const clean_dir_interval = 1000 * properties.get('CLEAN_DIR_INTERVAL');
const max_used_space = properties.get('MAX_USED_SPACE');
const reconnect_interval = properties.get('RECONNECT_INTERVAL');
const segment_duration = properties.get('SEGMENT_DURATION');
const storage_path = properties.get('LOCAL_SERVER_DIRECTORY') + "/";
const cam_user = properties.get('CAM_USER');
const cam_pass = properties.get('CAM_PASS');
const cam_auth = `rtsp://${cam_user}:${cam_pass}@`;
const nic = (properties.get('BROADCAST_NIC') === 'all' || properties.get('BROADCAST_NIC') === null) ? undefined : properties.get('BROADCAST_NIC');


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
        onvif.startProbe({ "bind_address": nic }).then((device_info_list) => {
            logger.info(device_info_list.length + ' devices found');
            if (device_info_list.length > 0) {
                //run cleaner every x time
                setInterval(() => {
                    console.log(storage_path)
                    fspace.listDir(storage_path, max_used_space);
                }, clean_dir_interval);
            }
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
                    const stream_path = storage_path + "cam" + camera_id;
                    logger.debug(stream_url);
                    //save stream into file
                    stream(stream_url, stream_path, segment_duration);
                });
            });
        }).catch((error) => {
            logger.error(error);
        });
    });
};