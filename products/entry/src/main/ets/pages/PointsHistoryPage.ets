import { AtomicPointsDetail, BenefitsApi } from '../data/JavaApiClient';

@Component
export struct PointsHistoryPage {
  @Prop userId: number = 0;
  @Prop storeId: number = 0;
  close: () => void = () => {};
  @State tab: number = 0;
  @State points: number = 0;
  @State records: AtomicPointsDetail[] = [];
  @State loading: boolean = false;
  @State failed: boolean = false;

  aboutToAppear() { this.load(); }
  async load() {
    this.loading = true; this.failed = false;
    try {
      const all = await BenefitsApi.pointsDetail(this.userId, this.storeId, this.tab, 1);
      this.records = all;
      if (all.length > 0) this.points = all[0].balance || 0;
    } catch (e) { this.failed = true; }
    finally { this.loading = false; }
  }
  private visible(item: AtomicPointsDetail): boolean {
    if (this.tab === 0) return (item.points || 0) > 0;
    return (item.points || 0) < 0;
  }
  build() { Column() {
    Column({ space: 4 }) { Text('总积分').fontSize(14); Text(`${this.points}`).fontSize(18).fontWeight(FontWeight.Bold); }.margin({ top: 12, bottom: 24 });
    Row() { this.tabItem('收入', 0); this.tabItem('支出', 1); Blank(); Text('本月').fontSize(14); Image($r('app.media.ic_chevron_down')).width(20).height(20); }.width('100%').padding(12).backgroundColor(Color.White).borderRadius({ topLeft: 16, topRight: 16 });
    if (this.loading) { Column({ space: 10 }) { LoadingProgress().width(34).height(34); Text('正在加载积分明细').fontSize(13).fontColor('#7A8699'); }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).backgroundColor(Color.White); }
    else if (this.failed) { Column({ space: 10 }) { Text('加载失败').fontSize(14).fontColor('#7A8699'); Button('重试').onClick(() => this.load()); }.width('100%').height(220).justifyContent(FlexAlign.Center).backgroundColor(Color.White); }
    else if (this.records.filter((item: AtomicPointsDetail) => this.visible(item)).length === 0) { Column() { Text('暂无积分记录').fontSize(14).fontColor('#8A94A3'); }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).backgroundColor(Color.White); }
    else { List({ space: 12 }) { ForEach(this.records, (item: AtomicPointsDetail) => { if (this.visible(item)) ListItem() { this.record(item); } }, (item: AtomicPointsDetail) => `${item.id}`); }.width('100%').layoutWeight(1).padding(12).backgroundColor(Color.White).scrollBar(BarState.Off); }
  }.width('100%').height('100%').padding({ left: 16, right: 16 }).linearGradient({ colors: [['#A8CAF0', 0.2], ['#F1F3F5', 1]] }); }
  @Builder tabItem(title: string, index: number) { Column({ space: 4 }) { Text(title).fontSize(14).fontColor(this.tab === index ? '#0A59F7' : '#7A8699'); Row().width(20).height(2).backgroundColor(this.tab === index ? '#0A59F7' : Color.Transparent); }.margin({ right: 16 }).onClick(() => { this.tab = index; this.load(); }); }
  @Builder record(item: AtomicPointsDetail) { Column({ space: 8 }) { Text(item.title || item.remark || '').fontSize(14).width('100%').textAlign(TextAlign.Start); Row() { Text(item.createTime || '').fontSize(12).fontColor('#576275'); Blank(); Text(`${(item.points || 0) > 0 ? '+' : ''}${item.points || 0}`).fontSize(14).fontColor('#0A59F7'); }.width('100%'); }.width('100%'); }
}
