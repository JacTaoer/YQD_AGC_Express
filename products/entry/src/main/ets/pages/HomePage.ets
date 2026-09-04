import { AdvertisementComponent } from 'module_advertisement';

@Component
export struct HomePage {
  // 首页入口通过双向状态通知外层容器切换详情视图。
  @Link detail: string;
  // 由公开配置下发的华为广告位 ID；为空时不展示广告区域。
  adUnitId: string = '';
  onOpenExpress: () => void = () => {};
  onOpenUnpaid: () => void = () => {};
  onOpenCustomer: () => void = () => {};
  @State brandShift: number = 0;
  private brandTimer: number = 0;
  private brandItems: string[] = [
    '圆通', '申通', '京东标快', '韵达', '中通', '顺丰标快',
    '德邦标快', '菜鸟速递', '德邦快运', 'EMS', '极兔', '顺心捷达'
  ];

  aboutToAppear() {
    this.brandTimer = setInterval(() => {
      this.brandShift = (this.brandShift + 1) % 760;
    }, 45);
  }

  aboutToDisappear() {
    if (this.brandTimer > 0) {
      clearInterval(this.brandTimer);
      this.brandTimer = 0;
    }
  }

  private handleAction(action: string): void {
    this.detail = action;
  }
  build() {
    Column() {
      Row() {
        Text('首页').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#182230');
      }.width('100%').height(56).padding({ left: 16 }).backgroundColor(Color.White);
      Scroll() {
        Column() {
          Image($r('app.media.banner_image2')).width('100%').height(150).objectFit(ImageFit.Fill);
        this.eventCard();
        this.serviceDashboard();
        this.quickServiceGrid();
        if (this.adUnitId.trim().length > 0) {
          AdvertisementComponent({ testAd: this.adUnitId, adType: 8 })
            .width('calc(100% - 32vp)').height(150).margin({ top: 12, bottom: 24 });
        }
        }.width('100%').backgroundColor('#F1F3F5');
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off);
    }.width('100%').height('100%');
  }

