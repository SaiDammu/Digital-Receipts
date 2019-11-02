//
//  Utils.m
//
//  Created by NXP on 8/5/14.
//  Copyright (c) 2015 NXP. All rights reserved.
//

#import "sys/utsname.h"
#import "Utils.h"

//#import "UIColor+Additions.h"
//#import "UIColor+FlatUI.h"

@implementation Utils

//+ (void)initUITabBarItem:(UIViewController *)viewController title:(NSString *)title imageName:(NSString *)imageName tag:(NSInteger) tag
//{
//    UIImage* tabBarItemSelectedImage = [UIImage imageNamed:imageName];
//    UIImage* tabBarItemImage = [tabBarItemSelectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    viewController.tabBarItem = [[UITabBarItem alloc]initWithTitle:title image:tabBarItemImage selectedImage:tabBarItemSelectedImage];
//    viewController.tabBarItem.tag = tag;
//    UIFont *font = [UIFont boldSystemFontOfSize:0.0];
//    [viewController.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithARGB:0xff1f2f44],NSForegroundColorAttributeName, font, NSFontAttributeName, nil] forState:UIControlStateNormal];
//    [viewController.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName, NSForegroundColorAttributeName, font, nil] forState:UIControlStateSelected];
//    viewController.tabBarItem.titlePositionAdjustment = UIOffsetMake(0, -0.5);
//}
//
//+ (void)initCSStyleButton:(FUIButton *)button
//{
//    button.buttonColor = [UIColor colorWithARGB:0xff1380ef];
//    button.shadowColor = [UIColor midnightBlueColor];
//    button.shadowHeight = 3.0f;
//    button.cornerRadius = 6.0f;
//    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
//    [button setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
//    [button setTitleColor:[UIColor cloudsColor] forState:UIControlStateSelected];
//}
//
//+ (NSString *)createUnkownDeviceName
//{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSInteger index = [defaults integerForKey:UNKNOWN_SEQUENCE] + 1;
//    [defaults setInteger:index forKey:UNKNOWN_SEQUENCE];
//    [defaults synchronize];
//    return [@"Unknown" stringByAppendingFormat:@"%ld", (long)index];
//}
//
//+ (BOOL)isLaunched
//{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    return [defaults boolForKey:LAUNCHED_KEY];
//}
//
//+ (void)setLaunched
//{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:YES forKey:LAUNCHED_KEY];
//    [defaults synchronize];
//}
//
//+ (BOOL)isSubordinate
//{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    return [defaults boolForKey:IS_SUBORDINATE];
//}
//
//+ (void)setSubordinate:(BOOL)isSubordinate
//{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:isSubordinate forKey:IS_SUBORDINATE];
//    [defaults synchronize];
//}

/// form comUtils
+ (Utils *)sharedInst
{
    static Utils *_sharedInstance = nil;
    
    if (_sharedInstance == nil) {
        _sharedInstance = [[Utils alloc] init];
    }
    
    return _sharedInstance;
}

