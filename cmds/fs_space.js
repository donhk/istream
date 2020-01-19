const fs = require('fs')
const max_space_used = 15; //in MB

module.exports = {
    listDir: (path) => {
        let files = fs.readdirSync(path); // You can also use the async method
        let filesWithStats = [];
        let sorted = files.sort((a, b) => {
            let s1 = fs.statSync(path + a);
            let s2 = fs.statSync(path + b);
            return new Date(s1.ctime) - new Date(s2.ctime);
        });
        let space_used = 0;
        sorted.forEach(file => {
            var filex = fs.statSync(path + file);
            space_used += (Math.round(filex.size / 1000000))
            console.log(filex.ctime + ' location: ' + file);
            filesWithStats.push({
                filename: file,
                date: new Date(filex.ctime),
                path: path + file
            });
        });
        console.log('space_used ' + space_used);
        if (space_used >= max_space_used) {
            console.log('freeing space' + filesWithStats[0].path);
            fs.unlink(filesWithStats[0].path, () => {
                console.log('file removed');
            });
        }
        return filesWithStats;
    }
};