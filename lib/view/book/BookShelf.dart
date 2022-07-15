import 'dart:io';

import 'package:book/common/Http.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/AppInfo.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/person/Me.dart';
import 'package:book/widgets/BooksWidget.dart';
import 'package:book/widgets/MyIcon.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xupdate/flutter_xupdate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class BookShelf extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _BookShelfState();
  }
}

class _BookShelfState extends State<BookShelf> {
  static final GlobalKey<ScaffoldState> key = new GlobalKey();
  @override
  void initState() {
    super.initState();
    _checkUpdate();
    if (!SpUtil.containsKey(Common.top_safe_height)) {
      SpUtil.putDouble(Common.top_safe_height, Screen.topSafeHeight);
    }
    if (!SpUtil.containsKey(Common.shimmer_nums)) {
      SpUtil.putInt(
          Common.shimmer_nums,
          (Screen.height -
                  Screen.topSafeHeight -
                  Screen.bottomSafeHeight -
                  60) ~/
              25);
    }
  }

  ///初始化
  Future<void> initXUpdate() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      FlutterXUpdate.init(

              ///是否输出日志
              debug: true,

              ///是否使用post请求
              isPost: false,

              ///post请求是否是上传json
              isPostJson: false,

              ///是否开启自动模式
              isWifiOnly: false,

              ///是否开启自动模式
              isAutoMode: false,

              ///需要设置的公共参数
              supportSilentInstall: false,

              ///在下载过程中，如果点击了取消的话，是否弹出切换下载方式的重试提示弹窗
              enableRetry: false)
          .then((value) {
        //  updateMessage("初始化成功: $value");
      }).catchError((error) {});
      FlutterXUpdate.setErrorHandler(
          onUpdateError: (Map<String, dynamic> message) async {});
    }
  }

  Future<void> _checkUpdate() async {
    await initXUpdate();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    Response response = await HttpUtil.instance.dio.get(Common.update);
    var data = response.data['data'];
    AppInfo appInfo = AppInfo.fromJson(data);

    if (int.parse(appInfo.version.replaceAll(".", "")) >
        int.parse(version.replaceAll(".", ""))) {
      var up = UpdateEntity(
          hasUpdate: true,
          isForce: appInfo.forceUpdate == "2",
          isIgnorable: false,
          versionCode: 1,
          versionName: appInfo.version,
          updateContent: appInfo.msg,
          downloadUrl: appInfo.link,
          apkSize: int.parse(appInfo.apkSize),
          apkMd5: appInfo.apkMD5);

      FlutterXUpdate.updateByInfo(
          updateEntity: up, supportBackgroundUpdate: true, widthRatio: .6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ShelfModel>(
        builder: (context, ShelfModel shelfModel, child) {
      return Scaffold(
        key: key,
          drawer: Drawer(
            child: Me(),
          ),
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.person),
              onPressed: ()=>key.currentState.openDrawer(),
              iconSize: 25,
            ),
            elevation: 0,
            centerTitle: true,
            actions: <Widget>[
              MyIcon(Icons.search, () {
                Routes.navigateTo(context, Routes.search,
                    params: {"type": "book", "name": ""});
              }),
              MyIcon(Icons.more_vert, () async {
                String shelfModelName = shelfModel.cover ? "列表模式" : "封面模式";
                final result = await showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(2000.0, .0, 0.0, 0.0),
                    items: <PopupMenuItem<String>>[
                      PopupMenuItem(
                          value: shelfModelName, child: Text(shelfModelName)),
                      PopupMenuItem(value: "书架整理", child: Text("书架整理"))
                    ]);
                if (result == "封面模式" || result == "列表模式") {
                  shelfModel.toggleModel();
                } else if (result == "书架整理") {
                  Routes.navigateTo(
                    context,
                    Routes.sortShelf,
                  );
                }
              }),
            ],
          ),
          body: BooksWidget(""));
    });
  }
}
