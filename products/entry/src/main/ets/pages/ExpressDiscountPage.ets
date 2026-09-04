import { AtomicAddress } from '../address/AddressTypes';
import { AddressBookPage } from '../address/AddressBookPage';

@Component
export struct ExpressDiscountPage {
  onBack: () => void = () => {};
  onOrder: () => void = () => {};
  @State senderRegion: string = '';
  @State receiverRegion: string = '';
  @State weight: number = 1;
  @State picker: string = '';
  @State queried: boolean = false;
  @State addressVisible: boolean = false;
  @State addressTarget: string = 'sender';

  private changeWeight(delta: number): void {
    this.weight = Math.max(0.1, Math.round((this.weight + delta) * 10) / 10);
  }

  private query(): void {
    this.queried = true;
  }

  private chooseRegion(value: string): void {
    if (this.picker === 'sender') {
      this.senderRegion = value;
    } else {
      this.receiverRegion = value;
    }
    this.picker = '';
  }

  private openAddress(target: string): void {
    this.addressTarget = target;
    this.addressVisible = true;
  }

  private applyAddress(item: AtomicAddress): void {
    const region = item.provinceName + item.cityName + item.districtName;
    if (this.addressTarget === 'sender') {
      this.senderRegion = region;
    } else {
      this.receiverRegion = region;
    }
    this.addressVisible = false;
  }

  build() {
    Column() {
      if (this.addressVisible) {
        AddressBookPage({
          mode: 'select',
          onSelected: (item: AtomicAddress) => this.applyAddress(item),
          onClosed: () => this.addressVisible = false
        });
      } else {
        this.mainContent();
      }
    }.width('100%').height('100%');
  }

  @Builder
  mainContent() {
    Column() {
      Row() {
        Button() { Image($r('app.media.chevron_backward')).width(22).height(22); }
          .width(40).height(40).backgroundColor('#EEF0F2').borderRadius(20).onClick(() => this.onBack());
        Text('查运费').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#182230').maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ left: 10 });
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center).backgroundColor(Color.White);
      Stack() {
        Scroll() {
          Column({ space: 14 }) {
            this.addressCard();
            if (this.queried) {
              this.resultCard();
            }
          }.padding({ left: 16, right: 16, top: 16, bottom: 24 });
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off);
        if (this.picker.length > 0) {
          this.regionPicker();
        }
      }.layoutWeight(1);
      Row({ space: 12 }) {
        Button('查询').layoutWeight(1).height(52).fontSize(18).fontColor('#3F68D9')
          .backgroundColor(Color.Transparent).border({ width: 1, color: '#3F68D9' }).borderRadius(28)
          .onClick(() => this.query());
        Button('去下单').layoutWeight(1).height(52).fontSize(18).fontColor(Color.White)
          .linearGradient({ angle: 0, colors: [['#57B9F0', 0.0], ['#2E59EA', 1.0]] }).borderRadius(28)
          .onClick(() => this.onOrder());
      }.width('100%').padding({ left: 36, right: 36, top: 16, bottom: 24 }).backgroundColor('#F4F5F6');
    }.width('100%').height('100%').backgroundColor('#F4F5F6');
  }

  @Builder
  addressCard() {
    Column() {
      Text('选择地址').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30343B').alignSelf(ItemAlign.Start).margin({ bottom: 10 });
      this.regionRow('寄件地区', this.senderRegion || '请选择寄件地区', 'sender');
      Divider().color('#F0F1F3');
      this.regionRow('收件地区', this.receiverRegion || '请选择收件地区', 'receiver');
      Divider().color('#F0F1F3');
      Row() {
        Text('重量(KG)').fontSize(17).fontColor('#666B73').layoutWeight(1);
        Row() {
          Button('-').width(48).height(46).fontSize(24).fontColor('#858B93').backgroundColor('#F1F3F5').borderRadius(0).onClick(() => this.changeWeight(-0.1));
          Text(this.weight.toFixed(1).replace('.0', '')).width(76).height(46).fontSize(22).fontColor('#30343B').textAlign(TextAlign.Center).backgroundColor('#FAFBFC').padding({ top: 8 });
          Button('+').width(48).height(46).fontSize(24).fontColor('#30343B').backgroundColor('#F1F3F5').borderRadius(0).onClick(() => this.changeWeight(0.1));
        }.borderRadius(6).clip(true);
      }.width('100%').height(72).alignItems(VerticalAlign.Center);
    }.width('100%').padding({ left: 20, right: 20, top: 24, bottom: 4 }).backgroundColor(Color.White).borderRadius(16);
  }

  @Builder
  regionRow(label: string, value: string, key: string) {
    Row() {
      Text(value).fontSize(17).fontColor(value.startsWith('请选择') ? '#686D75' : '#30343B').layoutWeight(1);
      Image($r('app.media.ic_arrow_right')).width(18).height(18);
    }.width('100%').height(66).onClick(() => this.openAddress(key));
  }

  @Builder
  regionPicker() {
    Column({ space: 14 }) {
      Text(this.picker === 'sender' ? '选择寄件地区' : '选择收件地区').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start);
      this.regionOption('上海市');
      this.regionOption('北京市');
      this.regionOption('广州市');
      Text('取消').fontSize(15).fontColor('#7A8699').width('100%').textAlign(TextAlign.Center).onClick(() => this.picker = '');
    }.width('calc(100% - 32vp)').padding(20).backgroundColor(Color.White).borderRadius(16).position({ bottom: 16, left: 16 });
  }

  @Builder
  regionOption(value: string) {
    Row() { Text(value).fontSize(16).layoutWeight(1); Image($r('app.media.ic_arrow_right')).width(16).height(16); }
      .width('100%').padding({ top: 10, bottom: 10 }).onClick(() => this.chooseRegion(value));
  }

  @Builder
  resultCard() {
    Column({ space: 10 }) {
      Row() {
        Text('预估报价').fontSize(17).fontWeight(FontWeight.Bold).width(84).maxLines(1);
        Text(`${this.senderRegion || '寄件地'} → ${this.receiverRegion || '收件地'}`).fontSize(12).fontColor('#8A94A3')
          .layoutWeight(1).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
      }.width('100%');
      this.quoteRow('顺丰标快', '¥12.00', '时效约1天');
      this.quoteRow('中通快递', '¥8.00', '时效约2天');
      this.quoteRow('圆通速递', '¥7.50', '时效约2天');
    }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16).alignItems(HorizontalAlign.Start);
  }

  @Builder
  quoteRow(name: string, price: string, eta: string) {
    Row() { Text(name).fontSize(15).layoutWeight(1); Text(eta).fontSize(12).fontColor('#8A94A3').margin({ right: 12 }); Text(price).fontSize(17).fontWeight(FontWeight.Bold).fontColor('#0A59F7'); }
      .width('100%').height(42).border({ width: { bottom: 1 }, color: '#F0F1F3' });
  }
}
