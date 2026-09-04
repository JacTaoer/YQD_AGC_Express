/**
 * 元服务页面同步占位容器。
 *
 * 具体页面源码以 `ets/synced/**/*.ets.source` 保留，接入时按页面逐个替换
 * 为元服务白名单 API；这样不会破坏源程序的布局、组件层级和交互设计。
 */
@Component
export struct SyncedSourcePage {
  @Prop pageName: string = '';
  @Prop purpose: string = '';

  build() {
    Column({ space: 12 }) {
      Text(this.pageName).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#182230');
      Text(this.purpose).fontSize(14).fontColor('#576275');
      Text('页面源码、组件和媒体资源已同步至元服务工程，正在按元服务能力逐项接入。')
        .fontSize(13).fontColor('#7A8699');
    }.width('100%').height('100%').padding(24).justifyContent(FlexAlign.Center);
  }
}
