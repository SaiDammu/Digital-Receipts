//
//  QbleQppClient.h
//  VoLE Demo
//
//  Created by Sai Seshu Sarath Chandra Dammu on 12/3/19.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

///// to notify discovered a peripheral to app layer
#define blePeriDiscoveredNotiQpp                      @"ble-PeriDiscoveredNoti"
///// to notify discovered Services to app layer
#define bleDiscoveredServicesNotiQpp                  @"ble-ServicesDiscoveredNoti"

/// to notify discovered Services to app layer
#define bleDiscoveredCharacteristicsNotiQpp            @"ble-CharacteristicsDiscoveredNoti"

#define keyQppPeriWrittenQpp              @"key-QppPeriWritten"
/// to notify write rsp to app layer
#define bleWriteValueForCharNotiQpp           @"ble-WriteValueForCharNoti"

/// for Qpp
#define didBleUpdateValueForQppCharNotiQpp        @"str-didBleUpdateValueForQppChar-Noti"
#define keyPeriInUpdateValueForQppCharNotiQpp       @"key-PeriInUpdateValueForQppChar"
#define keySvcInUpdateValueForQppCharNotiQpp        @"key-SvcInUpdateValueForQppChar"
#define keyCharInUpdateValueForQppCharNotiQpp       @"key-CharInUpdateValueForQppChar"
#define keyErrorInUpdateValueForQppCharNotiQpp      @"key-ErrorInUpdateValueForQppChar"




@interface QbleQppClient : NSObject

@end



@protocol bleDidConnectionsDelegate

/**
 *****************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 *****************************************************************
 */
-(void)bleDidConnectPeripheral : (CBPeripheral *)aPeripheral;

/**
 *****************************************************************
 * @brief       delegate ble update disconnected peripheral.
 *
 * @param[out]  aPeripheral : the disconnected peripheral.
 * @param[out]  error
 *
 *****************************************************************
 */
-(void)bleDidDisconnectPeripheral : (CBPeripheral *)aPeripheral error : (NSError *)error;

/**
 *****************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 *****************************************************************
 */
/// -(void)bleDidRetrievePeripheral : (NSArray *)aPeripheral;

/**
 *****************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 *****************************************************************
 */
-(void)bleDidFailToConnectPeripheral : (CBPeripheral *)aPeripheral
                               error : (NSError *)error;

@end

/// ble update for char delegate.
@protocol bleUpdateForQppDelegate

/**
 *****************************************************************
 * @brief       delegate ble update service and chara.
 *
 * @param[out]  aPeripheral    : the peripheral connected.
 * @param[out]  aService       : the QPP service discovered.
 * @param[out]  error          : the error from CoreBluetooth.
 *
 *****************************************************************
 */
-(void)bleDidUpdateCharForQppService : (CBPeripheral *)aPeri
                         withService : (CBService *)aService
                               error : (NSError *)error;

/**
 *****************************************************************
 * @brief       delegate ble update value for Char.
 *
 * @param[out]  aPeripheral    : the peripheral connected.
 * @param[out]  aService       : the QPP service discovered.
 * @param[out]  characteristic : the QPP characteristic updated.
 * @param[out]  error          : the error from CoreBluetooth.
 *
 *****************************************************************
 */
-(void)bleDidUpdateValueForQppChar : (CBPeripheral*)aPeripheral
                       withService : (CBService *)aService
                          withChar : (CBCharacteristic *)characteristic
                             error : (NSError *)error;

@end


@class qBleQppClient;

/// declare qBleClient interface
@interface qBleQppClient : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>{
    
}

/// update Connection/Disconnect/Retrieve/FailtoConnect Peripheral.
@property (nonatomic, assign) id <bleDidConnectionsDelegate> bleDidConnectionsDelegate;

/// update value/state for char to xxx Profile
@property (nonatomic, assign) id <bleUpdateForQppDelegate>  bleUpdateForQppDelegate;

/**********************************************************************
 * @brief output these discovered peripherals after scanning.
 *
 **********************************************************************/
@property (nonatomic, readonly, retain) NSMutableArray *discoveredPeripherals;
/**********************************************************************
 * @brief output these discovered peripherals after scanning.
 *
 **********************************************************************/
@property (nonatomic, readonly, retain) NSMutableArray *discoveredServices;
/**
 **********************************************************************
 * @brief Represents the current state of a CBCentralManager.
 *
 * @return : TRUE  (CBCentralManagerStatePoweredOn)
 *           FALSE (others).
 *
 * @ref    enum CBCentralManagerState
 **********************************************************************
 */
- (BOOL) isLECapableHardware;


/**
 **********************************************************************
 * @brief scan all ble peripherals.
 *
 **********************************************************************
 */
- (void) startScan;

/**
 **********************************************************************
 * @brief stop scan.
 *
 **********************************************************************
 */
- (void) stopScan;

/**
 **********************************************************************
 * @brief Api Or App layer to connect a peripheral
 *
 * @param[in] aPeripheral  : peripheral to connect
 *
 **********************************************************************
 */
- (void) pubConnectPeripheral:(CBPeripheral *)aPeripheral;

/**
 **********************************************************************
 * @brief Api Or App layer to disconnect a peripheral
 *
 * @param[in] aPeripheral  : peripheral to connect
 *
 **********************************************************************
 */
- (void) pubDisconnectPeripheral:(CBPeripheral *)aPeripheral;

/**
 **********************************************************************
 * @brief Api Or App layer to retrieve a Peripheral
 *
 * @param[in] aPeripheral  : peripheral to connect
 *
 **********************************************************************
 */
- (void) pubRetrievePeripheral:(CBPeripheral *)aPeripheral;

+ (qBleQppClient *)sharedInstance;

@end

