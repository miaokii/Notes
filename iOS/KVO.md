# KVO

KVO（Key-Value-Oberving）允许观察者对象监听目标对象属性的改变，在改变时，接收到改变事件。被监听的对象需继承自NSObject，否则不能事件监听。

KVO是观察者模式的一种实现，和NSNotificationCenter不同的是，KVO是一对一的，后者是一对多监听。KVO对被监听对象没有侵入性，

KVO可以监听单个属性的变化，也可以监听集合对象（NSArray、NSSet）的变化。当监听集合时，需要将集合当作属性添加到NSObject子类里面，并通过KVC的mutableArrayValueForKey:方法获取代理对象，向其中添加集合元素，才能被观察监听到。

## 使用

使用KVO分为三步：

1. 通过addObserver: forKeyPath: options: context:方法注册观察者
2. 观察者实现observeValueForKeyPath:ofObject:change:context:方法，当被观察对象的属性发生变化时，KVO会通过该方法通知观察者
3. 当不需要监听时，通过removeObserver: forKeyPath:方法注销对观察对象的监听，并且必须在观察者销毁之前调用，否则会Crash

### 注册监听

在注册观察的方法中，options参数是一个NSKeyValueObservingOptions类型的枚举值，表示监听对象属性的选项，有四种类型

- NSKeyValueObservingOptionNew：提供属性的新值
- NSKeyValueObservingOptionOld：提供属性的旧值
- NSKeyValueObservingOptionInitial：在注册了观察者后，立刻回调一次
- NSKeyValueObservingOptionPrior：每次修改属性之前，先回调一次，修改属性时再回调一次，如果同时设置了其他选项，在第一次回调中不会包含其他选项的key，相当于改变属性前通知一次观察者

### 监听方法

观察者必须要实现observeValueForKeyPath:ofObject:change:context:方法来监听KVO事件，当被监听对象的特定属性改变时，KVO会执行该方法，change字典中存放着改变属性相关的值，根据注册监听时的options不同，change返回的内容也不同

当监听了对象的集合属性时，change中还会有NSKeyValueChangeIndexesKey字段，用于记录集合操作的方式

### 触发KVO的方式

触发KVO除了点语法和set语法外，还有其他调用方式

1. KVC：setValue:forKey:方法

2. KVC：setValue:forKeyPath:方法

3. 通过mutableArrayValueForKey:获取到代理对象，修改代理对象触发

4. 手动调用

   > 直接修改成员变量不能触发KVO，因为没有调用set方法

### 实例

 定义继承自NSObject的类

```objective-c
@interface KVOPerson : NSObject
@property (nonatomic, copy) NSString* name;
@property (nonatomic, assign) NSInteger age;
// 集合属性
@property (nonatomic, strong) NSMutableArray<KVOPerson *>* friends;
@end
```

在Controller中添加观察者，并实现观察方法

```objective-c
[self.kvoPerson addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
[self.kvoPerson addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:nil];
[self.kvoPerson addObserver:self forKeyPath:@"friends" options:NSKeyValueObservingOptionNew context:nil];

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"keypath: %@", keyPath);
    NSLog(@"change: %@", change);
}
```

更改属性

```objective-c
// .语法
self.kvoPerson.age = 11;
// set方法
[self.kvoPerson setName:@"Lucy"];
// kvc
[self.kvoPerson setValue:@"Lucy" forKey:@"name"];
// kcv集合代理对象
[[self.kvoPerson mutableArrayValueForKey:@"friends"] addObject:self.normalPerson];
```

手动修改

```objective-c
- (void)setAge:(NSInteger)age {
    if (_age != age) {
        [self willChangeValueForKey:@"age"];
        _age = age;
        [self didChangeValueForKey:@"age"];
    }
}
```

## 原理

KVO通过isa-swizzling实现，当对属性添加了观察后，Runtime会创建一个继承自原类的中间类，将对象的isa指向这个中间类，并将中间类的class方法重写，返回原类的class。当修改对象的属性时，会调用Foundaton框架的_NSSetXXXVlaueAndNotify函数，该函数会先调用willChangeValueForKey:方法，然后调用原来的setter方法修改值，最后调用didChangeValueForKey:方法，并触发监听器Oberser的回调方法observeValueForKeyPath:ofObject:change: context:。













