import { http } from '@kit.NetworkKit';

class EmptyRequest {}

class ExpressLoginRequest {
  hmAppid: string = '';
  authorizationCode: string = '';
}

class ExpressCancelRequest {
  reason: string = '';
  requestId: string = '';
}
class ExpressAddressParseRequest { content: string = ''; }

/** 元服务统一通过 Java 服务 API 读写业务数据，不在端侧建立关系型数据库。 */
export class JavaApiClient {
  // 可通过构建变量替换；所有业务 API 均从此客户端发出。
  private static readonly baseUrl: string = 'https://a.bbddd.cn';
  private static token: string = '';
  private static readonly timeoutMs: number = 10000;
  private static readonly tokenKey: string = 'ExpressAccessToken';
  private static readonly expressAppKey: string = 'ircuf9CO';
  private static readonly expressAppId: string = '6917614461242904059';

  static setToken(value: string): void { JavaApiClient.token = value; AppStorage.setOrCreate(JavaApiClient.tokenKey, value); }
  static clearToken(): void {
    JavaApiClient.token = '';
    AppStorage.setOrCreate(JavaApiClient.tokenKey, '');
    // 清理基础库 HttpApi 使用的共享 Token，避免退出后地址接口继续带旧凭证。
    AppStorage.setOrCreate('Token', '');
  }
  static hasToken(): boolean { return JavaApiClient.currentToken().length > 0; }
  private static currentToken(): string {
    // 兼容基础库 HttpApi 的登录实现：两套客户端必须共享同一个元服务 Token。
    return JavaApiClient.token || (AppStorage.get<string>(JavaApiClient.tokenKey) || '') ||
      (AppStorage.get<string>('Token') || '');
  }

  static async put<T>(path: string, body: object): Promise<T> {
    return JavaApiClient.request<T>(path, http.RequestMethod.PUT, body);
  }

  static async delete<T>(path: string): Promise<T> {
    return JavaApiClient.request<T>(path, http.RequestMethod.DELETE);
  }

  private static async request<T>(path: string, method: http.RequestMethod, body?: object): Promise<T> {
    const request = http.createHttp();
    try {
      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      JavaApiClient.addExpressHeaders(path, headers);
      const token = JavaApiClient.currentToken();
      if (token) headers['Authorization'] = `Bearer ${token}`;
      const options: http.HttpRequestOptions = { method, header: headers, connectTimeout: JavaApiClient.timeoutMs, readTimeout: JavaApiClient.timeoutMs };
      if (body !== undefined) options.extraData = JSON.stringify(body);
      const response = await request.request(`${JavaApiClient.baseUrl}${path}`, options);
      if (response.responseCode === 401) { JavaApiClient.clearToken(); throw new Error('AUTH_EXPIRED'); }
      if (response.responseCode < 200 || response.responseCode >= 300) throw new Error(`Java API ${response.responseCode}`);
      const payload = JSON.parse(response.result as string) as JavaApiResult<T>;
      if (payload.code !== 0) throw new Error(payload.msg || `Java API business error ${payload.code}`);
      return payload.data as T;
    } finally { request.destroy(); }
  }

