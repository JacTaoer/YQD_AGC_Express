import { map, mapCommon, navi } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import {
  RouterModule,
  Logger,
  RouterMap,
  HttpApi,
  CommonUtil,
  DEFAULT_LATITUDE,
  DEFAULT_LONGITUDE,
  STATUS_MAP,
  ParcelStatus,
  BaseViewModel,
  Logistics,
} from 'lib_foundation';
import { OrderInfo } from '../models/Model';


@ObservedV2
export class OrderInfoPageVM extends BaseViewModel {
  // 订单号
  @Trace orderNo: string = '';
  @Trace mapOptions?: mapCommon.MapOptions;
  @Trace mapController?: map.MapComponentController;
  @Trace mapEventManager?: map.MapEventManager;
  @Trace callback?: AsyncCallback<map.MapComponentController>
  @Trace orderInfo: OrderInfo | undefined;
  @Trace origin?: mapCommon.LatLng;
  @Trace destination?: mapCommon.LatLng;
  @Trace logisticsList: Logistics[] = [];
  @Trace showLoadingMask: boolean = true;
  @Trace uiContext: UIContext | null = null;
  // 地图范围的高度
  @Trace boundHeight: number = this.windowModel.windowHeight / 2 - 300;

  @Computed
  get snText() {
    let company = '';
    let sn = '';
    if (this.orderInfo?.expressCompany) {
      company = this.orderInfo.expressCompany;
    }
    if (this.orderInfo?.parcelNumber) {
      sn = this.orderInfo.parcelNumber;
    }
    return `${company}：${sn}`
  }

  @Computed
  get statusText() {
    if (this.orderInfo?.status) {
      return STATUS_MAP[this.orderInfo.status];
    }
    return '';
  }

  @Computed
  get curLogisticInfo() {
    const currentLogistic = this.logisticsList.find((item) => {
      return item.nodeStatus === this.orderInfo?.status;
    })
    return currentLogistic;
  }

  @Computed
  get dateTimeText() {
    let status = this.orderInfo?.status;
    // 快递员已取件
    if (status === ParcelStatus.COLLECTED) {
      return `取件时间：${CommonUtil.formatDate(this.curLogisticInfo?.occurrenceTime, 'MM月DD日 HH:mm')}`;
    }
    // 运送和派送
    const estimatedArrivalStatus = [ParcelStatus.IN_TRANSIT, ParcelStatus.DELIVERY]
    if (status && estimatedArrivalStatus.includes(status)) {
      return `预计送达时间：${CommonUtil.formatDate(this.orderInfo?.estimatedArrivalTime, 'MM月DD日 HH:mm')}`;
    }
    // 待签收
    if (status === ParcelStatus.OUT_FOR_DELIVERY) {
      return `送达时间：${CommonUtil.formatDate(this.orderInfo?.estimatedArrivalTime, 'MM月DD日 HH:mm')}`;
    }
    // 已签收
    if (status === ParcelStatus.DELIVERED) {
      return `签收时间：${CommonUtil.formatDate(this.orderInfo?.deliveryTime, 'MM月DD日 HH:mm')}`;
    }
    return '';
  }

  initData(func1: (() => ESObject), func2: (() => ESObject)) {
    const param = RouterModule.getNavParam<string>({ url: RouterMap.ORDER_INFO_PAGE });
    if (param) {
      this.orderNo = param;
      this.queryOrderInfo(func1, func2);
    }
  }

