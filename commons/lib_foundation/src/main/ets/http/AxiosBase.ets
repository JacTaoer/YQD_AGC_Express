import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios';
import { AppStorageMap, CurAppInfo } from '../common/Constant';
import { Logger } from '../utils/Logger';

export const axiosInstance = axios.create({
  baseURL: CurAppInfo.BASE_URL,
  timeout: 3000,
});

// Add a request interceptor.
axiosInstance.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const url = config.url || '';
  if (url.includes('/tea-drink-orders/v1/app/api/express/')) {
    config.headers.set('X-Hm-App-Id', '6917614461242904059');
    const expressToken = AppStorage.get<string>(AppStorageMap.TOKEN) ?? '';
    if (expressToken) config.headers.set('Authorization', `Bearer ${expressToken}`);
  }
  if (!config.url?.includes('loginWithHuaweiID')) {
    config.headers.set('Token', AppStorage.get(AppStorageMap.TOKEN));
  }
  return config;
}, (error: AxiosError) => {
  return Promise.reject(error);
});

axiosInstance.interceptors.response.use(
  (response: AxiosResponse) => {
    if (response.status === 200) {
      return Promise.resolve(response.data);
    } else {
      Logger.error('[Network]', `https request failed：${response.config.url}. error: ${response.status}`);
      return Promise.reject(response);
    }
  },
  (error: BusinessError) => {
    Logger.error('[Network]', `https request failed：. error: ${JSON.stringify(error)}`);
    return Promise.reject(error);
  },
);

export default axiosInstance;