  static async get<T>(path: string, token?: string, retries: number = 2): Promise<T> {
    let lastError: Error = new Error('Java API request failed');
    for (let attempt = 0; attempt <= retries; attempt++) {
      const request = http.createHttp();
      try {
        const authToken = token || JavaApiClient.currentToken();
        const headers: Record<string, string> = { 'Content-Type': 'application/json' };
        JavaApiClient.addExpressHeaders(path, headers);
        if (authToken) { headers['Authorization'] = `Bearer ${authToken}`; }
        const response = await request.request(`${JavaApiClient.baseUrl}${path}`, {
          method: http.RequestMethod.GET,
          header: headers,
          connectTimeout: JavaApiClient.timeoutMs,
          readTimeout: JavaApiClient.timeoutMs
        });
        if (response.responseCode === 401) {
          JavaApiClient.clearToken();
          throw new Error('AUTH_EXPIRED');
        }
        if (response.responseCode < 200 || response.responseCode >= 300) {
          throw new Error(`Java API ${response.responseCode}`);
        }
        const payload = JSON.parse(response.result as string) as JavaApiResult<T>;
        if (payload.code !== 0) {
          throw new Error(payload.msg || `Java API business error ${payload.code}`);
        }
        return payload.data as T;
      } catch (error) {
        lastError = error as Error;
        if (lastError.message === 'AUTH_EXPIRED') { break; }
        if (attempt < retries) { await new Promise<void>((resolve) => setTimeout(resolve, 250 * (attempt + 1))); }
      } finally {
        request.destroy();
      }
    }
    throw lastError;
  }

  static async post<T>(path: string, body: object, token?: string, retries: number = 2): Promise<T> {
    let lastError: Error = new Error('Java API request failed');
    for (let attempt = 0; attempt <= retries; attempt++) {
      const request = http.createHttp();
      try {
        const authToken = token || JavaApiClient.currentToken();
        const headers: Record<string, string> = { 'Content-Type': 'application/json' };
        JavaApiClient.addExpressHeaders(path, headers);
        if (authToken) { headers['Authorization'] = `Bearer ${authToken}`; }
        const response = await request.request(`${JavaApiClient.baseUrl}${path}`, {
          method: http.RequestMethod.POST, header: headers, extraData: JSON.stringify(body),
          connectTimeout: JavaApiClient.timeoutMs, readTimeout: JavaApiClient.timeoutMs
        });
        if (response.responseCode === 401) { JavaApiClient.clearToken(); throw new Error('AUTH_EXPIRED'); }
        if (response.responseCode < 200 || response.responseCode >= 300) { throw new Error(`Java API ${response.responseCode}`); }
        const payload = JSON.parse(response.result as string) as JavaApiResult<T>;
        if (payload.code !== 0) {
          throw new Error(payload.msg || `Java API business error ${payload.code}`);
        }
        return payload.data as T;
      } catch (error) {
        lastError = error as Error;
        if (lastError.message === 'AUTH_EXPIRED' || attempt === retries) break;
        await new Promise<void>((resolve) => setTimeout(resolve, 250 * (attempt + 1)));
      } finally { request.destroy(); }
    }
    throw lastError;
  }

  /** 兼容 Java 服务中使用 @RequestParam 接收参数的旧接口。 */
  static async postForm<T>(path: string, body: object, token?: string): Promise<T | undefined> {
    const request = http.createHttp();
    try {
      const authToken = token || JavaApiClient.currentToken();
        const headers: Record<string, string> = { 'Content-Type': 'application/x-www-form-urlencoded' };
      JavaApiClient.addExpressHeaders(path, headers);
      if (authToken) { headers['Authorization'] = `Bearer ${authToken}`; }
      const fields: string[] = [];
      const values = body as Record<string, string>;
      Object.keys(values).forEach((key: string) => {
        fields.push(`${encodeURIComponent(key)}=${encodeURIComponent(values[key])}`);
      });
      const response = await request.request(`${JavaApiClient.baseUrl}${path}`, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: fields.join('&'),
        connectTimeout: JavaApiClient.timeoutMs,
        readTimeout: JavaApiClient.timeoutMs
      });
      if (response.responseCode === 401) { JavaApiClient.clearToken(); throw new Error('AUTH_EXPIRED'); }
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`Java API ${response.responseCode}`);
      }
      const payload = JSON.parse(response.result as string) as JavaApiResult<T>;
      if (payload.code !== 0) { throw new Error(payload.msg || `Java API business error ${payload.code}`); }
      return payload.data;
    } finally {
      request.destroy();
    }
  }

  private static addExpressHeaders(path: string, headers: Record<string, string>): void {
    if (path.indexOf('/tea-drink-orders/v1/app/api/express/') === 0) {
      headers['X-Hm-App-Id'] = JavaApiClient.expressAppId;
    }
  }
}

