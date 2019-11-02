//
//  Utils.h
//
//  Created by NXP on 10/25/15.
//  Copyright (c) 2015 NXP. All rights reserved.
//

///#import "FUIButton.h"
/// #import <Cocoa/Cocoa.h>

#define UNKNOWN_SEQUENCE        @"UNKNOWN_SEQUENCE"
#define LAUNCHED_KEY            @"LAUNCHED_KEY"
#define IS_SUBORDINATE          @"IS_SUBORDINATE"

#define CONTROL_OPERATION       LK_OP_CONTROL_COMMAND

@interface Utils : NSObject
 

//+ (void)initUITabBarItem:(UIViewController *)viewController title:(NSString *)title imageName:(NSString *)imageName tag:(NSInteger)tag;
//
//
//+ (void)initCSStyleButton:(FUIButton *)button;
//
//+ (NSString *)createUnkownDeviceName;
//
//+ (BOOL)isLaunched;
//+ (void)setLaunched;
//
//+ (BOOL)isSubordinate;
//+ (void)setSubordinate:(BOOL)isSubordinate;

-(NSData *)hexStrToBytes : (NSString *)hexString
              withStrMin : (int)strMin
              withStrMax : (long)strMax ;

-(uint32_t)decStrToDec : (NSString *)decString
        withStrMin : (int)strMin
        withStrMax : (int)strMax;

-(NSData *)bytesReversed : (char *)hexData
              withLength : (int)dataLength;

/// -(NSString *)stringByReversed:(NSString *)_strToReverse withSegLength:(int)_segLeng;

-(NSString *)bytesToString : (uint8_t *)_inBytes
                withLength : (uint8_t)_length;




-(void)restartTimer:(NSTimer*)timer;
-(void)pauseTimer:(NSTimer*)timer;
-(void)cancelTimer:(NSTimer*)timer;

-(u_int64_t)getCurenntTime;


-(NSDictionary *)getAllKeysAndCmdsFromFile : (NSString *)_srcString;

-(NSArray *)getKeysFromCasesFileString : (NSString *)_srcString;

-(NSDictionary *)getDictFromDefaultCases : (NSArray *)_input;
-(NSArray *)getKeysFromDefaultCases : (NSArray *)_defCases;

-(NSString *)getLocalDate;

-(NSString *)getLocalDateAndTime;

+ (NSString *) appleDeviceString;

//// e.g. "My iPhone"
//+(NSString *)getDevName;
//
//// e.g. @"iPhone", @"iPod touch"
//+(NSString *)getDevModel;

// e.g. @"4.0"
+(NSString *)getDevSysVersion;

+ (Utils *)sharedInst;

//+ (void)updateGroupsOperationAccordingDeviceOperation:(DeviceOperationTable *)deviceOperation;


@end
