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
    
    idx = 0;
    
    _data = [[NSMutableDictionary alloc] initWithObjectsAndKeys: @"Acc", @"FFA2", @"", @"Timestamp", @"", @"Label", @"", @"PosLabel", nil];
    
    _uuids = [[NSDictionary alloc] initWithObjectsAndKeys: @"0", @"FFA2", @"1", @"FFA4", nil];
    
    // Do any additional setup after loading the view, typically from a nib.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void) sendMsg {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:_data options:NSJSONWritingPrettyPrinted error: &error];
    [_socket writeData:data withTimeout:TIME_OUT tag:1];
    sleep(0.05);
    //[_socket sendData:data withTimeout:TIME_OUT tag:1];
}

- (IBAction)Connect_Click:(id)sender {
    NSString *ip = [self.Host text];
    NSString *port = [self.Port text];
    
    if ([[_Host text] isEqualToString:@""] || [[_Port text] isEqualToString: @""])
        return;
    
    [_data setValue: _label.text forKey:@"Label"];
    [_data setValue: _PosLabel.text forKey:@"PosLabel"];
    [self Initial_Socket: ip port: [port intValue]];
}

- (IBAction)Disconnect_Click:(id)sender
{
    [_socket disconnect];
    [_Connect setEnabled:YES];
    [_Disconnect setEnabled:NO];
}

- (void)Initial_Socket:(NSString *)ip port:(UInt16)port {
    _socket = [[AsyncSocket alloc] initWithDelegate: self];
    //_socket = [[AsyncUdpSocket alloc] initWithDelegate: self];
   
    // Connection
    
    if (![_socket isConnected]) {
        NSError *error = nil;
        
        if ([_socket connectToHost:ip onPort:port error:&error]) {
            [_Connect setEnabled:NO];
            [_Disconnect setEnabled:YES];
        }
    }
}

// Called when data is sent by socket
- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"Send");
}

-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Send");
}

// Called when socket is closed
- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock {
    NSLog(@"Socket Closed");
    [_Connect setEnabled: YES];
    [_Disconnect setEnabled: NO];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    NSLog(@"Socket Closed");
    [_Connect setEnabled: YES];
    [_Disconnect setEnabled: NO];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
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

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected");
    [_BLEStatus setText: @"BLE Status = ON"];
    [_Connect setEnabled:YES];
    [_centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [_BLEStatus setText:@"BLE Status = OFF"];
    [self viewDidLoad];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"Service");
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ACC_UUID]] forService:service];
    }
    // Discover other characteristics
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:ACC_UUID]])
        {
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
    
    NSString *value = [self NSData2Acc: characteristic.value];
    
    [_data setValue:value forKey:[characteristic.UUID UUIDString]];
    [_data setValue: TIMESTAMP forKey:@"Timestamp"];
    [_Package setText:[_data objectForKey:[characteristic.UUID UUIDString]]];
    
    [self sendMsg];
}

- (NSString*) dec2acc: (unsigned int)dec {
    float value = 0.0;
    switch (_SensitiveController.selectedSegmentIndex)
    {
        case 0:
            value = 16384.0;
            break;
        case 1:
            value = 8192.0;
            break;
        case 2:
            value = 4096.0;
    }
    
    if (dec > 32767.0)
    {
        return [self num2str:(float)((dec-65536.0)/value) ];
    }
    else
    {
        return [self num2str:(float)(dec/value)];
    }
}

- (NSString*) dec2deg: (unsigned int)dec {
    float value = 131.0;
    
    if (dec > 32767.0)
    {
        return [self num2str: (float)((dec-65536.0)/value)];
    }
    else
    {
        return [self num2str:(float)((dec/value))];
    }
}

- (NSString*) num2str: (float)value {
    return [NSString stringWithFormat:@"%f", value];
}

- (NSString *) NSData2Acc: (NSData *)data {
    unsigned int dec;
    uint8_t *hex = (uint8_t*) [data bytes];
    
    NSMutableArray *tmp = [[NSMutableArray alloc] initWithCapacity:3];
    for (int i = 0; i != [data length]; i+=2)
    {
        NSString *hex2str = [NSString stringWithFormat:@"%x%x", hex[i], hex[i+1]];
        NSScanner *scan = [NSScanner scannerWithString: hex2str];
        
        [scan scanHexInt: &dec];
        
        if (i < [data length]/2.0)
        {
            [tmp addObject:[self dec2acc:dec]];
        }
        else
        {
            [tmp addObject:[self dec2deg:dec]];
        }
    }
    return [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@", tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5]];
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
