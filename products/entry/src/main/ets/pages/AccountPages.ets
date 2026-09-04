import { AccountMockApi, MockAgreement, MockCoupon, MockUserProfile } from '../data/AccountMockApi';

@Component
export struct AccountPageHeader {
  @Prop title: string = '';
  @Prop onBack: () => void = () => {};
  build() {
    Row() {
      Button() { Image($r('app.media.ic_back')).width(22).height(22); }
        .width(44).height(44).padding(0).type(ButtonType.Circle)
        .backgroundColor('#E9EBED').onClick(() => this.onBack());
      Text(this.title).fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 12 });
    }.width('100%').height(76).padding({ left: 21, right: 18 }).backgroundColor('#F4F6F8');
  }
}

@Component
export struct PersonalInfoMockPage {
  @Prop onBack: () => void = () => {};
  @State profile: MockUserProfile = AccountMockApi.profile();
  @State editing: boolean = false;
  @State nickname: string = '';
  @State saved: boolean = false;
  aboutToAppear() { this.nickname = this.profile.nickname; }
  build() {
    Column() {
      AccountPageHeader({ title: '个人信息', onBack: this.onBack });
      Scroll() { Column({ space: 12 }) {
        Row() { Image(this.profile.avatar).width(64).height(64).borderRadius(32); Column({ space: 4 }) { Text(this.profile.nickname).fontSize(18).fontWeight(FontWeight.Bold); Text(`用户 ID  ${this.profile.userId}`).fontSize(12).fontColor('#7A8699'); }.alignItems(HorizontalAlign.Start).margin({ left: 12 }); Blank(); Button('修改').fontColor('#0A59F7').backgroundColor('#F0F1F3').borderRadius(18).onClick(() => this.editing = true); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16);
        if (this.editing) { Column({ space: 10 }) { Text('昵称').fontSize(13).fontColor('#7A8699'); TextInput({ text: this.nickname, placeholder: '请输入昵称' }).onChange((v: string) => this.nickname = v).height(44).backgroundColor('#F5F6F8'); Row({ space: 10 }) { Button('取消').layoutWeight(1).onClick(() => this.editing = false); Button('保存').layoutWeight(1).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => { this.profile.nickname = this.nickname; this.editing = false; this.saved = true; }); }.width('100%'); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(12); }
        this.infoRow('姓名/实名状态', this.profile.realNameStatus);
        this.infoRow('性别', this.profile.gender);
        this.infoRow('手机号', this.profile.phone);
        this.infoRow('邮箱', this.profile.email);
        this.infoRow('出生日期', this.profile.birthday);
        this.infoRow('所在地区', this.profile.region);
        this.infoRow('个性签名', this.profile.signature);
        this.infoRow('会员等级', `${this.profile.memberLevel}  ·  ${this.profile.memberExpireAt}`);
        this.infoRow('账号绑定', '华为账号已绑定');
        if (this.saved) Text('资料已保存').fontSize(13).fontColor('#0A59F7');
      }.padding(16); }.layoutWeight(1).scrollBar(BarState.Off);
    }.width('100%').height('100%').backgroundColor('#F4F6F8');
  }
  @Builder infoRow(label: string, value: string) { Row() { Text(label).fontSize(15).layoutWeight(1); Text(value).fontSize(14).fontColor('#7A8699'); }.width('100%').padding(16).backgroundColor(Color.White); }
}

