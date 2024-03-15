import 'package:beike_aspectd/aspectd.dart';
import 'package:example/route_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'hook_example.dart';
void main() {
  runApp(MyApp());
  LifecycleDetect.getInstance().init();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: GlobalKey(),
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: RouteHelper.routes,
      initialRoute: RouteHelper.main,
/*        onGenerateRoute: (RouteSettings settings) {
          print("onGenerateRoute+++++++");
          return MaterialPageRoute<dynamic>(
              builder: (BuildContext context) {
                print("builder+++++++");
                return RouteHelper.routes[settings.name]!(context);
              },
              settings: settings);
        }*/
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    LifecycleDetect.getInstance().addLifecycleObserver(LifecycleObserver(
      onResume: (String pageName, bool isNative) {
        print(
            'LifecycleDetect=======onResume:::pageName:$pageName   isNative:$isNative');
      },
      onPause: (String pageName, bool isNative) {
        print(
            'LifecycleDetect=======onPause:::pageName:$pageName   isNative:$isNative');
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              child: Container(
                color: Colors.blue,
                child: Text(
                  "GestureDetector点击",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, RouteHelper.firstPage);
              },
            ),
            ElevatedButton(
                onPressed: () {},
                child: Text(
                  "FlatButton点击",
                  style: TextStyle(fontSize: 20),
                ))
          ],
        ),
      ),
    );
  }
}