interface JavaApiResult<T> { code: number; msg?: string; data?: T; }

export interface AtomicCheckInResult {
  success?: boolean;
  points?: number;
  totalPoints?: number;
  continuousDays?: number;
  message?: string;
}

export interface AtomicPointsDetail {
  id?: string;
  type?: string | number;
  points?: number;
  balance?: number;
  title?: string;
  remark?: string;
  createTime?: string;
  goodsId?: string;
}

export interface AtomicMemberAccount {
  memberCardNo?: string;
  memberClassTName?: string;
  memberClassTLevel?: string;
  cumulativePaidAmount?: number;
  currentLevelThreshold?: number;
  nextLevelName?: string;
  nextLevelThreshold?: number;
  amountToNextLevel?: number;
  levelProgress?: number;
  pointBalance?: string;
  pointsDebt?: string;
  expiringPoints?: string;
  nearestExpireAt?: string;
  availableCouponCount?: number;
}

export interface AtomicCouponTemplate {
  couponTemplateId?: number;
  couponName?: string;
  pointsRequired?: number;
  validityDays?: number;
  exchangeable?: boolean;
  unavailableReason?: string;
  description?: string;
  exchangeStartTime?: string;
  exchangeEndTime?: string;
  usageRestriction?: string;
}

export interface AtomicCouponTemplateResponse {
  pointBalance?: string;
  items?: AtomicCouponTemplate[];
  list?: AtomicCouponTemplate[];
}

export interface AtomicTask {
  id?: number;
  title?: string;
  description?: string;
  actionText?: string;
  targetCount?: number;
  currentCount?: number;
  rewardValue?: number;
  isFinished?: boolean;
  isReceived?: boolean;
}

export interface AtomicTaskClaimResult {
  success?: boolean;
  points?: number;
  message?: string;
  account?: AtomicBalance;
}

export class AtomicBalance { balance?: number; }

/** 当前元服务统一使用本地 mock；后续接入 API 时替换各业务服务的实现。 */
export const BENEFITS_FRONTEND_MOCK: boolean = true;

export class BenefitsMock {
  static account(): AtomicMemberAccount {
    const account = new AtomicMemberAccountMock();
    account.memberCardNo = 'DEMO-10001';
    account.memberClassTName = '普通会员';
    account.memberClassTLevel = '0';
    account.pointBalance = '40';
    account.expiringPoints = '0';
    account.availableCouponCount = 3;
    account.nextLevelName = '银卡会员';
    account.amountToNextLevel = 60;
    account.levelProgress = 40;
    return account;
  }
  static coupons(): AtomicCouponTemplate[] {
    const first = new AtomicCouponTemplateMock();
    first.couponTemplateId = 9001; first.couponName = '新人首单立减'; first.pointsRequired = 5; first.exchangeable = true; first.description = '首单可用，不限快递类型';
    const second = new AtomicCouponTemplateMock();
    second.couponTemplateId = 9002; second.couponName = '签到寄件券'; second.pointsRequired = 5; second.exchangeable = true; second.description = '仅限普通快递寄件使用';
    const third = new AtomicCouponTemplateMock();
    third.couponTemplateId = 9003; third.couponName = '深夜寄件福利'; third.pointsRequired = 10; third.exchangeable = true; third.description = '21:00 后下单可用';
    return [first, second, third];
  }

  static pointsDetail(): AtomicPointsDetail[] {
    const first = new AtomicPointsDetailMock();
    first.id = 'points-1'; first.title = '每日签到'; first.points = 10; first.balance = 40; first.createTime = '2026-08-24 09:10';
    const second = new AtomicPointsDetailMock();
    second.id = 'points-2'; second.title = '完成首次寄件'; second.points = 30; second.balance = 30; second.createTime = '2026-08-20 16:35';
    const third = new AtomicPointsDetailMock();
    third.id = 'points-3'; third.title = '兑换签到寄件券'; third.points = -5; third.balance = 0; third.createTime = '2026-08-18 11:20';
    return [first, second, third];
  }

