//
//  bleDevMonitor.m
//  bleDevMonitor
//
//  Created by Derek on 12/05/13.
//  Copyright (c) 2012 QN Inc. All rights reserved.
//

#import "QBlueClient.h"

@interface bleDevMonitor ()
{
    CBCentralManager *_centralManager;
    CBPeripheral *_peripheral;
    NSMutableArray *_discoveredPeripherals;
    
    NSString *_manufacturer;
    BOOL _autoConnect;
    
    CBService *_service;
    CBCharacteristic *_wChar;
}

@end

@implementation bleDevMonitor
@synthesize connectionDelegate = _delegate, discoveredPeripherals = _discoveredPeripherals;
@synthesize updateDelegate = _updateDelegate;

- (id)init
{
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self
                                                              queue:nil];
        
        _discoveredPeripherals = [[NSMutableArray alloc] init];
        
        if (_autoConnect) {
            [self startScan];
        }
        
        _service = nil;
        _wChar = nil;
        
    }
    return self;
}

- (void)dealloc
{
    [self stopScan];
    _centralManager.delegate = nil;
    _peripheral.delegate = nil;
}

- (NSString *)devName
{
    return _peripheral.name;
}

+ (bleDevMonitor *)sharedInstance
{
    static bleDevMonitor *_sharedInstance = nil;
    if (_sharedInstance == nil) {
        _sharedInstance = [[bleDevMonitor alloc] init];
    }
    
    return _sharedInstance;
}

#pragma mark - Helpers


/*
 Update UI with Qpp data received from device
 */
- (void) updateWithQppReceivedData:(NSData *)data
{
    [_updateDelegate bleDevMonitor:self didUpdateReceivedData:data];
    
}

#pragma mark - Actions

/*
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE. An alert is raised if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([_centralManager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"isLECapableHardware: TRUE");
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    return FALSE;
}


/*
 Request CBCentralManager to scan for Qpp peripherals using service UUID 0xCC01:QPP
 */
- (void)startScan
{
    [_discoveredPeripherals removeAllObjects];
    [_centralManager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:UUID_VoLE_SERVICE]]
                                            options:nil];
}

/*
 Request CBCentralManager to stop scanning for Qpp peripherals
 */
- (void)stopScan
{
    [_centralManager stopScan];
}

- (void)connectPeripheral:(CBPeripheral *)aPeripheral
{
    [_centralManager connectPeripheral:aPeripheral options:nil];
    _peripheral = aPeripheral;
}


- (void)disconnect
{
    //    for (CBCharacteristic *aChar in _service.characteristics)
    //    {
    //        /* Write Qpp Server Received Data */
    //        if (NO == [aChar.UUID isEqual:[CBUUID UUIDWithString:@"CD20"]])
    //        {
    //            /* Cancel notification on Qpp Server Send Data, UUID should be within QPP_UUID_MIN and QPP_UUID_MAX */
    //            [_peripheral setNotifyValue:NO forCharacteristic:aChar];
    //            NSLog(@"Cancel a Notification of QPP Server Send Data Characteristic %@", aChar.UUID.description);
    //        }
    //    }
    [_centralManager cancelPeripheralConnection:_peripheral];
}

- (BOOL)isConnected
{
    //return [_peripheral isConnected];
    if (_peripheral.state != CBPeripheralStateConnected)
        return FALSE;
    else
        return TRUE;
}

- (BOOL) sendData:(uint8_t *)data
       withLength:(uint16_t)length
     withResponse:(BOOL)response
{
    if (length)
    {
        NSData* valData = [NSData dataWithBytes:(void*)data length:length];
        if (response == TRUE)
        {
            [_peripheral writeValue:valData forCharacteristic:_wChar type:CBCharacteristicWriteWithResponse];
        }
        else
        {
            [_peripheral writeValue:valData forCharacteristic:_wChar type:CBCharacteristicWriteWithoutResponse];
        }
        return TRUE;
    }
    
    return FALSE;
}

#pragma mark - CBCentralManagerDelegate

