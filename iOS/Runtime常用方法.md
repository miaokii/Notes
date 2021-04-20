# Runtime常用方法

总结Runtime中常用方法，方便使用，定义Person类如下：

```objective-c
@protocol PersonProtocol <NSObject>
- (void)work;
@end
  
@interface Person : NSObject<PersonProtocol, NSCoding>
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * profession;
@property (nonatomic, copy) NSString * address;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) UInt8 gender;
+ (void)run;
- (void)walk;
@end
```

## 常用函数

声明一个Person属性

```objective-c
Person * per = [Person new];
```

- **object_getClass**：获取对象类型

  ```objective-c
  Class personClass = object_getClass([per class]);
  Class
  ```

- **class_getSuperclass**：获取对象父类类型

  ```objective-c
  Class superClass = class_getSuperclass(object_getClass([per class]));
  ```

- **class_getClassMethod**：获取类方法

  ```objective-c
  Method classMethod = class_getClassMethod(personClass, @selector(run));
  ```

- **class_getInstanceMethod**：获取实例方法

  ```objective-c
  Method instanceMethod = class_getInstanceMethod([per class], @selector(walk));
  ```

- **method_getImplementation**：获取方法的实现

  ```objective-c
  Method nameMethod = class_getInstanceMethod([per class], @selector(setName:));
  IMP nameIMP = method_getImplementation(nameMethod);
  ```

- **method_setImplementation**：设置方法的实现

  ```objective-c
  Method walkMethod = class_getInstanceMethod([per class], @selector(walk));
  IMP walkIMP = imp_implementationWithBlock(^(id obj, NSDictionary* param) {
    NSLog(@"new walk", nil);
  });
  method_setImplementation(walkMethod, walkIMP);
  ```

- **class_getMethodImplementation**：获取类方法的实现

  ```objective-c
  IMP runIMP = class_getMethodImplementation([Person self], @selector(run));
  ```

- **class_addMethod**：添加方法

  ```objective-c
  Method addMethod = class_getInstanceMethod(object_getClass([self class]), @selector(personNewMethod));
  class_addMethod(personClass, @selector(personNewMethod), method_getImplementation(addMethod), method_getTypeEncoding(addMethod));
  ```

- **class_replaceMethod**：替换方法实现

  ```objective-c
  class_replaceMethod(personClass, oriSel, method_getImplementation(addMethod), method_getTypeEncoding(addMethod));
  ```

- **method_exchangeImplementations**：交换方法

  ```objective-c
  method_exchangeImplementations(classMethod, instanceMethod);
  ```

- **class_copyMethodList**：获取对象方法列表

  ```objective-c
  unsigned int classMethodCount = 0; 
  Method * methodList = class_copyMethodList([Person class], &classMethodCount);
  for (int i = 0; i < classMethodCount; i++) {
    NSLog(@"method name: %s", sel_getName(method_getName(methodList[i]))); 
  }
  ```

- **class_copyPropertyList**：获取类的属性列表

- **property_getName**：获取属性名

- **property_getAttributes**：获取属性的属性字符串

  ```objective-c
  unsigned int count = 0;   
  objc_property_t * properties = class_copyPropertyList([Person class], &count);
  for (int i = 0; i < count; i++) {
    NSLog(@"property name: %s", property_getName(properties[i]));
   	NSLog(@"property attribute：%s", property_getAttributes(properties[i])); 
  }
  ```

- **class_copyIvarList**：获取类的成员变量列表

- **ivar_getName**：获取成员变量名

- **ivar_getTypeEncoding**：获取成员变量类型

  ```objective-c
  unsigned int ivarCount;
  Ivar * ivarList = class_copyIvarList([per class], &ivarCount);
  for (int i = 0; i < ivarCount; i++) {
      // 11、获取成员变量的名字
      NSLog(@"ivar name：%s",ivar_getName(ivarList[i]));
      // 12、获取成员变量的类型
      NSLog(@"ivar type：%s", ivar_getTypeEncoding(ivarList[i]));
  }
  ```

- **class_copyProtocolList**：获取类实现的协议列表

- **protocol_getName**：获取协议名

  ```objective-c
  unsigned int protocolCount;
  __unsafe_unretained Protocol ** protocolList = class_copyProtocolList(personClass, &protocolCount);
  for (int i = 0; i < protocolCount; i++) {
      NSLog(@"protocol name：%s",protocol_getName(protocolList[i]));
  }
  ```

- **objc_setAssociatedObject**：关联值

  ```objective-c
  NSString * key = @"key";
  objc_setAssociatedObject(per, &key, @"name", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  ```

- **objc_getAssociatedObject**：读取关联值

  ```objective-c
  objc_getAssociatedObject(per, &key);
  ```

- **objc_allocateClassPair**：动态创建类

- **class_addIvar**：动态添加成员变量

- **objc_registerClassPair**注册类

- **object_setIvar**：设置成员属性

- **object_getIvar**：获取成员属性

