import { PersonalInfoView } from 'collect_personal_info';
import { CommonTitle } from 'lib_foundation';
import { PersonalInformationVM } from '../viewModels/PersonalInformationVM';

@Builder
export function PersonalInformationPageBuilder() {
  PersonalInformationPage();
}

@ComponentV2
export struct PersonalInformationPage {
  @Param onBack: () => void = () => {};
  @Param embedded: boolean = false;
  vm: PersonalInformationVM = new PersonalInformationVM();

  build() {
    NavDestination() {
      CommonTitle({
        title: '个人信息',
        onBack: this.onBack,
        useWindowPadding: !this.embedded,
      })
      Column({ space: 12 }) {
        PersonalInfoView({
          list: this.vm.list,
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        top: 8,
        left: this.vm.breakPointModel.pagePadding,
        right: this.vm.breakPointModel.pagePadding,
        bottom: this.vm.windowModel.windowBottomPadding
      })
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
