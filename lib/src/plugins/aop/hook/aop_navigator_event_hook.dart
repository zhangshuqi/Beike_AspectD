import 'package:beike_aspectd/aspectd.dart';
import 'package:flutter/material.dart';

@Aspect()
@pragma("vm:entry-point")
class AopNavigatorEventHook {
  @pragma("vm:entry-point")
  AopNavigatorEventHook();

  @Execute(
      "package:flutter/src/widgets/navigator.dart", "_RouteEntry", "-handleAdd")
  @pragma("vm:entry-point")
  void _handleAdd(PointCut pointCut) {
    debugPrint("++++_handleAdd++++");
    pointCut.proceed();

    if (pointCut.namedParams != null) {
      dynamic target = pointCut.target;
      Route? previousRoute = pointCut.namedParams!["previousPresent"];
      HookImpl.getInstance().handlePush(target.route, previousRoute);
    }
  }

  @Execute("package:flutter/src/widgets/navigator.dart", "_RouteEntry",
      "-handlePush")
  @pragma("vm:entry-point")
  void _handlePush(PointCut pointCut) {
    debugPrint("++++_handlePush++++");
    pointCut.proceed();
    dynamic target = pointCut.target;
    Route? previousRoute = pointCut.namedParams?["previousPresent"];
    HookImpl.getInstance().handlePush(target.route, previousRoute);
  }

  @Execute("package:flutter/src/scheduler/binding.dart", "SchedulerBinding",
      "-handleDrawFrame")
  @pragma("vm:entry-point")
  void _handleDrawFrame(PointCut pointCut) {
    //debugPrint("++++_handleDrawFrame++++");
    pointCut.proceed();
   // HookImpl.getInstance().handleDrawFrame();
  }

  @Execute("package:flutter/src/material/page.dart",
      "MaterialRouteTransitionMixin", "-buildPage")
  @pragma("vm:entry-point")
  dynamic _buildPage(PointCut pointCut) {
    dynamic pointCutProceed = pointCut.proceed();

    debugPrint("++++_buildPage++++");
    if (pointCut.positionalParams == null ||
        pointCut.target == null ||
        !(pointCut.target is Route)) {
      return pointCutProceed;
    }
    Route target = pointCut.target as Route;
    if (pointCutProceed != null && pointCutProceed is Semantics) {
      HookImpl.getInstance().buildPage(
          target, pointCutProceed.child, pointCut.positionalParams![0]);
      return pointCutProceed;
    }
    return pointCutProceed;
  }

  @Execute("package:flutter/src/cupertino/route.dart",
      "CupertinoRouteTransitionMixin", "-buildPage")
  @pragma("vm:entry-point")
  dynamic _cupertinoBuildPage(PointCut pointCut) {
    dynamic pointCutProceed = pointCut.proceed();

    if (pointCut.positionalParams == null ||
        pointCut.target == null ||
        !(pointCut.target is Route)) {
      return pointCutProceed;
    }
    Route target = pointCut.target as Route;
    if (pointCutProceed != null && pointCutProceed is Semantics) {
      HookImpl.getInstance().buildPage(
          target, pointCutProceed.child, pointCut.positionalParams![0]);
      return pointCutProceed;
    }
    return pointCutProceed;
  }

  @Execute(
      "package:flutter/src/widgets/navigator.dart", "_RouteEntry", "-handlePop")
  @pragma("vm:entry-point")
  _handlePop(PointCut pointCut) {
    debugPrint("++++handlePop++++");
    dynamic target = pointCut.target;
    Route? previousPresent = pointCut.namedParams?["previousPresent"];
    HookImpl.getInstance().handlePop(target?.route, previousPresent);
    return pointCut.proceed();
  }

  @Execute("package:lifecycle_detect/lifecycle_detect.dart", "LifecycleDetect",
      "-onActivityResumed")
  @pragma("vm:entry-point")
  void _onActivityResumed(PointCut pointCut) {
    debugPrint("++++onActivityResumed++++");
    pointCut.proceed();
    HookImpl.getInstance().onActivityResumed();
  }

  @Execute("package:lifecycle_detect/lifecycle_detect.dart", "LifecycleDetect",
      "-onActivityPaused")
  @pragma("vm:entry-point")
  void _onActivityPaused(PointCut pointCut) {
    debugPrint("++++onActivityPaused++++");
    pointCut.proceed();
    HookImpl.getInstance().onActivityPaused();
  }
}
