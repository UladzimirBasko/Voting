var http = require('http')
var url = require('url')
var fs = require('fs')
var reqIp = require('request-ip')

var iplist = [];

fs.readFile('iplist.txt', 'utf8', function(err, data) {
    var addresses = data.split(';').filter(function(rx) { return rx.length });
    addresses.forEach(function(address, index) {
        var splitedAddress = address.split(':');
        var portAndPath = splitedAddress[1].split('/');
        var ipAddr = {};
        ipAddr.ip = splitedAddress[0];
        ipAddr.port = portAndPath[0];
        ipAddr.path = portAndPath[1];
        iplist.push(ipAddr);
    })
})

function proxiedAddress(senderIp) {
   var lastOktet;
    if(senderIp) {
        if (senderIp.indexOf('.') > -1) {
            lastOktet = senderIp.split('.').pop();
        } else {
            lastOktet = senderIp.split(':').pop();
        }
    }else {
        lastOktet = 0;
    }
    var oktetDigit = parseInt(lastOktet, 10);
    var index = oktetDigit % iplist.length;
    return iplist[index];
}

var server = http.createServer();

server.on('request', function(request, response) {

    var clientIp = reqIp.getClientIp(request);
    var ipAddr = proxiedAddress(clientIp);

    var ph = url.parse(request.url);
    var options = {
        port : ipAddr.port,
        hostname : ipAddr.ip,
        method : request.method,
        path : "/" + ipAddr.path + ph.path,
        headers : ph.headers
    }
    var proxyRequest = http.request(options);

    proxyRequest.on('response', function(proxyResponse){
        proxyResponse.on('data',function(chunk) {
            response.write(chunk, 'binary');
        })
        proxyResponse.on('end', function(){
            response.end();
        })
        response.writeHead(proxyResponse.statusCode, proxyResponse.headers)
    })
    request.on('data', function(chunk){
        proxyRequest.write(chunk);
    })
    request.on('end', function(){
        proxyRequest.end();
    })
})

var portIdx = process.argv.indexOf('-p');
var port = (portIdx !== -1) ? process.argv[portIdx + 1] : 4000;
server.listen(port || 4000);