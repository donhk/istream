const util = require('util');
const exec = util.promisify(require('child_process', { maxBuffer: (1024 * 1024 * 100) }).exec);

async function execute(source, destiny) {
    const cmd = 'ffmpeg -i ' + source + ' -c:v copy -c:a pcm_alaw -flags +global_header -f segment -segment_time 60 -segment_format_options movflags=+faststart -segment_list_flags live -reset_timestamps 1 ' + destiny + 'output_%d.mov';
    console.log('ffmpeg started');
    await exec(cmd, (error, stdout, stderr) => {
        if (error) {
            execute(source, destiny);
            return;
        }
    });
};

module.exports = function (source, destiny) {
    execute(source, destiny);
};