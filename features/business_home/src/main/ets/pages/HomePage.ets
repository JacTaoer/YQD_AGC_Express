import { LengthMetrics } from '@kit.ArkUI';
import { SkeletonType, UISkeleton } from '@hw-agconnect/ui-skeleton';
import { PermissionUtil } from 'lib_foundation';
import { AdvertisementComponent } from 'module_advertisement';
import { HomePageVM } from '../viewModels/HomePageVM';
import { EventCard } from '../components/EventCard';
import { MainService } from '../components/MainService';
import { ServiceCard } from '../components/ServiceCard';
import { QuickServiceBanner } from '../components/QuickServiceBanner';


@Builder
export function homePageBuilder() {
  HomePage()
}

@ComponentV2
export struct HomePage {
  @Local titleBgOpacity: number = 0;
  @Local loading: boolean = false;
  @Local banner: ResourceStr = '';
  vm: HomePageVM = HomePageVM.instance;
  scroller: Scroller = new Scroller();

  async aboutToAppear() {
    this.loading = true
    this.vm.queryMemberStatus();
    // mock
    await new Promise<void>((resolve) => {
      setTimeout(() => {
        this.banner = $r('app.media.banner');
        this.loading = false;
        resolve()
      }, 800)
    })

    // push通知
    PermissionUtil.requestNotificationPermission();
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Scroll(this.scroller) {
        Stack({ alignContent: Alignment.Top }) {
          Image(this.banner)
            .height(240)
            .width('100%')
            .objectFit(ImageFit.Contain)
            .draggable(false)

          Column() {
            // 第一个内容
            this.firstContentCard()
            // 会员和实名认证
            EventCard({ loading: this.loading })
            if (this.vm.isTabVertical) {
              Flex({ space: { main: LengthMetrics.vp(12) }}) {
                Column() {
                  // 寄快递和发物流
                  MainService({ loading: this.loading })
                  // 广告
                  this.adViewCard()
                }
                .flexGrow(1)

                // 服务
                ServiceCard({ loading: this.loading }).flexGrow(1)
              }
              // 快捷服务标签（合作品牌区域上方）
              QuickServiceBanner()
            } else {
              // 寄快递和发物流
              MainService({ loading: this.loading })
              // 服务
              ServiceCard({ loading: this.loading })
              // 快捷服务标签（合作品牌区域上方）
              QuickServiceBanner()
              // 广告
              this.adViewCard()
            }
          }
          .width('100%')
          .padding({
            left: this.vm.breakPointModel.pagePadding,
            right: this.vm.breakPointModel.pagePadding,
            top: this.vm.windowModel.windowTopPadding
          })
        }
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .onDidScroll(() => {
        this.titleBgOpacity = this.scroller.currentOffset().yOffset / 56;
      })

      this.titleBuilder()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  titleBuilder() {
    Stack() {
      Row() {
        Column().height(56)
      }
      .width('100%')
      .padding({ top: this.vm.windowModel.windowTopPadding })
      .backgroundColor(Color.White)
      .opacity(this.titleBgOpacity)
      .alignSelf(ItemAlign.Stretch)

      Row() {
        Column() {
          UISkeleton({ options: [{ type: SkeletonType.TEXT, width: 80, height: 35 }], loading: this.loading }) {
            Text('首页').fontSize(26).fontWeight(700).height(56)
          }
        }
        .width('100%')
        .height(56)
        .padding({ left: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ top: this.vm.windowModel.windowTopPadding })
    }
  }

  @Builder
  firstContentCard() {
    Blank()
    .width('100%')
    .height(66)
    .margin({ top: 16 + this.vm.windowModel.windowTopPadding })
  }

  @Builder
  adViewCard() {
    Column() {
      UISkeleton({
        options: [{
          type: SkeletonType.RECT,
          radius: 16,
          width: '100%',
          height: 150,
        }],
        loading: this.loading,
      }) {
        AdvertisementComponent({
          testAd: 'testw6vs28auh3',
          adType: 8,
        })
      }
    }
    .width('100%')
    .height(150)
    .margin({ top: 12, bottom: 24 })
  }
}
