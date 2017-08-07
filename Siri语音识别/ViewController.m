//
//  ViewController.m
//  Siri语音识别
//
//  Created by Sundear on 2017/8/7.
//  Copyright © 2017年 xiexin. All rights reserved.
//

#import "ViewController.h"
#import "SiriButton.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet SiriButton *ListenBtn;
@property (weak, nonatomic) IBOutlet UILabel *showLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [_ListenBtn AddListenBlock:^(NSString *ShortWord) {
        _showLabel.text = ShortWord;
    }];

}





@end
