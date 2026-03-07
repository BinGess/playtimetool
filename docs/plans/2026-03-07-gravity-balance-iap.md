# 平衡边缘 1 元永久解锁开发计划

## 目标

- 只对 `平衡边缘 / Gravity Balance` 启用付费墙。
- 用户支付 `1 元` 后永久解锁该游戏。
- 已购用户支持恢复购买。
- 不能只在首页拦截，必须覆盖直接路由访问。

## 本次代码改动

1. 商品目录
   - 新增商品 ID：`com.partygames.playtimetool.gravity_balance_unlock`
   - 绑定路由：
     - `/games/gravity-balance`
     - `/games/gravity-balance/play`

2. 付费墙生效策略
   - `IAP` 付费墙默认开启。
   - 调试环境保留开关，正式环境强制开启，不向用户暴露关闭入口。

3. 入口层交互
   - Hub 中仅给 `平衡边缘` 卡片展示锁定态。
   - 锁定徽标显示 `¥1 解锁`。
   - 点击时弹出购买/恢复购买弹窗。

4. 路由层保护
   - 为 `平衡边缘` 准备页和正式游戏页增加 `PurchaseGate`。
   - 即使通过深链或内部直接跳转，也不能绕过购买。

5. 购买页文案
   - 明确 `1 元永久解锁`
   - 提示 `一次购买，永久可玩`
   - 提示 `支持恢复购买`

6. 测试
   - 校验商品目录只包含有效路由。
   - 校验 Hub 只显示一个锁定卡片。

## 商店后台仍需配置

这部分不能仅靠本地代码完成，发版前必须在两端后台补齐：

- App Store Connect
  - 创建 `Non-Consumable` 商品：`com.partygames.playtimetool.gravity_balance_unlock`
  - 定价设为 `CNY 1`
  - 补齐本地化标题与描述

- Google Play Console
  - 创建 `In-app product`：`com.partygames.playtimetool.gravity_balance_unlock`
  - 类型设为一次性非消耗型购买
  - 价格设为 `CNY 1`

## 验收标准

- 未购买时，首页“平衡边缘”显示锁定徽标。
- 未购买时，进入“平衡边缘”任一路由都会看到购买页。
- 购买成功后，同设备再次进入无需重复购买。
- 恢复购买后，可重新进入“平衡边缘”。
