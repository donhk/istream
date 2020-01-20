const winston = require('winston');
const util = require('util');
const exec = util.promisify(require('child_process').exec);

const logger = winston.createLogger({
    format: winston.format.simple(),
    transports: [
        new winston.transports.File({ filename: 'start_stream.log' })
    ]
});

async function execute(source, destiny) {
    const cmd = `
        ffmpeg \
        -i ${source}\
        -c:v copy \
        -c:a pcm_alaw \
        -flags +global_header \
        -f segment \
        -segment_time 60 \
        -segment_format_options movflags=+faststart \
        -segment_list_flags live \
        -reset_timestamps 1 \
        -strftime 1 "${destiny}/%Y-%m-%d_%H-%M-%S_output.mov"
    `;
    logger.info('ffmpeg started');
    await exec(cmd, { maxBuffer: (1024 * 1024 * 100) }, (error, stdout, stderr) => {
        if (error) {
            logger.error(stderr);
            logger.info('retrying execution');
            execute(source, destiny);
            return;
        }
        logger.info(stdout);
    });
};

module.exports = function (source, destiny) {
    execute(source, destiny);
};