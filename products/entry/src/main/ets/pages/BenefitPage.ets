import { BenefitsApi, JavaApiClient, AtomicCheckInResult, AtomicCouponTemplate, AtomicMemberAccount, AtomicTask, BENEFITS_FRONTEND_MOCK, BenefitsMock } from '../data/JavaApiClient';

/** 福利页：保留源程序的积分总览、七日签到、优惠券/任务两个 Tab，并把写操作交给 Java 服务。 */
@Component
export struct BenefitPage {
  @Prop userId: number = 0;
  @Prop storeId: number = 0;
  @Prop tenantId: number = 0;
  openPage: (page: string) => void = () => {};
  @State signed: boolean = false;
  @State loading: boolean = false;
  @State tab: number = 0;
  @State points: number = 0;
  @State continuousDays: number = 0;
  @State message: string = '';
  @State coupons: AtomicCouponTemplate[] = [];
  @State tasks: AtomicTask[] = [];
  @State account: AtomicMemberAccount = {};

  aboutToAppear() { this.refresh(); }

  async refresh() {
    if (!JavaApiClient.hasToken() && (this.userId <= 0 || this.storeId <= 0 || this.tenantId <= 0)) {
      if (BENEFITS_FRONTEND_MOCK) { this.points = 40; this.account = BenefitsMock.account(); this.coupons = BenefitsMock.coupons(); this.tasks = BenefitsMock.tasks(); this.message = ''; return; }
      this.message = '登录后查看福利与会员权益';
      return;
    }
    this.loading = true;
    try {
      this.account = await BenefitsApi.memberAccount(this.tenantId, this.userId);
      this.points = Number(this.account.pointBalance || 0);
      const couponResp = await BenefitsApi.couponTemplates(this.tenantId, this.userId);
      this.coupons = couponResp.items || couponResp.list || [];
      this.tasks = await BenefitsApi.tasks();
    } catch (e) {
      if (BENEFITS_FRONTEND_MOCK) { this.points = 40; this.account = BenefitsMock.account(); this.coupons = BenefitsMock.coupons(); this.tasks = BenefitsMock.tasks(); this.message = ''; }
      else { this.message = '福利加载失败，请重试'; }
    } finally { this.loading = false; }
  }

  async signIn() {
    if (this.signed) return;
    if (!JavaApiClient.hasToken() && (this.userId <= 0 || this.storeId <= 0)) {
      if (BENEFITS_FRONTEND_MOCK) { this.signed = true; this.continuousDays = 1; this.points += 10; this.message = '模拟签到成功，积分已到账 +10'; }
      return;
    }
    this.loading = true;
    try {
      const result: AtomicCheckInResult = await BenefitsApi.checkIn(this.userId, this.storeId);
      this.signed = result.success === true;
      this.points = result.totalPoints || this.points;
      this.continuousDays = result.continuousDays || this.continuousDays;
      this.message = result.message || (this.signed ? `签到成功，积分已到账 +${result.points || 0}` : '今日已签到');
    } catch (e) {
      if (BENEFITS_FRONTEND_MOCK) { this.signed = true; this.continuousDays = Math.max(this.continuousDays, 1); this.points += 10; this.message = '接口不可用，模拟签到成功 +10'; }
      else { this.message = '签到失败，请稍后再试'; }
    }
    finally { this.loading = false; }
  }

  async exchange(item: AtomicCouponTemplate) {
    if (!item.couponTemplateId || item.exchangeable === false) { this.message = item.unavailableReason || '当前不可兑换'; return; }
    if (BENEFITS_FRONTEND_MOCK && this.userId <= 0) {
      const cost = item.pointsRequired || 0;
      if (this.points < cost) { this.message = `积分不足，还需要 ${cost - this.points} 分`; return; }
      this.points -= cost; this.message = `模拟兑换成功，扣除 ${cost} 积分`; return;
    }
    try {
      await BenefitsApi.exchangeCoupon(this.tenantId, this.userId, item.couponTemplateId);
      this.message = '优惠券兑换成功';
      await this.refresh();
    } catch (e) {
      if (BENEFITS_FRONTEND_MOCK) {
        const cost = item.pointsRequired || 0;
        if (this.points < cost) { this.message = `积分不足，还需要 ${cost - this.points} 分`; return; }
        this.points -= cost; this.message = `接口不可用，模拟兑换成功，扣除 ${cost} 积分`;
      } else { this.message = '兑换失败，请稍后再试'; }
    }
  }