  static tasks(): AtomicTask[] {
    const first = new AtomicTaskMock();
    first.id = 1; first.title = '每日签到'; first.description = '完成今日签到'; first.actionText = '去签到'; first.targetCount = 1; first.currentCount = 0; first.rewardValue = 10; first.isFinished = false; first.isReceived = false;
    const second = new AtomicTaskMock();
    second.id = 2; second.title = '寄件有礼'; second.description = '本月完成 1 次寄件'; second.actionText = '领取'; second.targetCount = 1; second.currentCount = 1; second.rewardValue = 20; second.isFinished = true; second.isReceived = false;
    return [first, second];
  }
}

class AtomicMemberAccountMock implements AtomicMemberAccount {
  memberCardNo?: string; memberClassTName?: string; memberClassTLevel?: string; cumulativePaidAmount?: number;
  currentLevelThreshold?: number; nextLevelName?: string; nextLevelThreshold?: number; amountToNextLevel?: number;
  levelProgress?: number; pointBalance?: string; pointsDebt?: string; expiringPoints?: string; nearestExpireAt?: string; availableCouponCount?: number;
}
class AtomicCouponTemplateMock implements AtomicCouponTemplate {
  couponTemplateId?: number; couponName?: string; pointsRequired?: number; validityDays?: number; exchangeable?: boolean;
  unavailableReason?: string; description?: string; exchangeStartTime?: string; exchangeEndTime?: string; usageRestriction?: string;
}

class AtomicCheckInRequest { userId: number = 0; storeId: number = 0; }
class AtomicCouponExchangeRequest { tenantId: number = 0; userId: number = 0; couponTemplateId: number = 0; requestId: string = ''; }
class AtomicCouponExchangeResponse { success: boolean = true; }
class AtomicRequestIdPayload { requestId: string = ''; }
class AtomicTaskClaimPayload { taskId: number = 0; requestId: string = ''; }
class AtomicCouponExchangePayload { couponTemplateId: number = 0; requestId: string = ''; }
class AtomicPointsDetailMock implements AtomicPointsDetail {
  id?: string; title?: string; points?: number; balance?: number; remark?: string; createTime?: string;
}
class AtomicTaskMock implements AtomicTask {
  id?: number; title?: string; description?: string; actionText?: string; targetCount?: number;
  currentCount?: number; rewardValue?: number; isFinished?: boolean; isReceived?: boolean;
}

export class BenefitsApi {
  static async memberAccount(_tenantId: number, _userId: number): Promise<AtomicMemberAccount> {
    const data = await JavaApiClient.get<Record<string, object>>('/tea-drink-orders/v1/app/api/express/benefits/points/account');
    return { pointBalance: `${data['balance'] || 0}`, memberClassTLevel: `${data['member_level'] || 'NORMAL'}` };
  }

  static async checkIn(_userId: number, _storeId: number): Promise<AtomicCheckInResult> {
    const request = new AtomicRequestIdPayload();
    request.requestId = `${Date.now()}`;
    const result = await JavaApiClient.post<Record<string, object>>('/tea-drink-orders/v1/app/api/express/benefits/check-in', request);
    const account = result['account'] as Record<string, object>;
    return { success: JSON.stringify(result['success']) === 'true', points: Number(result['points'] || 0), totalPoints: Number(account?.['balance'] || 0), message: `${result['message'] || ''}` };
  }