- **objc_disposeClassPair**：销毁类

  ```objective-c
  // 创建一个类
  // param1: 父类
  // param2: 类名
  // param3: 分配个类和元类对象为不的索引ivars的字节数，通常为0
  Class clazz = objc_allocateClassPair([Person class], "Student", 0);
  
  // 添加成员属性_stuID
  // param1: 添加对象
  // param2: 属性命
  // param3: 属性内存大小
  // param4: 属性内存对齐偏移方式 https://www.zhihu.com/question/36590790
  // param5: 属性类型的c字符串 @encode()
  class_addIvar(clazz, "_stuID", sizeof(NSString *), log2(sizeof(NSString *)), @encode(NSString *));
  // 添加成员属性_class
  class_addIvar(clazz, "_class", sizeof(NSUInteger), log2(sizeof(NSUInteger)), @encode(NSUInteger));
  
  // 注册类
  objc_registerClassPair(clazz);
  
  // 创建类的实例
  id stu = [[clazz alloc] init];
  
  // 设置成员属性
  [stu setValue:@"lucy" forKey:@"name"];
  [stu setValue:@"201202211" forKey:@"stuID"];
  object_setIvar(stu, class_getInstanceVariable(clazz, "_class"), @2020);
  
  NSLog(@"new class object: %@", stu);
  // 获取所有成员属性
  unsigned int ivarCount;
  Ivar * ivars = class_copyIvarList(clazz, &ivarCount);
  
  for (int i = 0; i < ivarCount; i++) {
      NSLog(@"ivar name：%s",ivar_getName(ivars[i]));
  }
  
  NSLog(@"stuID: %@, class: %@", [stu valueForKey:@"stuID"], object_getIvar(stu, class_getInstanceVariable(clazz, "_class")));
  
  // 当类或者其子类的实例还存在，就不能调用obj_disposeClassPair方法
  stu = nil;
  
  // 销毁类
  objc_disposeClassPair(clazz);
  ```

## IMP、SEL、Method关系

- IMP表示为函数指针，记录函数的地址，包含两个隐含参数self和SEL

```objective-c
// objc.h
#if !OBJC_OLD_DISPATCH_PROTOTYPES
// oc
typedef void (*IMP)(void /* id, SEL, ... */ ); 
#else
// swift
typedef id _Nullable (*IMP)(id _Nonnull, SEL _Nonnull, ...); 
#endif
```

- SEL表示为方法名，实际是一个字符串

- Method是对方法实现、名称、编码的封装，是一个`method_t`类型的结构体指针

  ```objective-c
  typedef struct method_t *Method;
  
  struct method_t { 
    // 方法名
    SEL name;
    // 方法编码
  	const char *types;
    // 方法实现
  	IMP imp; 
  };
  ```

## 消息转发

方法的调用最终会被转换成objc_msgSend的调用，例如：

```objective-c
[per walk];
=>
objc_msgSend(per, @selector(walk));
```

objc_msgSend的执行流程如下：

1. 通过isa指针查找对象所属的类

2. 查找类的cache列表，如果没有则下一步

3. 查找类的方法列表

4. 如果找到了与方法选择器名称相同的方法，跳转至实现代码
5. 找不到，沿着继承体系一直向上查找，仍然是先查找cache列表，在查找方法列表
6. 找到了与方法选择名称相同的方法，就跳转至实现代码
7. 找不到，执行消息转发

如果执行的方法在继承体系中都没有查找到话，会执行消息转发流程消息转发流程如下：

1. 动态方法解析：通过+resolveInstanceMethod:方法询问接收者所属的类，能不能动态添加其他方法来处理这个未知消息，如果能，消息转发结束
2. 备用接收者：当动态方法解析不能处理时，通过-forwardingTargetForSelector：方法询问接收者有没有其他对象能处理这条消息，如果有，将该消息转发给能处理的其他对象，消息转发结束
3. 消息签名：当备用接收者也不能处理这条消息时，需要返回一个消息签名给后一步消息转发，如果返回nil，消息转发结束
4. 完整的消息转发：如果备用接收者也不能处理这条消息，就将消息的所有相关信息都封装到NSInvocation对象，再问一次接收者，是否能处理，如果不能处理，崩溃

下面的例子中，Man时Person的子类，代替Person实现run和walk方法，

```objective-c
Person * per = [Person new];
// 调用未实现的方法
[per walk];
[per run];
// 动态调用
[per performSelector:@selector(fly)];
```

Person实现，fly方法是动态调用的，动态添加该方法的实现

```objective-c
@implementation Person

// 消息转发流程
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (!strcmp("fly", sel_getName(sel))) {
        // 添加方法实现
        class_addMethod([self class], sel, (IMP)canNotFly, "v@:");
        return true;
    } else {
        return [super resolveInstanceMethod:sel];
    }
}

// 消息备用接收者
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(walk) && [Man instancesRespondToSelector:aSelector]) {
        return [[Man alloc] init];
    }
    return [super forwardingTargetForSelector: aSelector];
}

// 当备用消息接收者为nil时，生成方法签名
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (aSelector == @selector(run)) {
        // 为转发的方法手动生成签名
        // 签名类型就是用来描述这个方法的返回值、参数的
        // 方法签名默认隐藏两个参数
        // self代表方法调用者
        // _cmd代表这个方法的sel
        // v@:表示：v代表放回值void、@代表self，:代表_cmd
        return [NSMethodSignature signatureWithObjCTypes: "v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

// 当动态方法解析和备用接收者都没有处理这个消息时，执行完整消息转发
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    if ([Man instancesRespondToSelector: selector]) {
        // 转发到Man对象实现
        [anInvocation invokeWithTarget:[Man new]];
    }
}

// fly的实现
void canNotFly(id self, SEL sel) {
    NSLog(@"%@ can not %@", self, NSStringFromSelector(sel));
}
```

