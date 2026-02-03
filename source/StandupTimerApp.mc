import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class StandupTimerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new TimerView(), new TimerDelegate()];
    }
}

function getApp() as StandupTimerApp {
    return Application.getApp() as StandupTimerApp;
}
