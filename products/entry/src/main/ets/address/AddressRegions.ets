import { JavaApiClient } from '../data/JavaApiClient';

export class RegionNode {
  id: number = 0;
  networkCode: string = '';
  unionCode: string = '';
  regionName: string = '';
  areaName: string = '';
  children: RegionNode[] = [];

  displayName(): string { return this.areaName.length > 0 ? this.areaName : this.regionName; }
  code(): string { return this.unionCode.length > 0 ? this.unionCode : this.networkCode; }
}

export class AddressRegionStore {
  private static cached: RegionNode[] = [];

  static async tree(): Promise<RegionNode[]> {
    if (AddressRegionStore.cached.length > 0) return AddressRegionStore.cached;
    try {
      const remote = await JavaApiClient.get<RegionNode[]>('/tea-drink-orders/v1/app/api/open/region-codes');
      AddressRegionStore.cached = AddressRegionStore.normalize(remote);
    } catch (_error) {
      AddressRegionStore.cached = AddressRegionStore.fallback();
    }
    return AddressRegionStore.cached;
  }

  private static normalize(nodes: RegionNode[]): RegionNode[] {
    return (nodes || []).map((source: RegionNode) => {
      const node = new RegionNode();
      node.id = source.id || 0; node.networkCode = source.networkCode || '';
      node.unionCode = source.unionCode || ''; node.regionName = source.regionName || '';
      node.areaName = source.areaName || ''; node.children = AddressRegionStore.normalize(source.children || []);
      return node;
    });
  }

  private static make(id: number, code: string, name: string, children: RegionNode[] = []): RegionNode {
    const node = new RegionNode(); node.id = id; node.unionCode = code; node.areaName = name; node.children = children; return node;
  }

  private static fallback(): RegionNode[] {
    const shanghai = AddressRegionStore.make(1, '310000', '上海市', [
      AddressRegionStore.make(2, '310100', '上海市', [AddressRegionStore.make(3, '310115', '浦东新区')]),
      AddressRegionStore.make(4, '310100', '上海市', [AddressRegionStore.make(5, '310106', '静安区')])
    ]);
    const jiangsu = AddressRegionStore.make(6, '320000', '江苏省', [
      AddressRegionStore.make(7, '320100', '南京市', [AddressRegionStore.make(8, '320106', '鼓楼区'), AddressRegionStore.make(9, '320102', '玄武区')]),
      AddressRegionStore.make(10, '320500', '苏州市', [AddressRegionStore.make(11, '320508', '姑苏区')])
    ]);
    return [shanghai, jiangsu];
  }
}
