import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Attention;

class TimerDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Start/Pause button
    function onSelect() as Boolean {
        return toggleTimer();
    }

    // Tap on screen
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return toggleTimer();
    }

    private function toggleTimer() as Boolean {
        if (gStatus == STATUS_READY) {
            gStatus = STATUS_RUNNING;
            // Quick vibrate when starting
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(100, 100)]);
            }
        } else if (gStatus == STATUS_RUNNING) {
            gStatus = STATUS_PAUSED;
            // Longer vibrate when pausing
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(100, 200)]);
            }
        } else if (gStatus == STATUS_PAUSED) {
            gStatus = STATUS_RUNNING;
            // Quick vibrate when resuming
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(100, 100)]);
            }
        } else if (gStatus == STATUS_FINISHED) {
            // Stop vibration and reset
            if (gTimerView != null) {
                gTimerView.stopFinishedVibration();
            }
            TimerView.resetTimer();
        }
        WatchUi.requestUpdate();
        return true;
    }

    // Long press to reset
    function onHold(evt as WatchUi.ClickEvent) as Boolean {
        if (gStatus == STATUS_RUNNING || gStatus == STATUS_PAUSED) {
            TimerView.resetTimer();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // Menu button - open settings
    function onMenu() as Boolean {
        return openSettings();
    }

    // Swipe up or down to open settings (when ready)
    function onNextPage() as Boolean {
        return openSettings();
    }

    function onPreviousPage() as Boolean {
        return openSettings();
    }

    private function openSettings() as Boolean {
        if (gStatus == STATUS_READY) {
            WatchUi.pushView(new SettingsMenu(), new SettingsMenuDelegate(), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    // Back button - reset timer
    function onBack() as Boolean {
        if (gStatus == STATUS_READY) {
            return true; // Do nothing, block exit
        }
        if (gStatus == STATUS_FINISHED) {
            // When time is up, just reset (don't start)
            if (gTimerView != null) {
                gTimerView.stopFinishedVibration();
            }
            TimerView.resetTimer();
            WatchUi.requestUpdate();
            return true;
        }
        if (gStatus == STATUS_PAUSED) {
            // When paused, just reset (don't start)
            TimerView.resetTimer();
            WatchUi.requestUpdate();
            return true;
        }
        // Running - reset and start again
        TimerView.resetTimer();
        gStatus = STATUS_RUNNING;
        // Quick vibrate when starting
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 100)]);
        }
        WatchUi.requestUpdate();
        return true;
    }
}
