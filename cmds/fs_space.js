const winston = require('winston');
const fs = require('fs')

const logger = winston.createLogger({
    format: winston.format.simple(),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'logs/fs_space.log' })
    ],
    maxsize: 50000
});

module.exports = {
    listDir: (path, max_used_space) => {
        let files = fs.readdirSync(path); // You can also use the async method
        let filesWithStats = [];
        let sorted = files.sort((a, b) => {
            let s1 = fs.statSync(path + a);
            let s2 = fs.statSync(path + b);
            return new Date(s1.ctime) - new Date(s2.ctime);
        });
        let used_space = 0;
        sorted.forEach(file => {
            var filex = fs.statSync(path + file);
            used_space += (Math.round(filex.size / 1000000))
            logger.debug(filex.ctime + ' location: ' + file);
            filesWithStats.push({
                filename: file,
                date: new Date(filex.ctime),
                path: path + file
            });
        });
        logger.info('used_space ' + used_space);
        if (used_space >= max_used_space) {
            logger.info('freeing space ' + filesWithStats[0].path);
            fs.unlink(filesWithStats[0].path, () => {
                logger.info('file removed')
            });
        }
        return filesWithStats;
    }
};