import { LengthMetrics } from '@kit.ArkUI';

@Component
export struct GoodsPage {
  onBack: () => void = () => {};
  onSave: (name: string, weight: number, count: number) => void = () => {};
  initialWeight: number = 1;
  @State selected: string = '';
  @State weight: number = 1;
  @State count: number = 1;
  @State showVolume: boolean = false;
  @State length: string = '';
  @State boxWidth: string = '';
  @State boxHeight: string = '';
  @State volume: number = 0;
  aboutToAppear(): void {
    this.weight = this.initialWeight;
  }
  private names: string[] = ['文件', '衣服', '发票', '茶叶', '手机', '白酒', '行李', '灯具', '五金配件', '茅台', '其他'];
  build() {
    Column() {
      Row({ space: 12 }) { Button() { Text('‹').fontSize(34); }.width(40).height(40).backgroundColor('#E9EAEC').borderRadius(20).onClick(() => this.onBack()); Text('物品信息').fontSize(24).fontWeight(FontWeight.Bold); }.width('100%').height(64).padding({ left: 16, right: 16 }).backgroundColor('#F4F6F8');
      Scroll() { Column({ space: 14 }) {
        Text('ⓘ 请如实填写，因填写不实导致相关责任损失的，由您自行承担').fontSize(11).fontColor('#7A8699').width('100%');
        Column({ space: 10 }) { Text('物品类型').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start); Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) { ForEach(this.names, (name: string) => Text(name).fontSize(14).textAlign(TextAlign.Center).width(70).height(32).padding({ top: 6, bottom: 6 }).borderRadius(8).backgroundColor(this.selected === name ? '#0A59F7' : '#F1F2F4').fontColor(this.selected === name ? Color.White : '#182230').onClick(() => { this.selected = name; }), (name: string) => name); } }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(16);
        this.stepper('预估重量', `${this.weight} kg`, () => { if (this.weight > 0.5) this.weight -= 0.5; }, () => this.weight += 0.5);
        Column({ space: 12 }) {
          Row() { Text('总体积').fontSize(17).fontWeight(FontWeight.Bold).layoutWeight(1); Text('补充体积预估费用会更准确').fontSize(11).fontColor('#8A94A3'); Toggle({ type: ToggleType.Switch, isOn: $$this.showVolume }); }.width('100%');
          if (this.showVolume) {
            Row({ space: 8 }) {
              this.dimensionInput('长 cm', this.length, 'length');
              Text('×').fontSize(18).fontColor('#7A8699');
              this.dimensionInput('宽 cm', this.boxWidth, 'width');
              Text('×').fontSize(18).fontColor('#7A8699');
              this.dimensionInput('高 cm', this.boxHeight, 'height');
            }.width('100%').justifyContent(FlexAlign.SpaceBetween);
            Text(`体积 ${this.volume.toFixed(4)} m³`).fontSize(12).fontColor('#7A8699').alignSelf(ItemAlign.End);
          }
        }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(16);
        this.stepper('件数', `${this.count} 件`, () => { if (this.count > 1) this.count--; }, () => this.count++);
      }.padding({ left: 16, right: 16, top: 8, bottom: 90 }).justifyContent(FlexAlign.Start); }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off);
      Button('保存').width('calc(100% - 32vp)').height(46).backgroundColor('#0A59F7').fontColor(Color.White).borderRadius(23).margin({ bottom: 18 }).enabled(this.selected.length > 0).onClick(() => this.onSave(this.selected, this.weight, this.count));
    }.width('100%').height('100%').backgroundColor('#F4F6F8');
  }
  @Builder stepper(label: string, value: string, minus: () => void, plus: () => void) { Row() { Text(label).fontSize(17).fontWeight(FontWeight.Bold).layoutWeight(1); Button() { Text('-').fontSize(20).fontColor('#7A8699'); }.width(34).height(34).backgroundColor('#F1F2F4').borderRadius(17).onClick(minus); Text(value).fontSize(16).width(58).textAlign(TextAlign.Center); Button() { Text('+').fontSize(20).fontColor('#182230'); }.width(34).height(34).backgroundColor('#F1F2F4').borderRadius(17).onClick(plus); }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(16); }
  @Builder dimensionInput(placeholder: string, value: string, field: string) { TextInput({ placeholder: placeholder, text: value }).type(InputType.Number).width(78).height(34).padding({ left: 8, right: 4 }).backgroundColor('#F1F2F4').borderRadius(8).onChange((text: string) => { if (field === 'length') this.length = text; else if (field === 'width') this.boxWidth = text; else this.boxHeight = text; this.calculateVolume(); }); }
  private calculateVolume(): void { const l = Number(this.length) || 0; const w = Number(this.boxWidth) || 0; const h = Number(this.boxHeight) || 0; this.volume = l > 0 && w > 0 && h > 0 ? (l * w * h) / 1000000 : 0; }
}
