import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:beike_aspectd/aspectd.dart';
import 'package:flutter/rendering.dart';

@Aspect()
@pragma("vm:entry-point")
class ClickAopHook {
  @pragma("vm:entry-point")
  ClickAopHook();

  @Execute("package:flutter/src/gestures/binding.dart", "GestureBinding",
      "-dispatchEvent")
  @pragma("vm:entry-point")
  dynamic hookHitTest(PointCut pointCut) {
    if (pointCut.positionalParams != null) {
      PointerEvent pointEvent = pointCut.positionalParams![0];
      HitTestResult? hitTestResult;

      if (pointCut.positionalParams!.length >= 2) {
        hitTestResult = pointCut.positionalParams![1];
      }

      print("GestureRecognizer：：：：：invokeCallback---${hitTestResult?.path}");
      if (hitTestResult != null) {
        if (pointEvent is PointerUpEvent) {
          for (HitTestEntry hitTestEntry in hitTestResult.path) {
            if (hitTestEntry.target is RenderObject) {
              HookImpl.getInstance().hookHitTest(hitTestEntry, pointEvent);
              break;
            }
          }
        }
      }
    }
    return pointCut.proceed();
  }

  @Execute("package:flutter/src/gestures/recognizer.dart", "GestureRecognizer",
      "-invokeCallback")
  @pragma("vm:entry-point")
  dynamic hookInvokeCallback(PointCut pointCut) {
    dynamic result = pointCut.proceed();
    print("GestureRecognizer：：：：：invokeCallback---${pointCut.sourceInfos}");
    print("GestureRecognizer：：：：：invokeCallback---${pointCut.annotations}");
    Map<String, Object> map = HookImpl.getInstance().hookClick(pointCut);
    print("GestureRecognizer：：：：：mapmap---${map}");
    return result;
  }

  int curPointerCode = 0;
/*
  @Call("package:flutter/src/gestures/hit_test.dart", "HitTestTarget",
      "-handleEvent")
  @pragma("vm:entry-point")
  dynamic hookHitTestTargetHandleEvent(PointCut pointCut) {
    dynamic target = pointCut.target;
    PointerEvent pointerEvent = pointCut.positionalParams[0];
    HitTestEntry entry = pointCut.positionalParams[1];
    curPointerCode = pointerEvent.pointer;
    if (target is RenderObject) {
      bool localListenerWidget = false;
      if (target is RenderPointerListener) {
        ///处理单独使用Listener
        RenderPointerListener pointerListener = target;
        if (pointerListener.onPointerDown != null &&
            pointerEvent is PointerDownEvent) {
          DebugCreator debugCreator = pointerListener.debugCreator;
          dynamic widget;
          debugCreator.element.visitAncestorElements((element) {
            if (element.widget is Listener) {
              widget = element.widget;
              if (widget.isLocal != null && widget.isLocal) {
                localListenerWidget = true;
                String elementPath = getElementPath(element);
                //丰富当前事件的信息
                richJsonInfo(element, element, 'onTap', elementPath);
              }
              //else if(...) //可以过滤侧滑返回可能影响到的情况。因为它本身设置的HitTestBehavior.translucent，点击到侧滑栏区域它会成为我们认为的最小widget
            }
            return false;
          });
        }
      }
      if (!localListenerWidget) {
        if (curPointerCode > prePointerCode) {
          clearClickRenderMapData();
        }
        if (!clickRenderMap.containsKey(curPointerCode)) {
          clickRenderMap[curPointerCode] = target;
        }
      }
    }
    prePointerCode = curPointerCode;
    target.handleEvent(pointerEvent, entry);
  }*/
}
