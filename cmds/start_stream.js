const util = require('util');
const exec = util.promisify(require('child_process').exec);

async function execute(source, destiny) {
    const cmd = 'ffmpeg -i ' + source + ' -c:v copy -c:a pcm_alaw -flags +global_header -f segment -segment_time 300 -segment_format_options movflags=+faststart -segment_list_flags live -reset_timestamps 1 ' + destiny + 'output_%d.mov';
    exec(cmd);
    console.log('ffmpeg started');
};

module.exports = function (source, destiny) {
    execute(source, destiny);
};