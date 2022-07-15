import 'dart:convert';

import 'package:book/common/Http.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:keframe/src/frame_separate_widget.dart';
import 'package:keframe/src/size_cache_widget.dart';
class Video extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return VideoState();
  }
}

class VideoState extends State<Video> with AutomaticKeepAliveClientMixin {
  List<List<GBook>> gbks = [];
  List<Widget> wds = [];
  List<String> tags = ["最新美剧", "科幻", "恐怖", "喜剧", "剧情"];
  List<String> keys = [
    "all_mj",
    "kehuanpian",
    "kongbupian",
    "xijupian",
    "juqingpian"
  ];
  ColorModel value;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    value = Store.value<ColorModel>(context);
    return gbks.isEmpty
        ? Scaffold()
        : Scaffold(
            drawer: MHistory(),
            appBar: AppBar(
              title: Text("美剧"),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.history),
                onPressed: () {
                  eventBus.fire(OpenEvent("m"));
                },
              ),
              elevation: 0,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    Routes.navigateTo(context, Routes.search,
                        params: {"type": "movie", "name": ""});
                  },
                )
              ],
            ),
            body: SizeCacheWidget(
              child: ListView.builder(
                cacheExtent: 500,
                itemCount: wds.length,
                itemBuilder: (c, i) => FrameSeparateWidget(
                  index: i,
            
                  child: wds[i],
                ),
              ),
            ),
            // body: ListView(
            //   children: wds,
            // ),
          );
  }

  @override
  void initState() {
    super.initState();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      getIndex();
    });
  }

  getIndex() async {
    bool haveKey = SpUtil.haveKey(Common.cache_index);
    if (haveKey) {
      List objectList = jsonDecode(SpUtil.getString(Common.cache_index));
      formatData(objectList);
    }
    Response res = await HttpUtil.instance.dio.get(Common.index);
    List data = res.data;
    if (haveKey) {
      SpUtil.remove(Common.cache_index);
    }
    SpUtil.putString(Common.cache_index, jsonEncode(data));
    formatData(data);
  }

  void formatData(List data) {
    wds = [];
    gbks = [];
    for (List value in data) {
      gbks.add(value.map((f) => GBook.fromJson(f)).toList());
    }
    wds.add(swiper());
    for (var i = 2; i < gbks.length; i++) {
      wds.add(item(tags[i - 2], gbks[i], keys[i - 2]));
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget swiper() {
    return Container(
      height: 150.0,
      child: Swiper(
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            child: Image.network(
              gbks[0][index].cover,
              fit: BoxFit.fill,
            ),
            onTap: () {
              Routes.navigateTo(context, Routes.vDetail,
                  params: {"gbook": jsonEncode(gbks[0][index])});
            },
          );
        },
        viewportFraction: 0.9,
        scale: 0.9,
        itemCount: gbks[0].length,
      ),
    );
  }

  Widget item(String title, List<GBook> bks, String key) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
       
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Spacer(),
              GestureDetector(
                child: Row(
                  children: <Widget>[
                    Text(
                      "更多",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey,
                    )
                  ],
                ),
                onTap: () {
                  Routes.navigateTo(context, Routes.tagVideo,
                      params: {"category": key, "name": title});
                },
              )
            ],
          ),
          GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(15.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 0.7),
            children: bks.map((i) => img(i)).toList(),
          )
        ],
      ),
    );
  }

  Widget img(GBook gbk) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          PicWidget(
            gbk.cover,
            width: 120,
            height: 120 * 1.2,
          ),
          Text(
            gbk.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
      onTap: () async {
        Routes.navigateTo(context, Routes.vDetail,
            params: {"gbook": jsonEncode(gbk)});
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class MHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) => Theme(
              child: ListView(
                children: <Widget>[],
              ),
              data: model.theme,
            ));
  }
}
