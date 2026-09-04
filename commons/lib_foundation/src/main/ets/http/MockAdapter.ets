import AxiosMockAdapter from '@hw-agconnect/axios-mock-adapter';
import { MockApi } from './MockApi';
import { axiosInstance } from './AxiosBase';

// 创建mock拦截器
const mockAdapter = new AxiosMockAdapter(axiosInstance, { onNoMatch: 'passthrough' });

// 全局配置，是否启用mock，当前默认启用
const enableMock: boolean = true;

if (enableMock) {
  const mockApi = new MockApi();
  mockApi.start(mockAdapter);
}
