/** Four independently rendered quick-service entries for the homepage. */
interface QuickServiceItem {
  image: ResourceStr;
  title: string;
}

@ComponentV2
export struct QuickServiceBanner {
  private readonly services: QuickServiceItem[] = [
    { image: $r('app.media.quick_large'), title: '寄大件' },
    { image: $r('app.media.quick_fee'), title: '补缴运费' },
    { image: $r('app.media.quick_prohibited'), title: '违禁品' },
    { image: $r('app.media.quick_support'), title: '联系客服' },
  ];

  build() {
    Row() {
      ForEach(this.services, (service: QuickServiceItem) => {
        this.serviceBuilder(service.image, service.title)
      }, (service: QuickServiceItem) => service.title)
    }
      .width('100%')
      .height(132)
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 8, right: 8, top: 12, bottom: 10 })
      .backgroundColor(Color.White)
      .borderRadius(16)
      .margin({ top: 12 })
  }

  @Builder
  serviceBuilder(image: ResourceStr, title: string) {
    Column({ space: 6 }) {
      Image(image)
        .width(58)
        .height(58)
        .objectFit(ImageFit.Contain)
        .draggable(false)
      Text(title)
        .fontSize(15)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('25%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
