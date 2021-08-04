//
//  ViewController.m
//  RealmDB
//
//  Created by Miaokii on 2021/7/29.
//

#import "ViewController.h"
#import "RealmDB.h"
#import "User.h"

@interface ViewController ()

@property (nonatomic, copy) NSString * dbName;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"Root";
    
    self.dbName = @"rlmDB";
}

- (IBAction)openDB:(id)sender {
    [RealmDB openDBName:self.dbName];
}

- (IBAction)addRecord:(id)sender {
    User * user = [[User alloc] init];
    user.name = [self randomStringLength:(arc4random()%15 + 1)];
    user.birth = [NSDate new];
    user.gender = arc4random()%2;
    
    NSError * error;
    [RealmDB addObject:user error:&error complete:^{
        NSLog(@"添加对象成功：%@", user.name);
    }];
    
    if (error) {
        NSLog(@"添加对象失败：%@", user.name);
    }
}

- (IBAction)queryRecord:(id)sender {
}
- (IBAction)modifyRecord:(id)sender {
}
- (IBAction)deleteRecord:(id)sender {
}
- (IBAction)predicateRecord:(id)sender {
}
- (IBAction)sortRecord:(id)sender {
}

- (NSString *)randomStringLength:(NSInteger)length {
    NSString * alphas = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
    NSInteger count = alphas.length;
    NSMutableString * str = [NSMutableString new];
    for (int i = 0; i < length; i++) {
        NSInteger index = arc4random()%(count-1);
        [str appendString:[alphas substringWithRange:NSMakeRange(index, 1)]];
    }
    return str.copy;
}

@end
