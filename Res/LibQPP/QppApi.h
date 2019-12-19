//
//  QppApi.h
//  Qpp Demo
//
//  @brief Application Programming Interface Header File for Quintic Private Profile.
//
//  Created by NXP on 5/18/14.
//  Copyright (c) 2014 NXP. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "QBleClient.h"
#import "QbleQppClient.h"
#define didQppEnableConfirmForAppNoti               @"str-didQppEnableConfirmForApp-Noti"
#define keyPeriInQppEnableConfirmed             @"key-PeriInQppEnableConfirmForApp"
#define keyWrCharInQpp                          @"key-WrCharInQppEnableConfirmForApp"
#define keyNtfCharInQpp                         @"key-NtfCharInQppEnableConfirmForApp"

#define keyConfirmStatus                        @"key-StatusInQppEnableConfirmForApp"


#define _ENABLE_SUB_THREAD (1)

/// QPP receive data delegate.
@protocol qppReceiveDataDelegate

/**
 *****************************************************************
 * @brief APP receive data from QppApi Layer.
 *
 * @param[out]  aPeripheral          : the Peripheral connected. 
 * @param[out]  qppUUIDForNotifyChar : the Characteristic Notified.
 * @param[out]  qppData              : the data received.
 *
 *****************************************************************
 */
-(void)didQppReceiveData : (CBPeripheral *)aPeripheral
            withCharUUID : (CBUUID *)qppUUIDForNotifyChar
                withData : (NSData *)qppData;  

@end

/// QPP receive enablec onfirm delegate.
@protocol qppEnableConfirmDelegate

/**
 *****************************************************************
 * @brief APP receive data from QppApi Layer.
 *
 * @param[out]  aPeripheral     : the Peripheral connected.
 * @param[out]  qppEnableStatus : the qppEnableStatus enabled.
                                    STATE_QPP_CONFIRM_OK: all of the following four conditions are 
                                       satisfied,
                                       Qpp service discovered, 
                                       WrChar discovered, 
                                       NtfChar discovered
                                       NtfChar configured correctly.
 
                                    STATE_QPP_CONFIRM_FAILED
 *
 *****************************************************************
 */
 
/// -(void)didQppEnableConfirm : (CBPeripheral *)aPeripheral withStatus : (BOOL) qppEnableStatus;

@end

/// an Objective-C interface 
@interface QppApi : NSObject<bleUpdateForOtaDelegate,bleUpdateForQppDelegate>{
    
}

@property (nonatomic, assign) id <qppReceiveDataDelegate> ptReceiveDataDelegate;
///@property (nonatomic, assign) id <qppEnableConfirmDelegate> qppEnableConfirmDelegate;

/**
 *****************************************************************
 * @brief app register QPP's peripheral UUID and service UUID to Api layer.
 *
 * @param[in]  aPeripheral    : the peripheral connected.
 * @param[in]  qppServiceUUID : the service UUID to discover.
 * @param[in]  writeCharUUID  : the Characteristic UUID to write.
 *
 * @return none
 *****************************************************************
 */

- (void) qppEnable : (CBPeripheral *)aPeripheral
   withServiceUUID : (NSString *)qppServiceUUID
        withWrChar : (NSString *)writeCharUUID;

- (void) qppEnableNotify : (CBPeripheral *)aPeripheral
             withNtfChar : (CBCharacteristic *)ntfChar
               withEnable:(BOOL)enable;

/**
 *****************************************************************
 * @brief transfer data to QPP
 *
 * @param[in]  aPeripheral : the Peripheral connected.
 * @param[in]  qppData     : the data sent.
 * @param[in]  writeType   : the type written(refer to "typedef NS_ENUM(NSInteger, CBCharacteristicWriteType)" .
 *
 * @return none
 *****************************************************************
 */
-(void)qppSendData : (CBPeripheral *)aPeripheral
          withData : (NSData*)qppData
          withType : (CBCharacteristicWriteType)writeType;

#if _ENABLE_SUB_THREAD
-(void)startQppStateMachine;

-(void)qppStart:(CBPeripheral *)_objPeri
   withBlkInterval:(float)_interval
       withStart:(BOOL)fStart;
#endif

/**
 *****************************************************************
 * @brief QppApi class method.
 *
 * @param[out]  all methods.
 *
 * @return : none
 *****************************************************************
 */
+ (QppApi *)sharedInstance;

@end