  @Builder
  eventCard() {
    Column() {
      Row() {
        Image($r('app.media.ic_vip')).width(24).height(24);
        Text('开通会员').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#936900').margin({ left: 8 });
        Text('可领 788元 优惠礼包').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#936900').layoutWeight(1).margin({ left: 12 });
        Text('去开通').fontSize(13).fontColor('#0A59F7').backgroundColor('#DCE8FF').borderRadius(18).padding(9).onClick(() => this.handleAction('会员|开通会员'));
      }.width('100%').height(40).padding({ left: 12, right: 12 }).backgroundColor('#F2E7C9').borderRadius({ topLeft: 16, topRight: 16 });
      Row() {
        Image($r('app.media.ic_home_Event')).width(24).height(24);
        Column() { Text('邀请好友注册下单').fontSize(14).fontWeight(FontWeight.Medium); Text('领取优惠券礼包').fontSize(12).fontColor('#0A59F7').margin({ top: 4 }); }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 8 });
        Text('去邀请').fontSize(13).fontColor('#0A59F7').backgroundColor('#DCE8FF').borderRadius(18).padding(9).onClick(() => this.handleAction('邀请好友'));
      }.width('100%').height(58).padding({ left: 12, right: 12 }).backgroundColor(Color.White).borderRadius({ bottomLeft: 16, bottomRight: 16 });
    }.width('calc(100% - 32vp)').height(100).margin({ left: 16, right: 16, top: 0 });
  }

  @Builder
  serviceDashboard() {
    Row({ space: 10 }) {
      Stack() {
        Image($r('app.media.nav_express')).width('100%').height(156).objectFit(ImageFit.Fill);
        Column({ space: 6 }) {
          Text('寄快递').fontSize(18).fontWeight(FontWeight.Medium).fontColor(Color.White);
          Text('寄件立享优惠').fontSize(12).fontColor('#EEF0FF');
          Button('去寄件>').height(30).fontSize(13).fontColor('#384FD7')
            .padding({ left: 14, right: 14 }).borderRadius(15)
            .linearGradient({ angle: 0, colors: [['#FFFFFF', 0.34], ['#D2D8FF', 1]] })
            .onClick(() => this.handleAction('寄件|寄快递'));
        }.width('100%').alignItems(HorizontalAlign.Start).position({ left: 16, top: 14 });
      }.layoutWeight(1).height(156);
      Column({ space: 10 }) {
        Stack() {
          Image($r('app.media.nav_search')).width('100%').height(73).objectFit(ImageFit.Fill);
          Column({ space: 4 }) { Text('查运费').fontSize(17).fontWeight(FontWeight.Medium).fontColor(Color.White); Text('多品牌优惠比价').fontSize(12).fontColor('#EEF0FF'); }
            .width('100%').alignItems(HorizontalAlign.Start).position({ left: 14, top: 11 });
        }.layoutWeight(1).width('100%').onClick(() => this.handleAction('寄件|查运费'));
        Stack() {
          Image($r('app.media.nav_order')).width('100%').height(73).objectFit(ImageFit.Fill);
          Column({ space: 4 }) { Text('订单明细').fontSize(17).fontWeight(FontWeight.Medium).fontColor(Color.White); Text('查看快递进度').fontSize(12).fontColor('#EEF0FF'); }
            .width('100%').alignItems(HorizontalAlign.Start).position({ left: 14, top: 11 });
        }.layoutWeight(1).width('100%').onClick(() => this.onOpenExpress());
      }.layoutWeight(1).height(156);
    }
    .width('calc(100% - 32vp)').height(156).margin({ left: 16, right: 16, top: 4 });
  }

  @Builder
  cooperationBrands() {
    Column({ space: 10 }) {
      Text('合作品牌').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#182230').alignSelf(ItemAlign.Start);
      Stack() {
        Row({ space: 8 }) {
          ForEach(this.brandItems, (item: string) => {
            this.brandCard(item);
          }, (item: string) => item);
          ForEach(this.brandItems, (item: string) => {
            this.brandCard(item);
          }, (item: string) => `copy-${item}`);
        }.offset({ x: -this.brandShift, y: 0 });
      }.width('100%').height(62).clip(true);
    }
    .width('calc(100% - 32vp)').margin({ left: 16, right: 16, top: 16, bottom: 14 });
  }

  @Builder
  quickServiceGrid() {
    Row() {
      this.quickServiceItem($r('app.media.quick_large'), '寄大件', '寄件|寄大件');
      this.quickServiceItem($r('app.media.quick_fee'), '补缴运费', '查快递|补缴运费');
      this.quickServiceItem($r('app.media.quick_prohibited'), '违禁品', '违禁品说明');
      this.quickServiceItem($r('app.media.quick_support'), '联系客服', '客服|咨询客服');
    }
    .width('calc(100% - 32vp)')
    .height(126)
    .margin({ left: 16, right: 16, top: 12 })
    .padding({ left: 8, right: 8, top: 10, bottom: 8 })
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(16);
  }

  @Builder
  quickServiceItem(image: ResourceStr, title: string, action: string) {
    Column({ space: 5 }) {
      Image(image)
        .width(56)
        .height(56)
        .objectFit(ImageFit.Contain)
        .draggable(false);
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182230')
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('25%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (action === '查快递|补缴运费') {
        this.onOpenUnpaid();
      } else if (action === '客服|咨询客服') {
        this.onOpenCustomer();
      } else {
        this.handleAction(action);
      }
    });
  }

  @Builder
  brandCard(name: string) {
    Row({ space: 7 }) {
      this.brandLogo(name);
      Text(name).fontSize(13).fontColor('#39445A').maxLines(1);
    }
    .width(112).height(54).padding({ left: 8, right: 8 })
    .backgroundColor('#F4F6FF').borderRadius(10);
  }

  @Builder
  brandLogo(name: string) {
    if (name === '圆通') { Image($r('app.media.brand_yuantong')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '申通') { Image($r('app.media.brand_shentong')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '京东标快') { Image($r('app.media.brand_jd_standard')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '韵达') { Image($r('app.media.brand_yunda')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '中通') { Image($r('app.media.brand_zhongtong')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '顺丰标快') { Image($r('app.media.brand_shunfeng_standard')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '德邦标快') { Image($r('app.media.brand_debang_standard')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '菜鸟速递') { Image($r('app.media.brand_cainiao_express')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '德邦快运') { Image($r('app.media.brand_debang_freight')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === 'EMS') { Image($r('app.media.brand_ems')).width(34).height(34).objectFit(ImageFit.Contain); }
    else if (name === '极兔') { Image($r('app.media.brand_jitu')).width(34).height(34).objectFit(ImageFit.Contain); }
    else { Image($r('app.media.brand_shunxin')).width(34).height(34).objectFit(ImageFit.Contain); }
  }

  @Builder
  mainServices() {
    Row() { this.service('ic_car', '寄快递', '一小时取件', '寄件|寄快递'); this.service('ic_car', '发物流', '大件/整车/零担', '寄件|发物流'); }
      .width('calc(100% - 32vp)').height(196).justifyContent(FlexAlign.SpaceAround).padding(12).backgroundColor(Color.White).borderRadius(16).margin({ left: 16, right: 16, top: 4 });
  }

  @Builder
  serviceCards() {
    Row({ space: 12 }) {
      Column({ space: 12 }) { this.card('ic_get', '上门取件', '专业小哥，上门服务', '寄件|上门取件'); this.card('ic_service', '咨询客服', '在线客服，专业解答', '客服|咨询客服'); }.layoutWeight(1).height(240).justifyContent(FlexAlign.SpaceBetween);
      Stack() {
        Image($r('app.media.bg_return_exchange')).width('100%').height(240).objectFit(ImageFit.Cover).borderRadius(8);
        Column() { Text('网购退换货').fontSize(16).fontWeight(FontWeight.Medium); Text('低至 4.8元 起!').fontSize(16).margin({ top: 4 }); Text('立即寄件').fontSize(14).fontColor('#0A59F7').backgroundColor('#C9DBFF').borderRadius(18).padding(9).margin({ top: 8 }).onClick(() => this.handleAction('寄件|网购退换货')); }.alignItems(HorizontalAlign.Start).padding({ left: 14, top: 14 });
      }.layoutWeight(1).height(240);
    }.width('calc(100% - 32vp)').height(264).padding(12).backgroundColor(Color.White).borderRadius(16).margin({ left: 16, right: 16, top: 4 });
  }

  @Builder
  service(icon: string, title: string, detail: string, action: string) {
    Column() { this.serviceIcon(icon); Text(title).fontSize(16).fontWeight(FontWeight.Medium).margin({ top: 6 }); Text(detail).fontSize(12).fontColor('#7A8699').margin({ top: 3 }); }.width('45%').onClick(() => this.handleAction(action));
  }

  @Builder
  card(icon: string, title: string, detail: string, action: string) {
    Stack() { this.cardImage(icon); Column() { Text(title).fontSize(16).fontWeight(FontWeight.Medium); Text(detail).fontSize(12).margin({ top: 8 }); }.alignItems(HorizontalAlign.Start).padding({ left: 14, top: 14 }); }.width('100%').height(114).onClick(() => this.handleAction(action));
  }

  @Builder
  serviceIcon(icon: string) {
    if (icon === 'ic_car') { Image($r('app.media.ic_car')).width(60).height(60); }
    else if (icon === 'ic_get') { Image($r('app.media.ic_get')).width(60).height(60); }
    else { Image($r('app.media.ic_service')).width(60).height(60); }
  }

  @Builder
  cardImage(icon: string) {
    if (icon === 'ic_get') { Image($r('app.media.ic_get')).width('100%').height(114).objectFit(ImageFit.Cover).borderRadius(8); }
    else { Image($r('app.media.ic_service')).width('100%').height(114).objectFit(ImageFit.Cover).borderRadius(8); }
  }
}
