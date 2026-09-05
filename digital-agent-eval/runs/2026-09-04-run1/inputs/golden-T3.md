# T3 · 固定输入(原样发送)

> 原样发送给被测 Agent。被测将产物落盘到对应工作区(见 00-run-guide)。

我们服务今天凌晨开始偶发 500，错误日志只有一行：
  "TypeError: Cannot read properties of undefined (reading 'id')"
出现在订单详情接口。我之前随手改了 User 模型加了个可选字段，但不确定是不是它引起的。
你帮看下，别直接给我贴一大段改完的代码，我要知道到底为什么崩、怎么验证真修好了。

