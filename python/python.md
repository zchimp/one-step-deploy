# 设置中文编码
```
#!/usr/bin/python
# -*- coding: UTF-8 -*-
 
print( "你好，世界" )
```
# 语法
## 变量
```python
#!/usr/bin/python
# -*- coding: UTF-8 -*-
# Python 中的变量赋值不需要类型声明。
# 等号 = 用来给变量赋值。
a = b = c = 1
a, b, c = 1, 2, "john"

# 数据类型是不允许改变的,这就意味着如果改变 Number 数据类型的值，将重新分配内存空间。
# Numbers（数字）4种类型
counter = 100      # 赋值整型变量
count2 = 51924361L # long长整数，也可以代表八进制和十六进制
count3 = 0.0       # float浮点数
count4 = 3.14j     # complex复数

# String（字符串）
name = "John"      # 字符串

# List（列表）
list = [ 'runoob', 786 , 2.23, 'john', 70.2 ]
# Python 列表截取可以接收第三个参数,参数作用是截取的步长 list[1:4:2],1-4下标，步长2
list[1:4]          # [786 , 2.23, 'john'，70.2]
list[1:4:2]        # [786, 'john']

# Tuple（元组）只读列表
tuple = ( 'runoob', 786 , 2.23, 'john', 70.2 )
tinytuple = (123, 'john')
tuple[2] = 1000    # 非法操作，元组不允许更新
# Traceback (most recent call last):
#   File "test.py", line 6, in <module>
#     tuple[2] = 1000    # 元组中是非法应用
# TypeError: 'tuple' object does not support item assignment

# Dictionary（字典）键值对
tinydict = {'name': 'test','code':6734, 'dept': 'sales'}
print tinydict['name']  # test
tinydict.keys()     # 所有key
tinydict.values()   # 所有value
```

## 条件
```python
#!/usr/bin/python
# -*- coding: UTF-8 -*-
 
# 例1：if 基本用法
flag = False
name = 'luren'
if name == 'python':         # 判断变量是否为 python 
    flag = True              # 条件成立时设置标志为真
    print 'welcome boss'     # 并输出欢迎信息
elif name == 'java' or name == 'golang':
    print 'not my type'
elif name == 'rust' and name != 'js':
    print 'not my type too'
else:
    print name               # 条件不成立时输出变量名称
```

## 循环
```python
# Python 提供了 for 循环和 while 循环
count = 0
while (count < 9):
    print 'The count is:', count
    count = count + 1
    if i%2 > 0:
        break;
    else:
        contiue
else:                       # 跳出循环则执行
    print("跳出循环")

print "Good bye!"

fruits = ['banana', 'apple',  'mango']
for fruit in fruits:          # for循环
   print ('当前水果: %s'% fruit)

for index in range(len(fruits)): # 序列索引循环
   print ('当前水果 : %s' % fruits[index])

```

## 时间和日期
```python
#!/usr/bin/python
# -*- coding: UTF-8 -*-
 
import time  # 引入time模块
 
ticks = time.time()                         # 1459994232.51
localtime = time.localtime(time.time())     # time.struct_time(tm_year=2016, tm_mon=4, tm_mday=7, tm_hour=10, tm_min=3, tm_sec=27, tm_wday=3, tm_yday=98, tm_isdst=0)
localtime = time.asctime( time.localtime(time.time()) )  # Thu Apr  7 10:05:21 2016
time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())  # 2016-04-07 10:25:09
```
## 函数
def printme( str ):
   "打印传入的字符串到标准显示设备上"
   print str
   return

# http文件服务器
```
python -m http.server 8000
```