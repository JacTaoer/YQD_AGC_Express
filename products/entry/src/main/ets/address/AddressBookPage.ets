import { AtomicAddress, emptyAddress, copyAddress } from './AddressTypes';
import { AddressStore } from './AddressStore';
import { AddressListItem } from './AddressListItem';
import { AddressForm } from './AddressForm';

@ComponentV2
export struct AddressBookPage {
  @Param visible: boolean = true;
  @Event onClosed: () => void = () => {};
  @Param mode: string = 'manage';
  @Param userId: number = 0;
  @Param storeId: number = 0;
  @Event onSelected: (item: AtomicAddress) => void = () => {};
  @Local items: AtomicAddress[] = [];
  @Local loading: boolean = true;
  @Local formVisible: boolean = false;
  @Local editing: AtomicAddress = emptyAddress();
  @Local editingMode: boolean = false;
  @Local notice: string = '';
  @Local pendingDelete: AtomicAddress = emptyAddress();
  @Local deleteConfirm: boolean = false;
  @Local loadError: string = '';

  aboutToAppear(): void { AddressStore.shared.configure(this.userId, this.storeId); this.refresh(); }
  private async refresh(): Promise<void> {
    this.loading = true; this.loadError = '';
    try { this.items = await AddressStore.shared.list(); }
    catch (_error) { this.loadError = '地址加载失败，请检查网络后重试'; }
    finally { this.loading = false; }
  }
  private requestDelete(item: AtomicAddress): void { this.pendingDelete = copyAddress(item); this.deleteConfirm = true; }
  private async remove(): Promise<void> { this.deleteConfirm = false; this.notice = `正在删除${this.pendingDelete.contactName}的地址`; await AddressStore.shared.remove(this.pendingDelete.id); this.notice = '删除成功'; await this.refresh(); }
  private async setDefault(item: AtomicAddress, value: boolean): Promise<void> { if (value) await AddressStore.shared.setDefault(item.id); await this.refresh(); }
  private openForm(item?: AtomicAddress): void { this.editingMode = Boolean(item); this.editing = item ? copyAddress(item) : emptyAddress(); this.formVisible = true; }
  build() {
    Stack() {
      Column() {
        Row() { Button() { Image($r('app.media.chevron_backward')).width(22).height(22); }.width(44).height(44).backgroundColor('#E9EBED').borderRadius(22).onClick(() => this.onClosed()); Text(this.mode === 'select' ? '选择地址' : '地址管理').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 10 }); }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center).backgroundColor('#F4F6F8');
        if (this.mode === 'select' && AddressStore.shared.isDemoMode()) { Text('当前未登录，展示本地演示地址').width('100%').fontSize(12).fontColor('#7A8699').padding({ left: 16, right: 16, top: 8 }); }
        if (this.loading) { LoadingProgress().width(40).height(40).layoutWeight(1); }
        else if (this.loadError.length > 0) { Column({ space: 12 }) { Image($r('app.media.ic_address_empty')).width(96).height(96); Text(this.loadError).fontSize(14).fontColor('#576275'); Button('重新加载').height(40).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.refresh()); }.layoutWeight(1).justifyContent(FlexAlign.Center); }
        else if (this.items.length === 0) { Column({ space: 12 }) { Image($r('app.media.ic_address_empty')).width(120).height(120); Text('暂无地址，快去添加吧').fontSize(14).fontColor('#576275'); }.layoutWeight(1).justifyContent(FlexAlign.Center); }
        else { Scroll() { Column({ space: 12 }) { ForEach(this.items, (item: AtomicAddress) => { AddressListItem({ item: item, mode: this.mode, onSelect: () => this.onSelected(item), onEdit: () => this.openForm(item), onDelete: () => this.requestDelete(item), onDefault: (value: boolean) => this.setDefault(item, value) }); }, (item: AtomicAddress) => item.id); }.padding(16).justifyContent(FlexAlign.Start); }.layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off); }
        Button('添加地址').width('calc(100% - 32vp)').height(46).margin({ left: 16, right: 16, top: 4, bottom: 20 }).backgroundColor('#0A59F7').fontColor(Color.White).onClick(() => this.openForm());
      }.width('100%').height('100%').backgroundColor('#F4F6F8');
      if (this.notice.length > 0) { Text(this.notice).fontSize(13).fontColor(Color.White).backgroundColor('#182230').borderRadius(16).padding(12).position({ bottom: 84 }).alignSelf(ItemAlign.Center).onClick(() => this.notice = ''); }
      if (this.formVisible) { AddressForm({ initial: this.editing, editing: this.editingMode, onSaved: async (_item: AtomicAddress) => { this.formVisible = false; this.notice = ''; await this.refresh(); }, onCancel: () => this.formVisible = false }); }
      if (this.deleteConfirm) {
        Column({ space: 14 }) {
          Text('删除地址').fontSize(18).fontWeight(FontWeight.Bold)
          Text(`删除${this.pendingDelete.contactName}的地址后将无法恢复，是否继续？`).fontSize(14).fontColor('#576275')
          Row({ space: 12 }) {
            Button('取消').layoutWeight(1).height(40).backgroundColor('#E7E9EC').fontColor('#182230').onClick(() => this.deleteConfirm = false)
            Button('删除').layoutWeight(1).height(40).backgroundColor('#C44747').fontColor(Color.White).onClick(() => this.remove())
          }.width('100%')
        }.width('calc(100% - 48vp)').padding(20).backgroundColor(Color.White).borderRadius(16).alignSelf(ItemAlign.Center)
      }
    }.width('100%').height('100%');
  }
}
