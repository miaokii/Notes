# 常用操作符

## 创建序列

### create

通过函数构建一个序列，在函数中描述next、error、complete的产生

```swift
Observable<Int>.create { (observer) -> Disposable in
    observer.onNext(1)
    observer.onNext(2)
    observer.onCompleted()
    return Disposables.create()
}
.subscribe(onNext: { print($0) })
.disposed(by: bag)
```





## 转换

### map

通过一个操作函数，将原序列的每个元素都转换成新元素，组成新的序列后输出

```swift
Observable.of(1, 2, 3)
    .map{ $0 * 10 }
    .subscribe(onNext: { print($0) })
    .disposed(by: bag)
```

## flatMap

将原序列的每个元素转换成一个序列，再将这些序列的元素合并之后组成新的序列输出。适用于原序列中每个元素本身就有一个其他的序列时，通过flatMap将所有子序列的元素发送出来

> 类比二维数组转换为一维数组

```swift
let numObservable1 = Observable.of(1, 2, 3, 4)
let numObservable2 = Observable.of(10, 11, 12, 13)
Observable.of(numObservable1, numObservable2)
    .flatMap{ $0.map{$0} }
    .subscribe(onNext: { print($0) })
    .disposed(by: bag)
```

## flatMapLatest

将原序列的每个元素转换成一个序列，再将这些序列中最新的一个发出

