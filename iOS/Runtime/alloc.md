# alloc、init和new方法

## alloc

​	alloc调用流程

> +alloc/_objc_rootAlloc/callAlloc

### callAlloc

​	在callAlloc函数中，会进行编译优化，并且这一步并不是alloc的核心实现步骤

```c
// alloc和allocWithZone进入到这里，会进行编译器优化
callAlloc(Class cls, bool checkNil, bool allocWithZone=false)
{
#if __OBJC2__
  	// cls判空，返回nil
    if (slowpath(checkNil && !cls)) return nil;
    // 是否有自定义的allocWitZone实现
    if (fastpath(!cls->ISA()->hasCustomAWZ())) {
      	//实际的alloc实现
        return _objc_rootAllocWithZone(cls, nil);
    }
#endif
		// 兼容oc1，oc1通过objc_msgSend来实现
    if (allocWithZone) {
        return ((id(*)(id, SEL, struct _NSZone *))objc_msgSend)(cls, @selector(allocWithZone:), nil);
    }
    return ((id(*)(id, SEL))objc_msgSend)(cls, @selector(alloc));
}

```

> \_\_OBJC2\_\_：Objective2.0版本，在2.0版本中增加了可用的编译器优化
>
> fastpath和slowpath定义，参考https://www.jianshu.com/p/536824702ab6
>
> ```swift
> // exp==n的概率很大，由GCC提供的告诉编译器分支转移信息，减少指令跳转带来的性能下降
> __builtin_expect(exp, n)
> 
> // 表示x为真的概率更大
> #define fastpath(x) (__builtin_expect(bool(x), 1))
> // 表示x为假的概率更大
> #define slowpath(x) (__builtin_expect(bool(x), 0))
> ```

### _objc_rootAllocWithZone

​	此方法也是兼容oc1，在oc2中NSZone不推荐使用，所以zone参数传入nil

> 参考https://www.cnblogs.com/azxfire/p/3820025.html

### _class_createInstanceFromZone

​	这一步是alloc的核心实现步骤，分为三步

- cls->instanceSize：计算对象需要的内存空间

- calloc：申请内存，obj内存地址

