//
//  Book.h
//  ArrayControllerUndoSample
//
//  Created by Hiroshi Hashiguchi on 10/12/29.
//  Copyright 2010 . All rights reserved.
//

/// #import <Cocoa/Cocoa.h>
/// #import "qppApiCtrl.h"

#import "QBleClient.h"

@interface qppApiCtrl : NSObject {

	NSString* name_;
	NSMutableArray *arrRSSI_;
    NSMutableArray *arrDevList_;
}

@property (nonatomic, copy) NSString* name;
@property (strong) NSMutableArray *arrRSSI;

@property(strong) NSMutableArray *arrDevList;

@property(strong) CBPeripheral *qppPeri;
@property(strong) CBCharacteristic *aQppWriteChar,*aQppNtfChar;
@property(strong) NSMutableString *UUIDOfQppSvc,*UUIDOfQppWrChar;

@property(readwrite) BOOL fQppEnableStatus;

@property(readwrite) float intervalBtwPkg;

@property(readwrite) int lengOfPkg2Send;
@property(strong) NSMutableData *data2Send;

@property(readwrite) uint64_t pkgIdx;
@property(readwrite) BOOL fQppWrRepeat;
@property(readwrite) uint16_t times;


@end
