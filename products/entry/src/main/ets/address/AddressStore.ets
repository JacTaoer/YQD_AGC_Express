import { AtomicAddress } from './AddressTypes';
import { ExpressApi, ExpressAddressInput } from '../data/JavaApiClient';
import { JavaApiClient } from '../data/JavaApiClient';

interface JavaAddressDTO {
  id?: string | number;
  name?: string;
  phone?: string;
  province?: string;
  city?: string;
  district?: string;
  street?: string;
  detail?: string;
  countryCode?: string;
  isDefault?: boolean;
  tag?: string | number;
  addressPre?: string;
  addressNum?: string;
  tel?: string;
  latitude?: number;
  longitude?: number;
}

class JavaAddressForm {
  userId: string = '';
  storeId: string = '';
  id: string = '';
  addressPre: string = '';
  addressNum: string = '';
  name: string = '';
  tel: string = '';
  tag: string = '1';
  latitude: string = '0';
  longitude: string = '0';
}

class JavaAddressIdForm { id: string = ''; }
class JavaAddressDefaultForm { userId: string = ''; storeId: string = ''; id: string = ''; }

export class AddressStore {
  private static instance: AddressStore = new AddressStore();
  private records: AtomicAddress[] = [
    { id: '1001', userId: 'demo-user', contactName: '张三', phone: '13800138000', countryCode: 'CN', countryName: '中国', provinceCode: '310000', provinceName: '上海市', cityCode: '310100', cityName: '上海市', districtCode: '310115', districtName: '浦东新区', street: '世纪大道', detailAddress: '100号', longitude: 121.47, latitude: 31.23, label: '家庭', isDefault: true, isDeliverable: true },
    { id: '1002', userId: 'demo-user', contactName: '李四', phone: '13900139000', countryCode: 'CN', countryName: '中国', provinceCode: '320000', provinceName: '江苏省', cityCode: '320100', cityName: '南京市', districtCode: '320106', districtName: '鼓楼区', street: '中山路', detailAddress: '20号', longitude: 118.78, latitude: 32.06, label: '公司', isDefault: false, isDeliverable: true }
  ];
  private userId: number = 0;
  private storeId: number = 0;
  private demoMode: boolean = true;
  static get shared(): AddressStore { return AddressStore.instance; }
  configure(userId: number, storeId: number): void {
    this.userId = userId;
    this.storeId = storeId;
    // Unauthenticated users retain the existing local preview; logged-in users always use Java.
    this.demoMode = !JavaApiClient.hasToken();
  }
  isDemoMode(): boolean { return this.demoMode; }
  async list(): Promise<AtomicAddress[]> {
    if (!this.demoMode) {
      const remote = await ExpressApi.addresses();
      return (remote || []).map((item: Record<string, object>) => this.fromJava(item as JavaAddressDTO));
    }
    return this.records.map((item) => this.clone(item));
  }
  async save(input: AtomicAddress): Promise<AtomicAddress> {
    if (!this.demoMode) {
      const payload: ExpressAddressInput = this.toJava(input);
      const remote = input.id
        ? await ExpressApi.updateAddress(input.id, payload)
        : await ExpressApi.addAddress(payload);
      return this.fromJava(remote as JavaAddressDTO);
    }
    const item: AtomicAddress = this.clone(input); item.id = input.id || `${Date.now()}`;
    if (item.isDefault) this.records = this.records.map((old) => { const copy = this.clone(old); copy.isDefault = false; return copy; });
    const index = this.records.findIndex((old) => old.id === item.id);
    if (index >= 0) this.records[index] = item; else this.records.push(item);
    return this.clone(item);
  }
  async remove(id: string): Promise<boolean> {
    if (!this.demoMode) { await ExpressApi.deleteAddress(id); return true; }
    const target = this.records.find((item) => item.id === id);
    this.records = this.records.filter((item) => item.id !== id);
    if (target?.isDefault && this.records.length > 0) this.records[0].isDefault = true;
    return true;
  }
  async setDefault(id: string): Promise<boolean> {
    if (!this.demoMode) { await ExpressApi.setDefaultAddress(id); return true; }
    this.records = this.records.map((item) => { const copy = this.clone(item); copy.isDefault = item.id === id; return copy; });
    return true;
  }
  private tagName(tag?: string | number): string {
    if (typeof tag === 'string') return tag;
    return tag === 2 ? '家庭' : tag === 3 ? '公司' : tag === 4 ? '学校' : '';
  }
  private fromJava(item: JavaAddressDTO): AtomicAddress {
    const province = item.province || item.addressPre || '';
    const detail = item.detail || item.addressNum || '';
    return {
      id: item.id === undefined ? '' : `${item.id}`, userId: `${this.userId}`, contactName: item.name || '', phone: item.phone || item.tel || '',
      countryCode: item.countryCode || 'CN', countryName: '中国', provinceCode: '', provinceName: province,
      cityCode: '', cityName: item.city || '', districtCode: '', districtName: item.district || '', street: item.street || '', detailAddress: detail,
      longitude: item.longitude || 0, latitude: item.latitude || 0, label: this.tagName(item.tag),
      isDefault: item.isDefault === true, isDeliverable: true
    };
  }
  private toJava(item: AtomicAddress): ExpressAddressInput {
    return {
      name: item.contactName, phone: item.phone, countryCode: item.countryCode || 'CN',
      province: item.provinceName, city: item.cityName, district: item.districtName,
      street: item.street, detail: item.detailAddress, longitude: item.longitude, latitude: item.latitude,
      tag: item.label || undefined, isDefault: item.isDefault
    };
  }
  private clone(item: AtomicAddress): AtomicAddress { return { id: item.id, userId: item.userId, contactName: item.contactName, phone: item.phone, countryCode: item.countryCode, countryName: item.countryName, provinceCode: item.provinceCode, provinceName: item.provinceName, cityCode: item.cityCode, cityName: item.cityName, districtCode: item.districtCode, districtName: item.districtName, street: item.street, detailAddress: item.detailAddress, longitude: item.longitude, latitude: item.latitude, label: item.label, isDefault: item.isDefault, isDeliverable: item.isDeliverable }; }
}
