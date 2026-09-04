export interface MockUserProfile {
  userId: string;
  nickname: string;
  realName: string;
  gender: string;
  phone: string;
  email: string;
  birthday: string;
  region: string;
  signature: string;
  memberLevel: string;
  memberExpireAt: string;
  realNameStatus: string;
  avatar: Resource;
}

export interface MockCoupon {
  id: string;
  name: string;
  kind: string;
  amount: string;
  rule: string;
  company: string;
  valid: string;
  status: string;
  reason?: string;
}

export interface MockAgreement {
  type: string;
  title: string;
  version: string;
  effectiveAt: string;
  content: string;
}

export class AccountMockApi {
  static profile(): MockUserProfile {
    return {
      userId: 'YQD-10008642', nickname: '快递用户', realName: '未认证', gender: '保密',
      phone: '138****8900', email: '未绑定', birthday: '未设置', region: '未设置',
      signature: '记录每一次安心寄件', memberLevel: '普通用户', memberExpireAt: '未开通',
      realNameStatus: '未认证', avatar: $r('app.media.ic_default_avatar')
    };
  }

  static coupons(): MockCoupon[] {
    return [
      { id: 'c1', name: '寄件满减券', kind: '满减券', amount: '¥10', rule: '满¥30可用', company: '全平台快递', valid: '2026-12-31', status: '可使用' },
      { id: 'c2', name: '会员专享折扣券', kind: '折扣券', amount: '9折', rule: '会员寄件可用', company: '指定快递公司', valid: '2026-10-20', status: '可使用' },
      { id: 'c3', name: '新客运费券', kind: '运费券', amount: '¥8', rule: '首单可用', company: '全平台快递', valid: '2026-08-01', status: '已使用' },
      { id: 'c4', name: '活动专享券', kind: '活动券', amount: '¥20', rule: '满¥100可用', company: '顺丰', valid: '2026-05-01', status: '已过期', reason: '已超过使用期限' }
    ];
  }

  static agreements(): MockAgreement[] {
    const content = '本页面展示源程序正式协议内容。当前元服务使用本地 mock 数据，后续将切换为 Java 服务端下发的正式文本。\n\n一、服务说明\n我们将按照协议约定提供快递寄件、订单查询、会员和优惠券服务。\n\n二、个人信息保护\n个人信息的收集、使用、共享和删除以正式隐私政策为准。\n\n三、联系我们\n如有疑问，请通过意见反馈或客服入口联系我们。';
    return [
      { type: 'privacy', title: '隐私政策', version: 'v1.0.0', effectiveAt: '2026-08-01', content },
      { type: 'user', title: '用户协议', version: 'v1.0.0', effectiveAt: '2026-08-01', content },
      { type: 'third', title: '第三方信息共享清单', version: 'v1.0.0', effectiveAt: '2026-08-01', content },
      { type: 'personal', title: '个人信息收集清单', version: 'v1.0.0', effectiveAt: '2026-08-01', content }
    ];
  }
}
