import SocketServer
import json

__author__ = 'maeglin89273'

import socket as sk

HOST = ''
PORT = 3070

BUFFER_SIZE = 512

filename = 'tmp.csv'

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