  static async pointsDetail(_userId: number, _storeId: number, _type: number = 0, _page: number = 1): Promise<AtomicPointsDetail[]> {
    const rows = await JavaApiClient.get<Record<string, object>[]>('/tea-drink-orders/v1/app/api/express/benefits/points/ledger');
    return rows.map((row: Record<string, object>) => {
      const item = new AtomicPointsDetailMock();
      item.id = `${row['business_no'] || ''}`;
      item.points = Number(row['change_amount'] || 0);
      item.balance = Number(row['balance_after'] || 0);
      item.title = `${row['business_type'] || '积分变动'}`;
      item.remark = `${row['remark'] || ''}`;
      item.createTime = `${row['created_at'] || ''}`;
      return item;
    });
  }

  static async couponTemplates(_tenantId: number, _userId: number): Promise<AtomicCouponTemplateResponse> {
    return JavaApiClient.get<AtomicCouponTemplateResponse>('/tea-drink-orders/v1/app/api/express/benefits/coupons');
  }

  static async tasks(): Promise<AtomicTask[]> {
    return JavaApiClient.get<AtomicTask[]>('/tea-drink-orders/v1/app/api/express/benefits/tasks');
  }

  static async claimTask(taskId: number, requestId: string): Promise<AtomicTaskClaimResult> {
    const request = new AtomicTaskClaimPayload();
    request.taskId = taskId; request.requestId = requestId;
    return JavaApiClient.post<AtomicTaskClaimResult>('/tea-drink-orders/v1/app/api/express/benefits/tasks/claim', request);
  }

  static async exchangeCoupon(_tenantId: number, _userId: number, _couponTemplateId: number): Promise<AtomicCouponExchangeResponse> {
    const request = new AtomicCouponExchangePayload();
    request.couponTemplateId = _couponTemplateId; request.requestId = `${Date.now()}-${_couponTemplateId}`;
    return JavaApiClient.post<AtomicCouponExchangeResponse>('/tea-drink-orders/v1/app/api/express/benefits/coupons/exchange', request);
  }
}

