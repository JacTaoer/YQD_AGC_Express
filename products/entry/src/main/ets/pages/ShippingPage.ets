import { AtomicAddress, addressSummary, emptyAddress, maskedPhone } from '../address/AddressTypes';
import { AddressBookPage } from '../address/AddressBookPage';
import { ExpressApi, ExpressContactAddress, ExpressQuoteInput } from '../data/JavaApiClient';
import { GoodsPage } from './GoodsPage';
import { CouponsController, CouponItem, CouponStatus, ReductionTypes } from 'coupons';

interface CarrierOption {
  key: string;
  code: string;
  name: string;
  price: string;
}

class ExpressCouponRule {
  discountType: ReductionTypes = ReductionTypes.DIRECT_REDUCTION;
  fullAmount: string = '1';
  discountAmount: string = '0';
  discountCoefficient: string = '0';
}

class ExpressCouponItem implements CouponItem {
  couponID: string = '';
  couponName: string = '';
  usageRestriction: string = '';
  startTime: string = '2026-01-01';
  endTime: string = '2026-12-31';
  createdTime: string = '2026-01-01';
  couponStatus: CouponStatus = CouponStatus.AVAILABLE;
  amountRule: ExpressCouponRule = new ExpressCouponRule();
}

@Component
export struct ShippingPage {
  @Link detail: string;
  @Link submitted: boolean;
  @State sender: string = '';
  @State appName: string = '';
  @State receiver: string = '';
  @State senderAddress: string = '';
  @State receiverAddress: string = '';
  @State senderDetail: AtomicAddress = emptyAddress();
  @State receiverDetail: AtomicAddress = emptyAddress();
  @State goods: string = '';
  @State goodsWeight: number = 1;
  @State goodsCount: number = 1;
  @State goodsVolume: number = 0;
  @State pickupTime: string = '请选择时间';
  @State express: string = '请选择快递公司';
  @State expressCode: string = '';
  @State carriers: CarrierOption[] = [];
  @State quotedPrice: string = '';
  @State quoteLoading: boolean = false;
  @State quoteError: string = '';
  @State servicePoint: string = '请选择附近服务点';
  @State payment: string = '寄付现结';
  @State couponLabel: string = '暂无可用优惠券';
  @State couponDiscount: number = 0;
  @State template: string = '常规';
  @State templateIndex: number = 0;
  @State shippingMethod: number = 1;
  @State agreed: boolean = false;
  @State showPicker: string = '';
  @State pickerSheetVisible: boolean = false;
  @State activePickerKey: string = '';
  @State draftValue: string = '';
  @State draftTimeDay: string = '今天';
  @State draftTimeSlot: string = '08:00 - 09:00';
  @State draftExpressCode: string = '';
  @State draftExpressKey: string = '';
  @State draftExpressName: string = '';
  @State draftQuotedPrice: string = '';
  @State addressVisible: boolean = false;
  @State addressTarget: string = 'sender';
  @State goodsVisible: boolean = false;
  private quoteRequestId: number = 0;
  private pendingExpressKey: string = '';
  private pendingExpressCode: string = '';
  private pendingExpressName: string = '';
  private pendingExpressPrice: string = '';
  private isTodayAvailable(): boolean { return new Date().getHours() < 18; }

  private selectTemplate(label: string): void {
    this.templateIndex = label === '寄大件' ? 1 : 0;
    this.template = label;
    if (label === '寄大件') {
      this.goods = '20kg';
      this.goodsWeight = 20;
      this.goodsCount = 1;
    } else if (this.goods === '20kg') {
      this.goods = '';
      this.goodsWeight = 1;
      this.goodsCount = 1;
    }
    this.refreshQuotes();
  }

  aboutToAppear(): void {
    this.loadPublicConfig();
    if (this.detail.includes('寄大件')) {
      this.selectTemplate('寄大件');
    }
  }

