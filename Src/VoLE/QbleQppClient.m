//
//  QBleClient.m
//  Qpp Demo
//
// @brief Application Programming Interface Source File for NXP Ble Client.
//
//  Created by NXP on 5/18/14.
//  Copyright (c) 2014 NXP. All rights reserved.
//

#import "QbleQppClient.h"

@interface qBleQppClient ()
{
    CBCentralManager *_centralManager;
    CBPeripheral     *_peripheral;
    
    NSMutableArray   *_discoveredPeripherals;
    
    BOOL _autoConnect;
}

@end

@implementation qBleQppClient

@synthesize bleDidConnectionsDelegate;
@synthesize bleUpdateForQppDelegate;
@synthesize discoveredPeripherals = _discoveredPeripherals;

- (id)init
{
    self = [super init];
    
    if (self) {
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        
        ///
        _discoveredPeripherals = [[NSMutableArray alloc] init];
        
        if (_autoConnect) {
            [self startScan];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [self stopScan];
    _centralManager.delegate = nil;
    _peripheral.delegate = nil;
}

+ (qBleQppClient *)sharedInstance
{
    static qBleQppClient *_sharedInstance = nil;
    if (_sharedInstance == nil) {
        _sharedInstance = [[qBleQppClient alloc] init];
    }
    
    return _sharedInstance;
}

#pragma mark - Actions

/**********************************************************************
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE.
 An alert is raised if Bluetooth LE is not enabled or is not supported.
 
 CBCentralManagerStateUnknown = 0,
 CBCentralManagerStateResetting,
 CBCentralManagerStateUnsupported,
 CBCentralManagerStateUnauthorized,
 CBCentralManagerStatePoweredOff,
 CBCentralManagerStatePoweredOn ONLY maps to TRUE
 
 **********************************************************************/
- (BOOL) isLECapableHardware
{
    switch ([_centralManager state])
    {
        case CBCentralManagerStateUnsupported:
            NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"Bluetooth is currently powered off.");
            break;
        case CBCentralManagerStatePoweredOn:
        {
            NSLog(@"isLECapableHardware: TRUE");
            /// NSArray *uuidArray  = [NSArray arrayWithObjects:[CBUUID UUIDWithString:@"FEE9"], nil];
            
            /// NSDictionary    *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
            [_centralManager scanForPeripheralsWithServices:nil
                                                    options:nil];
        }
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    return FALSE;
}

/*********************************************************************
 start Scan Peripherals
 *********************************************************************/
- (void)startScan
{
    [_discoveredPeripherals removeAllObjects];
    
    [_centralManager scanForPeripheralsWithServices:nil
                                            options:nil];
}

/*********************************************************************
 stop Scan Peripherals
 *********************************************************************/
- (void)stopScan
{
    [_centralManager stopScan];
}

/*********************************************************************
 connect a Peripheral
 Para[In] aPeripheral  : peripheral to connect
 *********************************************************************/
- (void)pubConnectPeripheral:(CBPeripheral *)aPeripheral
{
    [_centralManager connectPeripheral : aPeripheral options : nil];
    
    _peripheral = aPeripheral;
}

/*********************************************************************
 disconnect a Peripheral
 Para[In]  aPeripheral  : to disconnect
 *********************************************************************/
- (void)pubDisconnectPeripheral:(CBPeripheral *)aPeripheral
{
    [_centralManager cancelPeripheralConnection : aPeripheral ];
}

/*********************************************************************
 retrieve a Peripheral
 Para[In] aPeripheral  : the peripheral to retrieve
 *********************************************************************/
-(void)pubRetrievePeripheral:(CBPeripheral *)aPeripheral
{
    
    ///[_centralManager retrievePeripherals:[NSArray arrayWithObject:(id)aPeripheral.UUID]];
#if QPP_IOS8
    [_centralManager retrievePeripherals : [NSArray arrayWithObject:(id)aPeripheral.identifier /*UUID*/]];
#endif
    
#if 1///  QPP_IOS9
    [_centralManager connectPeripheral:aPeripheral options:nil ];
#endif
}

#pragma mark - CBCentralManagerDelegate

/*
 Invoked whenever the central manager's state is updated.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self isLECapableHardware];
}

/*
 Invoked when the central discovers Qpp peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)aPeripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
    if( ![_discoveredPeripherals containsObject:aPeripheral] )
    {
        [_discoveredPeripherals addObject:aPeripheral];
        
        /// if([aPeripheral isEqual: @"aaa"])
        [[NSNotificationCenter defaultCenter] postNotificationName: blePeriDiscoveredNotiQpp object:nil userInfo : nil];
    }
    
    /* Retreive already known devices */
    if(_autoConnect)
    {
#if QPP_IOS8
        /// [_centralManager retrievePeripherals:[NSArray arrayWithObject:(id)aPeripheral.UUID]];
        [_centralManager retrievePeripherals : [NSArray arrayWithObject:(id)aPeripheral.identifier /*UUID*/]];
#endif
        
#if 1///  QPP_IOS9
        [_centralManager connectPeripheral:aPeripheral options:nil ];
#endif
    }
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
//- (void)centralManager:(CBCentralManager *)central
//didRetrievePeripherals : (NSArray *)peripherals
//{
//    [self stopScan];
//
//    /* If there are any known devices, automatically connect to it.*/
//    if([peripherals count] > 0)
//    {
//        _peripheral = [peripherals objectAtIndex : 0];
//
//        [_centralManager connectPeripheral:_peripheral
//                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]
//         ];
//    }
//}

/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void) centralManager : (CBCentralManager *)central
   didConnectPeripheral : (CBPeripheral *)aPeripheral
{
    [aPeripheral setDelegate : self];
#if __QPP_ENABLE_
    [aPeripheral discoverServices : nil];
#endif
    
    [bleDidConnectionsDelegate bleDidConnectPeripheral : aPeripheral];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager      : (CBCentralManager *)central
    didDisconnectPeripheral : (CBPeripheral *)aPeripheral
                      error : (NSError *)error
{
    if( aPeripheral)
    {
        [bleDidConnectionsDelegate bleDidDisconnectPeripheral : aPeripheral error :error];
        
        aPeripheral.delegate = nil;
        aPeripheral = nil;
    }
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager : (CBCentralManager *)central
    didFailToConnectPeripheral : (CBPeripheral *)aPeripheral
                 error : (NSError *)error
{
    if( aPeripheral )
    {
        [bleDidConnectionsDelegate bleDidFailToConnectPeripheral : aPeripheral error :error];
        
        [aPeripheral setDelegate:nil];
        aPeripheral = nil;
    }
}

///*
// Invoked whenever the central manager retrieve to create a connection with the peripheral.
// */
//- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
//{
//    [bleDidConnectionsDelegate bleDidRetrievePeripheral : peripherals];
//}

#pragma mark - CBPeripheralDelegate

/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral
    didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
        [aPeripheral discoverCharacteristics:nil forService:aService];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName : bleDiscoveredServicesNotiQpp
                                                        object : nil
                                                      userInfo : nil];
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */

- (void) peripheral:(CBPeripheral *)aPeripheral
    didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    /// for quintic profile delegate
    [bleUpdateForQppDelegate bleDidUpdateCharForQppService : aPeripheral
                                            withService : service
                                                  error : error];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: bleDiscoveredCharacteristicsNotiQpp object:nil userInfo:nil];
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    ///NSLog(@"value : %@", characteristic.value);
    
    for (CBService *aService in aPeripheral.services)
    {
        [bleUpdateForQppDelegate bleDidUpdateValueForQppChar : aPeripheral
                                                 withService : aService
                                                    withChar : characteristic
                                                       error : error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    ///NSLog(@"func : %s", __func__);
}
//- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
//
//}
/*
 Invoked upon completion of a -[writeValueForCharacteristic:] request.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    /// NSLog(@"func : %s", __func__);
    
    NSDictionary *dictPeri = [NSDictionary dictionaryWithObject : aPeripheral forKey:keyQppPeriWritten];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: bleWriteValueForCharNotiQpp object:nil userInfo : dictPeri];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    NSLog(@"func : %s", __func__);
}

@end
