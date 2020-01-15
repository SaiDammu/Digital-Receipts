//
//  QppApi.m
//  Qpp Demo
//
//  @brief Application Programming Interface Source File for Quintic Private Profile.
//
//  Created by NXP on 5/18/14.
//  Copyright (c) 2014 NXP. All rights reserved.
//

#import "QppApi.h"

#import "qppApiCtrl.h"


#define STATE_DISCOVERED_NONE      0x00
#define STATE_DISCOVERED_SERVICE   0x01
#define STATE_DISCOVERED_CHAR_WR   0x02
#define STATE_DISCOVERED_CHAR_NTF  0x04
#define STATE_CONFIRM_CHAR_NTF_OK  0x08

#define _ENABLE_UNIVERSAL_QPP_ (TRUE)

@interface QppApi ()
{
    CBPeripheral *qppPeripheral;    /// Qpp current Peripheral.
    NSString *uuidQppService;       /// Qpp Service    UUID .
    NSString *uuidQppCharWrite;     /// user CharWrite  UUID .
    
    CBCharacteristic *qppWrChar,*qppNtfChar;    /// Char for write
    
    int qppDiscoveryState;          /// qpp discovery svc/char/ state
    BOOL isOTA;
    
#if _ENABLE_SUB_THREAD
    /// write subthread
    NSThread *wrSubThread;
    NSCondition *lockWriteLoop;
    
    qppApiCtrl *objCtrl;
    
    NSTimer *repeatWrTimer;
    
    uint8_t qppWrData[512];
#endif
}

@end

@implementation QppApi

@synthesize ptReceiveDataDelegate;
/// @synthesize qppEnableConfirmDelegate;

- (id)init
{
    self = [super init];
    qppDiscoveryState = STATE_DISCOVERED_NONE;
    
    /// setup receive data callback delegate
    
   // [qBleClient sharedInstance].bleUpdateForOtaDelegate = self;
    [qBleQppClient sharedInstance].bleUpdateForQppDelegate = self;
#if _ENABLE_SUB_THREAD
    
    [self initQppApi];

#endif
    return self;
}

/**
 *****************************************************************
 * @brief QppApi class method.
 *
 * @return : all QppApi methods.
 *****************************************************************
 */

+ (QppApi *)sharedInstance
{
    static QppApi *_sharedInstance = nil;
    
    if (_sharedInstance == nil) {
        _sharedInstance = [[QppApi alloc] init];
    }
    
    return _sharedInstance;
}
-(void)initQppApi{
    lockWriteLoop=[[NSCondition alloc] init];
    
    objCtrl=[[qppApiCtrl alloc] init];
    
    objCtrl.times=40;
    objCtrl.lengOfPkg2Send=182;
    
    [self updateQppDataLength:objCtrl];
}

-(void)updateQppDataLength:(qppApiCtrl *)_devCtrl{
    for(int i=0; i<_devCtrl.lengOfPkg2Send;i++){
        qppWrData[i]=i;
    }
    
    _devCtrl.data2Send=[[NSMutableData alloc] initWithBytes:qppWrData length:_devCtrl.lengOfPkg2Send];
}


/**
 
 *****************************************************************
 * @brief app register QPP's peripheral UUID and service UUID to Api layer.
 *
 * @param[in]  qppServiceUUID : the service UUID to discover.
 * @param[in]  writeCharUUID  : the Characteristic UUID to write.
 *
 * @return none
 *****************************************************************
 */
- (void) qppEnable : (CBPeripheral *)aPeripheral
   withServiceUUID : (NSString *)qppServiceUUID
        withWrChar : (NSString *)writeCharUUID
{
    if(aPeripheral == NULL)
        return;
    
    NSLog(@"line : %d, func: %s ",__LINE__, __func__);
    
    qppPeripheral = aPeripheral;
    uuidQppService   = qppServiceUUID;
    uuidQppCharWrite = writeCharUUID;
    
#if _ENABLE_UNIVERSAL_QPP_
    if(uuidQppService == nil && uuidQppCharWrite==nil){
        
    }
#endif
    
    [qppPeripheral discoverServices : nil];
    
//#if _ENABLE_SUB_THREAD
//    [self startQppStateMachine:objCtrl];
//#endif
}

