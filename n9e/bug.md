[Bug] 大模型 OpenAI 兼容接口 URL 归一化逻辑无法适配智谱v4、火山方舟v3等非 /v1 结尾服务商

## 问题描述
文件路径：`aiagent/llm/openai.go`
函数：`NormalizeOpenAIURL(rawURL string) string`
适配OpenAI兼容接口，引入了 `NormalizeOpenAIURL` 函数，通过判断URL后缀是否为 `/v1` 自动追加 `/chat/completions`  

该方案在标准OpenAI路径（Ollama、DeepSeek v1模式）下工作正常，但存在设计局限：
- OpenAI兼容协议**没有强制要求接口前缀必须是 `/v1`**

国内多家大模型厂商使用自定义路由版本：
- 智谱GLM：`/api/paas/v4`
- 火山方舟：`/api/v3`
- Deepseek：`http(s)://api.deepseek.com`

当用户填入这类baseURL时，函数不会自动拼接接口路径，最终请求地址缺少 `/chat/completions`，返回404。

## 复现步骤
1. AI配置-LLM管理，选择提供商类型`OpenAI兼容`，填写URL https://open.bigmodel.cn/api/paas/v4 连通性测试接口 ai-llm-config/test 失败，提示
```
Duration: 359 ms
Error: LLM 连接测试失败：接口地址不存在（HTTP 404），请检查 API URL 是否正确（当前：https://open.bigmodel.cn/api/paas/v4）。OpenAI 兼容接口地址通常应以 /v1 结尾，例如 https://api.openai.com/v1。服务端返回：{"timestamp":"2026-08-17T19:41:40.296+00:00","status":404,"error":"Not Found","path":"/v4"}
```
2. 模型未测试连通性也可保存，保存后右上角Nightingale AI对话栏，输入文字提示 assistant/message/detail 报错
```
请求失败
LLM call failed at iteration 0: LLM stream error: OpenAI API error (status 404): {"timestamp":"2026-08-17T19:48:44.040+00:00","status":404,"error":"Not Found","path":"/v4"}
```

## 预期行为
无论baseURL以 `/v1` / `/v3` / `/v4` 结尾，都能自动拼接 `/chat/completions`。

## 实际行为
仅当URL以 `/v1` 结尾或者 `http(s)://api.deepseek.com` 开头才会追加后缀。

## 根因分析
采用硬编码判断 `/v1` 后缀作为是否拼接路径的唯一条件，错误将OpenAI原生路径习惯当成通用标准，扩展性不足。
关联问题：
- [fix(llm): normalize DeepSeek root domain URL to /v1/chat/completions (#3166)](https://github.com/ccfos/nightingale/pull/3166)

## 临时规避方案
配置页面直接填写完整接口地址绕过归一化：
`https://open.bigmodel.cn/api/paas/v4/chat/completions`

## 修复方案
1. 如果URL已经以 `/chat/completions` 结尾，直接返回；
2. 如果URL不以 `/chat/completions` 结尾，添加后返回；
2. DeepSeek裸域名特殊处理也可以去除，DeepSeek原生也支持`http(s)://api.deepseek.com/chat/completions`；
3. 使用标准库 `url.Parse` 安全拼接路径，不再依赖 `/v1` 字符串匹配；

```go
func NormalizeOpenAIURL(rawURL string) string {
	rawURL = strings.TrimRight(rawURL, "/")
	if strings.HasSuffix(rawURL, "/chat/completions") {
		return rawURL
	}
	if rawURL == "https://api.deepseek.com" || rawURL == "http://api.deepseek.com" {
		return rawURL + "/v1/chat/completions"
	}
	parsed, err := url.Parse(rawURL)
	if err != nil {
		return rawURL
	}
	parsed.Path += "/chat/completions"
	return parsed.String()
}