# 元服务快递接口映射

本表仅适用于鸿蒙元服务模块 `products/atomic_entry`。普通应用模块 `products/entry` 不使用本表的快递新接口。后端基地址：`https://a.bbddd.cn`，业务前缀：`/tea-drink-orders/v1/app/api/express`。

| 模块 | 前端入口 | 方法与路径 | 状态 |
|---|---|---|---|
| 认证 | aggregated login / `ExpressApi.login` | POST `/auth/login`，`{hmAppid,authorizationCode}` | 已接入客户端，登录 UI 授权码流程待联调 |
| 地址簿 | `AddressStore` | GET/POST `/addresses`；PUT/DELETE `/addresses/{id}`；PUT `/addresses/{id}/default` | 已接入，未登录保留演示数据 |
| 订单列表 | `products/atomic_entry/pages/OrderPage` | GET `/orders?pageNo&pageSize&status` | 已接入，含分页与状态归一化 |
| 订单详情/物流 | `products/atomic_entry/AtomicHome` | GET `/orders/{orderNo}`、GET `/logistics/{orderNo}/traces` | 已接入 |
| 订单取消 | `products/atomic_entry/AtomicHome` | POST `/orders/{orderNo}/cancel` | 已接入 |
| 报价/创建订单 | `ExpressApi` 客户端方法 | POST `/quotes`、`/orders` | 客户端已具备，寄件表单仍需绑定提交 |
| 快递公司/服务点 | `ExpressApi` 客户端方法 | GET `/public/carriers`、`/public/service-points` | 客户端已具备 |

## 未完成或风险

- 后端 `AppKeyAuthInterceptor` 要求 `X-App-Key`、`X-App-Timestamp`、`X-App-Nonce`、`X-App-Signature`。端侧不应内置密钥，当前部署需提供安全签名代理或后端对可信 App 做签名豁免；否则真实请求会返回 40001/40003。
- 会员权益、积分、优惠券页面仍使用 `BenefitsMock` 及旧 `/api/hw-atomic/*` 路径；后端快递控制器未提供对应新接口，需后端补充或明确继续走兼容控制器。
- 未发现售后/投诉/退款、通知、管理统计的快递专用 Controller；当前不能用假数据掩盖，需后端确认接口范围。
- 登录成功后应将 access token 持久化到 `AppStorageMap.TOKEN`，并调用 `JavaApiClient.setToken`；Token 过期由客户端抛出 `AUTH_EXPIRED`，页面需统一跳转登录。

## 验证

本环境无 `hvigorw`/Hvigor CLI，无法执行 ArkTS 编译；已完成静态路径、参数和响应结构核对。后端 Maven/Gradle 服务及数据库需在部署环境启动后，使用真实 AppKey 签名执行登录、地址、报价、下单、取消和物流回归。