#if _ENABLE_SUB_THREAD
-(void)startQppStateMachine{
    [self startQppStateMachine:objCtrl];
}

-(void)cancelTimer:(NSTimer*)timer{
    if(timer){
        [timer invalidate];
        timer = nil;
    }
}

-(void)qppStart:(CBPeripheral *)_objPeri
      withBlkInterval:(float)_interval
            withStart:(BOOL)fStart{
    objCtrl.qppPeri=_objPeri;
    if(fStart){
        [self cancelTimer:repeatWrTimer];
        
        repeatWrTimer= [NSTimer scheduledTimerWithTimeInterval:_interval target:self selector:@selector(didRepeatWrData:) userInfo:objCtrl repeats:YES];
    }else{
        objCtrl.fQppWrRepeat=FALSE;
        
        [self trigOneWriteBlock];
    }
}



-(void)startQppStateMachine:(qppApiCtrl *)_objCtrl{
    /// start thread
    _objCtrl.fQppWrRepeat=TRUE;
    [self hstWriteLoopStart :_objCtrl];
}

-(void)trigOneWriteBlock{
    /// NSLog(@"to triger OneWrite Loop...");
    [lockWriteLoop lock];
    [lockWriteLoop signal];
    [lockWriteLoop unlock];
}

- (void) hstWriteLoopStart:(qppApiCtrl *)_objCtrl
{
    NSLog(@"wrSubThread : %@ ", wrSubThread );
    
    if (!wrSubThread || [wrSubThread isFinished]) {
        if ([[NSThread currentThread] isMainThread]) {
            wrSubThread = [[NSThread alloc] initWithTarget:self
                                                  selector:@selector(onWriteloopInBackground:)
                                                    object:_objCtrl];
            
            [wrSubThread start];
        } else {
            wrSubThread = [NSThread currentThread];
            
            [self onWriteloopInBackground:_objCtrl];
        }
    }
}

- (void)onWriteloopInBackground:(qppApiCtrl *)_objCtrl
{
    NSLog(@"write data start !" );
    while(_objCtrl.fQppWrRepeat){
        [lockWriteLoop lock];
        [lockWriteLoop wait];
        /// NSLog(@"write data ... !" );
        [self blockDataCarrying :_objCtrl];
        [lockWriteLoop unlock];
    }
    
    NSLog(@"write data exit !" );
}

-(void)blockDataCarrying:(qppApiCtrl *)_objCtrl{
    for(uint32_t i=0; i<_objCtrl.times;i++){
        [self refreshQppDataToSend:_objCtrl];
        [self qppSendData : _objCtrl.qppPeri
                   withData : _objCtrl.data2Send
                   withType : CBCharacteristicWriteWithoutResponse ];
    }
}

-(void)didRepeatWrData:(NSTimer *)_tmr {
    /// qppApiCtrl *_objCtrl=[_tmr userInfo];
    
    // _objCtrl.pkgIdx++;
    /// [self refreshQppDataToSend:_objCtrl];
    
#if 1 /// _ENABLE_BACKCODE
    [self trigOneWriteBlock];
#endif
    
    /// self.repeatCounterLbl.text=[NSString stringWithFormat:@"%llu", _devInfo.pkgIdx];
}

-(void)refreshQppDataToSend:(qppApiCtrl *)_objCtrl{
    ///qppWrData[0]=_devInfo.pkgIdx;
    uint16_t header=_objCtrl.pkgIdx++; /// todo more.
    /// _devInfo.data2Send=[[NSData alloc] init];
    /// _devInfo.data2Send=[NSData dataWithBytes:&qppWrData length:QPP_ LENGTH_AT_BLE4_2];
    NSRange headerRang;
    headerRang.length=sizeof(header);
    headerRang.location=0;
    
    [_objCtrl.data2Send replaceBytesInRange:headerRang withBytes:&header length:sizeof(header)];
}

#endif

/**
 *****************************************************************
 * @brief       delegate ble update service and chara.
 *
 * @param[out]  charValue : the data from a char.
 *
 *****************************************************************
 */
