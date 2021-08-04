//
//  RealmDB.m
//  RealmDB
//
//  Created by Miaokii on 2021/7/29.
//

#import "RealmDB.h"

/// 单例RealmDB对象
static RealmDB * shareRealmDBObject = nil;
/// 单例RealmDB对象
#define shareDb [RealmDB shareInstance]

#define WeakObj(type) __weak typeof(type) type##Weak = type
#define StrongObj(type) __strong typeof(type##Weak) type##Strong = type##Weak

@interface RealmDB ()

/// db对象
@property (nonatomic, strong) RLMRealm * realm;
/// db路径
@property (nonatomic, copy) NSString   * dbPath;

+ (instancetype)shareInstance;

@end

@implementation RealmDB

// MARK: - Init
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareRealmDBObject = [[RealmDB alloc] init];
    });
    return shareRealmDBObject;
}

// https://docs.mongodb.com/realm/sdk/ios/quick-start/
// https://www.jianshu.com/p/deb2591217fc
- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"DB路径：%@", self.dbPath);
    }
    return self;
}

// MARK: - 创建与配置
+ (BOOL)openDBName:(NSString *)dbName {
    return [shareDb openDBName:dbName];
}

+ (BOOL)deleteDBName:(NSString *)dbName {
    NSURL * url = shareDb.realm.configuration.fileURL;
    if (!url)
        url = RLMRealmConfiguration.defaultConfiguration.fileURL;
    
    NSURL * lockUrl = [url URLByAppendingPathComponent:@"lock"];
    NSURL * managementUrl = [url URLByAppendingPathComponent:@"management"];
    
    NSArray * realmRuls = @[url, lockUrl, managementUrl];
    
    NSError * error = nil;
    for (NSURL * url in realmRuls) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        if (error)
            return false;
    }
    return true;
}

- (BOOL)openDBName:(NSString *)dbName {
    /// 数据库名称
    NSString * dbFileName = [NSString stringWithFormat:@"%@.realm", dbName];
    /// 数据库地址
    NSURL * dbUrl = [NSURL fileURLWithPath: [self.dbPath stringByAppendingPathComponent: dbFileName]];
    
    /// 默认配置
    RLMRealmConfiguration * configration = [RLMRealmConfiguration defaultConfiguration];
    // 修改路径
    configration.fileURL = dbUrl;
    // 是否只读
    configration.readOnly = false;
    // 是否加密
    configration.encryptionKey = nil;
    // 版本
    configration.schemaVersion = 0;
    
    // 迁移
    configration.migrationBlock = ^(RLMMigration * _Nonnull migration, uint64_t oldSchemaVersion) {
        // 迁移代码
        if (oldSchemaVersion < configration.schemaVersion) {
            
        }
    };
    
    // 设置默认配置
    RLMRealmConfiguration.defaultConfiguration = configration;
    
    // 创建
    NSError * error;
    self.realm = [RLMRealm realmWithConfiguration:configration error:&error];
    
    if (error){
        NSLog(@"数据库 %@ 创建或成功：%@", dbName, dbUrl.absoluteString);
        return false;
    }
    NSLog(@"数据库 %@ 创建或失败：%@", dbName, error.localizedDescription);
    return true;
}

// MARK: - Func
- (void)ed {
    
}

// MARK: - 增加
+ (void)addObject:(RLMObject *)object error:(NSError * _Nullable __autoreleasing *)error complete:(RealmDBCallBack)complete {
    [self addObjects:@[object] error:error complete:complete];
}

+ (void)addObjects:(NSArray <RLMObject *> *)objects error:(NSError * _Nullable *)error complete:(RealmDBCallBack)complete {
    
    if (!shareDb.realm) {
        return;
    }
    
    [shareDb.realm transactionWithBlock:^{
        [shareDb.realm addOrUpdateObjects:objects];
        complete();
    } error:error];
}

// MARK: - 删除

