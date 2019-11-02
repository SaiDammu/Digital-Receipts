//
//  Book.m
//  ArrayControllerUndoSample
//
//  Created by Hiroshi Hashiguchi on 10/12/29.
//  Copyright 2010 . All rights reserved.
//

#import "qppApiCtrl.h"


@implementation qppApiCtrl

@synthesize name = name_;
@synthesize arrRSSI = arrRSSI_;
@synthesize arrDevList=arrDevList_;
@synthesize qppPeri;
@synthesize aQppWriteChar,aQppNtfChar;
@synthesize UUIDOfQppSvc,UUIDOfQppWrChar;

@synthesize fQppEnableStatus;

@synthesize lengOfPkg2Send, data2Send, intervalBtwPkg, pkgIdx,fQppWrRepeat,times;


@end
