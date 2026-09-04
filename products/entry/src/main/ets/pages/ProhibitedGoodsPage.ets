@Component
export struct ProhibitedGoodsPage {
  onBack: () => void = () => {};

  build() {
    Column() {
      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_backward')).fontSize(24);
        }
        .width(44).height(44).backgroundColor(Color.Transparent)
        .onClick(() => this.onBack());
        Text('违禁品说明').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center);
        Blank().width(44);
      }
      .width('100%').height(64).padding({ left: 8, right: 8 }).alignItems(VerticalAlign.Center).backgroundColor(Color.White);

      Scroll() {
        Column({ space: 18 }) {
          Text('(一) 禁限寄物品标准说明').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#3478F6').alignSelf(ItemAlign.Center);
          Text('应国家邮政局等三部门联合发布的《禁止寄递物品管理规定》要求，以下物品的寄递会因禁止寄递而被拒收。').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#30343B').lineHeight(26);
          this.section('一、枪支（含仿制品、主要零部件）弹药', '枪支：如手枪、步枪、冲锋枪、防暴枪、气枪、猎枪、运动枪、麻醉注射枪、钢珠枪、催泪枪等。弹药：如子弹、炸弹、手榴弹、火箭弹、照明弹、燃烧弹、烟幕弹、信号弹、催泪弹、毒气弹、地雷、手雷、炮弹、火药等。');
          this.section('二、管制器具', '管制刀具：如匕首、三棱刮刀、带有自锁装置的弹簧刀（跳刀），以及其他类似的单刃、双刃、三棱尖刀等。其他：如弩、催泪器、催泪枪、电击器等。');
          this.section('三、爆炸物品', '爆破器材：如炸药、雷管、导火索、导爆索、爆破剂等。烟花爆竹：如烟花、鞭炮、摔炮、拉炮、砸炮、彩药弹等烟花爆竹及黑火药、烟火药、发令纸、引火线等。其他：如推进剂、发射药、硝化棉、电点火头等。');
          this.section('四、压缩和液化气体及其容器', '易燃气体：如氢气、甲烷、乙烷、丁烷、天然气、液化石油气、乙烯、丙烯、乙炔、打火机等。有毒气体：如一氧化碳、一氧化氮、氯气等。易爆或窒息、助燃气体：如压缩氧气、氮气、氨气、氩气、氟气、气雾剂等。');
          this.section('五、易燃液体', '如汽油、柴油、煤油、桐油、丙酮、乙醚、油漆、生漆、苯、酒精、松香油等。');
          this.section('六、易燃固体、自燃物质、遇水易燃物质', '易燃固体：如红磷、硫磺、铝粉、闪光粉、固体酒精、火柴、活性炭等。自燃物质：如黄磷、白磷、硝化纤维（含胶片）、铁粉等。遇水易燃物质：如金属钠、钾、锂、锌粉、镁粉、碳化钙（电石）、氰化钙等。');
          this.section('七、氧化剂和有机过氧化物', '如过氧化氢、高锰酸钾、氯酸钾、硝酸盐、过氧化钠、过氧化钾、过氧化苯甲酰等。');
          this.section('八、毒害品和感染性物质', '如氰化物、砷化物、汞（水银）、农药、杀虫剂、灭鼠药、病毒样本、细菌培养物、医疗废弃物及其他可能危害人体健康的有毒或感染性物质。');
          this.section('九、放射性物质', '如铀、钴、镭、钚等放射性同位素及放射性废料、放射源和相关包装容器。');
          this.section('十、腐蚀性物质', '如硫酸、盐酸、硝酸、氢氧化钠、氢氧化钾、电池液、蓄电池、甲酸、冰醋酸等酸碱及腐蚀性化学品。');
          this.section('十一、其他危害公共安全和寄递安全的物品', '包括活体动物（符合规定的运输动物除外）、未经检疫的动植物及其制品、反动或淫秽出版物、侵犯知识产权和假冒伪劣物品、现金及有价证券、个人隐私文件，以及法律法规和国家有关部门规定禁止寄递的其他物品。');
          Text('提示：不同快递公司和运输线路可能有更严格的限制。寄件前请如实申报物品信息，具体以承运方审核结果为准。').fontSize(14).fontColor('#7A8699').lineHeight(23).margin({ top: 4, bottom: 20 });
        }
        .padding({ left: 20, right: 20, top: 20, bottom: 30 });
      }
      .layoutWeight(1).scrollBar(BarState.Off).backgroundColor('#F7F8FA');
    }
    .width('100%').height('100%').backgroundColor('#F7F8FA');
  }

  @Builder
  section(title: string, content: string) {
    Column({ space: 8 }) {
      Text(title).fontSize(19).fontWeight(FontWeight.Bold).fontColor('#3478F6').lineHeight(27).width('100%');
      Text(content).fontSize(15).fontColor('#30343B').lineHeight(25).width('100%');
    }.width('100%').alignItems(HorizontalAlign.Start);
  }
}
