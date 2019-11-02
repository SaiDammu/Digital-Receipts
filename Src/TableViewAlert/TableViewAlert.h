//
//  TableViewAlert.h
//
//  Version 1.0
//
//  Created by Fuquan.Zhang on 10/12/2013.
//  Copyright (c) 2013 Quintic Labs. All rights reserved.
//  For the complete copyright notice, read Source Code License.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class TableViewAlert;


// Blocks definition for table view management
typedef NSInteger (^TableViewAlertNumberOfRowsBlock)(NSInteger section);
typedef UITableViewCell* (^TableViewAlertTableCellsBlock)(TableViewAlert *alert, NSIndexPath *indexPath);
typedef void (^TableViewAlertRowSelectionBlock)(NSIndexPath *selectedIndex);
typedef void (^TableViewAlertCompletionBlock)(void);


@interface TableViewAlert : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *table;

@property (nonatomic, assign) CGFloat height;

@property (nonatomic, strong) TableViewAlertCompletionBlock completionBlock;	// Called when Cancel button pressed
@property (nonatomic, strong) TableViewAlertRowSelectionBlock selectionBlock;	// Called when a row in table view is pressed


// Classe method; rowsBlock and cellsBlock MUST NOT be nil 
+(TableViewAlert *)tableAlertWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelBtnTitle numberOfRows:(TableViewAlertNumberOfRowsBlock)rowsBlock andCells:(TableViewAlertTableCellsBlock)cellsBlock;

// Initialization method; rowsBlock and cellsBlock MUST NOT be nil
-(id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelBtnTitle numberOfRows:(TableViewAlertNumberOfRowsBlock)rowsBlock andCells:(TableViewAlertTableCellsBlock)cellsBlock;

// Allows you to perform custom actions when a row is selected or the cancel button is pressed
-(void)configureSelectionBlock:(TableViewAlertRowSelectionBlock)selBlock andCompletionBlock:(TableViewAlertCompletionBlock)comBlock;

// Show the alert
-(void)show;

@end

