import { AtomicAddress, emptyAddress, copyAddress } from './AddressTypes';
import { AddressStore } from './AddressStore';
import { AddressRegionStore, RegionNode } from './AddressRegions';
import { ExpressApi, ExpressParsedAddress } from '../data/JavaApiClient';

@ComponentV2
export struct AddressForm {
  @Param initial: AtomicAddress = emptyAddress();
  @Param editing: boolean = false;
  @Event onSaved: (item: AtomicAddress) => void = () => {};
  @Event onCancel: () => void = () => {};
  @Local form: AtomicAddress = emptyAddress();
  @Local saving: boolean = false;
  @Local error: string = '';
  @Local recognizeText: string = '';
  @Local showRegion: boolean = false;
  @Local capabilityNotice: string = '';
  @Local discardConfirm: boolean = false;
  @Local regionLoading: boolean = false;
  @Local regionNodes: RegionNode[] = [];
  @Local regionRoot: RegionNode[] = [];
  @Local regionPath: RegionNode[] = [];
  @Local regionError: string = '';
  @Local recognizing: boolean = false;

  aboutToAppear(): void { this.form = copyAddress(this.initial); }
  private validate(): boolean {
    if (this.form.contactName.length < 1 || this.form.contactName.length > 20) { this.error = '请输入1-20个字符的联系人姓名'; return false; }
    if (!/^1\d{10}$/.test(this.form.phone)) { this.error = '手机号码不正确'; return false; }
    if (this.form.provinceName.length === 0 || this.form.cityName.length === 0 || this.form.districtName.length === 0) { this.error = '请选择所在地区'; return false; }
    if (this.form.detailAddress.length < 2 || this.form.detailAddress.length > 50) { this.error = '请输入2-50个字符的详细地址'; return false; }
    this.error = ''; return true;
  }
  private async parseText(): Promise<void> {
    if (this.recognizing || !this.recognizeText.trim()) return;
    this.recognizing = true;
    this.parseTextLocally();
    try {
      const result: ExpressParsedAddress = await ExpressApi.parseAddress(this.recognizeText.trim());
      const updated = copyAddress(this.form);
      const remotePhone = (result.phone || '').match(/1\d{10}/)?.[0] || '';
      const remoteDetail = result.detail || result.address || result.addr || '';
      if (result.name) updated.contactName = result.name;
      if (remotePhone) updated.phone = remotePhone;
      if (result.province) updated.provinceName = result.province;
      if (result.city) updated.cityName = result.city;
      if (result.district || result.area) updated.districtName = result.district || result.area || '';
      if (updated.provinceName === '北京市' || updated.provinceName === '上海市' || updated.provinceName === '天津市' || updated.provinceName === '重庆市') {
        updated.cityName = updated.provinceName;
      }
      if (result.street) updated.street = result.street;
      if (remoteDetail) updated.detailAddress = remoteDetail;
      const latitude = Number(result.latitude ?? result.lat); const longitude = Number(result.longitude ?? result.lng);
      if (Number.isFinite(latitude)) updated.latitude = latitude;
      if (Number.isFinite(longitude)) updated.longitude = longitude;
      this.form = updated;
      this.error = '已识别内容，请核对后保存';
    } catch (_error) {
      this.parseTextLocally();
    } finally { this.recognizing = false; }
  }
  private parseTextLocally(): void {
    const source = this.recognizeText.replace(/\r/g, '');
    const phoneMatch = source.match(/1\d{10}(?:-\d{1,8})?/);
    const phone = phoneMatch ? phoneMatch[0].match(/1\d{10}/)?.[0] || '' : '';
    const name = source.match(/(?:收货人|联系人|姓名)\s*[：:]?\s*([\u4e00-\u9fa5]{2,20})/)?.[1] ||
      source.trim().match(/^[\u4e00-\u9fa5]{2,4}/)?.[0] || '';
    const areaLine = source.match(/(?:所在地区|地址)\s*[：:]?\s*([^\n]+)/)?.[1] || source;
    const province = areaLine.match(/(四川省|云南省|贵州省|广东省|浙江省|江苏省|湖北省|湖南省|河北省|河南省|山东省|安徽省|江西省|福建省|陕西省|山西省|辽宁省|吉林省|黑龙江省|甘肃省|青海省|海南省|台湾省|北京市|上海市|天津市|重庆市)/)?.[1] || '';
    const city = areaLine.match(/(北京市|上海市|天津市|重庆市|成都市|广州市|深圳市|杭州市|南京市|武汉市|长沙市|郑州市|西安市|昆明市|贵阳市)/)?.[1] || '';
    const district = areaLine.match(/[\u4e00-\u9fa5]{2,8}(?:区|县)/)?.[0] || '';
    const updated = copyAddress(this.form);
    if (phone) updated.phone = phone;
    if (name) updated.contactName = name;
    if (province) updated.provinceName = province;
    if (city) updated.cityName = city;
    if (province === '北京市' || province === '上海市' || province === '天津市' || province === '重庆市') updated.cityName = province;
    if (district) updated.districtName = district;
    const detailLine = source.match(/详细地址\s*[：:]?\s*([^\n]+)/)?.[1] || '';
    const detail = detailLine || source.replace(phoneMatch?.[0] || phone, '').replace(name, '').replace(province, '').replace(city, '').replace(district, '').replace(/[,，]/g, ' ').replace(/\s+/g, ' ').trim();
    if (detail) updated.detailAddress = detail;
    this.form = updated;
    this.error = phone || name || detail ? '已识别内容，请核对后保存' : '暂未识别出有效地址，请手动填写';
  }
  private async save(): Promise<void> {
    if (this.saving || !this.validate()) return;
    this.saving = true;
    try { const saved = await AddressStore.shared.save(this.form); this.onSaved(saved); }
    catch (_error) { this.error = '保存失败，请检查网络后重试'; }
    finally { this.saving = false; }
  }
  private changed(): boolean {
    return this.form.contactName !== this.initial.contactName || this.form.phone !== this.initial.phone ||
      this.form.provinceName !== this.initial.provinceName || this.form.cityName !== this.initial.cityName ||
      this.form.districtName !== this.initial.districtName || this.form.detailAddress !== this.initial.detailAddress ||
      this.form.label !== this.initial.label || this.form.isDefault !== this.initial.isDefault;
  }
  private close(): void { if (this.changed()) this.discardConfirm = true; else this.onCancel(); }
  private async openRegion(): Promise<void> {
    this.showRegion = true; this.regionLoading = true; this.regionError = '';
    this.regionPath = [];
    try { this.regionRoot = await AddressRegionStore.tree(); this.regionNodes = this.regionRoot; }
    catch (_error) { this.regionError = '地区加载失败，请重试'; }
    finally { this.regionLoading = false; }
  }
  private chooseRegion(node: RegionNode): void {
    if (node.children.length > 0) { this.regionPath = [...this.regionPath, node]; this.regionNodes = node.children; return; }
    if (this.regionPath.length === 0) { this.regionError = '请选择省份'; return; }
    if (this.regionPath.length < 2 && this.regionPath[0].displayName().endsWith('市')) {
      const municipality = this.regionPath[0];
      const updated = copyAddress(this.form);
      updated.provinceName = municipality.displayName(); updated.provinceCode = municipality.code();
      updated.cityName = municipality.displayName(); updated.cityCode = municipality.code();
      updated.districtName = node.displayName(); updated.districtCode = node.code();
      updated.street = ''; this.form = updated; this.showRegion = false; this.regionPath = []; return;
    }
    if (this.regionPath.length < 2) { this.regionError = '请选择到区/县'; return; }
    const province = this.regionPath[0]; const city = this.regionPath[1];
    const updated = copyAddress(this.form);
    updated.provinceName = province.displayName(); updated.provinceCode = province.code();
    updated.cityName = city.displayName(); updated.cityCode = city.code();
    updated.districtName = node.displayName(); updated.districtCode = node.code();
    updated.street = ''; this.form = updated; this.showRegion = false; this.regionPath = [];
  }
  private regionBack(): void {
    if (this.regionPath.length === 0) { this.showRegion = false; return; }
    const path = this.regionPath.slice(0, this.regionPath.length - 1);
    this.regionPath = path;
    this.regionNodes = path.length === 0 ? this.regionRoot : path[path.length - 1].children;
  }
  build() {
    Stack() {
      Column() {
      Row() { Button() { Image($r('app.media.chevron_backward')).width(22).height(22); }.width(40).height(40).backgroundColor('#EEF0F2').borderRadius(20).onClick(() => this.close()); Text(this.editing ? '编辑地址' : '添加地址').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 10 }); }
        .width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center).backgroundColor(Color.White);
      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 0 }) {
          Column({ space: 8 }) {
            TextArea({ placeholder: '粘贴文本到此处，将自动识别地址信息', text: this.recognizeText }).width('100%').height(96).backgroundColor(Color.Transparent).maxLines(5).onChange((value: string) => this.recognizeText = value);
            Row() { Blank(); Button(this.recognizing ? '识别中' : (this.recognizeText.length > 0 ? '识别' : '粘贴')).width(72).height(30).backgroundColor('#0A59F7').fontColor(Color.White).enabled(!this.recognizing).onClick(() => this.parseText()); }.width('100%');
            if (this.error.length > 0) Text(this.error).fontSize(12).fontColor(this.error.startsWith('已识别') ? '#0A59F7' : '#C44747');
          }.width('calc(100% - 24vp)').padding(12).margin({ left: 12, right: 12, bottom: 8 }).backgroundColor('#F4F4F4').borderRadius(16);
          this.input('联系人姓名', this.form.contactName, 'name');
          this.input('手机号码', this.form.phone, 'phone');
          Row() { Text('选择地区').fontSize(15).width(92); Text(this.form.provinceName.length > 0 ? `${this.form.provinceName} ${this.form.cityName} ${this.form.districtName}` : '省、市、区').fontSize(14).fontColor('#576275').layoutWeight(1); Image($r('app.media.ic_arrow_right')).width(20).height(20); }.width('100%').padding(14).onClick(() => this.openRegion());
          if (this.capabilityNotice.length > 0) Text(this.capabilityNotice).fontSize(12).fontColor('#7A8699').width('100%')
          this.input('详细地址', this.form.detailAddress, 'detail');
          }.width('100%').padding({ top: 12, bottom: 12 }).backgroundColor(Color.White).borderRadius(16)
          Row() { Text('设为默认地址').fontSize(15).layoutWeight(1); Toggle({ type: ToggleType.Switch, isOn: this.form.isDefault }).onChange((value: boolean) => this.form.isDefault = value); }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(12);
          Button(this.saving ? '保存中' : '保存').width('100%').height(44).backgroundColor('#0A59F7').fontColor(Color.White).enabled(!this.saving).onClick(() => this.save());
          Button('从华为账号导入').width('100%').height(44).backgroundColor('#E7E9EC').fontColor('#0A59F7').onClick(() => this.capabilityNotice = '当前环境未配置 Account Kit，暂不能导入');
        }.width('100%').justifyContent(FlexAlign.Start).padding(16);
      }.layoutWeight(1).align(Alignment.TopStart).scrollBar(BarState.Off);
      }.width('100%').height('100%').backgroundColor('#F4F6F8');
      if (this.showRegion) this.regionPicker();
      if (this.discardConfirm) this.discardDialog();
    }.width('100%').height('100%');
  }
  @Builder input(label: string, _value: string, key: string) { Row() { Text(label === '联系人姓名' ? '姓名' : label).fontSize(15).width(92); TextInput({ text: key === 'name' ? this.form.contactName : key === 'phone' ? this.form.phone : this.form.detailAddress, placeholder: key === 'detail' ? '街道、门牌号、小区楼栋号等' : key === 'phone' ? '请输入11位手机号码' : '请输入' }).layoutWeight(1).height(48).backgroundColor(Color.Transparent).onChange((next: string) => { if (key === 'name') this.form.contactName = next; else if (key === 'phone') this.form.phone = next; else this.form.detailAddress = next; }); }.width('100%').padding({ left: 14, right: 14 }); }
  @Builder tag(value: string) { Text(value).fontSize(13).fontColor(this.form.label === value ? Color.White : '#576275').backgroundColor(this.form.label === value ? '#0A59F7' : '#F4F6F8').borderRadius(14).padding({ left: 12, right: 12, top: 6, bottom: 6 }).margin({ right: 8 }).onClick(() => this.form.label = value); }
  @Builder regionPicker() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#66000000').onClick(() => this.showRegion = false);
      Column({ space: 12 }) {
        Row() { Image($r('app.media.chevron_backward')).width(20).height(20).onClick(() => this.regionBack()); Text(this.regionPath.length === 0 ? '选择省份' : this.regionPath.length === 1 ? '选择城市' : '选择区县').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center); Text(`${this.regionPath.length}/3`).fontSize(13).fontColor('#7A8699'); }.width('100%').height(36);
        if (this.regionLoading) { LoadingProgress().width(36).height(36).alignSelf(ItemAlign.Center); }
        else if (this.regionError.length > 0) { Text(this.regionError).fontSize(14).fontColor('#C44747').width('100%').textAlign(TextAlign.Center); Button('重试').height(36).backgroundColor('#0A59F7').fontColor(Color.White).alignSelf(ItemAlign.Center).onClick(() => this.openRegion()); }
        else { Scroll() { Column() { ForEach(this.regionNodes, (node: RegionNode) => { this.regionOption(node); }, (node: RegionNode) => `${node.code()}-${node.displayName()}`); }.width('100%'); }.height(260).scrollBar(BarState.Off); }
        Text('取消').fontSize(15).fontColor('#576275').width('100%').height(40).textAlign(TextAlign.Center).onClick(() => this.showRegion = false);
      }.width('100%').padding({ left: 20, right: 20, top: 20, bottom: 12 }).backgroundColor(Color.White)
        .borderRadius({ topLeft: 20, topRight: 20 }).position({ bottom: 0 });
    }.width('100%').height('100%');
  }
  @Builder discardDialog() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#66000000').onClick(() => this.discardConfirm = false);
      Column({ space: 14 }) {
        Text('放弃修改？').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Center);
        Text('当前内容尚未保存，退出后将丢失。').fontSize(14).fontColor('#576275');
        Row({ space: 12 }) {
          Button('继续编辑').layoutWeight(1).height(42).backgroundColor('#E7E9EC').fontColor('#182230').onClick(() => this.discardConfirm = false);
          Button('放弃').layoutWeight(1).height(42).backgroundColor('#D83A45').fontColor(Color.White).onClick(() => this.onCancel());
        }.width('100%');
      }.width('calc(100% - 48vp)').padding(20).backgroundColor(Color.White).borderRadius(16).alignSelf(ItemAlign.Center);
    }.width('100%').height('100%');
  }
  @Builder regionOption(node: RegionNode) { Row() { Text(node.displayName()).fontSize(16).layoutWeight(1); Image($r('app.media.ic_arrow_right')).width(16).height(16); }.width('100%').padding({ top: 10, bottom: 10 }).onClick(() => this.chooseRegion(node)); }
}
