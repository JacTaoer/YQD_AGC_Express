import { AtomicOrder, OrdersMockApi } from '../data/JavaApiClient';
import { CommonUtil, ScanUtil } from 'lib_foundation';
import { common } from '@kit.AbilityKit';

/** 元服务订单 Tab 的 atomic service 兼容实现。 */
@Component
export struct OrderPage {
  onOpenDetail: (item: AtomicOrder) => void = (_item: AtomicOrder) => {};
  onOpenLogistics: (item: AtomicOrder) => void = (_item: AtomicOrder) => {};
  @Prop initialFilter: number = 0;
  @State searchText: string = '';
  @State selected: number = 0;
  @State loading: boolean = false;
  @State failed: boolean = false;
  @State orders: AtomicOrder[] = [];
  @State actionMessage: string = '';

  aboutToAppear(): void { this.selected = this.initialFilter; this.refresh(); }

  private async refresh(): Promise<void> {
    this.loading = true; this.failed = false;
    try { this.orders = await OrdersMockApi.list(); }
    catch (_) { this.failed = true; }
    finally { this.loading = false; }
  }

  build() {
    Column() {
      Row() {
        Search({ placeholder: '请输入运单/手机号或扫码查询', value: $$this.searchText }).layoutWeight(1).height(44).backgroundColor('#E7E9EC').borderRadius(24);
        Button() {
          SymbolGlyph($r('sys.symbol.line_viewfinder'))
            .fontSize(24)
            .fontColor(['#59636F'])
        }
          .accessibilityText('扫码查询')
          .width(44)
          .height(44)
          .backgroundColor(Color.Transparent)
          .onClick(async () => {
            const result = (await ScanUtil.getScanResult(this.getUIContext().getHostContext() as common.UIAbilityContext)).trim();
            if (result.length > 0) {
              this.searchText = result;
            }
          });
      }.width('100%').height(56).alignItems(VerticalAlign.Center);
      Row() { this.filter('全部', 0); this.filter('进行中', 1); this.filter('未补缴', 2); this.filter('已签收', 3); }.width('100%').height(58).justifyContent(FlexAlign.SpaceBetween);
      if (this.loading) { LoadingProgress().width(36).height(36).margin({ top: 30 }); }
      else if (this.failed) { this.empty('加载失败，点击重试', true); }
      else if (this.visibleOrders().length === 0) { this.empty('暂无相关快递', false); }
      else { List() { ForEach(this.visibleOrders(), (item: AtomicOrder) => { ListItem() { this.orderCard(item); } }, (item: AtomicOrder) => item.id); }.width('100%').layoutWeight(1).divider({ strokeWidth: 0 }); }
      if (this.actionMessage.length > 0) { Text(this.actionMessage).fontSize(13).fontColor('#0A59F7').margin({ top: 4 }); }
    }.width('100%').layoutWeight(1).padding({ left: 16, right: 16, bottom: 8 }).backgroundColor('#F1F3F5');
  }

