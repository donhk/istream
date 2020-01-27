/* ------------------------------------------------------------------
* istream - start_stream.js
*
* Copyright (c) 2020 Frederick Alvarez, All rights reserved.
* Released under the MIT license
* Date: 2020-01-26
* ---------------------------------------------------------------- */
const winston = require('winston');
const util = require('util');
var propertiesReader = require('properties-reader');
var path = require('path');
var appDir = path.dirname(require.main.filename);
var properties = propertiesReader(appDir + '/.app.properties');
const exec = util.promisify(require('child_process').exec);

const logger = winston.createLogger({
    format: winston.format.simple(),
    transports: [
        new winston.transports.File({ filename: appDir + '/logs/start_stream.log' })
    ],
    maxsize: 50000
});

const ffmpeg_home = properties.get('FFMPEG_HOME');

async function execute(source, destiny, segment_duration) {
    const cmd = `
        ${ffmpeg_home}/ffmpeg \
        -i ${source}\
        -c:v copy \
        -c:a pcm_alaw \
        -flags +global_header \
        -f segment \
        -segment_time ${segment_duration} \
        -segment_format_options movflags=+faststart \
        -segment_list_flags live \
        -reset_timestamps 1 \
        -strftime 1 "${destiny}_%Y-%m-%d_%H-%M-%S_output.mov"
    `;
    logger.info('ffmpeg started');
    logger.info(cmd);
    await exec(cmd, { maxBuffer: (1024 * 1024 * 100) }, (error, stdout, stderr) => {
        if (error) {
            logger.error(stderr);
            logger.info('retrying execution');
            execute(source, destiny, segment_duration);
            return;
        }
        logger.info(stdout);
    });
};

module.exports = function (source, destiny, segment_duration) {
    execute(source, destiny, segment_duration);
};