  build() {
    Column() {
      Row() {
        Text('福利').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#182230');
        Blank();
        Image($r('app.media.ic_more')).width(24).height(24).onClick(() => this.openPage('会员权益'));
      }
      .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White);
      if (!BENEFITS_FRONTEND_MOCK && !JavaApiClient.hasToken()) {
        Column({ space: 14 }) { Text('登录后查看福利').fontSize(20).fontWeight(FontWeight.Bold); Text('同步积分、签到、优惠券和会员权益').fontSize(14).fontColor('#7A8699'); Button('去登录').width('100%').height(46).backgroundColor('#0A59F7').fontColor(Color.White); }.padding(28).layoutWeight(1).justifyContent(FlexAlign.Center);
      } else {
        Scroll() { Column({ space: 12 }) {
          Row({ space: 8 }) { Image($r('app.media.ic_points')).width(20).height(20); Text('积分余额').fontSize(16); Text(`${this.points}`).fontSize(25).fontWeight(FontWeight.Bold); Blank(); Text('›').fontSize(24).fontColor('#0A59F7'); }.width('100%').height(30).onClick(() => this.openPage('积分明细'));
          Text(this.signed ? '今日积分已领取，每100积分可抵扣快递费5元' : '今天还没有签到，快点击签到领取积分吧~').fontSize(12).fontColor('#576275');
          this.signCard();
          Row({ space: 12 }) { this.tabButton('优惠券', 0); this.tabButton('日常任务', 1); }.width('100%');
          if (this.tab === 0) {
            if (this.coupons.length > 0) {
              ForEach(this.coupons, (item: AtomicCouponTemplate) => this.coupon(item), (item: AtomicCouponTemplate) => `${item.couponTemplateId}`);
            } else {
              this.emptyState('暂无可兑换优惠券');
            }
          } else {
            this.taskPanel();
          }
          if (this.message) Text(this.message).fontSize(12).fontColor('#576275').margin({ top: 4 });
        }.padding({ left: 16, right: 16, bottom: 20 }).justifyContent(FlexAlign.Start); }
        .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top);
      }
    }.width('100%').height('100%').backgroundImage($r('app.media.bg_benefit'))
      .backgroundImageSize({ width: '100%', height: '100%' })
      .backgroundImageResizable({ slice: { left: '0px', top: '520px', right: '0px', bottom: '900px' } });
  }

  @Builder signCard() { Column({ space: 14 }) { Row() { Text('签到7天 赚积分').fontSize(16).fontWeight(FontWeight.Bold); Blank(); Text(`已打卡${this.continuousDays}/7天`).fontSize(12).fontColor('#576275'); }.width('100%'); Row() { ForEach([5, 5, 5, 5, 5, 5, 10], (reward: number, index: number) => Column({ space: 6 }) { Image($r(index < this.continuousDays ? 'app.media.ic_checked' : index === 0 ? 'app.media.ic_expired' : 'app.media.ic_no_checked')).width(34).height(40); Text(index < this.continuousDays ? '已完成' : index === 0 ? '已过期' : `第${index + 1}天`).fontSize(11).fontColor('#576275'); }); }.width('100%').justifyContent(FlexAlign.SpaceAround); Button(this.signed ? '已签到' : '立即签到').width('100%').height(40).enabled(!this.signed && !this.loading).backgroundColor(this.signed ? '#999999' : '#0A59F7').fontColor(Color.White).onClick(() => this.signIn()); }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(16); }
  @Builder tabButton(title: string, index: number) { Button(title).width(84).height(32).borderRadius(18).backgroundColor(this.tab === index ? '#0A59F7' : '#E7E9EC').fontColor(this.tab === index ? Color.White : '#182230').onClick(() => this.tab = index); }
  @Builder coupon(item: AtomicCouponTemplate) { Row() { Column({ space: 6 }) { Text(`积分兑换 ${item.pointsRequired || 0}`).fontSize(18).fontColor('#0A59F7').fontWeight(FontWeight.Bold); Text(item.couponName || '').fontSize(15).fontWeight(FontWeight.Medium); Text(item.usageRestriction || item.description || '').fontSize(12).fontColor('#7A8699'); }.alignItems(HorizontalAlign.Start).layoutWeight(1); Button(item.exchangeable === false ? (item.unavailableReason || '不可兑换') : '立即兑换').enabled(item.exchangeable !== false).height(34).padding({ left: 16, right: 16 }).borderRadius(18).backgroundColor(item.exchangeable === false ? '#D7DADF' : '#0A59F7').fontColor(item.exchangeable === false ? '#7A8699' : Color.White).onClick(() => this.exchange(item)); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16); }
  @Builder taskPanel() {
    Column({ space: 14 }) {
      if (this.tasks.length > 0) {
        ForEach(this.tasks, (item: AtomicTask) => this.task(item), (item: AtomicTask) => `${item.id}`);
      } else {
        this.emptyState('暂无日常任务');
      }
    }.width('100%').margin({ top: -12 });
  }

  @Builder task(item: AtomicTask) {
    Row() {
      Column({ space: 6 }) {
        Row({ space: 6 }) {
          Text(item.title || '').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#182230');
          Text(`+${item.rewardValue || 0}`).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#0A59F7');
          if ((item.targetCount || 0) > 1) {
            Text(`(${item.currentCount || 0}/${item.targetCount || 0})`).fontSize(12).fontColor('#7A8699');
          }
        }
        Text(item.description || '').fontSize(12).fontColor('#7A8699');
      }.alignItems(HorizontalAlign.Start).layoutWeight(1);
      Button(this.taskButtonText(item))
        .width(78).height(34).fontSize(14).borderRadius(17)
        .backgroundColor(item.isReceived ? '#E7E9EC' : '#0A59F7')
        .fontColor(item.isReceived ? '#7A8699' : Color.White)
        .enabled(!item.isReceived && !this.loading)
        .onClick(() => this.handleTask(item));
    }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16);
  }

  private taskButtonText(item: AtomicTask): string {
    if (item.isReceived) return '已领取';
    if (item.isFinished) return '领取';
    return item.actionText || '去完成';
  }

  private async handleTask(item: AtomicTask) {
    if (item.actionText === '去签到') {
      await this.signIn();
      if (this.signed) {
        this.tasks.forEach((task: AtomicTask) => {
          if (task.id === item.id) {
            task.isFinished = true;
            task.isReceived = true;
            task.currentCount = task.targetCount || 1;
          }
        });
      }
      return;
    }
    if (item.actionText === '去寄件') {
      this.openPage('寄件|寄快递');
      return;
    }
    if (this.userId > 0 && item.id !== undefined) {
      try {
        const result = await BenefitsApi.claimTask(item.id, `${Date.now()}-${item.id}`);
        this.tasks.forEach((task: AtomicTask) => {
          if (task.id === item.id) {
            task.isFinished = true;
            task.isReceived = true;
            task.currentCount = task.targetCount || 1;
          }
        });
        this.points = Number(result.account?.balance || this.points + Number(result.points || 0));
        this.message = result.message || `任务完成，积分已到账 +${result.points || 0}`;
      } catch (e) {
        this.message = '任务领取失败，请稍后再试';
      }
      return;
    }
    this.tasks.forEach((task: AtomicTask) => {
      if (task.id === item.id) {
        task.isFinished = true;
        task.isReceived = true;
        task.currentCount = item.targetCount || 1;
      }
    });
    this.points += item.rewardValue || 0;
    this.message = `任务完成，积分已到账 +${item.rewardValue || 0}`;
  }

  @Builder emptyState(text: string) {
    Text(text).width('100%').textAlign(TextAlign.Center).fontSize(13).fontColor('#7A8699').padding({ top: 16, bottom: 8 });
  }
}
