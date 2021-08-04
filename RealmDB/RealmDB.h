//
//  RealmDB.h
//  RealmDB
//
//  Created by Miaokii on 2021/7/29.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

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

/// 删除一个对象
/// @param object 删除的对象
/// @param error 错误信息
/// @param complete 删除成功的回调
+ (void)deleteObject:(RLMObject *)object error:(NSError * _Nullable *)error complete:(RealmDBCallBack)complete;

/// 删除多个对象
/// @param objects 删除的对象
/// @param error 错误信息
/// @param complete 删除成功的回调
+ (void)deleteObjects:(NSArray <RLMObject *> *)objects error:(NSError * _Nullable *)error complete:(RealmDBCallBack)complete;

/// 删除某个表的所有记录
/// @param objectType 表类型
+ (void)deleteAllObjectFromObjectType:(id)objectType complete:(RealmDBCallBack)complete;

// MARK: - 改

/// 更改一个对象
/// @param object 对象
+ (void)updateObejct:(RLMObject *)object;

/// 更改多个对象
/// @param objects 对象
+ (void)updateObejcts:(NSArray <RLMObject *> *)objects;

/// 更新操作
+ (void)updateWithTranstionAction:(void(^)(void))action;

// MARK: - 查

/// 查询某个类型的所有记录
/// @param className 表名，必须是RLMObject类型的子类
+ (NSArray<RLMObject *> *)objectsForClass:(Class)className;

/// 根据条件查询某个类型的所有记录
/// @param className 表名
/// @param predicate 查询条件
+ (NSArray<RLMObject *> *)objectsForClass:(Class)className predicate:(NSPredicate *)predicate;

/// 带排序的条件查询
/// @param className 表名
/// @param predicate 查询条件
/// @param sortKey 排序键
/// @param ascending 升序
+ (NSArray<RLMObject *> *)objectsForClass:(Class)className predicate:(NSPredicate *)predicate sortKey:(NSString *)sortKey ascending:(BOOL)ascending;

@end

NS_ASSUME_NONNULL_END
