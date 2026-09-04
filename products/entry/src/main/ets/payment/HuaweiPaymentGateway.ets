/** 华为支付适配边界。真实下单参数和服务端签名由 Java API 提供。 */
export interface HuaweiPaymentOrder {
  orderId: string;
  amount: number;
  currency: string;
  sign: string;
}

export interface HuaweiPaymentGateway {
  pay(order: HuaweiPaymentOrder): Promise<boolean>;
}

export class ServerHuaweiPaymentGateway implements HuaweiPaymentGateway {
  async pay(_order: HuaweiPaymentOrder): Promise<boolean> {
    // TODO: 接入 Huawei IAP/华为支付 Kit，并调用 Java API 完成服务端验签。
    throw new Error('Huawei payment is not configured: provide Java API and AGC IAP credentials');
  }
}
