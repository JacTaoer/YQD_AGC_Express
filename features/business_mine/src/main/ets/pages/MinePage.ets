import { CommonTitle } from 'lib_foundation';
import { CommonServiceView } from '../components/CommonServiceView';
import { LoginAvatarCard } from '../components/LoginAvatarCard';
import { MainService } from '../components/MainService';
import { MinePageVM } from '../viewModels/MinePageVM';

export interface MinePageParam {
  externalNavigation: boolean,
  onOpenExpress: () => void,
  onOpenMessage: () => void,
  onOpenCoupon: () => void,
  onOpenFeedback: () => void,
  onOpenSetting: () => void,
  onOpenLogin: () => void
}

@Builder
export function MinePageBuilder(param: MinePageParam) {
  MinePage({
    externalNavigation: param.externalNavigation,
    onOpenExpress: param.onOpenExpress,
    onOpenMessage: param.onOpenMessage,
    onOpenCoupon: param.onOpenCoupon,
    onOpenFeedback: param.onOpenFeedback,
    onOpenSetting: param.onOpenSetting,
    onOpenLogin: param.onOpenLogin
  });
}

@ComponentV2
export struct MinePage {
  @Param onOpenExpress: () => void = () => {};
  @Param onOpenMessage: () => void = () => {};
  @Param onOpenCoupon: () => void = () => {};
  @Param onOpenFeedback: () => void = () => {};
  @Param onOpenSetting: () => void = () => {};
  @Param externalNavigation: boolean = false;
  @Param onOpenLogin: () => void = () => {};
  vm: MinePageVM = MinePageVM.instance;

  build() {
    Column() {
      CommonTitle({
        title: '我的',
        showBackBtn: false,
        fontSize: 24,
        useWindowPadding: false,
        bgColor: Color.White
      })
      Scroll() {
        Column({ space: 12 }) {
          LoginAvatarCard({ externalNavigation: this.externalNavigation, onOpenLogin: this.onOpenLogin })
          MainService({
            onOpenExpress: this.onOpenExpress,
            onOpenMessage: this.onOpenMessage,
            onOpenCoupon: this.onOpenCoupon,
            externalNavigation: this.externalNavigation,
          })
          CommonServiceView({
            externalNavigation: this.externalNavigation,
            onOpenFeedback: this.onOpenFeedback,
            onOpenSetting: this.onOpenSetting,
          })
        }
        .padding({
          left: this.vm.breakPointModel.pagePadding,
          right: this.vm.breakPointModel.pagePadding,
        })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