export interface ExpressAddressInput { name: string; phone: string; province: string; city: string; district: string; detail: string; street?: string; countryCode?: string; longitude?: number; latitude?: number; tag?: string; isDefault?: boolean; }
export interface ExpressParsedAddress { name?: string; phone?: string; province?: string; city?: string; area?: string; district?: string; street?: string; address?: string; addr?: string; detail?: string; lat?: string | number; lng?: string | number; latitude?: string | number; longitude?: string | number; }
export interface ExpressContactAddress {
  name: string; phone: string; province: string; city: string; district: string; address: string;
  street?: string; longitude?: number; latitude?: number;
}
export interface ExpressQuoteInput {
  companyCode?: string; sender: ExpressContactAddress; receiver: ExpressContactAddress;
  weight: number; goodsName: string;
}
export interface ExpressCreateOrderInput {
  clientOrderNo: string; requestId: string; shippingMethod: string; servicePointId?: number; servicePointCode?: string;
  servicePointName?: string; dropOffCode?: string; gridType?: string; companyCode: string; companyName: string;
  sender: object; receiver: object; goodsName: string; weight: number; amount: number; paymentType?: string;
}
export interface ExpressPublicConfig {
  appName?: string;
  merchant_name?: string;
  config?: Record<string, object>;
}
export class ExpressApi {
  static parseAddress(content: string): Promise<ExpressParsedAddress> {
    const request = new ExpressAddressParseRequest(); request.content = content;
    return JavaApiClient.post<ExpressParsedAddress>('/tea-drink-orders/v1/app/api/express/public/address-parse', request);
  }
  static async login(hmAppid: string, authorizationCode: string): Promise<Record<string, string>> {
    const request = new ExpressLoginRequest();
    request.hmAppid = hmAppid;
    request.authorizationCode = authorizationCode;
    const pair = await JavaApiClient.post<Record<string, string>>('/tea-drink-orders/v1/app/api/express/auth/login', request);
    const access = pair['accessToken'] || pair['token']; if (access) JavaApiClient.setToken(access); return pair;
  }
  static async logout(): Promise<void> { await JavaApiClient.post<void>('/tea-drink-orders/v1/app/api/express/auth/logout', new EmptyRequest()); JavaApiClient.clearToken(); }
  static addresses(): Promise<Record<string, object>[]> { return JavaApiClient.get<Record<string, object>[]>('/tea-drink-orders/v1/app/api/express/addresses'); }
  static addAddress(input: ExpressAddressInput): Promise<Record<string, object>> { return JavaApiClient.post<Record<string, object>>('/tea-drink-orders/v1/app/api/express/addresses', input); }
  static updateAddress(id: string, input: ExpressAddressInput): Promise<Record<string, object>> { return JavaApiClient.put<Record<string, object>>(`/tea-drink-orders/v1/app/api/express/addresses/${id}`, input); }
  static deleteAddress(id: string): Promise<void> { return JavaApiClient.delete<void>(`/tea-drink-orders/v1/app/api/express/addresses/${id}`); }
  static setDefaultAddress(id: string): Promise<void> { return JavaApiClient.put<void>(`/tea-drink-orders/v1/app/api/express/addresses/${id}/default`, new EmptyRequest()); }
  static orders(status?: string, pageNo: number = 1, pageSize: number = 20): Promise<Record<string, object>> {
    const query = status ? `?status=${encodeURIComponent(status)}&pageNo=${pageNo}&pageSize=${pageSize}` : `?pageNo=${pageNo}&pageSize=${pageSize}`;
    return JavaApiClient.get<Record<string, object>>(`/tea-drink-orders/v1/app/api/express/orders${query}`);
  }
  static order(orderNo: string): Promise<Record<string, object>> { return JavaApiClient.get<Record<string, object>>(`/tea-drink-orders/v1/app/api/express/orders/${encodeURIComponent(orderNo)}`); }
  static cancel(orderNo: string, reason: string = '用户取消'): Promise<void> {
    const request = new ExpressCancelRequest();
    request.reason = reason;
    request.requestId = `${Date.now()}`;
    return JavaApiClient.post<void>(`/tea-drink-orders/v1/app/api/express/orders/${encodeURIComponent(orderNo)}/cancel`, request);
  }
  static traces(orderNo: string): Promise<Record<string, object>[]> { return JavaApiClient.get<Record<string, object>[]>(`/tea-drink-orders/v1/app/api/express/logistics/${encodeURIComponent(orderNo)}/traces`); }
  static refreshTraces(orderNo: string): Promise<Record<string, object>[]> { return JavaApiClient.post<Record<string, object>[]>(`/tea-drink-orders/v1/app/api/express/logistics/${encodeURIComponent(orderNo)}/refresh`, new EmptyRequest()); }
  static createOrder(input: ExpressCreateOrderInput): Promise<Record<string, object>> { return JavaApiClient.post<Record<string, object>>('/tea-drink-orders/v1/app/api/express/orders', input); }
  static quotes(input: ExpressQuoteInput): Promise<Record<string, object>[]> { return JavaApiClient.post<Record<string, object>[]>('/tea-drink-orders/v1/app/api/express/quotes', input); }
  static carriers(): Promise<Record<string, object>[]> { return JavaApiClient.get<Record<string, object>[]>('/tea-drink-orders/v1/app/api/express/public/carriers'); }
  static servicePoints(type?: string): Promise<Record<string, object>[]> { return JavaApiClient.get<Record<string, object>[]>(`/tea-drink-orders/v1/app/api/express/public/service-points${type ? `?type=${encodeURIComponent(type)}` : ''}`); }
  static publicConfig(): Promise<Record<string, object>> { return JavaApiClient.get<Record<string, object>>('/tea-drink-orders/v1/app/api/express/public/config'); }
}

export interface AtomicOrder {
  id: string;
  carrier: string;
  trackingNo: string;
  from: string;
  to: string;
  sender: string;
  receiver: string;
  status: string;
  eta: string;
  createdAt: string;
  amount: number;
  supplementAmount?: number;
  verifiedWeight?: number;
  overweight?: number;
  senderLatitude?: number;
  senderLongitude?: number;
  receiverLatitude?: number;
  receiverLongitude?: number;
}

