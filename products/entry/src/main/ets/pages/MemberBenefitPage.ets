import { AtomicMemberAccount, BenefitsApi, BENEFITS_FRONTEND_MOCK, BenefitsMock } from '../data/JavaApiClient';

@Component
export struct MemberBenefitPage {
  @Prop userId: number = 0;
  @Prop tenantId: number = 0;
  close: () => void = () => {};
  @State account: AtomicMemberAccount = {};
  @State failed: boolean = false;
  @State actionMessage: string = '';

  get opened() {
    return !!this.account.memberCardNo;
  }
  aboutToAppear() { this.load(); }
  async load() {
    if (this.userId <= 0 || this.tenantId <= 0) { if (BENEFITS_FRONTEND_MOCK) this.account = BenefitsMock.account(); return; }
    try { this.account = await BenefitsApi.memberAccount(this.tenantId, this.userId); }
    catch (e) { if (BENEFITS_FRONTEND_MOCK) this.account = BenefitsMock.account(); else this.failed = true; }
  }
  build() { Column() {
    if (this.failed) {
      Column({ space: 12 }) { Image($r('app.media.ic_warning')).width(56).height(56); Text('会员信息加载失败').fontSize(15).fontColor('#576275'); Button('重新加载').height(42).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.load()); }.layoutWeight(1).justifyContent(FlexAlign.Center);
    } else {
      Scroll() { Column({ space: 14 }) {
        this.memberCard();
        Text('会员权益').fontSize(18).fontWeight(FontWeight.Bold).width('100%').textAlign(TextAlign.Start);
        Row({ space: 12 }) { this.metric('积分余额', this.account.pointBalance || '0'); this.metric('可用优惠券', `${this.account.availableCouponCount || 0} 张`); }.width('100%');
        this.growthCard();
        this.exchangeCard();
        if (this.actionMessage) Text(this.actionMessage).fontSize(12).fontColor('#576275').width('100%').textAlign(TextAlign.Center);
        Button(this.opened ? '会员管理' : '立即开通').width('100%').height(46).backgroundColor('#0A59F7').fontColor(Color.White).borderRadius(23)
          .onClick(() => this.actionMessage = this.opened ? '会员管理功能即将开放' : '请先登录后开通会员');
      }.width('100%').padding({ left: 16, right: 16, bottom: 16 }); }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off);
    }
  }.width('100%').height('100%').backgroundColor('#F4F6F8'); }
  @Builder metric(label: string, value: string) { Column({ space: 5 }) { Text(value).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#0A59F7'); Text(label).fontSize(13).fontColor('#7A8699'); }.layoutWeight(1).padding(14).backgroundColor(Color.White).borderRadius(12); }

  @Builder memberCard() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Image($r('app.media.member_diamond')).width('100%').height(180).objectFit(ImageFit.Cover).borderRadius(16);
      Image($r('app.media.member')).width(100).height(100).opacity(0.55).margin({ top: 24, right: 20 });
      Column({ space: 8 }) {
        Text(this.opened ? (this.account.memberClassTName || '普通会员') : '普通会员')
          .fontSize(21).fontWeight(FontWeight.Bold).fontColor(Color.White);
        Text(this.opened ? `会员卡号 ${this.account.memberCardNo}` : '开通会员，享受专属权益')
          .fontSize(12).fontColor('#EAF2FF');
        if (this.opened) {
          Text('有效会员 · 专属寄件优惠').fontSize(11).fontColor('#EAF2FF').opacity(0.9);
        }
      }.alignItems(HorizontalAlign.Start).position({ left: 18, top: 28 });
    }
  }

  @Builder growthCard() {
    Column({ space: 10 }) {
      Row() {
        Text('会员成长').fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1);
        Text(this.opened ? `距${this.account.nextLevelName || '银卡会员'}还需 ${this.account.amountToNextLevel || 0}` : '开通后开始成长')
          .fontSize(13).fontColor('#7A8699');
      }.width('100%');
      Progress({ value: this.opened ? (this.account.levelProgress || 0) : 0, total: 100, type: ProgressType.Linear })
        .width('100%').color('#0A59F7');
    }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16);
  }

  @Builder exchangeCard() {
    Column({ space: 8 }) {
      Row() { Text('会员兑换').fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1); Text('查看全部 ›').fontSize(13).fontColor('#7A8699'); }.width('100%');
      if (this.opened) {
        Text('暂无可兑换会员套餐').fontSize(14).fontColor('#7A8699').margin({ top: 8 });
      } else {
        Text('开通会员后可兑换专属套餐和优惠券').fontSize(14).fontColor('#7A8699').margin({ top: 8 });
      }
      Image($r('app.media.member_empty')).width(88).height(88);
    }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16);
  }
}
