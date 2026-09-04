# 福利与会员同步审计

## 页面、组件与路由对应

| 源程序 | 元服务运行文件 | 入口 | 状态 |
|---|---|---|---|
| `features/business_benefits/.../BenefitPage.ets` | `products/atomic_entry/.../pages/BenefitPage.ets` | `AtomicHome` 福利 Tab | 已接入运行态 |
| `CouponListSection.ets` | `BenefitPage.coupon` | 福利页“优惠券”Tab | 已接入模板查询与兑换 |
| `TaskListSection.ets` | `BenefitPage.task` | 福利页“日常任务”Tab | 仅完成视图；后端缺任务接口 |
| `PointsHistoryPage.ets` | `pages/PointsHistoryPage.ets` | 点击积分余额 | 已接入运行态 |
| `MonthFilterSheet.ets` | 积分页月份入口 | 积分页右上角 | 源 UI 已呈现，后端缺月份参数，暂未弹出筛选 |
| `VipBenefitPage.ets` | `pages/MemberBenefitPage.ets` | 福利页更多按钮 | 源页仅复用福利页；元服务展示已有会员组件信息 |
| `components/membership/.../MemberShipPage.ets` | `pages/MemberBenefitPage.ets` | 会员权益 | 已复用会员背景、权益结构与账户字段；IAP 未迁移 |

## 逐项差异

### 福利首页

- 已还原：福利标题区、积分余额入口、源背景、7 日签到、连续天数、签到状态、优惠券/日常任务 Tab、优惠券列表、领取/兑换状态、底部 Tab。
- 已纠正：删除本地 `points += 10` 模拟；签到和积分余额均使用 Java 接口返回值。
- 源程序没有：头像/昵称、多个会员等级主题、成长值、Banner 轮播、热门/限时福利、推荐商品、权益预览、规则弹窗、补签。
- 接口缺口：每日任务列表和领取接口、周签到掩码查询、普通领取券接口、福利运营位接口。

### 积分历史

- 已还原：标题、总积分、收入/支出 Tab、明细标题、时间、积分数值、空/失败/重试状态、滚动列表。
- 源程序只按 `amount > 0` 和 `< 0` 区分收入/支出；没有全部、过期、冻结、解冻、退回分类，也没有累计获得/使用和即将过期汇总。
- Java `PointsDetailInfoDTO.type` 目前只定义 `1=签到获得、2=兑换使用`，不支持冻结、解冻、退回、过期等独立状态。
- 月份筛选源程序存在，但当前 `/api/metaservice/user/points/detail` 不接收开始/结束时间；需补 `startTime/endTime` 或 `year/month`。

### 会员权益详情

- 源 `VipBenefitPage` 没有独立详情，只嵌套 `BenefitPage`；实际会员 UI 位于 `components/membership`。
- 已复用：`membership_back.png`、`member.png`、`privilege.png`、会员账户、等级、卡号、优惠券数、积分、过期积分、升级进度。
- 源会员组件支持套餐、权益数组、购买、隐私条款和 IAP 状态；Java 会员账户接口不返回权益列表/详情/次数/有效期，因此不能按权益类型生成真实详情。
- 缺接口：会员等级列表、权益列表、权益详情、权益使用/核销、有效期、剩余次数、不可用范围、FAQ、服务条款、会员过期/续费状态。

## 素材迁移清单

| 素材 | 源尺寸 | 校验 |
|---|---:|---|
| `bg_benefit.png` | 1080x2601 | 与源文件字节一致 |
| `ic_checked.png` | 103x120 | 与源文件字节一致 |
| `ic_expired.png` | 103x120 | 已存在元服务资源 |
| `ic_no_checked.png` | 103x120 | 已存在元服务资源 |
| `ic_points.png` | 48x48 | 已存在元服务资源 |
| `member.png` | 416x381 | 已存在元服务资源 |
| `member_empty.png` | 360x360 | 已存在元服务资源 |
| `membership_back.png` | 120x120 | 与源文件字节一致 |
| `privilege.png` | 120x120 | 已存在元服务资源 |

源程序没有会员等级徽章、福利 Banner、活动运营图、锁定/解锁权益图、福利专属空状态插画或字体文件，因此未使用占位素材补造。

## 状态映射

| 业务状态 | 接口值 | 元服务表现 |
|---|---|---|
| 未登录 | `userId <= 0` / 无 token | 登录引导，不展示会员或积分假数据 |
| 已签到 | `CheckInResultDTO.success=true` | 按钮禁用，刷新总积分与连续天数 |
| 重复签到 | `points=0` + 服务端 `message` | 展示服务端消息，不重复加积分 |
| 优惠券可兑换 | `exchangeable=true` | “立即兑换”可用 |
| 积分不足/活动状态异常 | `exchangeable=false` + `unavailableReason` | 禁用并显示服务端原因 |
| 会员等级 | `memberClassTLevel/memberClassTName` | 展示真实等级代码和名称 |
| 更高等级 | `nextLevelName/amountToNextLevel/levelProgress` | 展示升级条件和进度 |
| 积分收入/支出 | `points` 与 `type` | 当前按源程序正负规则呈现 |
| 接口失败 | HTTP/业务 `code != 0` | 不写入页面数据，展示失败/重试 |

会员过期、权益次数用尽、权益失效、活动未开始/已结束等状态当前没有对应源字段和 Java 返回字段，不能可靠映射。

## 接口字段映射

| 页面字段 | Java 字段 | 状态 |
|---|---|---|
| 当前积分 | `pointBalance` / `totalPoints` / `balance` | 已接入 |
| 签到奖励 | `CheckInResultDTO.points` | 已接入 |
| 连续签到 | `continuousDays` | 已接入 |
| 会员等级 | `memberClassTLevel/memberClassTName` | 已接入 |
| 升级进度 | `levelProgress/amountToNextLevel/nextLevelName` | 已接入 |
| 优惠券数量 | `availableCouponCount` | 已接入 |
| 即将过期积分 | `expiringPoints/nearestExpireAt` | 数值已接入；后端日期当前为空 |
| 积分流水 | `id/type/points/balance/title/remark/createTime/goodsId` | 已接入 |
| 兑换模板 | `couponTemplateId/couponName/pointsRequired/exchangeable/unavailableReason` | 已接入 |
| 任务 | 无 Java 接口 | 缺失 |
| 权益内容/状态/次数 | 无 Java 接口 | 缺失 |
| 会员有效期/过期状态 | 无会员账户字段 | 缺失 |
| 周签到每天状态 | 仅有签到结果，无查询接口 | 缺失 |

## 组件复用与重构

- 直接复用源媒体资源、福利背景和会员视觉资源。
- 将元服务网络访问集中在 `BenefitsApi`，页面只消费显式类型，避免重复拼装接口。
- 保留福利页内部 Builder 以贴合源页面结构；积分历史和会员权益拆为独立运行页面。
- 普通应用依赖的关系数据库、广告任务和 IAP Kit 没有直接移入元服务，避免引入受限 API。

## 验收限制

- HAP 可完成编译与打包，但项目没有 `signingConfigs`，命令行产物未签名，不能覆盖安装到模拟器进行本轮同尺寸截图。
- 真实登录态尚未接入 `AtomicHome`，因此运行默认值是未登录，不会请求带身份的会员接口。
- 服务端 `/api/metaservice/user/coupon/list` 仍返回空数组；福利页改用已实现的 `/member/coupon-templates` 和 `/member/coupons/exchange`。
