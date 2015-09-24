import SocketServer
import json

__author__ = 'maeglin89273'

import sys
import socket as sk

HOST = '192.168.0.170'
PORT = 3070

BUFFER_SIZE = 512

if len(sys.argv) > 1:
    filename = sys.argv[1]
else :
    print "Usage: python pyfile <output file>"

out = open(filename, 'a')

def direct_to_model(raw_data):
    data = [raw_data['FFA2'], raw_data['Timestamp'], raw_data['Label']]

    print data
    out.write(','.join([str(x) for x in data]) + '\n')

class UDPHandler(SocketServer.BaseRequestHandler):
    def handle(self):
        json_data = self.request[0]
        raw_data = json.loads(json_data)
        direct_to_model(raw_data)

def start_server():
    print 'current ip address: ' + sk.gethostbyname(sk.gethostname()) + ':' + str(PORT)

    server = SocketServer.UDPServer((HOST, PORT), UDPHandler)
    server.serve_forever()


if __name__ == '__main__':
    start_server()
