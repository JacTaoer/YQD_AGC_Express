export interface AtomicAddress {
  id: string;
  userId: string;
  contactName: string;
  phone: string;
  countryCode: string;
  countryName: string;
  provinceCode: string;
  provinceName: string;
  cityCode: string;
  cityName: string;
  districtCode: string;
  districtName: string;
  street: string;
  detailAddress: string;
  longitude: number;
  latitude: number;
  label: string;
  isDefault: boolean;
  isDeliverable: boolean;
}

export function addressSummary(item: AtomicAddress): string {
  return `${item.provinceName}${item.cityName}${item.districtName}${item.street}${item.detailAddress}`;
}

export function maskedPhone(phone: string): string {
  if (phone.length < 7) return phone;
  return `${phone.slice(0, 3)}****${phone.slice(phone.length - 4)}`;
}

export function emptyAddress(): AtomicAddress {
  return {
    id: '', userId: 'demo-user', contactName: '', phone: '', countryCode: 'CN', countryName: '中国',
    provinceCode: '', provinceName: '', cityCode: '', cityName: '', districtCode: '', districtName: '',
    street: '', detailAddress: '', longitude: 0, latitude: 0, label: '', isDefault: false, isDeliverable: true
  };
}

export function copyAddress(item: AtomicAddress): AtomicAddress {
  return { id: item.id, userId: item.userId, contactName: item.contactName, phone: item.phone,
    countryCode: item.countryCode, countryName: item.countryName, provinceCode: item.provinceCode,
    provinceName: item.provinceName, cityCode: item.cityCode, cityName: item.cityName,
    districtCode: item.districtCode, districtName: item.districtName, street: item.street,
    detailAddress: item.detailAddress, longitude: item.longitude, latitude: item.latitude,
    label: item.label, isDefault: item.isDefault, isDeliverable: item.isDeliverable };
}
