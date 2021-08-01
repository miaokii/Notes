//
//  RealmDB.h
//  RealmDB
//
//  Created by Miaokii on 2021/7/29.
//

#import <Foundation/Foundation.h>
#import <realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RealmDBCallBack)(void);
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

// MARK: - 增

/// 增加或更新一个对象
/// @param object 数据对象
+ (void)addObject:(RLMObject *)object error:(NSError * _Nullable *)error complete:(RealmDBCallBack)complete;

/// 增加或更新多个数据对象
/// @param objects 数据对象集合
+ (void)addObjects:(NSArray <RLMObject *> *)objects error:(NSError * _Nullable *)error complete:(RealmDBCallBack)complete;

// MARK: - 删

+ (void)deleteObject:(RLMObject *)object error:(NSError * _Nullable *)error complete:(RealmDBCallBack)complete;

+ (void)deleteObjects:(NSArray <RLMObject *> *)objects error:(NSError * _Nullable *)error complete:(RealmDBCallBack)complete;

+ (void)deleteAllObjectFromObjectType:(id)objectType;

@end

NS_ASSUME_NONNULL_END