-(u_int64_t)getCurenntTime{
///     u_int64_t preTimeMs;
    NSDate *  currentTime = [NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
    
    return [self getDateTimeTOMilliSeconds : currentTime];
}



/// pickup device number.
-(NSString *)bytesToString : (uint8_t *)_inBytes withLength : (uint8_t)_length{
    NSData *aData = [[NSData alloc] initWithBytes : _inBytes length : _length];
    
    /// Byte array­> Hex
    Byte *bytes = (Byte *)[aData bytes];
    
    NSString *hexStr = @"";
    
    for(int i=0;i<[aData length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];/// Hex
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    
    return hexStr;
}

-(NSData *)hexStrToBytes : (NSString *)hexString
              withStrMin : (int)strMin
              withStrMax : (long)strMax
{
    BOOL strValid = false;
    
    /// check length
    if(hexString.length >= strMax){
        hexString = [hexString substringToIndex : strMax];
    }
    
    /// check illegal edit
    NSMutableString *strEditedUpper = [[NSMutableString alloc ]initWithCapacity : strMax];
    /// NSLog(@"hexString : %@", hexString);
    
    [strEditedUpper setString: [hexString uppercaseString]];
    
    /// NSLog(@"strEditedUpper : %@", strEditedUpper);
    
    
    NSString *strSub = NULL;
    NSString *strRef = @"1234567890ABCDEF";
    
    NSRange strRange;
    
    for(int i = 0; i < strEditedUpper.length; i++)
    {
        unichar cStr = [strEditedUpper characterAtIndex : i];
        
        /// NSLog(@"cStr : %c", cStr);
        strSub = [NSString stringWithFormat:@"%c", cStr ];
        
        strRange = [strRef rangeOfString:strSub];
        
        if(strRange.length <= 0)
        {
            // NSLog(@"illegal str!");
            strValid = true;
            break;
        }
    }
    
    if(strValid)
        return NULL;
    
    /// strEdited = null
    if(strEditedUpper.length < strMin){
        return NULL;
    }
    
    /// odd string
    if(strEditedUpper.length % 2)
    {
        [strEditedUpper insertString:@"0" atIndex:0];
        /// NSLog(@"strEditedUpper:%@", strEditedUpper);
    }
    
    Byte j=0;
    
    Byte bytes[100];
    
    for(int i=0;i<[strEditedUpper length];i++)
    {
        Byte int_ch;  ///
        
        char hex_char1 = [strEditedUpper characterAtIndex:i]; //// high nibble
        Byte int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48) << 4;   //// 0 's Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55) << 4; //// A's Ascll - 65
        else
            int_ch1 = (hex_char1-87) << 4; //// a's Ascll - 97
        i++;
        
        
        char hex_char2 = [strEditedUpper characterAtIndex:i]; /// low nibble
        Byte int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48)&0x0f; //// 0 µÄAscll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = (hex_char2-55)&0x0f; //// A µÄAscll - 65
        else
            int_ch2 = (hex_char2-87)&0x0f; //// a µÄAscll - 97
        
        int_ch = int_ch1 | int_ch2 ;
        
        /// NSLog(@"int_ch=%x",int_ch);
        bytes[j] = int_ch;
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:[strEditedUpper length]>>1];
    
    return newData;
}

-(uint32_t)decStrToDec : (NSString *)decString
              withStrMin : (int)strMin
              withStrMax : (int)strMax
{
    BOOL strValid = false;
    
    /// check length
    if(decString.length >= strMax){
        decString = [decString substringToIndex : strMax];
    }
    
    /// check illegal edit
    NSMutableString *strEditedUpper = [[NSMutableString alloc ]initWithCapacity : strMax];
    /// NSLog(@"hexString : %@", hexString);
    
    [strEditedUpper setString: [decString uppercaseString]];
    
    /// NSLog(@"strEditedUpper : %@", strEditedUpper);
    
    
    NSString *strSub = NULL;
    NSString *strRef = @"1234567890ABCDEF";
    
    NSRange strRange;
    
    for(int i = 0; i < strEditedUpper.length; i++)
    {
        unichar cStr = [strEditedUpper characterAtIndex : i];
        
        /// NSLog(@"cStr : %c", cStr);
        strSub = [NSString stringWithFormat:@"%c", cStr ];
        
        strRange = [strRef rangeOfString:strSub];
        
        if(strRange.length <= 0)
        {
            // NSLog(@"illegal str!");
            strValid = true;
            break;
        }
    }
    
    if(strValid)
        return 0;
    
    /// strEdited = null
    if(strEditedUpper.length < strMin){
        return 0;
    }
    
    /// odd string
    if(strEditedUpper.length % 2)
    {
        [strEditedUpper insertString:@"0" atIndex:0];
        /// NSLog(@"strEditedUpper:%@", strEditedUpper);
    }
    
    uint32_t retData=0;
    
    for(int i=0;i<[strEditedUpper length];i++)
    {
        /// Byte int_ch=0;  ///
        
        char hex_char1 = [strEditedUpper characterAtIndex:i]; //// high nibble
        
        Byte int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48);   //// 0 's Ascll - 48
        else
            return 0; //// a's Ascll - 97
        
        /// NSLog(@"int_ch=%x",int_ch);
        retData = retData*10 + int_ch1;
    }
    
    return retData;
}

-(NSData *)bytesReversed : (char *)hexData
              withLength : (int)dataLength{
    
    Byte tempBytes[100];
    
    for(int i=0; i<dataLength;i++){
        tempBytes[i]=hexData[dataLength-i-1];
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:tempBytes length:dataLength];
    
    return  newData;
}

