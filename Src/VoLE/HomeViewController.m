//
//  HomeViewController.m
//  VoLE Demo
//
//  Created by Sai Seshu Sarath Chandra Dammu on 12/5/19.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

#import "HomeViewController.h"
#import "QBlueVoLEViewController.h"
#import "RootViewController.h"
#import "Extract-Swift.h"
#import "QppViewController.h"

@interface HomeViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
    NSArray *titlesArray;
}
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"VoLE";
    titlesArray = @[@"QPP",@"OTA",@"HRM",@"Graphs"];
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    UICollectionView *_collectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2) collectionViewLayout:layout];
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    [self.view addSubview:_collectionView];
    _collectionView.center = self.view.center;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [_collectionView setBackgroundColor:[UIColor whiteColor]];
    _collectionView.scrollEnabled = NO;
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return titlesArray.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];

   // cell.backgroundColor = [UIColor redColor];
    UIImageView *iconImageView = [UIImageView new];
    iconImageView.backgroundColor = [UIColor colorWithRed:7.0/255.0f green:192.0/255.0f blue:226.0/255.0f alpha:1.0];
    iconImageView.frame = CGRectMake(5, 0, cell.contentView.frame.size.width-10, cell.contentView.frame.size.height-30);
    //iconImageView.center = cell.contentView.center;
    [cell addSubview:iconImageView];
    iconImageView.layer.cornerRadius = 10.0;

    UILabel *titlelabel = [UILabel new];
    titlelabel.frame = CGRectMake(5, iconImageView.frame.size.height, iconImageView.frame.size.width, 30);
    titlelabel.text = [titlesArray objectAtIndex:indexPath.row];
    titlelabel.textAlignment = NSTextAlignmentCenter;
    titlelabel.font = [UIFont systemFontOfSize:20];
    titlelabel.textColor = [UIColor darkGrayColor];
    [cell addSubview:titlelabel];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((self.view.frame.size.width/2.5), (self.view.frame.size.width/2.5));
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    
    return UIEdgeInsetsMake(20, 20, 20, 20);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){
        
        QppViewController *qvc = [[QppViewController alloc]initWithNibName:@"QppViewController_iPhone" bundle:[NSBundle mainBundle]];
        [self.navigationController pushViewController:qvc animated:YES];
        
     /*   QBlueVoLEViewController *qbvc = [[QBlueVoLEViewController alloc]initWithNibName:@"QBlueVoLEViewController" bundle:[NSBundle mainBundle]];
        qbvc.enableTwoGraphs = NO;
        qbvc.view.backgroundColor = [UIColor whiteColor];
        [self.navigationController pushViewController:qbvc animated:YES];
      */
    }else if (indexPath.row == 1){
        RootViewController *rbvc = [[RootViewController alloc]initWithNibName:@"RootViewController" bundle:[NSBundle mainBundle]];
        [self.navigationController pushViewController:rbvc animated:YES];
    }else if (indexPath.row == 2){
        HRMViewController *hvc = [[HRMViewController alloc]init];
        [self.navigationController pushViewController:hvc animated:YES];
    }else if (indexPath.row == 3){
        
        HRMViewController *hvc = [[HRMViewController alloc]init];
        hvc.enableTwoGraphs = true;
        [self.navigationController pushViewController:hvc animated:YES];
        
    }
}

@end
