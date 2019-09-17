//
//  ViewController.m
//  KJToolGatherDemo
//
//  Created by 杨科军 on 2019/8/29.
//  Copyright © 2019 杨科军. All rights reserved.
//

#import "ViewController.h"
#import "KJScanVC.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)XXXXXX:(UIButton *)sender {
    KJScanVC *vc = [KJScanVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