- obj->initInstanceIsa：创建isa，将isa和obj关联

  ```c
  // alloc的核心方法
  static ALWAYS_INLINE id
  _class_createInstanceFromZone(Class cls, size_t extraBytes, void *zone,
                                int construct_flags = OBJECT_CONSTRUCT_NONE,
                                bool cxxConstruct = true,
                                size_t *outAllocatedSize = nil)
  {
      ASSERT(cls->isRealized());
    
      // 一次读取类的信息位以提高性能
      bool hasCxxCtor = cxxConstruct && cls->hasCxxCtor();
      bool hasCxxDtor = cls->hasCxxDtor();
      bool fast = cls->canAllocNonpointer();
      size_t size;
  
      // 1、内存大小
    	// 内存对齐
      size = cls->instanceSize(extraBytes);
      if (outAllocatedSize) *outAllocatedSize = size;
  
      id obj;
      if (zone) {
          obj = (id)malloc_zone_calloc((malloc_zone_t *)zone, 1, size);
      } else {
          // 2、申请内存，并赋值给obj
          obj = (id)calloc(1, size);
      }
      if (slowpath(!obj)) {
          if (construct_flags & OBJECT_CONSTRUCT_CALL_BADALLOC) {
              return _objc_callBadAllocHandler(cls);
          }
          return nil;
      }
  
      if (!zone && fast) {
          // 3、初始化isa并与obj关联
          obj->initInstanceIsa(cls, hasCxxDtor);
      } else {
          // Use raw pointer isa on the assumption that they might be
          // doing something weird with the zone or RR.
          obj->initIsa(cls);
      }
  
      if (fastpath(!hasCxxCtor)) {
          return obj;
      }
  
      construct_flags |= OBJECT_CONSTRUCT_FREE_ONFAILURE;
      return object_cxxConstructFromClass(obj, cls, construct_flags);
  }
  ```

  #### instanceSize	

  ​	instanceSize函数计算存储对象需要的内存大小，为了提高存储和IO效率，使用内存对齐来计算内存大小

  #### 内存对齐

  ​	在64位系统中，cpu每次能从内存取出的的对齐大小为8字节的内存如[0-7]，[8-15]，内存对齐就可以提高cpu访问内存数据的效率，是一种以空间换时间的优化方式。

  ​	物理层面原因：https://zhuanlan.zhihu.com/p/83449008

  ​	对齐原则：

  1. 成员变量：作为类或者结构体的成员变量，第一个变量放在offset为0的地方，以后每个成员变量的存储位置从该成员的大小或者成员的子成员（数组，结构体，类）的整数倍开始。
  2. 在类或者结构体中定义了其他类或结构体：成员变量从其内部最大元素大小的整数倍地址开始布局
  3. 整体对齐规则：类或结构体的总大小，即sizeof的结果，必须是其内部最大成员的整数倍，不足的要补齐

  ```c
  typedef struct Body {
      int id;         //  4字节   [0-3]
      double weight;  //  8字节   [8-15]	原则1
      float height;   //  4字节   [16-29] 对齐 [20-23]	原则2
  } Body;
  
  typedef struct Stu {
      char name[2];   // 2字节   [0-1]
      int id;         // 4字节   [4-7]	原则1
      double score;   // 8字节   [8-15]	
      short grade;    // 2字节   [16-17]
      struct Body body;   // 24字节 [24-47]	原则2
  } Stu;
  
  sizeof(Body)	// 24
  sizeof(Stu))	// 48
  ```

  ​	在iOS中，使用16字节对齐，在OC对象中，第一个位是isa指针，占了8个字节，如果对象中没有其他属性，对象至少占8字节。如果iOS以8字节对齐，连续的两个没有其他属性的对象内存是完全挨在一起的，可能造成访问出错，参考https://www.jianshu.com/p/e01fffd22091。

  ​	objc中，16位内存对齐实现

  > ```c
  > static inline size_t align16(size_t x) {
  >   	//  x >> 3 << 3
  >     return (x + size_t(15)) & ~size_t(15);
  > }
  > ```

  #### calloc

  ​	申请大小为instanceSize的内存，并使得obj指向该地址

  ```objective-c
  obj = (id)calloc(1, size);
  ```

  ​	此时，打印obj，发现obj指向一个16位的地址

  ```lldb
  (lldb) po obj
  0x0000000101247740
  ```

  ​	但是打印结果并不像打印其他OC对象一样类似于<Person: 0x0011111f>的指针呢，因为这一步只开辟了内存地址，并没有与cls关联。

  > 可以看出alloc的本质作用就是开辟对象的内存

  #### initInstanceIsa

  ​	创建cls的isa并与obj关联，每个继承自NSObject的OC对象都可以通过isa连接到运行时系统，获取到对象的类，而类的isa又指向了其元类，如此就可以找到静态方法和变量了。

  ```c
  // 新建isa指针
  isa_t newisa(0);
  // 关联cls
  newisa.setClass(cls, this)
  ```

  ​	初始化isa并关联cls后，赋值给obj

  ```objective-c
  obj->initInstanceIsa(cls, hasCxxDtor);
  ```

  ​	此时，打印obj

  ```
  (lldb) po obj
  <Person: 0x10131f780>
  ```

  ​	至此，可以得出alloc方法主要工作就是开辟对象内存，并使用里内存16字节对齐的优化，其核心步骤位：`计算内存`/`申请内存`/`关联类`

  

## init

​	init方法用于初始化对象，可以分为`类init`和`对象init`

### 类init

​	 类init是一个构造方法，通过工厂设计提供给子类构造方法入口，在字节对齐后，可以强转为需要的类型

```objective-c
+ (id)init {
    return (id)self;
}
```

### 对象init

​	对象init返回的仍然是对象本身

```objective-c
- (id)init {
    return _objc_rootInit(self);
}
```

```c
id _objc_rootInit(id obj) {
    return obj;
}
```

​	所以init方法就是提供一个统一的构造方法，来初始化对象



## new

​	创建对象通可以用new方法，

```objective-c
Person * p = [Person new];
```

​	new内部同样调用了alloc方法调用的`callAlloc`方法，在创建了对象后，有调用了`init`方法，所以new等价于`[[xxx alloc] init]`

```objective-c
+ (id)new {
    return [callAlloc(self, false/*checkNil*/) init];
}
```

​	但是实际开发中，用到new的方法很少，原因在于new内部创建了对象后，直接调用了init方法，但是实际情况下一个类可能还有其他成员属性需要初始化，例如`UIView`类的`initWithFrame`方法，所以此种情况下就不适合使用new方法了

