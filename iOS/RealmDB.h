//
//  RealmDB.h
//  RealmDB
//
//  Created by Miaokii on 2021/7/29.
//

#import <Foundation/Foundation.h>
#import <realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@interface RealmDB : NSObject

+ (instancetype)shareInstance;

// MARK: - 创建与配置

/// 根据数据库名字，创建并打开数据库，如果数据库不存在就创建后打开
/// @param dbName 数据库名称
+ (BOOL)openDBName:(NSString *)dbName;

/// 删除数据库
/// @param dbName 删除的名称
+ (BOOL)deleteDBName:(NSString *)dbName;

/// 删除所有数据库
+ (BOOL)deleteAllDB;

// MARK: - 增加
+ (void)addObject:(RLMObject *)object;

@end

NS_ASSUME_NONNULL_END