  // 地图初始化
  initMap() {
    this.mapOptions = {
      position: {
        target: {
          latitude: DEFAULT_LATITUDE,
          longitude: DEFAULT_LONGITUDE,
        },
        zoom: 6,
      },
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        // 获取地图的控制器类，用来操作地图
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        let callback = () => {
          console.info('on-mapLoad');
        }
        this.mapEventManager.on('mapLoad', callback);
      }
    };
  }

  // 查询订单详情
  queryOrderInfo(func1: () => ESObject, func2: () => ESObject) {
    HttpApi.queryParcelDetail(this.orderNo).then((resp) => {
      if (resp.detail) {
        this.orderInfo = new OrderInfo(resp.detail);
        this.getLocationData(func1, func2);
      }
      // 物流轨迹
      this.logisticsList = resp.logs;
    }).catch(() => {
      this.showLoadingMask = false
    })
  }

  // 获取经纬度
  getLocationData(func1: () => ESObject, func2: () => ESObject) {
    if (!this.orderInfo) {
      return;
    }
    this.origin = {
      latitude: this.orderInfo.senderLatitude,
      longitude: this.orderInfo.senderLongitude,
    };
    this.destination = {
      latitude: this.orderInfo.receiverLatitude,
      longitude: this.orderInfo.receiverLongitude,
    }
    this.tryRenderMarkers(func1, func2);
  }

  tryRenderMarkers(func1: () => ESObject, func2: () => ESObject) {
    if (this.mapController && this.origin && this.destination) {
      // 跨省运输展示省级范围，省内运输收紧到城市级视野。
      const crossProvince = this.isCrossProvince();
      // 计算发送地和目的地的边界
      const minLat = Math.min(this.origin.latitude, this.destination.latitude);
      const maxLat = Math.max(this.origin.latitude, this.destination.latitude);
      const minLng = Math.min(this.origin.longitude, this.destination.longitude);
      const maxLng = Math.max(this.origin.longitude, this.destination.longitude);
      try {
        // 两点过近时扩展最小边界，避免地图组件退回全国级默认视野。
        const minSpan = crossProvince ? 0.2 : 0.06;
        const centerLat = (minLat + maxLat) / 2;
        const centerLng = (minLng + maxLng) / 2;
        const latLngBounds: mapCommon.LatLngBounds = {
          southwest: {
            latitude: Math.min(minLat, centerLat - minSpan / 2),
            longitude: Math.min(minLng, centerLng - minSpan / 2),
          },
          northeast: {
            latitude: Math.max(maxLat, centerLat + minSpan / 2),
            longitude: Math.max(maxLng, centerLng + minSpan / 2),
          }
        };
        const viewportHeight = Math.max(250, this.boundHeight);
        // 跨省路线跨度较大，直接使用区域级固定缩放，避免 bounds 拟合到全国级。
        const cameraUpdate = crossProvince
          ? map.newCameraPosition({
              target: { latitude: centerLat, longitude: centerLng },
              zoom: 5.8,
            })
          : map.newLatLngBounds(
              latLngBounds,
              this.windowModel.windowWidth,
              viewportHeight,
              24,
            );
        // 移动相机
        this.mapController!.moveCamera(cameraUpdate);
      } catch (e) {
        Logger.error(`newLatLngBounds failed. error: ${JSON.stringify(e)}`)
      }
      this.testDrivingRoutes()
      this.addMarker();
      this.addMarkerCard(func1, func2);

      this.showLoadingMask = false
    }
  }

  /** 比较订单两端的省级行政区，兼容接口返回的不同后缀格式。 */
  private isCrossProvince(): boolean {
    const sender = this.normalizeProvince(this.orderInfo?.senderProvince);
    const receiver = this.normalizeProvince(this.orderInfo?.receiverProvince);
    if (sender.length > 0 && receiver.length > 0) {
      return sender !== receiver;
    }
    // 老订单可能没有省份字段，按坐标跨度做保守兜底。
    if (this.origin && this.destination) {
      return Math.abs(this.origin.latitude - this.destination.latitude) > 2.5 ||
        Math.abs(this.origin.longitude - this.destination.longitude) > 3.5;
    }
    return false;
  }

  private normalizeProvince(value: string | undefined): string {
    if (!value) {
      return '';
    }
    return value
      .replace('壮族自治区', '')
      .replace('维吾尔自治区', '')
      .replace('回族自治区', '')
      .replace('自治区', '')
      .replace('特别行政区', '')
      .replace('省', '')
      .replace('市', '')
      .trim();
  }

  clear() {
    this.orderInfo = undefined
    this.showLoadingMask = true
  }

  async testDrivingRoutes() {
    if (!this.origin || !this.destination) {
      return
    }
    let params: navi.DrivingRouteParams = {
      // 起点的经纬度
      origins: [this.origin],
      // 终点的经纬度
      destination: this.destination,
      language: 'zh_CN',
    };
    try {
      const result = await navi.getDrivingRoutes(params);
      this.mapController?.addPolyline({
        points: result.routes[0].overviewPolyline,
        width: 15,
        color: 0xFF0A59F7,
      })
    } catch (e) {
      Logger.error(JSON.stringify(e))
    }
  }

  async addMarker() {
    let markerOptions1: mapCommon.MarkerOptions = {
      position: this.origin!,
      anchorV: 0,
      clickable: true,
      icon: $r('app.media.ic_send_map'),
    };
    await this.mapController?.addMarker(markerOptions1)

    let markerOptions2: mapCommon.MarkerOptions = {
      position: this.destination!,
      anchorV: 0,
      clickable: true,
      icon: $r('app.media.ic_receive_map'),
    };
    await this.mapController?.addMarker(markerOptions2)
  }

  addMarkerCard(func1: (() => ESObject) | void, func2: (() => ESObject) | void) {
    this.uiContext?.getComponentSnapshot().createFromBuilder(func1,
      async (error: Error, pixmap: image.PixelMap) => {
        if (error) {
          Logger.error('error: ' + JSON.stringify(error))
          return;
        }
        // Marker初始化参数
        let markerOptions: mapCommon.MarkerOptions = {
          position: this.origin!,
          anchorV: 1,
          clickable: true,
          icon: pixmap,
        };
        this.mapController?.addMarker(markerOptions);
      })

    this.uiContext?.getComponentSnapshot().createFromBuilder(func2,
      async (error: Error, pixmap: image.PixelMap) => {
        if (error) {
          Logger.error('error: ' + JSON.stringify(error))
          return;
        }
        // Marker初始化参数
        let markerOptions: mapCommon.MarkerOptions = {
          position: this.destination!,
          anchorV: 1,
          clickable: true,
          icon: pixmap,
        };
        this.mapController?.addMarker(markerOptions);
      })
  }
}