  private async loadPublicConfig(): Promise<void> {
    try {
      const data = await ExpressApi.publicConfig();
      const config = data['config'] as Record<string, object> | undefined;
      const configuredName = config ? `${config['appName'] || ''}` : '';
      const merchantName = `${data['merchant_name'] || ''}`;
      if (configuredName.length > 0) this.appName = configuredName;
      else if (merchantName.length > 0) this.appName = merchantName;
      if (this.appName.length > 0) this.servicePoint = this.appName;
    } catch (_) {
      // Keep local defaults when public configuration is temporarily unavailable.
    }
  }

  private back(): void { this.detail = ''; this.submitted = false; }
  private valid(): boolean {
    const commonValid = this.sender.length > 0 && this.receiver.length > 0 && this.senderAddress.length > 0 &&
      this.receiverAddress.length > 0 && this.goods.length > 0 && this.agreed;
    const methodValid = this.shippingMethod === 1 ?
      this.expressCode.length > 0 && this.quotedPrice.length > 0 && !this.quoteLoading && this.pickupTime !== '请选择时间' :
      this.servicePoint !== '请选择附近服务点';
    return commonValid && methodValid;
  }
  private price(): string { return this.shippingMethod === 1 ? (this.quotedPrice || '--') : '6.00'; }
  private applyAddress(item: AtomicAddress): void {
    if (this.addressTarget === 'sender') { this.senderDetail = item; this.sender = item.contactName; this.senderAddress = addressSummary(item); }
    else { this.receiverDetail = item; this.receiver = item.contactName; this.receiverAddress = addressSummary(item); }
    this.addressVisible = false;
    this.refreshQuotes();
  }
  private contact(item: AtomicAddress): ExpressContactAddress {
    return {
      name: item.contactName, phone: item.phone, province: item.provinceName, city: item.cityName,
      district: item.districtName, address: addressSummary(item), street: item.street,
      longitude: item.longitude, latitude: item.latitude
    };
  }
  private quoteReady(): boolean {
    return this.shippingMethod === 1 && this.senderDetail.id.length > 0 &&
      this.receiverDetail.id.length > 0 && this.goods.length > 0 && this.goodsWeight > 0;
  }
  private async refreshQuotes(): Promise<void> {
    const requestId = ++this.quoteRequestId;
    const selectedCode = this.expressCode;
    this.carriers = [];
    this.quotedPrice = '';
    this.quoteError = '';
    if (!this.quoteReady()) { this.quoteLoading = false; return; }
    this.quoteLoading = true;
    const input: ExpressQuoteInput = {
      sender: this.contact(this.senderDetail), receiver: this.contact(this.receiverDetail),
      weight: this.goodsWeight, goodsName: this.goods.split(' ')[0]
    };
    try {
      const quotes = await ExpressApi.quotes(input);
      if (requestId !== this.quoteRequestId) return;
      const options: CarrierOption[] = [];
      quotes.forEach((quote: Record<string, object>, index: number) => {
        const code = `${quote['companyCode'] || quote['company_code'] || ''}`;
        const name = `${quote['companyName'] || quote['company_name'] || ''}`;
        const amount = Number(quote['amount']);
        if (code.length > 0 && name.length > 0 && !Number.isNaN(amount) && amount >= 0) {
          const quoteId = `${quote['quoteId'] || quote['quote_id'] || ''}`;
          const channelId = `${quote['channelId'] || quote['channel_id'] || ''}`;
          const key = quoteId.length > 0 ? quoteId : `${code}-${channelId}-${index}`;
          const transportName = `${quote['transportName'] || quote['transport_name'] || ''}`;
          const displayName = transportName.length > 0 && transportName !== '默认' ? `${name}（${transportName}）` : name;
          const option: CarrierOption = { key: key, code: code, name: displayName, price: amount.toFixed(2) };
          const existingIndex = options.findIndex((item: CarrierOption) => item.code === code);
          if (existingIndex < 0) {
            options.push(option);
          } else if (amount < Number(options[existingIndex].price)) {
            options[existingIndex] = option;
          }
        }
      });
      this.carriers = options;
      const selected = options.find((item: CarrierOption) => item.code === selectedCode);
      if (selected) { this.expressCode = selected.code; this.express = selected.name; this.quotedPrice = selected.price; }
      else { this.expressCode = ''; this.express = '请选择快递公司'; }
      if (options.length === 0) this.quoteError = '当前路线暂无可用快递报价';
    } catch (_) {
      if (requestId === this.quoteRequestId) { this.expressCode = ''; this.express = '请选择快递公司'; this.quoteError = '查价失败，请稍后重试'; }
    } finally {
      if (requestId === this.quoteRequestId) this.quoteLoading = false;
    }
  }

