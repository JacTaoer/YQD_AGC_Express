import { AtomicAddress, addressSummary } from './AddressTypes';

@ComponentV2
export struct AddressListItem {
  @Param item: AtomicAddress = {} as AtomicAddress;
  @Param mode: string = 'manage';
  @Param selected: boolean = false;
  @Event onSelect: () => void = () => {};
  @Event onEdit: () => void = () => {};
  @Event onDelete: () => void = () => {};
  @Event onDefault: (value: boolean) => void = () => {};

  build() {
    Column() {
      Column({ space: 4 }) {
          Text(`${this.item.contactName}  ${this.item.phone}`).width('100%').maxLines(1).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#182230').textOverflow({ overflow: TextOverflow.Ellipsis });
          Text(addressSummary(this.item)).fontSize(14).fontColor(this.item.isDeliverable ? '#182230' : '#A33A3A').lineHeight(20).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
          if (!this.item.isDeliverable) Text('当前地址暂不支持配送').fontSize(12).fontColor('#A33A3A');
      }.width('100%').constraintSize({ minHeight: 64 }).alignItems(HorizontalAlign.Start);
      if (this.mode === 'manage') {
        Divider().color('#E7EAF0').margin({ top: 12 });
        Row() {
          Row() { Toggle({ type: ToggleType.Switch, isOn: this.item.isDefault }).margin({ right: 8 }).onChange((value: boolean) => this.onDefault(value)); Text('默认地址').fontSize(14).fontColor('#182230'); }
          Row({ space: 12 }) { Button('编辑').width(72).height(28).fontSize(14).fontColor('#0A59F7').backgroundColor('#F0F1F3').onClick(() => this.onEdit()); Button('删除').width(72).height(28).fontSize(14).fontColor('#E84026').backgroundColor('#F0F1F3').onClick(() => this.onDelete()); }
        }.width('100%').margin({ top: 12 }).justifyContent(FlexAlign.SpaceBetween);
      } else {
        Image($r('app.media.ic_arrow_right')).width(18).height(18).alignSelf(ItemAlign.End);
      }
    }.width('100%').padding({ left: 12, right: 12, top: 12, bottom: 10 }).backgroundColor(Color.White).borderRadius(16)
      .border({ width: this.selected ? 2 : 0, color: '#0A59F7' }).onClick(() => { if (this.mode === 'select') this.onSelect(); });
  }
}
