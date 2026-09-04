import { AppLinkingService, AppLinkResult } from '../data/AppLinkingService';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';

@Component
export struct InviteFriendsPage {
  onBack: () => void = () => {};
  private readonly appId: string = 'com.atomicservice.6917614461242904059';
  private readonly userId: string = 'demo-user-10008642';
  @State invite: AppLinkResult = AppLinkingService.createInviteLink('com.atomicservice.6917614461242904059', 'demo-user-10008642');
  @State saveMessage: string = '';

  private async savePoster(result: SaveButtonOnClickResult): Promise<void> {
    if (result !== SaveButtonOnClickResult.SUCCESS) {
      this.saveMessage = '保存失败，请允许保存图片后重试';
      return;
    }
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        this.saveMessage = '保存失败，暂时无法访问系统相册';
        return;
      }
      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const assetUri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, `express_invite_${Date.now()}.png`);
      const raw = await context.resourceManager.getRawFileContent('express_invite_poster_qr.png');
      const file = await fs.open(assetUri, fs.OpenMode.READ_WRITE);
      await fs.write(file.fd, raw);
      fs.close(file.fd);
      this.saveMessage = '海报已保存到系统相册';
    } catch (_error) {
      this.saveMessage = '保存失败，请授予照片访问权限后重试';
    }
  }

  build() {
    Column() {
      Row() {
        Button() { Image($r('app.media.chevron_backward')).width(22).height(22); }
          .width(40).height(40).backgroundColor('#EEF0F2').borderRadius(20).onClick(() => this.onBack());
        Text('邀请好友').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#182230').margin({ left: 10 });
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center).backgroundColor(Color.White);
      Scroll() {
        Column({ space: 14 }) {
          Stack() {
            Image($r('app.media.express_invite_poster')).width('100%').objectFit(ImageFit.Contain).borderRadius(14);
            Image($r('app.media.invite_qr')).width(92).height(92).position({ right: 31, bottom: 42 });
          }.width('100%');
          Text('扫码邀请好友注册下单，领取优惠券礼包').fontSize(15).fontColor('#182230');
          Text(`邀请链接已按元服务 App ID 与用户 ID 生成`).fontSize(12).fontColor('#8A94A3');
          Text(this.invite.link).fontSize(11).fontColor('#576275').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
          SaveButton({
            icon: SaveIconStyle.FULL_FILLED,
            text: SaveDescription.SAVE_IMAGE,
            buttonType: ButtonType.Capsule
          })
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#0A59F7')
            .borderRadius(23)
            .onClick((_event: ClickEvent, result: SaveButtonOnClickResult) => this.savePoster(result));
          if (this.saveMessage.length > 0) {
            Text(this.saveMessage).fontSize(13).fontColor('#0A59F7');
          }
        }.padding({ left: 16, right: 16, top: 16, bottom: 24 });
      }.layoutWeight(1).scrollBar(BarState.Off);
    }.width('100%').height('100%').backgroundColor('#F4F6F8');
  }
}
