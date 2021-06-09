# 数据库分析

## 登录功能

用户表

- 创建用户表
- 查询用户
  - 存在就登录
  - 不存在就添加用户，再登录

| 字段     | 类型   | 说明     |
| -------- | ------ | -------- |
| userId   | int    | 用户主键 |
| phone    | string | 电话号码 |
| haedpath | string | 头像     |
| name     | string | 姓名     |

根据用户创建数据库，存储货品、进出货信息

用户之间相互独立

##  进货功能

货品表/进货记录表

- 创建货品表
- 创建进货记录表
- 添加货品
  - 货品名相同算同一个货品：根据货品名判断，相同就更新，不存在就插入
  - 货品名相同算两个货品：直接插入
- 添加进货记录

### 货品表

| 字段       | 类型   | 说明         |
| ---------- | ------ | ------------ |
| goodsId    | int    | 货品id       |
| name       | string | 货品名       |
| imagePath  | string | 货品图片     |
| stock      | int    | 货品库存     |
| unit       | string | 单位         |
| unitPrice  | double | 单价         |
| sellPrice  | double | 售价         |
| remark     | string | 备注         |
| createDate | Date   | 创建货品时间 |
| editDate   | Date   | 更新货品时间 |

### 进货记录表

| 字段       | 类型   | 说明               |
| ---------- | ------ | ------------------ |
| recordId   | int    | 进货记录id         |
| name       | string | 进货货品名         |
| amount     | int    | 进货总数           |
| totalPrice | double | 进货总额           |
| createDate | Date   | 进货时间           |
| groupDate  | string | 进货日期，用于分组 |

## 选择货品

查询货品表

- 只显示有库存的货品

 - 选中货品
 - 设置货品数量
    - 判断货品数量，最多可输入库存大小的数量

## 出货功能

出货记录表/货品表

- 创建出货表
- 选择货品
- 出货
  - 更新货品表，更新货品库存
  - 添加出货记录

| 字段       | 类型   | 说明                 |
| ---------- | ------ | -------------------- |
| recordId   | int    | 出货记录id           |
| goodsName  | string | 货品名集合，空格分割 |
| amount     | int    | 出货总数             |
| totalPrice | double | 出货总额             |
| createDate | Date   | 出货时间             |
| groupDate  | string | 出货日期、用于分组   |

## 出货明细

待沟通