  build() {
    if (this.goodsVisible) {
      GoodsPage({ initialWeight: this.templateIndex === 1 ? 20 : 1, onBack: () => this.goodsVisible = false, onSave: (name: string, weight: number, count: number) => { this.goods = `${name} ${weight}kg`; this.goodsWeight = weight; this.goodsCount = count; this.goodsVisible = false; this.refreshQuotes(); } });
    } else if (this.addressVisible) {
      AddressBookPage({
        mode: 'select',
        onSelected: (item: AtomicAddress) => this.applyAddress(item),
        onClosed: () => this.addressVisible = false
      });
    } else {
      Column() {
        Row() {
          Button() { Image($r('app.media.chevron_backward')).width(22).height(22); }
            .width(40).height(40).backgroundColor('#EEF0F2').borderRadius(20).onClick(() => this.back());
          Text('寄快递').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#182230').margin({ left: 10 });
        }
          .width('100%')
          .constraintSize({ minHeight: 56 })
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor(Color.White)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP]);
        if (this.submitted) {
          Column({ space: 14 }) {
            Image($r('app.media.ic_checked')).width(64).height(64).margin({ top: 80 });
            Text('下单成功').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#182230');
            Text('订单已提交，等待快递员上门取件').fontSize(14).fontColor('#7A8699');
            Button('返回首页').width('100%').height(46).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.back());
          }.padding(24).layoutWeight(1).justifyContent(FlexAlign.Start);
        } else {
          Stack({ alignContent: Alignment.Top }) {
            Scroll() { Column({ space: 12 }) { this.templateRow(); this.addressCard(); this.methodRow(); this.optionsCard(); }
              .padding({ left: 16, right: 16, top: 8, bottom: 24 }); }.scrollBar(BarState.Off).layoutWeight(1);
          }
          .layoutWeight(1)
          .bindSheet($$this.pickerSheetVisible, this.pickerSheet(), {
            title: { title: this.pickerTitle() },
            backgroundColor: '#F4F6F8',
            height: SheetSize.FIT_CONTENT,
            preferType: SheetType.CENTER,
            onWillDismiss: () => this.closePicker(),
          });
          this.purchaseBar();
        }
      }.width('100%').height('100%').backgroundColor('#F4F6F8');
    }
  }

  @Builder templateRow() {
    Row({ space: 8 }) {
      Button('常规')
        .type(ButtonType.Normal)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.templateIndex === 0 ? Color.White : '#182230')
        .width(64).height(36).padding(0).borderRadius(18)
        .backgroundColor(this.templateIndex === 0 ? '#0A59F7' : Color.White)
        .onClick(() => this.selectTemplate('常规'));
      Button('寄大件')
        .type(ButtonType.Normal)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.templateIndex === 1 ? Color.White : '#182230')
        .width(96).height(36).padding(0).borderRadius(18)
        .backgroundColor(this.templateIndex === 1 ? '#0A59F7' : Color.White)
        .onClick(() => this.selectTemplate('寄大件'));
    }.width('100%').alignItems(VerticalAlign.Top);
  }
  @Builder addressCard() {
    Column() { this.addressRow(true); Row() { Image($r('app.media.ic_change')).width(24).height(24).onClick(() => { const name = this.sender; const address = this.senderAddress; const detail = this.senderDetail; this.sender = this.receiver; this.senderAddress = this.receiverAddress; this.senderDetail = this.receiverDetail; this.receiver = name; this.receiverAddress = address; this.receiverDetail = detail; this.refreshQuotes(); }); Divider().strokeWidth(1).color('#E7EAF0').margin({ left: 12, right: 12 }); }.height(30).margin({ top: 4, bottom: 4, right: 12 }); this.addressRow(false); }
      .width('100%').padding(12).backgroundColor(Color.White).borderRadius(16);
  }
  @Builder addressRow(isSender: boolean) {
    Row() {
      Image(isSender ? $r('app.media.ic_send_address') : $r('app.media.ic_receiver_address')).width(24).height(28);
      Column({ space: 6 }) { Row() { Text(isSender ? (this.sender || '请填写寄件人信息') : (this.receiver || '请填写收件人信息')).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#182230'); Text(isSender && this.sender.length > 0 ? ` ${maskedPhone(this.senderDetail.phone)}` : (!isSender && this.receiver.length > 0 ? ` ${maskedPhone(this.receiverDetail.phone)}` : '')).fontSize(14).fontColor('#576275'); }.width('100%'); Text(isSender ? (this.senderAddress || '支持智能识别地址') : (this.receiverAddress || '支持智能识别地址')).fontSize(14).fontColor('#7A8699').lineHeight(19); }.layoutWeight(1).padding({ left: 12, right: 12 }).alignItems(HorizontalAlign.Start);
      Text('地址簿').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#182230').padding({ left: 12 }).border({ width: { left: 1 }, color: '#E7EAF0' }).onClick(() => { this.addressTarget = isSender ? 'sender' : 'receiver'; this.addressVisible = true; });
    }.width('100%').justifyContent(FlexAlign.SpaceBetween);
  }
  @Builder methodRow() { Row({ space: 12 }) { this.methodChip('上门取件', 1); this.methodChip('服务点自寄', 2); }.width('100%'); }
  @Builder methodChip(label: string, value: number) { Text(label).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.shippingMethod === value ? Color.White : '#182230').padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(18).backgroundColor(this.shippingMethod === value ? '#0A59F7' : Color.White).onClick(() => { this.shippingMethod = value; if (value === 2 && this.servicePoint === '请选择附近服务点' && this.appName.length > 0) this.servicePoint = this.appName; this.refreshQuotes(); }); }
  @Builder optionsCard() {
    Column() {
      if (this.shippingMethod === 2 && this.servicePoint !== '请选择附近服务点') {
        Row({ space: 10 }) {
          Image($r('app.media.store')).width(54).height(60);
          Column({ space: 5 }) {
            Text(this.servicePoint).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#182230').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
            Text('线下寄件服务点门店').fontSize(12).fontColor('#0A59F7');
          }.alignItems(HorizontalAlign.Start).layoutWeight(1);
        }.width('100%').padding({ bottom: 12 });
      }
      this.optionRow('物品信息', this.templateIndex === 1 ? '20kg' : (this.goods || '请选择物品信息'), 'goods');
      if (this.shippingMethod === 1) { this.optionRow('选择快递', this.express, 'express'); this.optionRow('期望上门时间', this.pickupTime, 'time'); }
      else { this.optionRow('服务点', this.servicePoint, 'store'); }
      this.optionRow('付款方式', this.payment, 'payment'); this.optionRow('优惠券', this.couponLabel, 'coupon');
    }
      .width('100%').padding({ top: 12, left: 12, right: 12 }).backgroundColor(Color.White).borderRadius(16);
  }
  @Builder optionRow(label: string, value: string, key: string) { Column() { Row() { Text(label).fontSize(16).fontColor('#182230').layoutWeight(1); Text(key === 'express' ? this.express : value).fontSize(14).fontColor((key === 'express' ? this.express : value).startsWith('请选择') ? '#182230' : '#576275').margin({ right: 6 }); Image($r('app.media.ic_arrow_right')).width(16).height(16); }.width('100%').height(42).onClick(() => { if (key === 'goods') { this.goodsVisible = true; } else if (key === 'coupon') { this.openCouponPicker(); } else { this.openPicker(key, key === 'express' ? this.express : value); } }); Divider().color('#E7EAF0'); }.width('100%'); }

  private pickerTitle(): string {
    if (this.showPicker === 'time') return '期望上门时间';
    if (this.showPicker === 'payment') return '付款方式';
    if (this.showPicker === 'store') return '服务点选择';
    return '选择快递公司';
  }

  private openPicker(key: string, value: string): void {
    this.showPicker = key;
    this.activePickerKey = key;
    this.draftValue = value;
    if (key === 'time') {
      this.draftTimeDay = value.startsWith('明天') ? '明天' : value.startsWith('后天') ? '后天' : (this.isTodayAvailable() ? '今天' : '明天');
      const parsedSlot = value.includes(' ') ? value.substring(value.indexOf(' ') + 1) : '';
      this.draftTimeSlot = parsedSlot.length > 0 ? parsedSlot : '08:00 - 09:00';
      // Always keep a valid draft value so confirming after a single click cannot submit the placeholder.
      this.draftValue = `${this.draftTimeDay} ${this.draftTimeSlot}`;
    }
    if (key === 'express') {
      this.draftExpressCode = this.expressCode;
      const selected = this.carriers.find((item: CarrierOption) => item.code === this.expressCode && item.price === this.quotedPrice);
      this.draftExpressKey = selected ? selected.key : '';
      this.draftExpressName = selected ? selected.name : '';
      this.draftQuotedPrice = this.quotedPrice;
      this.pendingExpressKey = this.draftExpressKey;
      this.pendingExpressCode = this.draftExpressCode;
      this.pendingExpressName = this.draftExpressName;
      this.pendingExpressPrice = this.draftQuotedPrice;
      if (this.carriers.length === 0) this.refreshQuotes();
    }
    this.pickerSheetVisible = true;
  }

  private closePicker(): void {
    this.pickerSheetVisible = false;
    // Keep the picker key until the dismiss animation completes so confirm can commit its draft.
  }

  private confirmPicker(): void {
    const pickerKey = this.showPicker || this.activePickerKey;
    if (pickerKey === 'time') {
      // Build from the two draft columns instead of relying on a possibly stale row value.
      this.pickupTime = `${this.draftTimeDay} ${this.draftTimeSlot}`;
    } else if (pickerKey === 'payment') {
      this.payment = this.draftValue;
    } else if (pickerKey === 'express' && this.pendingExpressCode.length > 0) {
      const selected = this.carriers.find((item: CarrierOption) => item.key === this.pendingExpressKey) ||
        this.carriers.find((item: CarrierOption) => item.code === this.pendingExpressCode && item.price === this.pendingExpressPrice);
      if (selected) {
        this.express = selected.name;
        this.expressCode = selected.code;
        this.quotedPrice = selected.price;
      } else {
        this.express = this.pendingExpressName;
        this.expressCode = this.pendingExpressCode;
        this.quotedPrice = this.pendingExpressPrice;
      }
      this.quoteError = '';
    } else if (pickerKey === 'store') {
      this.servicePoint = this.draftValue;
    }
    this.closePicker();
    this.showPicker = '';
  }

  @Builder pickerSheet() {
    Column({ space: 16 }) {
      if (this.showPicker === 'payment') {
        Column({ space: 2 }) { this.pickerOption('寄付现结'); this.pickerOption('到付'); }.width('100%');
      } else if (this.showPicker === 'time') {
        this.timePickerOptions();
      } else if (this.showPicker === 'express') {
        Scroll() {
          Column() { this.carrierPickerOptions(); }.width('100%');
        }
          .height(280)
          .scrollBar(BarState.Off);
      } else if (this.showPicker === 'store') {
        Column({ space: 2 }) { this.pickerOption(this.appName || this.servicePoint); }.width('100%');
      }
      Row({ space: 12 }) {
        Button('取消').layoutWeight(1).height(44).backgroundColor('#E7E9EC').fontColor('#182230').onClick(() => this.closePicker());
        Button('确认').layoutWeight(1).height(44).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.confirmPicker());
      }.width('100%');
    }.width('100%').padding({ left: 16, right: 16, bottom: 16 });
  }

  private openCouponPicker(): void {
    const controller = new CouponsController();
    controller.themeColor = '#0A59F7';
    controller.totalMoney = Number(this.quotedPrice || 0);
    controller.selectedId = this.couponDiscount > 0 ? 'express-direct-380' : '';
    controller.reduce = this.couponDiscount;
    controller.onLoadCoupons = async (): Promise<CouponItem[]> => {
      const first = new ExpressCouponItem();
      first.couponID = 'express-direct-380';
      first.couponName = '寄件立减券';
      first.usageRestriction = '快递寄件满 1 元可用';
      first.amountRule.discountAmount = '3.8';
      const second = new ExpressCouponItem();
      second.couponID = 'express-direct-200';
      second.couponName = '新人寄件券';
      second.usageRestriction = '快递寄件满 1 元可用';
      second.amountRule.discountAmount = '2';
      return [first, second];
    };
    controller.onConfirm = (data) => {
      this.couponDiscount = data.reduce;
      this.couponLabel = data.selectId ? `-${data.reduce.toFixed(2)} 元` : '暂无可用优惠券';
    };
    controller.select(this.getUIContext());
  }
  @Builder carrierPickerOptions() {
    if (this.quoteLoading) {
      Row({ space: 10 }) { LoadingProgress().width(22).height(22); Text('正在查询快递报价').fontSize(14).fontColor('#7A8699'); }.height(96).justifyContent(FlexAlign.Center);
    } else if (this.quoteError.length > 0) {
      Column({ space: 8 }) { Text(this.quoteError).fontSize(14).fontColor('#7A8699'); Text('点击重试').fontSize(14).fontColor('#0A59F7').onClick(() => this.refreshQuotes()); }.height(96).justifyContent(FlexAlign.Center);
    } else if (this.carriers.length === 0) {
      Text('请先选择寄件人、收件人和物品信息').fontSize(14).fontColor('#7A8699').height(96).textAlign(TextAlign.Center);
    } else {
      ForEach(this.carriers, (item: CarrierOption) => {
        Row() { Text(item.name).fontSize(16).fontColor(this.draftExpressKey === item.key ? '#0A59F7' : '#182230').layoutWeight(1); Text(`￥${item.price}`).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#0A59F7').margin({ right: 12 }); if (this.draftExpressKey === item.key) Text('✓').fontSize(20).fontColor('#0A59F7'); }
          .width('100%').height(48).padding({ left: 8, right: 8 }).onClick(() => {
            this.pendingExpressKey = item.key;
            this.pendingExpressCode = item.code;
            this.pendingExpressName = item.name;
            this.pendingExpressPrice = item.price;
            this.draftValue = item.name;
            this.draftExpressKey = item.key;
            this.draftExpressName = item.name;
            this.draftExpressCode = item.code;
            this.draftQuotedPrice = item.price;
          });
      }, (item: CarrierOption) => item.key);
    }
  }
  @Builder
  timePickerOptions() {
    Row() {
      Column() {
        if (this.isTodayAvailable()) this.timeDayOption('今天');
        this.timeDayOption('明天');
        this.timeDayOption('后天');
      }.width('30%');
      Scroll() {
        Column() {
        if (this.draftTimeDay === '今天') {
          this.timeSlotOption('08:00 - 09:00');
          this.timeSlotOption('09:00 - 10:00');
          this.timeSlotOption('10:00 - 11:00');
          this.timeSlotOption('11:00 - 12:00');
          this.timeSlotOption('12:00 - 13:00');
          this.timeSlotOption('13:00 - 14:00');
          this.timeSlotOption('14:00 - 15:00');
          this.timeSlotOption('15:00 - 16:00');
          this.timeSlotOption('16:00 - 17:00');
          this.timeSlotOption('17:00 - 18:00');
        } else {
          this.timeSlotOption('08:00 - 09:00');
          this.timeSlotOption('09:00 - 10:00');
          this.timeSlotOption('10:00 - 11:00');
          this.timeSlotOption('11:00 - 12:00');
          this.timeSlotOption('12:00 - 13:00');
          this.timeSlotOption('13:00 - 14:00');
          this.timeSlotOption('14:00 - 15:00');
          this.timeSlotOption('15:00 - 16:00');
          this.timeSlotOption('16:00 - 17:00');
          this.timeSlotOption('17:00 - 18:00');
          this.timeSlotOption('18:00 - 19:00');
          this.timeSlotOption('19:00 - 20:00');
        }
        }.layoutWeight(1);
      }.height(300).scrollBar(BarState.Off);
    }.width('100%').height(300).alignItems(VerticalAlign.Center);
  }
  @Builder
  timeDayOption(day: string) {
    Row() {
      Text(day).fontSize(16).fontColor(this.draftTimeDay === day ? '#0A59F7' : '#182230')
    }.justifyContent(FlexAlign.Center)
      .width('100%').height(55)
      .backgroundColor(this.draftTimeDay === day ? Color.White : Color.Transparent)
      .onClick(() => {
        this.draftTimeDay = day;
        this.draftTimeSlot = '08:00 - 09:00';
        this.draftValue = `${day} ${this.draftTimeSlot}`;
      });
  }
  @Builder
  timeSlotOption(slot: string) {
    Row() {
      Text(slot).fontSize(16).fontColor(this.draftTimeSlot === slot ? '#0A59F7' : '#182230')
    }.justifyContent(FlexAlign.Center)
      .width('100%').height(44)
      .backgroundColor(Color.Transparent)
      .border({ width: { bottom: 1 }, color: '#E7EAF0' })
      .onClick(() => { this.draftTimeSlot = slot; this.draftValue = `${this.draftTimeDay} ${slot}`; });
  }
  @Builder pickerOption(value: string) { Row() { Text(value).fontSize(16).fontColor(this.draftValue === value ? '#0A59F7' : '#182230').layoutWeight(1); if (this.draftValue === value) Text('✓').fontSize(20).fontColor('#0A59F7'); }.width('100%').height(48).padding({ left: 8, right: 8 }).onClick(() => { this.draftValue = value; }); }
  @Builder purchaseBar() {
    Row() {
      Column({ space: 8 }) {
        Row() {
          Text('预估总价').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#182230')
          if (this.quoteLoading && this.shippingMethod === 1) LoadingProgress().width(16).height(16).margin({ left: 6 });
          else Text(`￥${this.price()}`).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#0A59F7').margin({ left: 4 })
        }
        if (this.quoteError.length > 0 && this.shippingMethod === 1) Text(this.quoteError).fontSize(11).fontColor('#C44747');
        Row() {
          Checkbox({ name: 'agreement', group: 'agreement' })
            .select(this.agreed).shape(CheckBoxShape.CIRCLE)
            .onChange((value: boolean) => { this.agreed = value; })
          Text('阅读并同意').fontSize(12).fontColor('#7A8699').margin({ left: 4 })
          Text('《电子运单契约条约》').fontSize(12).fontColor('#0A59F7')
        }.onClick(() => { this.agreed = !this.agreed; })
      }.alignItems(HorizontalAlign.Start)
      Button('下单').width(120).height(44).fontSize(16).fontWeight(FontWeight.Medium).fontColor(Color.White)
        .backgroundColor(this.valid() ? '#0A59F7' : '#B8C8E8').enabled(this.valid())
        .onClick(() => { this.submitted = true; })
    }
    .width('100%').padding({ left: 16, right: 16, top: 16, bottom: 24 })
    .justifyContent(FlexAlign.SpaceBetween).backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
