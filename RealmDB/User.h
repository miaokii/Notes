//
//  User.h
//  RealmDB
//
//  Created by Miaokii on 2021/8/5.
//

#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@interface User : RLMObject

/// 主键
@property RLMObjectId * _id;
/// 姓名
@property NSString * name;
/// 性别 1男 0女
@property NSInteger gender;
/// 生日
@property NSDate * birth;
/// 头像
@property NSData * headImage;
///
//@property RLMArray<User> * friends;

@end

NS_ASSUME_NONNULL_END
