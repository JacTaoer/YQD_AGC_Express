import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';
import { LoginUtil } from '../viewModels/QuickLoginPageVM';

@ComponentV2
export struct PhoneAuthorizationButton {
  build() {
    FunctionalButton({
      params: {
        openType: functionalButtonComponentManager.OpenType.GET_PHONE_NUMBER,
        label: '授权手机号',
        styleOption: {
          styleConfig: new functionalButtonComponentManager.ButtonConfig()
            .type(ButtonType.Normal)
            .width(112)
            .height(28)
            .padding(0)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_emphasize'))
            .backgroundColor(Color.Transparent)
        },
      },
      controller: new functionalButtonComponentManager.FunctionalButtonController()
        .onGetPhoneNumber((error, data) => {
          if (error || !data.code) {
            this.getUIContext().getPromptAction().showToast({ message: error?.message ?? '未获取到手机号授权码' });
            return;
          }
          LoginUtil.authorizePhone(data.code).catch((loginError: Error) => {
            this.getUIContext().getPromptAction().showToast({ message: loginError.message });
          });
        }),
    })
  }
}