  private visibleOrders(): AtomicOrder[] {
    let filtered = this.orders;
    if (this.selected === 1) {
      filtered = filtered.filter((item: AtomicOrder) => item.status === '待取件' || item.status === '运输中' || item.status === '运输中（待补缴）');
    } else if (this.selected === 2) {
      filtered = filtered.filter((item: AtomicOrder) => item.status === '运输中（待补缴）');
    } else if (this.selected === 3) {
      filtered = filtered.filter((item: AtomicOrder) => item.status === '已签收');
    }
    if (this.searchText.length > 0) {
      filtered = filtered.filter((item: AtomicOrder) => item.trackingNo.includes(this.searchText) ||
        item.sender.includes(this.searchText) || item.receiver.includes(this.searchText));
    }
    return filtered;
  }
  private unpaidCount(): number { return this.orders.filter((item: AtomicOrder) => item.status === '运输中（待补缴）').length; }
  private formatDateTime(value: string): string {
    if (value.length === 0) return '--';
    const normalized = value.replace('T', ' ');
    return normalized.length > 16 ? normalized.substring(0, 16) : normalized;
  }
  @Builder filter(title: string, index: number) { if (index === 2 && this.unpaidCount() > 0) { Badge({ count: this.unpaidCount(), position: BadgePosition.RightTop, style: { badgeSize: 16, badgeColor: '#FA2A2D', fontSize: 10, fontWeight: FontWeight.Medium } }) { Text(title).fontSize(14).fontWeight(this.selected === index ? FontWeight.Bold : FontWeight.Regular).fontColor(this.selected === index ? Color.White : '#182230').backgroundColor(this.selected === index ? '#0A59F7' : '#E7E9EC').borderRadius(20).padding({ left: 12, right: 12, top: 10, bottom: 10 }); }.onClick(() => this.selected = index); } else { Text(title).fontSize(14).fontWeight(this.selected === index ? FontWeight.Bold : FontWeight.Regular).fontColor(this.selected === index ? Color.White : '#182230').backgroundColor(this.selected === index ? '#0A59F7' : '#E7E9EC').borderRadius(20).padding({ left: 12, right: 12, top: 10, bottom: 10 }).onClick(() => this.selected = index); } }
  @Builder orderCard(item: AtomicOrder) { Column({ space: 10 }) { Row({ space: 4 }) { Row({ space: 5 }) { Text(`${item.carrier}  ${item.trackingNo}`).fontSize(12).fontColor('#8A94A3').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }); SymbolGlyph($r('sys.symbol.doc_plaintext')).fontSize(16).fontColor(['#6F7781']).onClick(() => CommonUtil.copyText(item.trackingNo)); }.layoutWeight(1); Button() { Image($r('app.media.ic_more')).width(18).height(18); }.width(30).height(28).backgroundColor(Color.Transparent).onClick(() => this.onOpenDetail(item)); }
    Row() { Column() { Text(item.from).fontSize(18).fontWeight(FontWeight.Medium); Text(`${item.sender}`).fontSize(13).fontColor('#6F7781'); }.layoutWeight(1); Text(item.status).fontSize(12).fontColor('#0A59F7').margin({ left: 8, right: 8 }); Column() { Text(item.to).fontSize(18).fontWeight(FontWeight.Medium); Text(`${item.receiver}`).fontSize(13).fontColor('#6F7781'); }.layoutWeight(1); }
    Row() { Column({ space: 4 }) { if (item.status === '待取件') { Text(`预计上门取件时间：${this.formatDateTime(item.eta)}`).fontSize(12).fontColor('#8A94A3'); } Text(`下单时间：${this.formatDateTime(item.createdAt)}`).fontSize(12).fontColor('#8A94A3'); if (item.status === '运输中（待补缴）' && (item.supplementAmount || 0) > 0) { Text(`待补缴金额：¥${(item.supplementAmount || 0).toFixed(2)}`).fontSize(12).fontColor('#E64545'); } }.layoutWeight(1).alignItems(HorizontalAlign.Start); Text(`运费 ¥${item.amount.toFixed(2)}`).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#4B5563'); }.alignItems(VerticalAlign.Center)
    Divider().color('#E2E4E7'); Row() { Text('物流详情').fontSize(13).fontColor('#0A59F7').layoutWeight(1).onClick(() => this.onOpenLogistics(item)); if (item.status === '待支付') { Button('立即付款').height(32).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.pay(item)); } else if (item.status === '已签收') { Button('再次下单').height(32).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.actionMessage = '已创建再次下单请求'); } else if (item.status === '待取件' || item.status === '下单异常') { Button('取消寄件').width(88).height(32).backgroundColor('#F1F2F4').fontColor('#182230').border({ width: 1, color: '#D9DDE3' }).onClick(() => { this.cancel(item); }); } }.width('100%'); }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(16).margin({ bottom: 12 }); }
  private async pay(item: AtomicOrder) { this.actionMessage = '正在发起支付'; await OrdersMockApi.action(item, 'pay'); this.actionMessage = '模拟支付成功'; }
  private async cancel(item: AtomicOrder) { this.actionMessage = '正在取消订单'; await OrdersMockApi.action(item, 'cancel'); this.actionMessage = '模拟取消成功'; }
  @Builder empty(message: string, retry: boolean) { Column() { Image($r('app.media.ic_send_null')).width(80).height(80); Text(message).fontSize(14).fontColor('#8A94A3').margin({ top: 10 }); if (retry) { Button('重试').margin({ top: 14 }).onClick(() => this.refresh()); } }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center); }
}
