# Taijijs web应用框架
  前后端s实时双向绑定技术
  实时远程调用
  实时远程事件
  express的超集
  客户端可以无缝配合angularjs
    tjDirectives:
      tjModel tjBind tjBindHtml tjBindTemplate
      tjClick tjDblclick tjFocus：实时远程调用
      tjClass tjStyle
  底层使用websocket及其兼容替代技术。
  模板：
    任何模板，使用express原来模板解析后，在将html发往前端之前再经过太极模板解析器重新解析一遍，寻找太极指令
    普通太极指令
    插补太极指令

    增加如下特性: 实时插补指令（interpolation）
      {} jade插补指令，保持jade兼容性
      {{ }} angular插补指令
      #{ 实时双向绑定 }
      !{ 实时下传绑定 }
      ^{ 实时上传绑定 }


实现方法
  模板：
    后端模板编译时收集太极实时指令（包括常规太极angular指令以及实时插补指令），生成html页面，页面中嵌入实时通讯脚本。
  模型同步：
    后端watch，产生socket消息，传递到前端，前端同步模型，然后触发页面更新。
    页面交互引起模型变化，前端watch，产生socket消息，传递到后端，后端同步模型。