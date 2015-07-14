//
//  ViewController.m
//  udp
//
//  Created by jhow on 7/6/15.
//  Copyright (c) 2015 jhow. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

#define TIME_OUT 10
#define TIMESTAMP [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]
// Return UNIX timestamp in milisecs

int idx;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_Connect setEnabled: NO];
    [_Disconnect setEnabled: NO];
    _Host.text = @"192.168.0.159";
    _Port.text = @"3070";
    _label.text = @"1";
    idx = 0;
    
    _data = [[NSMutableDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt:0], @"FFA2", [NSNumber numberWithInt:1], @"FFA3", [NSNumber numberWithInt:2], @"FFA4", [NSNumber numberWithInt:3], @"FFA6", [NSNumber numberWithInt:4], @"FFA7", [NSNumber numberWithInt:5], @"FFA8", @"", @"Timestamp", @"Label", @"" ,nil];
    
    _uuids = [[NSDictionary alloc] initWithObjectsAndKeys: @"0", @"FFA2", @"1", @"FFA3", @"2", @"FFA4", @"3", @"FFA6", @"4", @"FFA7", @"5", @"FFA8", nil];
    // Do any additional setup after loading the view, typically from a nib.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void) sendMsg {
    NSError *error = nil;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:_data options:NSJSONWritingPrettyPrinted error: &error];
    [_socket sendData:data withTimeout:TIME_OUT tag:1];
}

- (IBAction)Connect_Click:(id)sender {
    NSString *ip = [self.Host text];
    NSString *port = [self.Port text];
    
    if ([[_Host text] isEqualToString:@""] || [[_Port text] isEqualToString: @""])
        return;
    
    [_data setValue: _label.text forKey:@"Label"];
    [self Initial_Socket: ip port: [port intValue]];
}

- (IBAction)Disconnect_Click:(id)sender {
    [_socket close];
    [_Connect setEnabled: YES];
    [_Disconnect setEnabled: NO];
}

- (void)Initial_Socket:(NSString *)ip port:(UInt16)port {
    _socket = [[AsyncUdpSocket alloc] initWithDelegate: self];
   
    // Connection
    
    if (![_socket isConnected]) {
        NSError *error = nil;
        
        if ([_socket connectToHost:ip onPort:port error:&error]) {
            NSLog(@"Socket Connected, %d", [_socket isConnected]);
            [_Connect setEnabled:NO];
            [_Disconnect setEnabled:YES];
        }
    }
}

// Called when data is sent by socket
- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"Send");
}

// Called when socket is closed
- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock {
    NSLog(@"Socket Closed");
    [_Connect setEnabled: YES];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"%ld", central.state);
    
    if (central.state != CBCentralManagerStatePoweredOn) return;
    else {
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        
        NSLog(@"Scanning Started");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
   
    if (_discoveredPeripheral != peripheral) {
        _discoveredPeripheral = peripheral;
        NSLog(@"Connecting to peripheral %@", peripheral);
        [_centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    [_BLEStatus setText: @"BLE Status = On"];
    [_Connect setEnabled: YES];
    [_centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ACCELERATION_X_UUID]] forService:service];
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ACCELERATION_Y_UUID]] forService:service];
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ACCELERATION_Z_UUID]] forService:service];
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:DEGREE_X_UUID]] forService:service];
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:DEGREE_Y_UUID]] forService:service];
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:DEGREE_Z_UUID]] forService:service];
    }
    // Discover other characteristics
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:ACCELERATION_X_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:ACCELERATION_Y_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:ACCELERATION_Z_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:DEGREE_X_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:DEGREE_Y_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:DEGREE_Z_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([_Connect isEnabled]) return;
    
    if (error) {
        NSLog(@"Error");
        return;
    }
    
    NSNumber *tmp = _uuids[[characteristic.UUID UUIDString]];
    
    if ([tmp intValue] == idx) {
        unsigned int dec = [self NSData2dec: characteristic.value];
        NSString *value = idx < 3 ? [self dec2acc: dec] : [self dec2deg: dec];
       
        [_data setValue: value forKey:[characteristic.UUID UUIDString]];
        idx += 1;
        idx = idx % 6;
        if (idx == 0) {
            [_data setValue: TIMESTAMP forKey:@"Timestamp"];
            [self sendMsg];
            sleep(0.01);
        }
        
    }
}

- (NSString*) dec2acc: (unsigned int)dec {
    return [self num2str:(float)((dec - 32768.0)/16384.0) ];
}

- (NSString*) dec2deg: (unsigned int)dec {
    return [self num2str: (float)((dec - 32768.0)/131.0)];
}

- (NSString*) num2str: (float)value {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:8];
    [formatter setRoundingMode: NSNumberFormatterRoundUp];
    
    return [formatter stringFromNumber: [NSNumber numberWithFloat:value]];
}

- (unsigned int) NSData2dec: (NSData *)data {
    unsigned int dec;
    uint8_t *hex = (uint8_t*) [data bytes];
    NSString *hex2string = [NSString stringWithFormat:@"%x%x", hex[0], hex[1]];
    NSScanner *scan = [NSScanner scannerWithString: hex2string];
    
    [scan scanHexInt: &dec];
        
    return dec;
}
- (IBAction)onBackgroungHit:(id)sender {
    
    [_Host resignFirstResponder];
    [_Port resignFirstResponder];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