@Component
export struct CouponMockPage {
  @Prop onBack: () => void = () => {};
  @State tab: number = 0;
  @State coupons: MockCoupon[] = AccountMockApi.coupons();
  build() {
    Column() { AccountPageHeader({ title: '我的优惠券', onBack: this.onBack });
      Row() { this.tabButton('可使用', 0); this.tabButton('已使用', 1); this.tabButton('已过期', 2); }.width('100%').padding(12).backgroundColor(Color.White);
      Scroll() { Column({ space: 12 }) { ForEach(this.filtered(), (item: MockCoupon) => { this.couponCard(item); }, (item: MockCoupon) => item.id); if (this.filtered().length === 0) { Column({ space: 10 }) { Image($r('app.media.ic_search_empty')).width(80).height(80); Text('暂无优惠券').fontSize(14).fontColor('#7A8699'); }.padding(40); } }.padding(16).justifyContent(FlexAlign.Start); }.layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off);
    }.width('100%').height('100%').backgroundColor('#F4F6F8');
  }
  private filtered(): MockCoupon[] { const state = this.tab === 0 ? '可使用' : this.tab === 1 ? '已使用' : '已过期'; return this.coupons.filter((item: MockCoupon) => item.status === state); }
  @Builder tabButton(text: string, index: number) { Button(text).layoutWeight(1).fontColor(this.tab === index ? '#0A59F7' : '#7A8699').backgroundColor(Color.Transparent).onClick(() => this.tab = index); }
  @Builder couponCard(item: MockCoupon) { Column({ space: 8 }) { Row() { Column({ space: 4 }) { Text(item.amount).fontSize(24).fontWeight(FontWeight.Bold).fontColor(item.status === '可使用' ? '#F05A4F' : '#9AA3AF'); Text(item.kind).fontSize(12).fontColor('#7A8699'); }.width(76); Column({ space: 5 }) { Text(item.name).fontSize(16).fontWeight(FontWeight.Medium); Text(item.rule).fontSize(13).fontColor('#576275'); Text(item.company).fontSize(12).fontColor('#8A94A3'); }.alignItems(HorizontalAlign.Start).layoutWeight(1); if (item.status === '可使用') Button('立即使用').fontColor('#0A59F7').backgroundColor(Color.Transparent); else Text(item.status).fontSize(13).fontColor('#9AA3AF'); }.width('100%'); Divider().color('#E7EAF0'); Row() { Text(`有效期至 ${item.valid}`).fontSize(12).fontColor('#8A94A3').layoutWeight(1); if (item.reason) Text(item.reason).fontSize(12).fontColor('#C44747'); }.width('100%'); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(10); }
}

@Component
export struct AgreementMockPage {
  @Prop title: string = '隐私政策';
  @Prop onBack: () => void = () => {};
  @State agreement: MockAgreement = AccountMockApi.agreements()[0];
  aboutToAppear() { const found = AccountMockApi.agreements().find((item: MockAgreement) => item.title === this.title); if (found) this.agreement = found; }
  build() { Column() { AccountPageHeader({ title: this.agreement.title, onBack: this.onBack }); Row() { Text(`版本 ${this.agreement.version}`).fontSize(12).fontColor('#7A8699').layoutWeight(1); Text(`生效日期 ${this.agreement.effectiveAt}`).fontSize(12).fontColor('#7A8699'); }.width('100%').padding(16).backgroundColor(Color.White); Scroll() { Text(this.agreement.content).fontSize(14).fontColor('#3E4653').lineHeight(25).width('100%').padding(18); }.layoutWeight(1); }.width('100%').height('100%').backgroundColor('#F4F6F8'); }
}

@Component
export struct SettingsMockPage {
  @Prop onBack: () => void = () => {};
  @Prop open: (page: string) => void = () => {};
  @State loggedIn: boolean = true;
  build() { Column() { AccountPageHeader({ title: '设置', onBack: this.onBack }); Scroll() { Column({ space: 10 }) { this.group('账号与安全', [['个人信息', '个人信息'], ['隐私设置', '隐私设置'], ['实名认证', '实名认证']]); this.group('服务与协议', [['会员管理', '会员购买'], ['用户协议', '用户协议'], ['隐私政策', '隐私政策']]); this.group('应用', [['清除缓存', 'cache'], ['关于我们', 'about'], ['意见反馈', 'feedback']]); if (this.loggedIn) Button('退出登录').width('100%').height(46).margin({ top: 12 }).backgroundColor(Color.White).fontColor('#C44747').onClick(() => { this.loggedIn = false; }); }.padding(16); }.layoutWeight(1).scrollBar(BarState.Off); }.width('100%').height('100%').backgroundColor('#F4F6F8'); }
  @Builder group(title: string, items: string[][]) { Column({ space: 0 }) { Text(title).fontSize(13).fontColor('#7A8699').padding({ left: 4, bottom: 8 }); ForEach(items, (item: string[]) => { Row() { Text(item[0]).fontSize(15).layoutWeight(1); Text('›').fontSize(22).fontColor('#A0A8B5'); }.width('100%').padding(16).backgroundColor(Color.White).onClick(() => this.open(item[1])); }, (item: string[]) => item[1]); }.width('100%'); }
}

