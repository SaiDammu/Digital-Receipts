//
//  bleDevMonitor.h
//  Qpp Client
//
//  Created by Derek on 12/05/13.
//  Copyright (c) 2012 QN Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif




#define voleDataUpdateNoti            @"voleDataNotification"


#define voleDidConnectNoti            @"voleDidConnectNotification"
#define voleDidDisconnectNoti         @"voleDidDisconnectNotification"
#define voleDidRetrieveNoti           @"voleDidRetrieveNotification"

#define voleCmdMetaDataWriteNoti      @"voleCmdMetaDataWriteNotification"
#define voleCmdBrickDataWriteNoti     @"voleCmdBrickDataWriteNotification"
#define voleCmdBinFileCheckNoti       @"voleCmdBinFileCheckNotification"
#define voleCmdBinFileDoneNoti        @"voleCmdBinFileDoneNotification"

#define voleMetaDataCarringNoti       @"voleMetaDataCarringNotification"
#define voleBrickDataCarryingNoti     @"voleBrickDataCarryingNotification"

#define voleScanPeriEndNoti           @"voleScanPeripheralsEndNotification"
#define voleSelOnePeripheralNoti      @"voleSelOnePeripheralNotification"


#define voleProgressStatusNoti        @"voleProgressStatusNotification"
#define voleUpdateDataRateNoti        @"voleUpdateDataRateNotification"

#define voleScanDevTimeoutNoti        @"voleScanDevTimeoutNotification"
#define voleConnectDevTimeoutNoti     @"voleConnectDevTimeoutNotification"
#define voleResumeTimeoutNoti         @"voleResumeTimeoutNotification"


//#define UUID_VoLE_SERVICE          @"CE208583-7925-499A-157E-B360340F9CDE"

//#define UUID_VoLE_SERVICE          @"0000FEE9-0000-1000-8000-00805F9B34FB"
//
//#define UUID_VoLE_NOTI             @"D44BC439-ABFD-45A2-B575-925416129601"
//#define UUID_VoLE_NOTI12           @"D44BC439-ABFD-45A2-B575-925416129602"
//
//#define UUID_VoLE_WRITE            @"D44BC439-ABFD-45A2-B575-925416129600"

//
#define UUID_VoLE_SERVICE          @"CC07"

#define UUID_VoLE_NOTI             @"CD01"
#define UUID_VoLE_NOTI12           @"CD0C"

#define UUID_VoLE_WRITE            @"CD20"


#define UPDATE_DATA_RATE_IN_TIME    1
#define UPDATE_DATA_RATE_INTERVAL   5

#define QPP_DATA_CHECK              0 // zfq
#define QPP_LOG_FILE                1 // zfq

#define TYPE_DEF_CMD                0x31

@class bleDevMonitor;

@protocol bleDevMonitorConnectionDelegate <NSObject>

- (void)bleDevMonitor:(bleDevMonitor *)client
    didDiscoverPeripheral:(CBPeripheral *)aPeripheral;
- (void)bleDevMonitor:(bleDevMonitor *)client
    didConnectPeripheral:(CBPeripheral *)aPeripheral;
- (void)bleDevMonitor:(bleDevMonitor *)client
    didDisconnectPeripheral:(CBPeripheral *)aPeripheral;
- (void)bleDevMonitor:(bleDevMonitor *)client
    didFailToConnectPeripheral:(CBPeripheral *)aPeripheral;

@end


@protocol bleDevMonitorUpdateDelegate <NSObject>

- (void)bleDevMonitor:(bleDevMonitor *)client
    didUpdateReceivedData:(NSData *)data;

@end


@interface bleDevMonitor : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) id<bleDevMonitorConnectionDelegate> connectionDelegate;
@property (nonatomic, assign) id<bleDevMonitorUpdateDelegate> updateDelegate;
@property (nonatomic, readonly, retain) NSMutableArray *discoveredPeripherals;

- (BOOL) isLECapableHardware;

- (void) startScan;
- (void) stopScan;

- (void) connectPeripheral:(CBPeripheral *)aPeripheral;
- (void) disconnect;
- (BOOL) isConnected;

- (BOOL) sendData:(uint8_t *)data
       withLength:(uint16_t)length
     withResponse:(BOOL)response;

- (NSString *)devName;

+ (bleDevMonitor *)sharedInstance;

@end