//-(NSString *)stringByReversed:(NSString *)_strToReverse withSegLength:(int)_segLeng{
//    NSString *strRevesed;
//    
//    if(_segLeng==2){
//        //        int length=(int)([_strToReverse length])>>1;
//        //        unsigned char p=0;
//        //        unsigned char *pBuffer=&p;
//        //
//        //        pBuffer=(unsigned char *)[[self hexStrToBytes:_strToReverse withStrMin:0 withStrMax:100] bytes];
//        //
//        //        NSMutableString *strToReverse=[[NSMutableString alloc] init];
//        //
//        //        for(int i=length-1;i>=0;i--){
//        //            [strToReverse appendString:[NSString stringWithFormat:@"%02x",pBuffer[i]]];
//        //        }
//        //
//        //        strRevesed=[strToReverse uppercaseString];
//        
//        unsigned char pBuffer[6];
//        [[_strToReverse hexToBytes] getBytes:pBuffer length:6];
//        strRevesed=[NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
//                    pBuffer[5], pBuffer[4], pBuffer[3], pBuffer[2], pBuffer[1], pBuffer[0]];
//    }
//    
//    return strRevesed;
//}

+ (NSString *) appleDeviceString
{
    // need #import "sys/utsname.h"
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    /// NSLog(@"deviceString: %@", deviceString);
    
    if([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    //
    if([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    //
    if([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    //
    if([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    //
    if([deviceString isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
    //
    if([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    //
    if([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    //
    if([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone 5C";
    //
    if([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone 5C";
    //
    if([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone 5";
    if([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5S";
    
    if([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6+";
    
    if([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    
    if([deviceString isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    //
    if([deviceString isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    //
    if([deviceString isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    //
    if([deviceString isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    //
    if([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    //
    if([deviceString isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    //
    if([deviceString isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    //
    if([deviceString isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    //
    if([deviceString isEqualToString:@"iPad2,5"])      return @"iPad mini";
    //
    if([deviceString isEqualToString:@"i386"])         return @"Simulator";
    //
    if([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    
    else return @"Unknown Apple device";
    //
    //    NSLog(@"NOTE: Unknown device type: %@", deviceString);
    
    return deviceString;
}


-(void)restartTimer:(NSTimer*)timer{
    [timer setFireDate:[NSDate distantPast]];
}

-(void)pauseTimer:(NSTimer*)timer{
    [timer setFireDate:[NSDate distantFuture]];
}

-(void)cancelTimer:(NSTimer*)timer{
    if(timer){
        [timer invalidate];
        timer = nil;
    }
}

-(NSDictionary *)getDictFromDefaultCases : (NSArray *)_arrInput{
    NSMutableDictionary *dictRet=[[NSMutableDictionary alloc] init];
    NSMutableArray *arrRet=[[NSMutableArray alloc] init];
    
//    NSArray *arrfileData = [_strInput componentsSeparatedByString:NSLocalizedString(@"<B R/>", nil)];
//    /// NSLog(@"%@ : %lu",arrfileData, (unsigned long)[arrfileData count]);
    
    for(int i=0; i<([_arrInput count]-1);i++){
        /// pickup key.
        NSString *cmdKey=[[_arrInput objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdKey=[cmdKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        i++;
        
        /// pickup cmd code
        NSString *cmdValue=[[_arrInput objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdValue=[cmdValue stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        cmdValue=[cmdValue stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *arrCmdStr = [cmdValue componentsSeparatedByString:NSLocalizedString(@",", nil)];
        
        /// NSMutableArray *arrCmd0=[[NSMutableArray alloc] init];
        NSMutableData *dataCmd=[[NSMutableData alloc] init];
        
        for(int j=0;j<[arrCmdStr count];j++){
            NSString *aCmd=[arrCmdStr objectAtIndex:j];
            [aCmd stringByReplacingOccurrencesOfString:@"," withString:@""];
            NSData *subDataCmd=[[Utils sharedInst] hexStrToBytes:aCmd withStrMin:0 withStrMax:10];
            [dataCmd appendData:subDataCmd];
        }
        
        [dictRet setObject:dataCmd forKey:cmdKey];
        [arrRet addObject:cmdKey];
    }
    
    return dictRet;
}
-(NSArray *)getKeysFromDefaultCases : (NSArray *)_defCmds{
    NSMutableArray *arrRet=[[NSMutableArray alloc] init];
    //
    //    NSArray *arrfileData = [_srcString componentsSeparatedByString:NSLocalizedString(@"<B R/>", nil)];
    /// NSLog(@"%@ : %lu",arrfileData, (unsigned long)[arrfileData count]);
    
    for(int i=0; i<([_defCmds count]-1);i++){
        /// pickup key.
        NSString *cmdKey=[[_defCmds objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdKey=[cmdKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        i++;
        [arrRet addObject:cmdKey];
    }
    
    return arrRet;
}

-(NSDictionary *)getAllKeysAndCmdsFromFile : (NSString *)_strInput{
    NSMutableDictionary *dictRet=[[NSMutableDictionary alloc] init];
    NSMutableArray *arrRet=[[NSMutableArray alloc] init];
    
    NSArray *arrfileData = [_strInput componentsSeparatedByString:NSLocalizedString(@"<BR/>", nil)];
    /// NSLog(@"%@ : %lu",arrfileData, (unsigned long)[arrfileData count]);
    
    for(int i=0; i<([arrfileData count]-1);i++){
        /// pickup key.
        NSString *cmdKey=[[arrfileData objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdKey=[cmdKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        i++;
        
        /// pickup cmd code
        NSString *cmdValue=[[arrfileData objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdValue=[cmdValue stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        cmdValue=[cmdValue stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *arrCmdStr = [cmdValue componentsSeparatedByString:NSLocalizedString(@",", nil)];
        
        /// NSMutableArray *arrCmd0=[[NSMutableArray alloc] init];
        NSMutableData *dataCmd=[[NSMutableData alloc] init];
        
        for(int j=0;j<[arrCmdStr count];j++){
            NSString *aCmd=[arrCmdStr objectAtIndex:j];
            [aCmd stringByReplacingOccurrencesOfString:@"," withString:@""];
            NSData *subDataCmd=[[Utils sharedInst] hexStrToBytes:aCmd withStrMin:0 withStrMax:10];
            [dataCmd appendData:subDataCmd];
        }
        
        [dictRet setObject:dataCmd forKey:cmdKey];
        
        [arrRet addObject:cmdKey];
    }
    
    return dictRet;
}

-(NSArray *)getKeysFromCasesFileString : (NSString *)_srcString{
    NSMutableArray *arrRet=[[NSMutableArray alloc] init];
    
    NSArray *arrfileData = [_srcString componentsSeparatedByString:NSLocalizedString(@"<BR/>", nil)];
    /// NSLog(@"%@ : %lu",arrfileData, (unsigned long)[arrfileData count]);
    
    for(int i=0; i<([arrfileData count]-1);i++){
        /// pickup key.
        NSString *cmdKey=[[arrfileData objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdKey=[cmdKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        i++;
        [arrRet addObject:cmdKey];
    }
    
    return arrRet;
}


/**********************************************************
 @breif : convert time with NSDate format into NSInteger,
 from 1970/1/1
 **********************************************************/
-(NSString *)getLocalDateAndTime{
    NSString *retStr=[self getLocalDate];
    retStr=[retStr stringByReplacingOccurrencesOfString:@" +0000" withString:@""];
    return retStr;
}

-(NSString *)getLocalDate{
    NSDate *  localTime = [NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
    
    return [NSString stringWithFormat: @"%@",[self getNowDateFromatAnyDate:localTime]];
}

- (uint64_t)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    
    uint64_t totalMilliseconds = interval*1000 ;
    
    return totalMilliseconds;
}

-(NSDate *)getNowDateFromatAnyDate:(NSDate *)anyDate{
    NSTimeZone *srcTimeZone=[NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSTimeZone *destTimeZone=[NSTimeZone localTimeZone];
    NSInteger srcGMTOffset=[srcTimeZone secondsFromGMTForDate:anyDate];
    NSInteger destGMTOffset=[destTimeZone secondsFromGMTForDate:anyDate];
    
    NSTimeInterval interval=destGMTOffset-srcGMTOffset;
    
    NSDate *destDateNow=[[NSDate alloc] initWithTimeInterval:interval sinceDate:anyDate];
    
    /// NSLog(@"destDateNow:%@",destDateNow);
    
    return destDateNow;
}

//
//// e.g. "My iPhone"
//+(NSString *)getDevName{
//    return [[UIDevice currentDevice] name];
//}
//
//// e.g. @"iPhone", @"iPod touch"
//+(NSString *)getDevModel{
//    return [[UIDevice currentDevice] model];
//}
//
// e.g. @"4.0"
+(NSString *)getDevSysVersion{
    // return [NSString stringWithFormat:@"%d", gestaltVersion];
    
    return [[UIDevice currentDevice] systemVersion];
    /// return [[[UIDevice currentDevice] systemVersion] floatValue];
}
@end