+ (void)deleteObject:(RLMObject *)object error:(NSError * _Nullable __autoreleasing *)error complete:(RealmDBCallBack)complete {
    [self deleteObjects:@[object] error:error complete:complete];
}

+ (void)deleteObjects:(NSArray<RLMObject *> *)objects error:(NSError * _Nullable __autoreleasing *)error complete:(RealmDBCallBack)complete {
    if (!shareDb.realm) {
        return;
    }
    
    [shareDb.realm transactionWithBlock:^{
        [shareDb.realm deleteObjects:objects];
        complete();
    }];
}

+ (void)deleteAllObjectFromObjectType:(id)objectType complete:(RealmDBCallBack)complete {
    if (!shareDb.realm) {
        return;
    }
    
    [shareDb.realm transactionWithBlock:^{
        [shareDb.realm deleteAllObjects];
        complete();
    }];
}

// MARK: - 改动
+ (void)updateObejct:(RLMObject *)object {
    [self updateObejcts:@[object]];
}

+ (void)updateObejcts:(NSArray<RLMObject *> *)objects {
    if (!shareDb.realm) {
        return;
    }
        
    [shareDb.realm transactionWithBlock:^{
        [shareDb.realm addObjects:objects];
    }];
}

+ (void)updateWithTranstionAction:(void (^)(void))action {
    if (!shareDb.realm) {
        return;
    }
        
    [shareDb.realm transactionWithBlock:^{
        action();
    }];
    
}

// MARK: - 查
+ (NSArray<RLMObject *> *)objectsForClass:(Class)className {
    RLMResults * results = [self quertyWithObjectTypeClass:className predicate:nil sortKey:nil ascending:false];
    return [self rlmResultToArray:results];
}

+ (NSArray<RLMObject *> *)objectsForClass:(Class)className predicate:(NSPredicate *)predicate {
    RLMResults * results = [self quertyWithObjectTypeClass:className predicate:predicate sortKey:nil ascending:false];
    return [self rlmResultToArray:results];
}

+ (NSArray<RLMObject *> *)objectsForClass:(Class)className predicate:(NSPredicate *)predicate sortKey:(NSString *)sortKey ascending:(BOOL)ascending {
    RLMResults * results = [self quertyWithObjectTypeClass:className predicate:predicate sortKey:sortKey ascending:ascending];
    return [self rlmResultToArray:results];
}

// MARK: - 私有查询方法
+ (RLMResults<RLMObject *> *)quertyWithObjectTypeClass:(Class)class predicate:(NSPredicate *)predicate sortKey:(NSString *)sortKey ascending:(BOOL)ascending {
    if (shareDb.realm)
        return nil;
    if ([class isSubclassOfClass:RLMObject.class]) {
        
        // 查询结果
        RLMResults * results;
        if (predicate)
            results = [class objectsInRealm:shareDb.realm withPredicate:predicate];
        else
            results = [class allObjectsInRealm:shareDb.realm];
        
        if (sortKey) {
            results = [results sortedResultsUsingKeyPath:sortKey ascending:ascending];
        }
        return results;
    } else {
        return nil;
    }
}

/// 将realm查询到的结果对象转换为数组返回
/// @param results 查询结果
+ (NSArray <RLMObject *> *)rlmResultToArray:(RLMResults *)results {
    NSMutableArray * array = [NSMutableArray array];
    for (int i = 0; i < results.count; i++) {
        [array addObject:[results objectAtIndex:i]];
    }
    return array.copy;
}

// MARK: - Getter
- (NSString *)dbPath {
    if (!_dbPath) {
//        NSString * homePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//        _dbPath = [homePath stringByAppendingPathComponent:@"DB"];
        _dbPath = @"/Users/miaokii/Desktop/DB";
        NSFileManager * fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:_dbPath]) {
            NSError * error;
            [fileManager createDirectoryAtPath:_dbPath withIntermediateDirectories:true attributes:@{} error:&error];
            
            if (error) {
                NSLog(@"创建数据库路径失败：%@", error);
            }
        }
    }
    return _dbPath;
}



@end
