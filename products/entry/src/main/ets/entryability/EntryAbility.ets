import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {}

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 只能从 AtomicHome 进入，保证福利页由底部 Tab 容器承载，而不是直接加载 BenefitPage。
    windowStage.loadContent('pages/AtomicHome');
  }
}
