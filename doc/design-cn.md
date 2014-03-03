方案一：
  后端：在express的view后再加一层中间件，利用htmlparser找出其中的太极指令，生成对应的前端页面。
  前端：利用angularjs系统完成双向绑定。在angularjs的$scope和控制器中实现远程同步。
  优点：
    后端view代码预计会更简单。
    angularjs很强大，预计前端只需要再增加一层薄的代码即可以实现远程实时双向绑定。
  缺点：
    只能嵌入与angularjs对应的太极指令（普通指令和插补指令），无法实现我希望的更灵活的模板语法。
    angularjs太庞大，对jquery不友好，速度受限制。
    需要更深入地理解angularjs。


方案二：
  前端：express的基础上实现太极模板系统，解析.tjv文件，生成对应的前端页面
  前端：根据太极模板系统的解析结果，生成与后端适配的全部前端代码。
  缺点：
    要编写整个太极模板系统及前端控制系统，需要更多编码。
  优点：
    可以实现灵活的模板语法
    可以将对jquery友好作为目标。
    可以期望更优化的速度。
    不需要花那么多时间与angularjs共舞。

  方案二设计关键点
    解析过程产生的html指令，根据需要增加tjid=“genenrated-taiji-id”特性，jquery以此特性选择元素，实现太极指令需要的操作。
    特别是对数组指令，可以有arrayElement = $('[tjid=#tjid1],[tjid=#tjid2],...'), 在此基础上可以实现数组操作。
    前端api
      tj.Element(path) # model path
      tj.id(path) # model path
      $('[tj-model=xxx]')
      $('.tj-page')
      $('tj-date') #<tj-date>...<tj-date>