export interface AtomicOrderDetail extends AtomicOrder {
  senderPhone?: string;
  receiverPhone?: string;
  weight?: number;
  remark?: string;
  paidAt?: string;
  pickedAt?: string;
  completedAt?: string;
  discount?: number;
  paymentMethod?: string;
  pickupMethod?: string;
  goodsName?: string;
  orderedWeight?: number;
}

export interface AtomicLogisticsNode {
  time: string;
  description: string;
  location?: string;
  completed?: boolean;
  operatorName?: string;
  operatorPhone?: string;
}

export interface AtomicOrderDetailResponse {
  order?: AtomicOrderDetail;
  detail?: AtomicOrderDetail;
  logistics?: AtomicLogisticsNode[];
  logs?: AtomicLogisticsNode[];
}

export class AtomicOrderActionRequest {
  reason?: string = '';
}

export class OrdersMockApi {
  static async list(status?: string): Promise<AtomicOrder[]> {
    const page = await ExpressApi.orders(status, 1, 50);
    const rows = (page['list'] || page['records'] || []) as Record<string, object>[];
    return rows.map((row) => OrdersMockApi.mapOrder(row));
  }
  static async detail(item: AtomicOrder): Promise<AtomicOrderDetailResponse> {
    // 物流查询接口使用元服务内部订单号，不使用运单号替代。
    const orderNo = item.id;
    if (!orderNo) { throw new Error('MISSING_INTERNAL_ORDER_NO'); }
    console.info('OrdersMockApi', `detail request internalOrderNo=${orderNo}, waybillNo=${item.trackingNo || ''}`);
    const payload = await ExpressApi.order(orderNo);
    const row = (payload['order'] || payload) as Record<string, object>;
    let traces: Record<string, object>[] = [];
    // 详情页始终先向上游查询，确保展示最新物流；上游暂不可用时回退本地缓存。
    try {
      traces = await ExpressApi.refreshTraces(orderNo);
      console.info('OrdersMockApi', `refresh traces success internalOrderNo=${orderNo}, count=${traces.length}`);
    } catch (_refreshError) {
      traces = (payload['traces'] || payload['logs'] || []) as Record<string, object>[];
      if (traces.length === 0) {
        try { traces = await ExpressApi.traces(orderNo); console.info('OrdersMockApi', `trace query success internalOrderNo=${orderNo}, count=${traces.length}`); } catch (_traceError) { traces = []; console.error('OrdersMockApi', `trace query failed internalOrderNo=${orderNo}`); }
      }
    }
    console.info('OrdersMockApi', `logistics resolved internalOrderNo=${orderNo}, count=${traces.length}`);
    const order = OrdersMockApi.mapOrder(row) as AtomicOrderDetail;
    order.createdAt = `${row['created_at'] || row['createdAt'] || ''}`;
    order.pickedAt = `${row['picked_at'] || row['pickedAt'] || row['pickup_start_at'] || ''}`;
    order.completedAt = `${row['completed_at'] || row['completedAt'] || ''}`;
    order.goodsName = `${row['goods_name'] || row['goodsName'] || ''}`;
    order.weight = Number(row['weight'] || 0);
    order.orderedWeight = Number(row['ordered_weight'] || row['orderedWeight'] || row['weight'] || 0);
    order.verifiedWeight = Number(row['verified_weight'] || row['verifiedWeight'] || 0);
    order.supplementAmount = Number(row['supplement_amount'] || row['supplementAmount'] || 0);
    order.overweight = Number(row['overweight'] || row['over_weight'] || Math.max(0, (order.verifiedWeight || 0) - (order.orderedWeight || 0)));
    order.remark = `${row['remark'] || ''}`;
    return { order: order, logistics: traces.map((t) => OrdersMockApi.mapTrace(t)) };
  }

