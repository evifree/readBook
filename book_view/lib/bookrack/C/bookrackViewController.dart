import 'package:flutter/material.dart';
import 'package:book_view/Global/dataHelper.dart';
import 'package:book_view/Global/XContants.dart';
import 'package:book_view/read/readViewController.dart';
import 'package:book_view/searchBook/searchResultViewController.dart';
import "package:pull_to_refresh/pull_to_refresh.dart";
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:book_view/Global/V/blankView.dart';
import 'package:flutter/services.dart';
import 'package:book_view/Global/Adnet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:book_view/Global/XHttp.dart';
import 'package:flutter/cupertino.dart';
import 'package:book_view/bookrack/M/BookRackModel.dart';
import 'package:book_view/Global/V/XHUD.dart';
import 'dart:async';
import 'package:book_view/menu/MenuViewController.dart';
class BookRack extends StatefulWidget {
  @override
  BookRackState createState() => new BookRackState();
}

class BookRackState extends State<BookRack> {
  RefreshController refreshController = RefreshController();
  List rackList = [];
  List lastChapterList = [];
  XHud hud = XHud();


  BookRackState() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
        .copyWith(statusBarIconBrightness: Brightness.light));
    AdNet.load();
    updateRackList();
  }
  @override
  initState(){
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => checkVersion());
  }
  checkVersion(){
    print("checkVersion");
    XHttp.get("/checkVersion", {}, (Map response){
      print("checkVersion success");

      if(response['code'] == 100){
        print("show alert");
        showDialog<String>(
          context: context,
          builder: (BuildContext context){
            return new CupertinoAlertDialog(
              title: Text(response['description']),
              actions: <Widget>[
                new CupertinoDialogAction(
                  child: const Text('取消'),
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.pop(context, '取消');
                  },
                ),
                new CupertinoDialogAction(
                  child: const Text('确定'),
                  isDefaultAction: true,
                  onPressed: () {
                    launch(response['link']);
                    Navigator.pop(context, '确定');
                  },
                ),
              ],
            );
          },
        );
      }
    }, (e){
      print("checkVersion fail");
    });
  }
  updateRackList() async {
    await getRackList();
    setState(() {});
    if (refreshController.scrollController != null) {
      refreshController.sendBack(true, RefreshStatus.idle);
    }
  }

  getRackList() async {
    DataHelper db = await getDataHelp();
    rackList = await db.getRackList();
    lastChapterList = [];
    for(Map book in rackList){
      Map lastChapter = await db.getLastChapter(book['bookName']);
      if(lastChapter!=null){
        lastChapterList.add({"lastChapter":"最新更新 "+lastChapter['chapterName'],"lastChapterDate":""});
      }else{
        lastChapterList.add({"lastChapter":book['lastChapter'],"lastChapterDate":book['lastChapterDate']});
      }
    }
  }

  startRead(index) async {
    Map book = rackList[index];
    DataHelper db = await getDataHelp();
    if (book['currentChapter'] == null) {
      Map firstChapter = await db.getFirstChapter(book['bookName']);
      if(firstChapter == null){
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (ctx) => SearchResultViewController(
              bookName: book['bookName'],
            )));
      }else{
        String url = firstChapter['menuLink'];
        print(url);
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (ctx) => new MenuViewController(
              url: url,
              bookName: book['bookName'],
            )));
      }

    } else {
      Map chapter =
          await db.getChapter(book['bookName'], book['currentChapter']);
      if (chapter == null) {
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (ctx) => SearchResultViewController(
                  bookName: book['bookName'],
                )));
      } else {
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (ctx) => ReadViewController(
                  chapter: chapter,
                )));
      }
    }
  }

  Widget renderRow(i) {
    Map book = rackList[i];
    String thumbImgUrl = book['cover'];
//    String thumbImgUrl = "https://qidian.qpic.cn/qdbimg/349573/2248950/150";
    if (!thumbImgUrl.startsWith(RegExp('^http'))) {
      thumbImgUrl = "https://" + thumbImgUrl;
    }
    var thumbImg;
//    if (thumbImgUrl.startsWith(RegExp('^https'))) {
//      thumbImg = new Container(
//        width: 102.0,
//        height: 136.0,
//        color: Color(0xFFECECEC),
//        child: CachedNetworkImage(
//          imageUrl: thumbImgUrl,
//          placeholder: Image.asset("./images/01.jpg"),
//        ),
//      );
//    } else {
    thumbImg = new Container(
      width: 102.0,
      height: 136.0,
      decoration: new BoxDecoration(
        shape: BoxShape.rectangle,
        color: const Color(0xFFECECEC),
        image: new DecorationImage(
            image: new NetworkImage(thumbImgUrl), fit: BoxFit.fitWidth),
      ),
    );
//    }

    var titleRow = new Row(
      children: <Widget>[
        new Expanded(
          child: new Text('${i + 1}.' + book['bookName'],
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15.0)),
        )
      ],
    );

    var authorRow = new Row(
      children: <Widget>[
        new Expanded(
//          padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          child: new Text(
            book['author'] + " | " + book['type'],
            style: TextStyle(
                color: const Color.fromRGBO(168, 168, 168, 1.0),
                fontSize: 12.0),
          ),
        ),
      ],
    );
    String intro = book['desc'];
    intro = intro.replaceAll(RegExp('\\s'), '');
    var descRow = new Row(
      children: <Widget>[
        new Expanded(
          child: new Text(
            intro,
            style: TextStyle(
                color: const Color.fromRGBO(92, 92, 92, 1.0), fontSize: 13.0),
            maxLines: 2,
          ),
        ),
      ],
    );
    Map lastChapter = lastChapterList[i];
    var lastChapterRow = new Row(
      children: <Widget>[
        new Expanded(
//          padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          child: new Text(
            lastChapter['lastChapter'] + "  \n. " + lastChapter['lastChapterDate'],
            style: TextStyle(
                color: const Color.fromRGBO(107, 125, 167, 1.0),
                fontSize: 11.0),
          ),
        ),
      ],
    );
    var row = Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 10.0),
                child: thumbImg),
            Expanded(
              flex: 1,
              child: new Padding(
                padding: const EdgeInsets.all(4.0),
                child: new Column(
                  children: <Widget>[
                    titleRow,
                    Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 4.0),
                      child: authorRow,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 4.0),
                      child: descRow,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 4.0),
                      child: lastChapterRow,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Divider(height: 1.0,),

      ],
    );
    return new InkWell(
      child: row,
      onTap: () {
        startRead(i);
      },
    );
  }

  void deleteAction(index) async {
    Map book = rackList[index];

    DataHelper db = await getDataHelp();
    await db.deleteRack(book['id']);
    updateRackList();
  }

  Widget getSlidAbleRow(index) {
    return new Slidable(
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: renderRow(index),
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: '删除',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => deleteAction(index),
        ),
      ],
    );
  }

  void _onRefresh(bool up) {
    Future.delayed(const Duration(milliseconds: 300))
        .then((val) {
      if (up) {
        //headerIndicator callback
        updateRackList();
      } else {
        //footerIndicator Callback
      }
        });


  }


  @override
  Widget build(BuildContext context) {
    getRackList();
    Widget _body;
    if (rackList.length == 0) {
      _body = BlankView(
        tipText: "快去添加书籍吧～～",
      );
    } else {
      _body = Container(
          padding: const EdgeInsets.all(.0),
          child: SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            onRefresh: _onRefresh,
            onOffsetChange: null,
            child: new ListView.builder(
              itemCount: rackList.length,
              itemBuilder: (context, i) => getSlidAbleRow(i),
            ),
            controller: refreshController,
          ));
    }
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("书架"),
          backgroundColor: XColor.appBarColor,
          textTheme: TextTheme(title: XTextStyle.navigationTitleStyle),
          actions: <Widget>[
            CupertinoButton(child: Text("检查更新",style: TextStyle(color: Colors.white),),

            onPressed: (){
              hud.state.show();
              BookRackModel.checkBookUpdate((){
                hud.state.showSuccessWithString("更新成功");
                updateRackList();
              });
            },
            )
          ],
        ),
        body:  Stack(
          children: <Widget>[
            _body,
            hud,
          ],
        )

    );
  }
}
