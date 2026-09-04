export interface AppLinkResult {
  appId: string;
  userId: string;
  link: string;
}

export class AppLinkingService {
  // 商家接入 App Linking 后，将此基础地址替换为服务端下发的短链接口。
  static createInviteLink(appId: string, userId: string): AppLinkResult {
    const link = `https://appgallery.huawei.com/app/C${encodeURIComponent(appId)}?invite_user=${encodeURIComponent(userId)}`;
    return { appId, userId, link };
  }
}
