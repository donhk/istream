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
const spawn = require('child_process').spawn;

const logger = winston.createLogger({
    format: winston.format.simple(),
    transports: [
        new winston.transports.File({ filename: appDir + '/logs/start_stream.log' })
    ],
    maxsize: 50000000
});

const ffmpeg_home = properties.get('FFMPEG_HOME');

async function execute(source, destiny, segment_duration) {
    logger.info('ffmpeg started');
    const options = {
    shell: true,
    stdio: [
        'inherit', // StdIn.
        'pipe',    // StdOut.
        'pipe',    // StdErr.
        ],
    };
    const args = [
    `-i`, `${source}`,
    `-analyzeduration`, `120`,
    `-probesize`,`1024000`,
    `-c:v`, `copy`,
    `-c:a`, `pcm_alaw`,
    `-flags`, `+global_header`,
    `-f`, `segment`,
    `-segment_time`,`${segment_duration}`,
    `-segment_format_options`,` movflags=+faststart`,
    `-segment_list_flags`,`live`,
    `-reset_timestamps`, `1`,
    `-strftime`, `1`, 
    `-use_wallclock_as_timestamps`, `1`,
    `-fflags`, `+genpts`,
    `-hide_banner`,
    `"${destiny}_%Y-%m-%d_%H-%M-%S_output.mov"`
    ];
    var process = spawn(`${ffmpeg_home}/ffmpeg`, args, options);

    process.stdout.on('data', function (data){ logger.info(data.toString()); });
    process.stderr.on('data', function (data){ logger.info(data.toString()); });
    process.on('exit', function(code){ logger.info('exit code ' + code); });

};

module.exports = function (source, destiny, segment_duration) {
    execute(source, destiny, segment_duration);
};
