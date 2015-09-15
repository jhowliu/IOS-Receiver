//
//  ViewController.h
//  udp
//
//  Created by jhow on 7/6/15.
//  Copyright (c) 2015 jhow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "AsyncUdpSocket.h"

#import "Service.h"

@interface ViewController : UIViewController<AsyncUdpSocketDelegate, CBCentralManagerDelegate, CBPeripheralDelegate> {
    AsyncUdpSocket *_socket;
}

@property (strong, nonatomic) IBOutlet UITextField *Host;
@property (strong, nonatomic) IBOutlet UITextField *Port;
@property (strong, nonatomic) IBOutlet UITextField *label;
@property (strong, nonatomic) IBOutlet UIButton *Connect;
@property (strong, nonatomic) IBOutlet UIButton *Disconnect;
@property (strong, nonatomic) IBOutlet UILabel *BLEStatus;
@property (strong, nonatomic) IBOutlet UILabel *Package;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic) NSMutableDictionary *data;
@property (strong, nonatomic) NSDictionary *uuids;

- (IBAction)Connect_Click :(id)sender;
- (IBAction)Disconnect_Click:(id)sender;

- (NSString*) dec2acc: (unsigned int)dec;
- (NSString*) dec2deg: (unsigned int)dec;
@end

