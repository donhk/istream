const onvif = require('node-onvif');
const uniqid = require('uniqid');

let cameras = [];

function processDevice(info) {
    let device = new onvif.OnvifDevice({
        xaddr: info.xaddrs[0],
        user: 'admin',
        pass: '123456' //TODO add dynamic user list
    });
    return device.init().then(() => {
        console.log("init done");
        const camObj = { name: uniqid(), attr: device }; //uniqid()
        cameras.push(camObj);
    }).catch((error)=>{
        console.error(error)
    });
}

module.exports = function find_cameras(params) {
    console.log('finding cameras');
    onvif.startProbe().then((device_info_list) => {
        console.log(device_info_list.length + ' devices will be initialized.');
        let requests = device_info_list.map((info) => {
            return processDevice(info);
        });
        Promise.all(requests).then(() => {
            console.log('returning cameras found ' + cameras.length);
        }).catch((error) => {
            console.error(error)
        });
    }).catch((error) => {
        console.error(error);
    });
};