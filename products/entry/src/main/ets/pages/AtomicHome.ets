import { HomePage } from './HomePage';
import { OrderPage } from './OrderPage';
import { BenefitPage } from './BenefitPage';
import { ShippingPage } from './ShippingPage';
import { ExpressDiscountPage } from './ExpressDiscountPage';
import { InviteFriendsPage } from './InviteFriendsPage';
import { AtomicOrder, AtomicOrderDetail, AtomicLogisticsNode, OrdersMockApi, ExpressApi } from '../data/JavaApiClient';
import { PointsHistoryPage } from './PointsHistoryPage';
import { MemberBenefitPage } from './MemberBenefitPage';
import { ProhibitedGoodsPage } from './ProhibitedGoodsPage';
import { AddressBookPage } from '../address/AddressBookPage';
import { AgreementMockPage } from './AccountPages';
import { MinePage as SourceMinePage, CouponPage as SourceCouponPage, PrivacyPage as SourcePrivacyPage, PersonalInformationPage as SourcePersonalInformationPage, SettingPage as SourceSettingPage, SettingPrivacyPage as SourceSettingPrivacyPage, PurchasePage as SourcePurchasePage, LoginUtil } from 'business_mine';
import { NoticeCenterPage as SourceNoticeCenterPage } from 'notice_center';
import { map, mapCommon, navi, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { CommonTitle, TelUtil } from 'lib_foundation';

@Entry
@Component
struct AtomicHome {
  // 福利是主底部 Tab；元服务首屏直接展示福利 Tab，积分明细/会员权益才进入二级详情。
  @State selected: number = 0;
  @State orderFilter: number = 0;
  @State merchantPhone: string = '0012356';
  @State bannerAdId: string = '';
  @State contactSheetVisible: boolean = false;
  @State detail: string = '';
  @State submitted: boolean = false;
  @State addressVisible: boolean = true;
  @State selectedOrder: AtomicOrder | null = null;
  @State detailData: AtomicOrderDetail | null = null;
  @State logistics: AtomicLogisticsNode[] = [];
  @State detailLoading: boolean = false;
  @State detailFailed: boolean = false;
  @State detailMessage: string = '';
  @State infoExpanded: boolean = false;
  @State detailPanelHeight: number = 250;
  @State detailMapHeight: number = 0;
  @State previousDetail: string = '';
  @State feedbackText: string = '';
  @State feedbackContact: string = '';
  @State feedbackImages: string[] = [];
  private detailPanelStartY: number = 0;
  private detailPanelStartHeight: number = 250;
  private silentLoginAttempted: boolean = false;
  private detailMapOptions: mapCommon.MapOptions = {
    position: { target: { latitude: 31.778, longitude: 119.554 }, zoom: 8 },
    rotateGesturesEnabled: true,
    scrollGesturesEnabled: true,
    zoomGesturesEnabled: true,
  };
  private detailMapController?: map.MapComponentController;
  private detailMapCallback: AsyncCallback<map.MapComponentController> = async (error, controller) => {
    if (!error) {
      this.detailMapController = controller;
      controller.getEventManager().on('mapLoad', () => {
        console.info('AtomicHome', 'order detail map loaded');
      });
      const current = this.detailData || this.selectedOrder;
      if (current) {
        await this.renderTransportRoute(current);
      }
    } else {
      console.error('AtomicHome', `order detail map init failed, code: ${error.code}, message: ${error.message}`);
    }
  };

  onPageShow(): void {
    this.detailMapController?.show();
  }

  aboutToAppear(): void {
    if (this.silentLoginAttempted) return;
    this.silentLoginAttempted = true;
    this.loadMerchantPhone();
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    LoginUtil.silentHuaweiLogin(context);
  }

  private async loadMerchantPhone(): Promise<void> {
    try {
      const data = await ExpressApi.publicConfig();
      const config = data['config'] as Record<string, object> | undefined;
      const value = config ? (config['merchant_phone'] || config['merchantPhone'] || config['business_phone']) : undefined;
      const direct = data['merchant_phone'] || data['merchantPhone'] || data['business_phone'];
      const phone = `${value || direct || ''}`.trim();
      if (phone.length > 0) this.merchantPhone = phone;
      const adValue = config ? (config['bannerAdId'] || config['banner_ad_id'] || config['adUnitId'] || config['ad_unit_id']) : undefined;
      const directAd = data['bannerAdId'] || data['banner_ad_id'] || data['adUnitId'] || data['ad_unit_id'];
      this.bannerAdId = `${adValue || directAd || ''}`.trim();
    } catch (_) {
      // Keep the local fallback when the public config is unavailable.
    }
  }

  onPageHide(): void {
    this.detailMapController?.hide();
  }

  private openDetailPage(page: string): void {
    this.previousDetail = this.detail;
    this.detail = page;
  }

  private backToPreviousPage(): void {
    const leavingOrderDetail = this.detail.startsWith('物流');
    this.detail = this.previousDetail;
    this.previousDetail = '';
    if (leavingOrderDetail) {
      // 物流详情返回查快递列表时清除首页入口遗留的“未补缴”筛选。
      this.orderFilter = 0;
      this.selected = 1;
    }
    this.submitted = false;
    this.selectedOrder = null;
    this.detailData = null;
    this.logistics = [];
    this.detailLoading = false;
    this.detailFailed = false;
    this.detailMessage = '';
    this.detailPanelHeight = 250;
    this.detailMapController?.clear();
    this.detailMapController = undefined;
  }

  private async selectFeedbackImages(): Promise<void> {
    const remainingCount = 6 - this.feedbackImages.length;
    if (remainingCount <= 0) {
      return;
    }
    const options: photoAccessHelper.PhotoSelectOptions = {
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: remainingCount,
      isPreviewForSingleSelectionSupported: true,
    };
    try {
      const result = await new photoAccessHelper.PhotoViewPicker().select(options);
      this.feedbackImages = [...this.feedbackImages, ...result.photoUris];
    } catch (error) {
      console.error('AtomicHome', `select feedback images failed: ${JSON.stringify(error)}`);
      this.getUIContext().getPromptAction().showToast({ message: '图片选择失败，请重试' });
    }
  }

  private removeFeedbackImage(index: number): void {
    this.feedbackImages = this.feedbackImages.filter((_uri: string, imageIndex: number) => imageIndex !== index);
  }

  build() {
    Column() {
      if (this.detail.length > 0) {
        this.detailPage();
      } else {
          // 源程序的“我的”页面自带标题栏；作为底部 Tab 展示时不再叠加元服务外层标题。
          // 查快递页面没有自带标题栏；福利和我的页面由各自页面负责顶部区域。
          if (this.selected === 1) {
            Row() {
              Text('查快递')
                .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#182230');
            }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White);
          }
          if (this.selected === 0) {
            HomePage({ detail: $detail, adUnitId: this.bannerAdId, onOpenExpress: () => this.selectTab(1), onOpenUnpaid: () => { this.orderFilter = 2; this.selectTab(1); }, onOpenCustomer: () => { this.contactSheetVisible = true; } }).layoutWeight(1);
          } else if (this.selected === 1) {
            OrderPage({ initialFilter: this.orderFilter, onOpenDetail: (item: AtomicOrder) => { this.selectedOrder = item; this.detailData = null; this.infoExpanded = false; this.openDetailPage('订单详情'); this.loadOrderDetail(item); }, onOpenLogistics: (item: AtomicOrder) => { this.selectedOrder = item; this.detailData = null; this.openDetailPage('物流详情'); this.loadOrderDetail(item); } }).layoutWeight(1);
          } else if (this.selected === 2) {
            BenefitPage({ userId: 0, storeId: 0, tenantId: 0, openPage: (page: string) => this.openDetailPage(page) }).layoutWeight(1);
          } else if (this.selected === 3) {
            SourceMinePage({
              externalNavigation: true,
              onOpenExpress: () => this.selectTab(1),
              onOpenMessage: () => this.openDetailPage('消息通知'),
              onOpenCoupon: () => this.openDetailPage('优惠券'),
              onOpenFeedback: () => this.openDetailPage('问题反馈'),
              onOpenSetting: () => this.openDetailPage('设置'),
              onOpenLogin: () => {
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                LoginUtil.interactiveHuaweiLogin(context);
              },
            }).layoutWeight(1);
          } else if (this.detail.startsWith('物流')) {
            this.orderDetailPage();
          } else {
            SourceMinePage({
              externalNavigation: true,
              onOpenExpress: () => this.selectTab(1),
              onOpenMessage: () => this.openDetailPage('消息通知'),
              onOpenCoupon: () => this.openDetailPage('优惠券'),
              onOpenFeedback: () => this.openDetailPage('问题反馈'),
              onOpenSetting: () => this.openDetailPage('设置'),
              onOpenLogin: () => {
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                LoginUtil.interactiveHuaweiLogin(context);
              },
            }).layoutWeight(1);
          }
        this.bottomTabs();
      }
    }.width('100%').height('100%').backgroundColor('#F4F6F8')
      .bindSheet($$this.contactSheetVisible, this.merchantPhoneSheet(), {
        height: SheetSize.FIT_CONTENT,
        preferType: SheetType.BOTTOM,
        backgroundColor: '#F4F6F8',
      });
  }

  @Builder
  merchantPhoneSheet() {
    Column({ space: 14 }) {
      Text('联系客服').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#182230');
      Text('商家电话').fontSize(13).fontColor('#7A8699');
      Text(this.merchantPhone).fontSize(26).fontWeight(FontWeight.Bold).fontColor('#0A59F7');
      Button('拨打电话').width('100%').height(46).backgroundColor('#0A59F7').fontColor(Color.White)
        .onClick(() => TelUtil.makeCall('联系客服', this.merchantPhone));
      Button('取消').width('100%').height(44).backgroundColor('#E7E9EC').fontColor('#182230')
        .onClick(() => this.contactSheetVisible = false);
    }.width('100%').padding({ left: 20, right: 20, top: 20, bottom: 24 });
  }

  @Builder
  orderDetailPage() {
    Column() {
      CommonTitle({
        title: '寄快递',
        bgColor: Color.White,
        useWindowPadding: false,
        onBack: () => this.backToPreviousPage(),
      })
      Scroll() {
        Column({ space: 12 }) {
          Column() {
            Row({ space: 12 }) { SymbolGlyph($r('sys.symbol.checkmark_circle')).fontSize(58).fontColor([Color.White]); Column({ space: 4 }) { Text('下单成功').fontSize(24).fontWeight(FontWeight.Bold).fontColor(Color.White); Text('感谢使用快递服务，期待再次为您服务').fontSize(13).fontColor('#E8FFF3'); }.alignItems(HorizontalAlign.Start); }.width('100%').margin({ top: 18 });
          }.width('100%').padding({ left: 20, right: 20, top: 6, bottom: 24 }).backgroundColor('#0A59F7');
          this.waybillCard((this.detailData || this.selectedOrder) as AtomicOrderDetail);
          this.addressDetailCard((this.detailData || this.selectedOrder) as AtomicOrderDetail);
          this.feeDetailCard((this.detailData || this.selectedOrder) as AtomicOrderDetail);
        }.width('100%').padding({ bottom: 88 });
      }.layoutWeight(1).scrollBar(BarState.Off);
      Row({ space: 10 }) { Button('返回首页').layoutWeight(1).height(46).backgroundColor(Color.White).fontColor('#0A59F7').border({ width: 1, color: '#0A59F7' }).borderRadius(8).onClick(() => this.selectTab(0)); Button('查看物流').layoutWeight(1).height(46).backgroundColor('#0A59F7').fontColor(Color.White).borderRadius(8).onClick(() => { this.detail = '物流详情'; }); }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 12 }).backgroundColor(Color.White);
    }.width('100%').height('100%').backgroundColor('#F3F5F7');
  }

  @Builder waybillCard(item: AtomicOrderDetail) {
    Column({ space: 14 }) {
      Row() { Text('运单信息').fontSize(18).fontWeight(FontWeight.Bold); Text('复制运单号  ⧉').fontSize(13).fontColor('#0A59F7').onClick(() => this.detailMessage = '运单号已复制'); }.width('100%').justifyContent(FlexAlign.SpaceBetween);
      Row({ space: 12 }) { Image($r('app.media.brand_shunfeng_standard')).width(54).height(54); Column({ space: 5 }) { Text(item.carrier || '顺丰速运').fontSize(17).fontWeight(FontWeight.Medium); Text('极速发货  安全可靠').fontSize(12).fontColor('#7A8699'); }.layoutWeight(1); Column({ space: 5 }) { Text('运单号：' + (item.trackingNo || item.id)).fontSize(12).fontColor('#6F7781'); Text('下单时间：' + this.formatDateTime(item.createdAt)).fontSize(12).fontColor('#6F7781'); }.alignItems(HorizontalAlign.End); }.width('100%');
      Row() { ForEach(['已下单', '已揽件', '运输中', '派送中', '已签收'], (label: string, index: number) => { Column({ space: 5 }) { Circle({ width: 22, height: 22 }).fill(index === 0 ? '#0A59F7' : '#D7DADF'); Text(label).fontSize(12).fontColor(index === 0 ? '#0A59F7' : '#6F7781'); if (index === 0) Text('05-20 09:41').fontSize(10).fontColor('#0A59F7'); }.layoutWeight(1); if (index < 4) Divider().layoutWeight(1).color('#D7DADF').margin({ top: 11 }); }, (label: string) => label); }.width('100%').alignItems(VerticalAlign.Top);
    }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16);
  }

  @Builder addressDetailCard(item: AtomicOrderDetail) { Column({ space: 12 }) { Text('寄件信息').fontSize(17).fontWeight(FontWeight.Bold); this.addressDetailRow('寄', item.sender || '张三', item.senderPhone || '138****1234', item.from || '广东省深圳市南山区科技园'); Divider().color('#E8EAED'); Text('收件信息').fontSize(17).fontWeight(FontWeight.Bold); this.addressDetailRow('收', item.receiver || '李四', item.receiverPhone || '139****5678', item.to || '北京市朝阳区望京街道'); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16); }
  @Builder addressDetailRow(tag: string, name: string, phone: string, address: string) { Row({ space: 10 }) { Text(tag).fontSize(14).fontColor(Color.White).textAlign(TextAlign.Center).width(30).height(30).padding({ top: 6 }).backgroundColor(tag === '寄' ? '#0A59F7' : '#BFD8FF').borderRadius(6); Column({ space: 4 }) { Row({ space: 12 }) { Text(name).fontSize(16).fontWeight(FontWeight.Medium); Text(phone).fontSize(13).fontColor('#6F7781'); }; Text(address).fontSize(12).fontColor('#7A8699').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }); }.layoutWeight(1); SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(18).fontColor(['#9AA1AA']); }.width('100%'); }
  @Builder feeDetailCard(item: AtomicOrderDetail) { Column({ space: 14 }) { this.feeRow('物品信息', (item.goodsName || '日用品') + ' / ' + (item.weight ? item.weight + 'kg' : '1kg')); this.feeRow('服务类型', item.pickupMethod || '顺丰标快'); this.feeRow('付款方式', item.paymentMethod || '在线支付'); this.feeRow('运费金额', '¥ ' + item.amount.toFixed(2), '#E53935'); this.feeRow('优惠金额', '- ¥ ' + (item.discount || 3).toFixed(2), '#E53935'); this.feeRow('实际支付', '¥ ' + (item.amount - (item.discount || 3)).toFixed(2), '#182230'); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(16); }
  @Builder feeRow(label: string, value: string, color: string = '#182230') { Row() { Text(label).fontSize(14).fontColor('#6F7781'); Text(value).fontSize(14).fontWeight(label === '实际支付' ? FontWeight.Bold : FontWeight.Regular).fontColor(color).layoutWeight(1).textAlign(TextAlign.End); }.width('100%'); }

  @Builder mapStatusOverlay(item: AtomicOrder) {
    Column() {
      Row({ space: 5 }) {
        Text((item.carrier || '圆通快递') + '：' + (item.trackingNo || item.id)).fontSize(10).fontColor(Color.White).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis });
        SymbolGlyph($r('sys.symbol.plus_square_on_square')).fontSize(15).fontColor(['#E5E7EB']);
      }.width('100%').height(34).padding({ left: 12, right: 12 }).backgroundColor('#746F63')
        .borderRadius({ topLeft: 16, topRight: 16 });
      Row() {
        Column({ space: 7 }) {
          Text(this.displayOrderStatus(item.status)).fontSize(18).fontWeight(FontWeight.Medium).fontColor('#182230');
          Text(this.statusTimeText(item)).fontSize(10).fontColor('#6F7781');
        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        Text(item.from).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#182230').layoutWeight(1).textAlign(TextAlign.End).maxLines(1);
        SymbolGlyph($r('sys.symbol.arrow_right')).fontSize(18).fontColor(['#0A59F7']).margin({ left: 10, right: 10 });
        Text(item.to).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#182230').layoutWeight(1).maxLines(1);
      }.width('100%').height(76).padding({ left: 12, right: 12 });
    }.width('calc(100% - 32vp)').height(110).backgroundColor(Color.White).borderRadius(16)
      .position({ top: 8, left: 16 }).zIndex(1);
  }

  @Builder courierCard(item: AtomicOrder) {
    Row() {
      Image($r('app.media.ic_courier_avatar')).width(38).height(38).borderRadius(19);
      Column({ space: 4 }) {
        Text(this.courierName()).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#182230');
        Text(item.carrier).fontSize(11).fontColor('#6F7781');
      }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 8 });
      Button() { SymbolGlyph($r('sys.symbol.phone_fill')).fontSize(18).fontColor(['#0A59F7']); }
        .width(34).height(34).padding(0).backgroundColor('#EAF1FF').borderRadius(17)
        .onClick(() => TelUtil.makeCall('联系快递员', this.courierPhone()));
    }.width('100%').height(58).padding({ left: 12, right: 12 }).backgroundColor('#F4F5F7').borderRadius(16);
  }

  private async loadOrderDetail(item: AtomicOrder) {
    this.detailLoading = true;
    this.detailFailed = false;
    try {
      const response = await OrdersMockApi.detail(item);
      this.detailData = response.order || response.detail || item as AtomicOrderDetail;
      this.logistics = response.logistics || response.logs || [];
      await this.renderTransportRoute(this.detailData);
    } catch (_error) {
      this.detailFailed = true;
    } finally {
      this.detailLoading = false;
    }
  }
  private displayOrderStatus(status: string): string {
    if (status === '已签收') { return '已签收'; }
    if (status === '运输中') { return '已取件'; }
    return status;
  }
  private statusTimeText(item: AtomicOrder): string {
    if (item.status === '已签收') { return '签收时间：' + this.valueOr(this.detailData?.completedAt, item.eta); }
    return '取件时间：' + this.valueOr(this.detailData?.pickedAt, item.eta);
  }
  private courierName(): string {
    const node = this.logistics.find((item: AtomicLogisticsNode) => !!item.operatorName);
    return node?.operatorName || '快递员';
  }
  private courierPhone(): string {
    const node = this.logistics.find((item: AtomicLogisticsNode) => !!item.operatorPhone);
    return node?.operatorPhone || '95338';
  }
  private moveDetailPanel(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.detailPanelStartY = event.touches[0].y;
      this.detailPanelStartHeight = this.detailPanelHeight;
      return;
    }
    if (event.type === TouchType.Move) {
      const distance = this.detailPanelStartY - event.touches[0].y;
      const maxHeight = Math.max(250, this.detailMapHeight - 126);
      this.detailPanelHeight = Math.min(maxHeight, Math.max(250, this.detailPanelStartHeight + distance));
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      const maxHeight = Math.max(250, this.detailMapHeight - 126);
      const middleHeight = Math.max(250, this.detailMapHeight * 0.58);
      const target = this.detailPanelHeight > (middleHeight + 250) / 2 ? middleHeight : 250;
      const finalHeight = this.detailPanelHeight > (maxHeight + middleHeight) / 2 ? maxHeight : target;
      this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
        this.detailPanelHeight = finalHeight;
      });
    }
  }
  private resolveCoordinate(item: AtomicOrder, destination: boolean): mapCommon.LatLng {
    const city = destination ? item.to : item.from;
    // 演示订单可能从接口带回旧坐标；城市名是当前页面展示的权威数据。
    if (city.includes('广州')) { return { latitude: 23.1291, longitude: 113.2644 }; }
    if (city.includes('无锡')) { return { latitude: 31.4912, longitude: 120.3119 }; }
    if (city.includes('南京')) { return { latitude: 32.0603, longitude: 118.7969 }; }
    if (city.includes('上海')) { return { latitude: 31.2304, longitude: 121.4737 }; }
    if (city.includes('北京')) {
      return destination ? { latitude: 39.9062, longitude: 116.4750 } : { latitude: 39.9165, longitude: 116.3150 };
    }
    const latitude = destination ? item.receiverLatitude : item.senderLatitude;
    const longitude = destination ? item.receiverLongitude : item.senderLongitude;
    if (latitude && longitude) { return { latitude: latitude, longitude: longitude }; }
    return destination ? { latitude: 32.0603, longitude: 118.7969 } : { latitude: 31.4912, longitude: 120.3119 };
  }
  private async renderTransportRoute(item: AtomicOrder | null): Promise<void> {
    if (!item || !this.detailMapController) { return; }
    const origin = this.resolveCoordinate(item, false);
    const destination = this.resolveCoordinate(item, true);
    this.detailMapController.clear();
    const crossProvince = this.isCrossProvince(item, origin, destination);
    this.fitRouteBounds([origin, destination], crossProvince);
    try {
      const result = await navi.getDrivingRoutes({ origins: [origin], destination: destination, language: 'zh_CN' });
      if (result.routes.length > 0) {
        const routePoints: mapCommon.LatLng[] = result.routes[0].overviewPolyline || [origin, destination];
        this.detailMapController.addPolyline({ points: routePoints, width: 12, color: 0xFF0A59F7 });
        this.fitRouteBounds(routePoints, crossProvince);
      } else {
        this.detailMapController.addPolyline({ points: [origin, destination], width: 12, color: 0xFF0A59F7 });
      }
    } catch (_error) {
      this.detailMapController.addPolyline({ points: [origin, destination], width: 12, color: 0xFF0A59F7 });
    }
    const senderMarker = await this.detailMapController.addMarker({ position: origin, anchorV: 0, clickable: true, icon: $r('app.media.ic_send_map') });
    const receiverMarker = await this.detailMapController.addMarker({ position: destination, anchorV: 0, clickable: true, icon: $r('app.media.ic_receive_map') });
    senderMarker.setTitle('始发地');
    senderMarker.setSnippet(item.from);
    senderMarker.setInfoWindowVisible(true);
    receiverMarker.setTitle(item.status === '已签收' ? '已签收' : '签收地');
    receiverMarker.setSnippet(item.to);
    receiverMarker.setInfoWindowVisible(true);
  }
  private fitRouteBounds(points: mapCommon.LatLng[], crossProvince: boolean = false): void {
    if (!this.detailMapController || points.length === 0) { return; }
    let minLat = points[0].latitude;
    let maxLat = points[0].latitude;
    let minLng = points[0].longitude;
    let maxLng = points[0].longitude;
    points.forEach((point: mapCommon.LatLng) => {
      minLat = Math.min(minLat, point.latitude);
      maxLat = Math.max(maxLat, point.latitude);
      minLng = Math.min(minLng, point.longitude);
      maxLng = Math.max(maxLng, point.longitude);
    });
    const bounds: mapCommon.LatLngBounds = {
      southwest: { latitude: minLat, longitude: minLng },
      northeast: { latitude: maxLat, longitude: maxLng }
    };
    // 首次渲染时区域高度可能尚未回调，使用详情页地图的稳定最小视口，避免退到全国级别。
    const height = Math.max(620, this.detailMapHeight - 20);
    const width = Math.max(620, height);
    if (crossProvince) {
      this.detailMapController.moveCamera(map.newCameraPosition({
        target: { latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2 },
        zoom: 5.8,
      }));
    } else {
      this.detailMapController.moveCamera(map.newLatLngBounds(bounds, width, height, 24));
    }
  }
  private isCrossProvince(item: AtomicOrder, origin: mapCommon.LatLng, destination: mapCommon.LatLng): boolean {
    const province = (city: string): string => {
      if (city.includes('北京')) return '北京';
      if (city.includes('上海')) return '上海';
      if (city.includes('广州') || city.includes('深圳') || city.includes('东莞')) return '广东';
      if (city.includes('南京') || city.includes('无锡') || city.includes('苏州')) return '江苏';
      if (city.includes('杭州') || city.includes('宁波')) return '浙江';
      return '';
    };
    const fromProvince = province(item.from);
    const toProvince = province(item.to);
    if (fromProvince && toProvince) return fromProvince !== toProvince;
    return Math.abs(origin.latitude - destination.latitude) > 2.5 ||
      Math.abs(origin.longitude - destination.longitude) > 3.5;
  }
  private valueOr(value: string | undefined, fallback: string): string { return value && value.length > 0 ? value : fallback; }
  private formatDateTime(value: string): string { if (value.length === 0) return '--'; const normalized = value.replace('T', ' '); return normalized.length > 19 ? normalized.substring(0, 19) : normalized; }
  private detailFeeRows(): string[] { const item = this.detailData || this.selectedOrder as AtomicOrder; const detail = this.detailData; const rows = ['物品信息：' + this.valueOr(detail?.goodsName, '普通物品'), '重量及计费重量：' + (detail?.weight ? detail.weight + ' kg' : '以实际称重为准'), '配送服务：' + this.valueOr(detail?.pickupMethod, '上门取件'), '支付方式：' + this.valueOr(detail?.paymentMethod, '在线支付'), '优惠金额：¥' + (detail?.discount || 0).toFixed(2), '实付金额：¥' + item.amount.toFixed(2), '订单备注：' + this.valueOr(detail?.remark, '无')]; if (item.status === '运输中（待补缴）') { if ((detail?.supplementAmount || item.supplementAmount || 0) > 0) rows.splice(2, 0, '待补缴金额：¥' + (detail?.supplementAmount || item.supplementAmount || 0).toFixed(2)); if ((detail?.overweight || item.overweight || 0) > 0) rows.splice(3, 0, '超重重量：' + (detail?.overweight || item.overweight || 0).toFixed(2) + ' kg'); } return rows; }
  private detailRows(): string[] { const item = this.detailData || this.selectedOrder as AtomicOrder; return ['订单编号：' + item.id, '订单来源：元服务', '订单类型：快递寄件', '快递公司：' + item.carrier, '运单号：' + item.trackingNo, '期望取件时间：' + this.valueOr(this.detailData?.eta, item.eta)]; }
  @Builder logisticsSection() {
    Column({ space: 10 }) {
      if (this.logistics.length > 0) {
        ForEach(this.logistics, (node: AtomicLogisticsNode, index: number) => {
          Row({ space: 10 }) {
            Column() {
              if (index === 0) { Image($r('app.media.ic_get_selected')).width(24).height(28); }
              else { Circle({ width: 8, height: 8 }).fill(node.completed === false ? '#C8CDD5' : '#0A59F7').margin({ top: 8 }); }
              if (index < this.logistics.length - 1) { Divider().vertical(true).height(34).color('#D8DCE2'); }
            }.width(26);
            Column({ space: 3 }) {
              Text(node.description).fontSize(14).fontWeight(index === 0 ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(index === 0 ? '#182230' : '#6F7781');
              Text(node.time + (node.location ? '  ' + node.location : '')).fontSize(11).fontColor('#8A94A3');
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%').alignItems(VerticalAlign.Top);
        }, (node: AtomicLogisticsNode, index: number) => node.time + index);
      } else {
        Text('暂无物流轨迹，请稍后刷新').fontSize(13).fontColor('#8A94A3');
      }
    }.width('100%').alignItems(HorizontalAlign.Start);
  }
  @Builder detailActions() { Row({ space: 8 }) { if ((this.selectedOrder as AtomicOrder).status === '待付款') { Button('立即付款').layoutWeight(1).height(44).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.detailMessage = '请从订单列表发起支付'); } if (['待取件', '下单异常'].includes((this.selectedOrder as AtomicOrder).status)) { Button('取消订单').layoutWeight(1).height(44).backgroundColor('#F1F2F4').onClick(() => this.performOrderAction('cancel')); } if ((this.selectedOrder as AtomicOrder).status === '待确认') { Button('确认收货').layoutWeight(1).height(44).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.performOrderAction('confirm')); } if (['已签收', '已取消'].includes((this.selectedOrder as AtomicOrder).status)) { Button('再次下单').layoutWeight(1).height(44).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.detailMessage = '已创建再次下单请求'); } Button('联系客服').layoutWeight(1).height(44).backgroundColor('#F1F2F4'); }.width('100%'); if (this.detailMessage.length > 0) { Text(this.detailMessage).fontSize(13).fontColor('#0A59F7').margin({ top: 6 }); } }
  private async performOrderAction(action: string) { const item = this.selectedOrder as AtomicOrder; await OrdersMockApi.action(item, action); this.detailMessage = action === 'confirm' ? '模拟确认收货成功' : '模拟订单已取消'; }
  @Builder detailStatus(item: AtomicOrder) { Column({ space: 6 }) { Text(item.status).fontSize(22).fontWeight(FontWeight.Bold).fontColor(item.status === '已取消' ? '#8A94A3' : '#0A59F7'); Text(item.status === '运输中' || item.status === '运输中（待补缴）' ? '包裹正在运输中' : item.status === '待取件' ? '等待快递员上门取件' : item.status === '已签收' ? '订单已签收' : '订单状态信息').fontSize(13).fontColor('#7A8699'); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(14).alignItems(HorizontalAlign.Start); }
  @Builder detailAddress(item: AtomicOrder) { Row() { Column() { Text('寄件地址').fontSize(12).fontColor('#8A94A3'); Text(item.from).fontSize(17).fontWeight(FontWeight.Medium); Text(item.sender).fontSize(13).fontColor('#6F7781'); }.layoutWeight(1); SymbolGlyph($r('sys.symbol.arrow_right')).fontSize(24).fontColor(['#0A59F7']); Column() { Text('收件地址').fontSize(12).fontColor('#8A94A3'); Text(item.to).fontSize(17).fontWeight(FontWeight.Medium); Text(item.receiver).fontSize(13).fontColor('#6F7781'); }.layoutWeight(1); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(14); }
  @Builder infoSection(title: string, rows: string[]) { Column({ space: 8 }) { Text(title).fontSize(16).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start); ForEach(rows, (row: string) => { Text(row).fontSize(14).fontColor('#4F5968').width('100%'); }, (row: string) => row); }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(14); }

  private open(action: string): void { this.detail = action; }

  private selectTab(index: number): void {
    this.selected = index;
    this.detail = '';
    this.previousDetail = '';
    this.selectedOrder = null;
    this.detailData = null;
    this.logistics = [];
  }

  @Builder
  bottomTabs() {
    Row() {
      this.tab('首页', 0, $r('app.media.tab_home_selected_fixed'), $r('app.media.tab_home_fixed'));
      this.tab('查快递', 1, $r('app.media.tab_express_selected_fixed'), $r('app.media.tab_express_fixed'));
      this.tab('福利', 2, $r('app.media.tab_gift_selected_fixed'), $r('app.media.tab_gift_fixed'));
      this.tab('我的', 3, $r('app.media.tab_mine_selected_fixed'), $r('app.media.tab_mine_fixed'));
    }.width('100%').height(74).justifyContent(FlexAlign.SpaceAround).backgroundColor(Color.White);
  }

  @Builder
  tab(title: string, index: number, selectedIcon: Resource, normalIcon: Resource) {
    Button() {
      Column() {
        if (this.selected === index) {
          Image(selectedIcon).width(27).height(27);
        } else {
          Image(normalIcon).width(27).height(27);
        }
        Text(title).fontSize(11).fontColor(this.selected === index ? '#0A59F7' : '#626B78').margin({ top: 4 });
      }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    }
    .type(ButtonType.Normal)
    .width('25%').height(74)
    .padding(0)
    .backgroundColor(Color.Transparent)
    .stateStyles({
      normal: { .backgroundColor(Color.Transparent) },
      pressed: { .backgroundColor('#EEF4FF') }
    })
    .onClick(() => this.selectTab(index));
  }

  @Builder
  detailPage() {
    if (this.detail.startsWith('订单')) {
      this.orderDetailPage();
    } else if (this.detail.startsWith('物流')) {
      this.logisticsDetailPage();
    } else {
    Column() {
      if (this.detail.includes('查运费')) {
        ExpressDiscountPage({ onBack: () => this.backToPreviousPage(), onOrder: () => this.detail = '寄件|寄快递' });
      } else if (this.detail.startsWith('寄件') && this.detail.includes('查运费') === false) {
        ShippingPage({ detail: $detail, submitted: $submitted });
      } else if (this.detail.startsWith('地址')) {
        AddressBookPage({ mode: 'manage', onClosed: () => this.backToPreviousPage() });
      } else if (this.detail.startsWith('邀请好友')) {
        InviteFriendsPage({ onBack: () => this.backToPreviousPage() });
      } else {
        // These embedded pages render their own title bar; avoid stacking a second one here.
        if (!['个人信息', '优惠券', '消息通知', '隐私政策', '用户协议', '设置', '隐私设置', '会员购买', '实名认证', '问题反馈', '反馈记录', '违禁品说明', 'third', 'personal'].includes(this.detail)) {
          Row() { Button() { Image($r('app.media.ic_back')).width(22).height(22); }.width(40).height(40).backgroundColor('#EEF0F2').borderRadius(20).onClick(() => this.backToPreviousPage()); Text(this.detail.split('|')[0]).fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 10 }); }
            .width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center).backgroundColor(Color.White);
        }
        if (this.detail === '个人信息') {
          SourcePersonalInformationPage({ embedded: true, onBack: () => this.backToPreviousPage() });
        } else if (this.detail === '优惠券') {
          SourceCouponPage({ embedded: true, onBack: () => this.backToPreviousPage() });
        } else if (this.detail === '消息通知') {
          SourceNoticeCenterPage({ embedded: true, onBack: () => this.backToPreviousPage() });
        } else if (this.detail === '隐私政策') {
          SourcePrivacyPage({ embedded: true, onBack: () => this.backToPreviousPage() });
        } else if (this.detail === '用户协议') {
          AgreementMockPage({ title: '用户协议', onBack: () => this.detail = '' });
        } else if (this.detail === '设置') {
          SourceSettingPage({ embedded: true, onBack: () => this.backToPreviousPage() });
        } else if (this.detail === '隐私设置') {
          SourceSettingPrivacyPage({ embedded: true, onBack: () => this.backToPreviousPage() });
        } else if (this.detail === '会员购买') {
          SourcePurchasePage();
        } else if (this.detail === '问题反馈') {
          this.feedbackSubmitPage();
        } else if (this.detail === '反馈记录') {
          this.feedbackHistoryPage();
        } else if (this.detail === '实名认证') {
          this.unavailablePage('实名认证', '当前元服务暂未开放实名认证能力');
        } else if (this.detail === '违禁品说明') {
          ProhibitedGoodsPage({ onBack: () => this.backToPreviousPage() });
        } else if (this.detail === 'third' || this.detail === 'personal') {
          AgreementMockPage({ title: this.detail === 'third' ? '第三方信息共享清单' : '个人信息收集清单', onBack: () => this.detail = '' });
        } else if (this.detail.startsWith('会员')) {
          MemberBenefitPage({ userId: 0, tenantId: 0, close: () => this.detail = '' });
        } else if (this.detail.startsWith('积分明细')) {
          PointsHistoryPage({ close: () => this.detail = '' });
        } else if (this.detail.startsWith('设置')) {
          this.settingsPage();
        } else if (this.detail.startsWith('客服') || this.detail.startsWith('意见反馈')) {
          this.contactPage();
        } else {
          this.unavailablePage('页面不存在', '该页面已移除');
        }
      }
    }.width('100%').height('100%').backgroundColor('#F4F6F8');
    }
  }

  @Builder
  logisticsDetailPage() {
    Column() {
      Row() {
        Button() { Image($r('app.media.ic_back')).width(22).height(22); }
          .width(40).height(40).padding(0).backgroundColor('#E9EDF2').borderRadius(20)
          .onClick(() => this.backToPreviousPage());
        Text('运单详情').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#182230').margin({ left: 10 });
      }.width('100%').height(64).padding({ left: 16, right: 16 }).backgroundColor('#F3F5F7');
      Stack() {
        MapComponent({ mapOptions: this.detailMapOptions, mapCallback: this.detailMapCallback }).width('100%').height('100%');
        this.mapStatusOverlay((this.detailData || this.selectedOrder) as AtomicOrder);
        Column() {
          Row() { Image($r('app.media.ic_drag_bar')).width(96).height(16); }
            .width('100%').height(30).justifyContent(FlexAlign.Center)
            .onTouch((event: TouchEvent) => this.moveDetailPanel(event));
          Column({ space: 12 }) {
            this.courierCard((this.detailData || this.selectedOrder) as AtomicOrder);
            Text('物流详情').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#182230').alignSelf(ItemAlign.Start);
            Scroll() { this.logisticsSection(); }.layoutWeight(1).scrollBar(BarState.Off);
            Row({ space: 10 }) {
              Button('再次下单').layoutWeight(1).height(44).backgroundColor('#0A59F7').fontColor(Color.White).borderRadius(22).onClick(() => this.detailMessage = '已创建再次下单请求');
              Button('联系客服').layoutWeight(1).height(44).backgroundColor('#E7E9EC').fontColor('#AAB1BB').borderRadius(22).onClick(() => this.contactSheetVisible = true);
            }.width('100%');
          }.width('100%').layoutWeight(1).padding({ left: 16, right: 16 });
        }.width('100%').height(this.detailPanelHeight).backgroundColor('#F5F6F8')
          .constraintSize({ minHeight: this.detailPanelHeight, maxHeight: this.detailPanelHeight })
          .borderRadius({ topLeft: 22, topRight: 22 }).clip(true).position({ bottom: 0 });
      }.width('100%').layoutWeight(1).onAreaChange((_oldValue: Area, newValue: Area) => { this.detailMapHeight = Number(newValue.height); });
    }.width('100%').height('100%').backgroundColor('#F3F5F7');
  }

  @Builder
  unavailablePage(title: string, message: string) {
    Column({ space: 14 }) { Image($r('app.media.ic_warning')).width(56).height(56); Text(message).fontSize(15).fontColor('#6F7781'); Button('返回').width('100%').height(44).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.detail = ''); }.width('100%').layoutWeight(1).padding(24).justifyContent(FlexAlign.Center);
  }

  @Builder
  feedbackSubmitPage() {
    Column() {
      Row() {
        Button() { SymbolGlyph($r('sys.symbol.chevron_backward')).fontSize(24); }
          .width(40).height(40).type(ButtonType.Circle)
          .backgroundColor('#E9EAEC').onClick(() => this.backToPreviousPage());
        Text('问题反馈').fontSize(24).fontWeight(FontWeight.Bold).layoutWeight(1).margin({ left: 8 });
        Button() { SymbolGlyph($r('sys.symbol.doc_plaintext')).fontSize(24); }
          .width(40).height(40).type(ButtonType.Circle).backgroundColor('#E9EAEC')
          .onClick(() => this.openDetailPage('反馈记录'));
      }.height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White);
      Scroll() {
        Column({ space: 8 }) {
          Text('问题描述 *').fontSize(14).fontColor('#5D6570').alignSelf(ItemAlign.Start).margin({ top: 18 });
          TextArea({ placeholder: '请详细描述您的问题（必填）', text: this.feedbackText })
            .height(150).backgroundColor(Color.White).borderRadius(16)
            .onChange((v: string) => this.feedbackText = v);
          Row() {
            Text('上传图片').fontSize(14).fontColor('#5D6570');
            Text(`${this.feedbackImages.length}/6`).fontSize(12).fontColor('#8A94A3');
          }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 12 });
          Grid() {
            ForEach(this.feedbackImages, (uri: string, index: number) => {
              GridItem() {
                Stack({ alignContent: Alignment.TopEnd }) {
                  Image(uri).width('100%').height('100%').objectFit(ImageFit.Cover).draggable(false);
                  Button() { SymbolGlyph($r('sys.symbol.xmark')).fontSize(16).fontColor([Color.White]); }
                    .width(28).height(28).type(ButtonType.Circle).backgroundColor('#99000000')
                    .margin(4).onClick(() => this.removeFeedbackImage(index));
                }.width('100%').height('100%');
              }.aspectRatio(1).borderRadius(16).clip(true).backgroundColor(Color.White);
            }, (uri: string, index: number) => `${index}_${uri}`)
            if (this.feedbackImages.length < 6) {
              GridItem() {
                Button() { SymbolGlyph($r('sys.symbol.plus')).fontSize(28).fontColor(['#555555']); }
                  .width('100%').height('100%').type(ButtonType.ROUNDED_RECTANGLE)
                  .backgroundColor(Color.White).onClick(() => this.selectFeedbackImages());
              }.aspectRatio(1);
            }
          }.width('100%').height('auto').columnsTemplate('1fr 1fr 1fr').columnsGap(8).rowsGap(8);
          Text('您的联系方式').fontSize(14).fontColor('#5D6570').alignSelf(ItemAlign.Start).margin({ top: 12 });
          TextInput({ placeholder: '手机号或邮箱（选填）', text: this.feedbackContact }).height(48).backgroundColor(Color.White).borderRadius(16).onChange((v: string) => this.feedbackContact = v);
        }.padding({ left: 18, right: 18, bottom: 24 });
      }.layoutWeight(1).scrollBar(BarState.Off);
      Button('提交').width('calc(100% - 36vp)').height(44).margin({ left: 18, right: 18, bottom: 18 }).backgroundColor('#0A59F7').fontColor(Color.White).borderRadius(22)
        .onClick(() => {
          if (this.feedbackText.trim().length > 0) {
            this.feedbackText = '';
            this.feedbackContact = '';
            this.feedbackImages = [];
            this.detailMessage = '提交成功';
          }
        });
    }.width('100%').height('100%').backgroundColor('#F3F4F5');
  }

  @Builder
  feedbackHistoryPage() {
    Column() {
      Row() {
        Button() { SymbolGlyph($r('sys.symbol.chevron_backward')).fontSize(24); }
          .width(40).height(40).type(ButtonType.Circle).backgroundColor('#E9EAEC')
          .onClick(() => this.backToPreviousPage());
        Text('反馈记录').fontSize(24).fontWeight(FontWeight.Bold).layoutWeight(1).margin({ left: 8 });
      }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White);
      Column() {
        Text('暂无反馈记录').fontSize(14).fontColor('#6B7280');
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center);
    }.width('100%').height('100%').backgroundColor('#F3F4F5');
  }

  @Builder
  membershipPage() {
    Scroll() { Column({ space: 14 }) {
      Image($r('app.media.member_diamond')).width('100%').height(180).objectFit(ImageFit.Cover).borderRadius(14);
      Text('会员专享权益').fontSize(20).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start);
      this.infoRow('寄件优惠', '每月享受专属寄件折扣');
      this.infoRow('优惠礼包', '开通即送价值788元优惠券');
      Button('立即开通').width('100%').height(46).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.detail = '');
    }.padding(16); }.layoutWeight(1);
  }

  @Builder
  loginPage() {
    Column({ space: 14 }) {
      Image($r('app.media.huawei_count')).width(72).height(72).margin({ top: 28 });
      Text('华为账号登录').fontSize(22).fontWeight(FontWeight.Bold);
      Text('登录后同步地址、订单和会员权益').fontSize(14).fontColor('#7A8699');
      Button('华为账号一键登录').width('100%').height(46).margin({ top: 20 }).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => { this.detail = ''; });
      Text('登录即代表同意用户协议和隐私政策').fontSize(12).fontColor('#8A94A3');
    }.padding(24).layoutWeight(1);
  }

  @Builder
  contactPage() {
    Column({ space: 14 }) {
      Text(this.detail.startsWith('客服') ? '联系客服' : '意见反馈').fontSize(22).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start);
      TextInput({ placeholder: this.detail.startsWith('客服') ? '请输入您的问题' : '请描述您遇到的问题' }).height(130).backgroundColor(Color.White).borderRadius(10).maxLines(5);
      Button(this.detail.startsWith('客服') ? '提交咨询' : '提交反馈').width('100%').height(46).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.detail = '');
    }.padding(16).layoutWeight(1);
  }

  @Builder
  settingsPage() {
    Column({ space: 10 }) {
      this.infoRow('隐私与权限', '管理隐私设置');
      this.infoRow('字体大小', '标准');
      this.infoRow('关于我们', '版本 1.0.0');
      Button('返回').width('100%').height(44).margin({ top: 10 }).onClick(() => this.detail = '');
    }.padding(16).layoutWeight(1);
  }

  @Builder
  infoRow(title: string, detail: string) {
    Row() { Column() { Text(title).fontSize(16); Text(detail).fontSize(13).fontColor('#7A8699').margin({ top: 5 }); }.alignItems(HorizontalAlign.Start).layoutWeight(1); SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(18).fontColor(['#A0A8B5']); }
      .width('100%').padding(16).backgroundColor(Color.White).borderRadius(10);
  }

  @Builder
  track(time: string, text: string) {
    Row({ space: 12 }) { Image($r('app.media.ic_express')).width(18).height(18); Column() { Text(text).fontSize(15); Text(time).fontSize(12).fontColor('#8A94A3').margin({ top: 5 }); }.alignItems(HorizontalAlign.Start); }
      .width('100%').padding(14).backgroundColor(Color.White).borderRadius(10);
  }
}