/*
 Invoked whenever the central manager's state is updated.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self isLECapableHardware];
}


- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)aPeripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
    //  [_discoveredPeripherals removeAllObjects];
    
    if( ![_discoveredPeripherals containsObject:aPeripheral] )
        [_discoveredPeripherals addObject:aPeripheral];
    
    
    /* Retreive already known devices */
    NSString *uuidString = [NSString stringWithFormat:@"%@", [[aPeripheral identifier] UUIDString]];
    NSUUID *nsUUID = [[NSUUID UUID] initWithUUIDString:uuidString];
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
//    NSData *manufacturerData = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
    [[NSUserDefaults standardUserDefaults] setValue:localName forKey:@"localName"];
    if(nsUUID)
    {
        NSArray *peripheralArray = [_centralManager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:nsUUID]];
    }
    if(_autoConnect)
    {
        //[_centralManager retrievePeripherals:[NSArray arrayWithObject:@[nsUUID]];
        [_centralManager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:nsUUID]];
    }
    NSLog(@"%@,%@",uuidString,nsUUID);
}


/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central
didRetrievePeripherals:(NSArray *)peripherals
{
   
  //  [self stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] > 0)
    {
        _peripheral = [peripherals objectAtIndex:0];
        [_centralManager connectPeripheral:_peripheral
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]
         ];
    }
}


/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central
   didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    NSLog(@"method: %s ", __func__);
    
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
    
    //zfq [_delegate bleDevMonitor:self didConnectPeripheral:aPeripheral];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:voleDidConnectNoti object:nil];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    if( _peripheral)
    {
        //zfq [_delegate bleDevMonitor:self didDisconnectPeripheral:aPeripheral];
        _peripheral.delegate = nil;
        _peripheral = nil;
    }
    
    NSLog(@"method: %s ", __func__);
    
    [[NSNotificationCenter defaultCenter]postNotificationName:voleDidDisconnectNoti object:nil];
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral
                 error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    
    if( _peripheral )
    {
        //zfq [_delegate bleDevMonitor:self didFailToConnectPeripheral:aPeripheral];
        [_peripheral setDelegate:nil];
        _peripheral = nil;
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    NSLog(@"method = %s", __func__);
}

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
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        /* GAP (Generic Access Profile) for Device Name */
        if ( [aService.UUID isEqual:[CBUUID UUIDWithString:@"1800"]] )
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* Device Information Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180A"]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* QPP Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:UUID_VoLE_SERVICE]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service
              error:(NSError *)error
{
   
    //  [[NSNotificationCenter defaultCenter] postNotificationName:<#(nonnull NSString *)#> object:<#(nullable id)#>];
    /* vardhman */
    if ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_VoLE_SERVICE]])
    {
        uint8_t i = 1;
        
        _service = service;
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Write Qpp Server Received Data */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUID_VoLE_WRITE]])
            {
                /* remember the characteristic */
                _wChar = aChar;
                // zfq NSLog(@"Found a QPP Server Received Data Characteristic CD20");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:[NSString stringWithFormat:@"CD0%x",i]]])
            {
                /* Set notification on Qpp Server Send Data, UUID should be within QPP_UUID_MIN and QPP_UUID_MAX */
                [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
                
                i++;
                
                // zfq NSLog(@"Found a QPP Server Send Data Characteristic %@", aChar.UUID.description);
            }
        }
    }
    
    //if ( [service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1800"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Read device name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A00"]])
            {
                [aPeripheral readValueForCharacteristic:aChar];
                // zfq NSLog(@"Found a Device Name Characteristic");
            }
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180A"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Read manufacturer name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]])
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Manufacturer Name Characteristic");
            }
        }
    }
}


/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
         [self updateWithQppReceivedData:characteristic.value];
    
    /* vardhman */
    /* Value for manufacturer name received */
 //   if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]])
   // {
     //   _manufacturer = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    //    NSLog(@"Manufacturer Name = %@", _manufacturer);
  //  }
    /* Updated value for Qpp Server Received Data, UUID should be within QPP_UUID_MIN and QPP_UUID_MAX */
    //else if ((characteristic.value) || !error )
    //{
        /* Update UI with Qpp Received data */
      //  [self updateWithQppReceivedData:characteristic.value];
    //}
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }

    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
}

/*
 Invoked upon completion of a -[writeValueForCharacteristic:] request.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    /* Write value with response received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"CD20"]])
    {
        NSLog(@"Send Data Error Code = %ld", (long)error.code);
        //        const uint8_t *p = [characteristic.value bytes];
        //        if (p[0] == TYPE_DEF_CMD)
        //        {
        //            ;
        //        }
        uint8_t type;
        [characteristic.value getBytes: &type length:1];
        if (type == TYPE_DEF_CMD)
        {
            NSLog(@"TYPE_DEF_CMD send successful!\n");
        }
    }
}

-(void) peripheralDidUpdateName:(CBPeripheral *)aPeripheral
{
    NSLog(@"peipheralDidUpdateName:%@", aPeripheral);
}

/*!
 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
 */
//- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
@end
