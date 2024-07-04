//
//  ViewController.m
//  SampleAppObjC
//
//  Created by Pallab Maiti on 11/03/22.
//

#import "ViewController.h"
@import Rudder;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self customTrackWithProperties];
    [self customTrackWithoutProperties];
}

// Custom Events
- (void)customTrackWithoutProperties{
   
    [[RSClient sharedInstance] track:@"Custom Track Without Properties"];
    
}
- (void)customTrackWithProperties{
    [[RSClient sharedInstance] track:@"Custom Track With Properties" properties:[self getCustomProperties]];
}

- (NSDictionary*) getCustomProperties {
    NSDictionary *property = @{
        @"key-1": @"value-1",
        @"key-2": @123
    };
    return property;
}

@end