  static async action(item: AtomicOrder, action: string): Promise<boolean> {
    if (action === 'cancel') {
      try { await ExpressApi.cancel(item.id || item.trackingNo); item.status = '已取消'; return true; } catch (_) { }
    }
    item.status = action === 'confirm' ? '已签收' : action === 'pay' ? '待取件' : '已取消';
    return true;
  }

  private static mapOrder(row: Record<string, object>): AtomicOrderDetail {
    const statusCode = `${row['order_status'] || row['status'] || ''}`;
    const paymentStatus = `${row['payment_status'] || row['paymentStatus'] || ''}`;
    const statusMap: Map<string, string> = new Map([
      ['CREATED', '待支付'], ['PENDING_PAYMENT', '待支付'], ['PAID', '待取件'],
      ['PICKED_UP', '运输中'], ['IN_TRANSIT', '运输中'], ['DELIVERED', '已签收'],
      ['COMPLETED', '已签收'], ['CANCELLED', '已取消'], ['INVALID', '下单异常']
    ]);
    const sender = OrdersMockApi.addressObject(row['sender'] || row['sender_json']);
    const receiver = OrdersMockApi.addressObject(row['receiver'] || row['receiver_json']);
    return {
      id: `${row['order_no'] || row['id'] || ''}`,
      carrier: `${row['company_name'] || row['carrier'] || ''}`,
      trackingNo: `${row['waybill_no'] || row['tracking_no'] || row['order_no'] || ''}`,
      from: `${row['sender_city'] || sender['city'] || row['from'] || ''}`,
      to: `${row['receiver_city'] || receiver['city'] || row['to'] || ''}`,
      sender: `${row['sender_name'] || sender['name'] || row['sender'] || ''}`,
      receiver: `${row['receiver_name'] || receiver['name'] || row['receiver'] || ''}`,
      status: paymentStatus === 'PENDING_SUPPLEMENT' && ['PICKED_UP', 'IN_TRANSIT'].includes(statusCode) ? '运输中（待补缴）' : statusMap.get(statusCode) || statusCode || '待支付',
      eta: `${row['pickup_start_at'] || row['eta'] || ''}`,
      createdAt: `${row['created_at'] || row['createdAt'] || ''}`,
      amount: Number(row['amount'] || 0),
      supplementAmount: Number(row['supplement_amount'] || row['supplementAmount'] || 0),
      verifiedWeight: Number(row['verified_weight'] || row['verifiedWeight'] || 0),
      overweight: Number(row['overweight'] || row['over_weight'] || Math.max(0, Number(row['verified_weight'] || row['verifiedWeight'] || 0) - Number(row['ordered_weight'] || row['orderedWeight'] || row['weight'] || 0))),
      senderLatitude: Number(row['sender_latitude'] || sender['latitude'] || 0),
      senderLongitude: Number(row['sender_longitude'] || sender['longitude'] || 0),
      receiverLatitude: Number(row['receiver_latitude'] || receiver['latitude'] || 0),
      receiverLongitude: Number(row['receiver_longitude'] || receiver['longitude'] || 0),
    };
  }

  private static addressObject(value: object | undefined): Record<string, object> {
    if (!value) { return {}; }
    if (typeof value === 'string') {
      try { return JSON.parse(value) as Record<string, object>; } catch (_error) { return {}; }
    }
    return value as Record<string, object>;
  }

  private static mapTrace(trace: Record<string, object>): AtomicLogisticsNode {
    return {
      time: `${trace['occurred_at'] || trace['occurredAt'] || ''}`,
      description: `${trace['description'] || trace['status'] || ''}`,
      location: `${trace['location'] || ''}`,
      completed: true,
      operatorName: `${trace['operator_name'] || trace['operatorName'] || ''}`,
      operatorPhone: `${trace['operator_phone'] || trace['operatorPhone'] || ''}`,
    };
  }

}
