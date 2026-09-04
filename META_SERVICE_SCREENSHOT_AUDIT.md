# 元服务页面截图审查记录

审查日期：2026-08-24

## 当前结论

本机已通过 DevEco Studio 的 `nova 16 Pro` 模拟器启动 HarmonyOS 元服务运行时，并完成核心页面截图。

此前关于“无法启动”的判断已被模拟器运行状态纠正。

## 本轮运行时截图

截图目录：`screenshots/meta-service/`。

| 页面 | 运行时截图 | 审查结果 |
|---|---|---|
| 首页 | [home.jpeg](screenshots/meta-service/home.jpeg) | 资源正常，主视觉和底部导航正常；首屏下方服务卡片在截屏边界处被截断，需滚动复核。 |
| 查快递 | [order.jpeg](screenshots/meta-service/order.jpeg) | 搜索框、状态 Tab、订单卡片、底部导航均正常；列表滚动条和底部导航没有重叠。 |
| 福利 | [benefit.jpeg](screenshots/meta-service/benefit.jpeg) | 页面可用，但积分卡片与签到卡片之间存在大块浅灰空白区域，疑似广告/异步内容占位。 |
| 我的 | [mine.jpeg](screenshots/meta-service/mine.jpeg) | 登录卡、服务入口、反馈/客服/设置/隐私列表和底部导航均正常。 |

## 当前模拟器信息

- 设备：`nova 16 Pro`
- 目标：`atomic_entry`
- 包名：`com.atomicservice.6917614461242904059`
- Ability：`EntryAbility`
- 截图分辨率：1320 x 2856

## 仍待逐项验证

- 首页“立即寄件”、会员、实名认证等详情页；
- 我的页“登录、地址管理、意见反馈、设置、隐私政策”等详情页；
- 查快递订单详情、取消寄件、筛选；
- 福利积分明细、签到、优惠券列表；
- 同步清单中未暴露在当前 `AtomicHome` 入口的其余页面。

## 详情页逐项点击结果

本轮跳过四个已经完成的 Tab 主页面，仅尝试从首页和“我的”进入详情页：

| 页面 | 截图 | 结果 |
|---|---|---|
| 立即寄件 | [shipping2.jpeg](screenshots/meta-service/shipping2.jpeg) | 未进入寄件表单，点击后停留在首页滚动位置；视觉按钮与可点击父容器存在偏移或事件拦截。 |
| 会员开通 | [membership.jpeg](screenshots/meta-service/membership.jpeg) | 未进入详情页，仍为首页状态。 |
| 实名认证 | [auth.jpeg](screenshots/meta-service/auth.jpeg) | 未进入详情页，仍为首页状态。 |
| 登录 | [login.jpeg](screenshots/meta-service/login.jpeg) | 未进入登录详情，仍为“我的”页面。 |
| 地址管理 | [address.jpeg](screenshots/meta-service/address.jpeg) | 未进入地址详情，仍为“我的”页面。 |
| 意见反馈 | [feedback.jpeg](screenshots/meta-service/feedback.jpeg) | 未进入反馈详情，仍为“我的”页面。 |
| 设置 | [settings.jpeg](screenshots/meta-service/settings.jpeg) | 未进入设置详情，仍为“我的”页面。 |

因此上述截图作为“点击尝试证据”保留，不标记为详情页完成截图。下一步需要修正 `AtomicHome` 中详情入口的点击绑定或使用可点击父容器的布局边界重新验证。

## 环境诊断记录

- 未发现 DevEco Studio 应用可执行入口；
- 未发现 `hdc` 或 `adb` 命令；
- 没有连接的 HarmonyOS 模拟器或真机；
- 工程虽存在 `products/atomic_entry/build/atomic/outputs/default/atomic_entry-default-unsigned.hap`，但无法安装和启动。

以上四条是早期检查结果，已被本轮通过 DevEco Studio 内置 `hdc` 连接模拟器的实测结果覆盖。

- 未发现 DevEco Studio 应用可执行入口；
- 未发现 `hdc` 或 `adb` 命令；
- 没有连接的 HarmonyOS 模拟器或真机；
- 工程虽存在 `products/atomic_entry/build/atomic/outputs/default/atomic_entry-default-unsigned.hap`，但无法安装和启动。

因此，本轮不能生成新的运行时截图，也不能声称已完成各页面的真实交互审查。

## 已有截图证据

工程内已有以下元服务截图，可作为历史视觉基线：

| 页面 | 截图 | 审查状态 |
|---|---|---|
| 首页 | [atomic_home_latest.jpeg](screenshots/atomic_home_latest.jpeg) | 已有截图，可做静态视觉检查 |
| 首页旧版 | [atomic_home.jpeg](screenshots/atomic_home.jpeg) | 历史截图 |
| 查快递 Tab | [tab_order.png](screenshots/tab_order.png) | 已有截图，可做静态视觉检查 |
| 福利 Tab | [tab_benefits.png](screenshots/tab_benefits.png) | 已有截图，可做静态视觉检查 |
| 我的 Tab | [tab_mine.png](screenshots/tab_mine.png) | 已有截图，可做静态视觉检查 |
| 我的元服务版 | [tab_mine_atomic.jpeg](screenshots/tab_mine_atomic.jpeg) | 历史截图 |

## 静态检查结果

- 首页、查快递、福利、我的四个核心 Tab 已有视觉证据。
- 现有截图没有覆盖同步清单中的全部 40 个页面，也没有覆盖寄件、会员、地址、设置等详情页的完整交互路径。
- 清单中的 `.ets.source` 文件是源码镜像，不能直接作为运行时页面截图。

## 下一步运行条件

在安装 DevEco Studio 并启动 HarmonyOS 模拟器或连接真机后，使用 `hdc` 安装该 HAP，再按 [synced_pages.json](products/atomic_entry/src/main/resources/base/profile/synced_pages.json) 顺序逐页截图；截图应保存到 `screenshots/meta-service/`，并在本文件追加每页的运行时结果、问题和截图链接。