-(void)bleDidUpdateCharForQppService : (CBPeripheral *)aPeri
                         withService : (CBService *)aService
                               error : (NSError *)error
{
    NSNumber *qppStatus = @0;
    
    if(qppPeripheral == aPeri) /// lib version 1.1
    {
        /// D44BC439-ABFD-45A2-B575-925416129600
        NSLog(@"line : %d, aService.UUID: %@ ",__LINE__, aService.UUID);
      
#if !_ENABLE_UNIVERSAL_QPP_
        if ([aService.UUID isEqual:[CBUUID UUIDWithString : uuidQppService]])
#endif
        {
            qppDiscoveryState |= STATE_DISCOVERED_SERVICE;
            
            for (CBCharacteristic *aChar in aService.characteristics)
            {
                /// NSLog(@"line : %d, aChar.properties: %d ",__LINE__, aChar.properties);
                if((aChar.properties & CBCharacteristicPropertyWriteWithoutResponse)
                   == CBCharacteristicPropertyWriteWithoutResponse)
                {      
#if !_ENABLE_UNIVERSAL_QPP_
                    if([aChar.UUID isEqual:[CBUUID UUIDWithString : uuidQppCharWrite]])
#endif
                    {
                        qppDiscoveryState |= STATE_DISCOVERED_CHAR_WR;
                        qppWrChar = aChar;
                    }
                }
                else if (aChar.properties == CBCharacteristicPropertyNotify)
                {
                    qppDiscoveryState |= STATE_DISCOVERED_CHAR_NTF;
                    /// [aPeri setNotifyValue : YES forCharacteristic : aChar];
                    qppNtfChar=aChar;
                }
            }
            
            qppDiscoveryState |= STATE_CONFIRM_CHAR_NTF_OK;
            if(qppDiscoveryState & (STATE_DISCOVERED_SERVICE | STATE_DISCOVERED_CHAR_WR | STATE_DISCOVERED_CHAR_NTF | STATE_CONFIRM_CHAR_NTF_OK))
                qppStatus = @1;
            
            ///[qppEnableConfirmDelegate didQppEnableConfirm : aPeris withStatus : qppStatus];
            NSDictionary *dictStatus=[[NSDictionary alloc] initWithObjectsAndKeys:
                                      aPeri,keyPeriInQppEnableConfirmed,
                                      qppWrChar,keyWrCharInQpp,
                                      qppNtfChar,keyNtfCharInQpp,
                                      qppStatus,keyConfirmStatus, nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:didQppEnableConfirmForAppNoti object:dictStatus userInfo:nil];
        }
    }
}



/**
 *****************************************************************
 * @brief       delegate ble update value for Char.
 *
 * @param[out]  charValue : the data from a char.
 *
 *****************************************************************
 */
-(void)bleDidUpdateValueForQppChar : (CBPeripheral*)aPeripheral
                       withService : (CBService *)aService
                          withChar : (CBCharacteristic *)characteristic
                             error : (NSError *)error
{
    /// NSLog(@"uuidQppService : %@", uuidQppService);
    
    if ([aService.UUID isEqual:[CBUUID UUIDWithString : uuidQppService]])
    {
        if(objCtrl.lengOfPkg2Send !=[characteristic.value length]){
            [self updateQppDataLength:objCtrl];
        }
        
        [ptReceiveDataDelegate didQppReceiveData : aPeripheral
                                    withCharUUID : characteristic.UUID
                                        withData : characteristic.value];
    }
}

/**
 *****************************************************************
 * @brief       delegate ble update value for Char.
 *
 * @param[out]  charValue : the data from a char.
 *
 *****************************************************************
 */
-(void)bleDidUpdateStateForChar : (CBCharacteristic *)characteristic error : (NSError *)error
{
    /// NSLog(@"line : %d, func: %s ",__LINE__, __func__);

    //// NSLog(@"%s , characteristic :%@", __func__, characteristic.value);
}

- (void) qppEnableNotify : (CBPeripheral *)aPeripheral
             withNtfChar : (CBCharacteristic *)ntfChar
               withEnable:(BOOL)enable{
    if (ntfChar != nil){
        
        [aPeripheral setNotifyValue:enable forCharacteristic:ntfChar];
        
}

}

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
-(void)qppSendData : (CBPeripheral *)aPeri
          withData : (NSData*)qppData
          withType : (CBCharacteristicWriteType)writeType

{
    [aPeri writeValue : qppData
    forCharacteristic : qppWrChar
                 type : writeType/* CBCharacteristicWriteWithoutResponse */];
}

@end