@Component
export struct PrivacySettingsMockPage {
  @Prop onBack: () => void = () => {};
  @State recommend: boolean = true;
  @State marketing: boolean = false;
  build() { Column() { AccountPageHeader({ title: '隐私设置', onBack: this.onBack }); Scroll() { Column({ space: 10 }) { this.switchRow('个性化推荐', '根据偏好推荐服务内容', this.recommend, (v: boolean) => this.recommend = v); this.switchRow('营销信息接收', '接收活动和优惠提醒', this.marketing, (v: boolean) => this.marketing = v); this.statusRow('位置信息授权', '系统权限状态：未开启'); this.statusRow('相机和相册权限', '系统权限状态：按需申请'); this.statusRow('通知权限', '系统权限状态：按系统设置'); this.statusRow('剪贴板使用说明', '仅在业务需要时读取'); this.statusRow('个人信息下载、更正和删除', '提交申请'); }.padding(16); }.layoutWeight(1); }.width('100%').height('100%').backgroundColor('#F4F6F8'); }
  @Builder switchRow(title: string, desc: string, value: boolean, onChange: (v: boolean) => void) { Row() { Column({ space: 4 }) { Text(title).fontSize(15); Text(desc).fontSize(12).fontColor('#7A8699'); }.alignItems(HorizontalAlign.Start).layoutWeight(1); Toggle({ type: ToggleType.Switch, isOn: value }).onChange((v: boolean) => onChange(v)); }.width('100%').padding(16).backgroundColor(Color.White); }
  @Builder statusRow(title: string, value: string) { Row() { Column({ space: 4 }) { Text(title).fontSize(15); Text(value).fontSize(12).fontColor('#7A8699'); }.alignItems(HorizontalAlign.Start).layoutWeight(1); Text('›').fontSize(22).fontColor('#A0A8B5'); }.width('100%').padding(16).backgroundColor(Color.White); }
}

@Component
export struct PurchaseMockPage {
  @Prop onBack: () => void = () => {};
  @State selected: number = 1;
  @State message: string = '';
  build() { Column() { AccountPageHeader({ title: '会员购买', onBack: this.onBack }); Scroll() { Column({ space: 14 }) { Column({ space: 5 }) { Text('当前会员身份').fontSize(13).fontColor('#7A8699'); Text('普通用户').fontSize(22).fontWeight(FontWeight.Bold); Text('未开通会员').fontSize(13).fontColor('#7A8699'); }.width('100%').padding(18).backgroundColor(Color.White).borderRadius(12); Text('选择套餐').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start); this.plan('月卡', '¥18', 0); this.plan('季卡', '¥48', 1); this.plan('年卡', '¥128', 2); Text('会员权益').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start); this.benefit('会员寄件折扣', '寄快递享专属价格'); this.benefit('每月优惠券', '会员专享券持续发放'); if (this.message.length > 0) Text(this.message).fontSize(13).fontColor('#0A59F7'); Button('立即开通').width('100%').height(46).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.message = '当前使用 mock 支付，订单接口接入后启用'); }.padding(16); }.layoutWeight(1); }.width('100%').height('100%').backgroundColor('#F4F6F8'); }
  @Builder plan(name: string, price: string, index: number) { Row() { Column({ space: 5 }) { Text(name).fontSize(16).fontWeight(FontWeight.Medium); Text('连续包月可随时取消').fontSize(12).fontColor('#7A8699'); }.alignItems(HorizontalAlign.Start).layoutWeight(1); Text(price).fontSize(21).fontWeight(FontWeight.Bold).fontColor('#F05A4F'); Radio({ value: name, group: 'plans' }).checked(this.selected === index).onClick(() => this.selected = index); }.width('100%').padding(16).backgroundColor(this.selected === index ? '#EEF5FF' : Color.White).borderRadius(10); }
  @Builder benefit(title: string, desc: string) { Row() { Image($r('app.media.privilege')).width(32).height(32); Column({ space: 4 }) { Text(title).fontSize(15); Text(desc).fontSize(12).fontColor('#7A8699'); }.alignItems(HorizontalAlign.Start).margin({ left: 10 }); }.width('100%').padding(14).backgroundColor(Color.White); }
}
