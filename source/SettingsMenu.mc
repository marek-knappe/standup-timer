import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// Global reference to settings menu for updating
var gSettingsMenu as SettingsMenu?;

class SettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Settings"});

        addItem(new WatchUi.MenuItem("Duration", formatMin(gDurationSeconds), :duration, {}));
        
        // Alert 1 with on/off status
        var a1Label = gAlert1Enabled ? formatMin(gAlert1Seconds) : "Off";
        addItem(new WatchUi.MenuItem("Alert 1", a1Label, :alert1, {}));
        
        // Alert 2 with on/off status
        var a2Label = gAlert2Enabled ? formatMin(gAlert2Seconds) : "Off";
        addItem(new WatchUi.MenuItem("Alert 2", a2Label, :alert2, {}));
        
        // Final countdown options
        var fcLabel = getFinalCountdownLabel();
        addItem(new WatchUi.MenuItem("Final Count", fcLabel, :finalcd, {}));
        
        addItem(new WatchUi.ToggleMenuItem("Show Clock", {:enabled => "On", :disabled => "Off"}, 
            :clock, gShowClock, {}));
        addItem(new WatchUi.MenuItem("Exit App", null, :exit, {}));
        
        gSettingsMenu = self;
    }

    static function formatMin(seconds as Number) as String {
        var m = seconds / 60;
        var s = seconds % 60;
        return m.format("%d") + ":" + s.format("%02d");
    }
    
    static function getFinalCountdownLabel() as String {
        if (gFinalCountdown == 5) { return "5 sec"; }
        if (gFinalCountdown == 3) { return "3 sec"; }
        return "Off";
    }

    // Update menu item labels after changes
    function updateLabels() as Void {
        var item0 = getItem(0);
        var item1 = getItem(1);
        var item2 = getItem(2);
        var item3 = getItem(3);
        
        if (item0 != null) { item0.setSubLabel(formatMin(gDurationSeconds)); }
        if (item1 != null) { item1.setSubLabel(gAlert1Enabled ? formatMin(gAlert1Seconds) : "Off"); }
        if (item2 != null) { item2.setSubLabel(gAlert2Enabled ? formatMin(gAlert2Seconds) : "Off"); }
        if (item3 != null) { item3.setSubLabel(getFinalCountdownLabel()); }
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :duration) {
            WatchUi.pushView(new TimePicker(:duration, "Duration", 60, 5400), 
                new TimePickerDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :alert1) {
            // Open Alert 1 sub-menu
            WatchUi.pushView(new AlertSubMenu(1), new AlertSubMenuDelegate(1), WatchUi.SLIDE_LEFT);
        } else if (id == :alert2) {
            // Open Alert 2 sub-menu
            WatchUi.pushView(new AlertSubMenu(2), new AlertSubMenuDelegate(2), WatchUi.SLIDE_LEFT);
        } else if (id == :finalcd) {
            // Open Final Countdown sub-menu
            WatchUi.pushView(new FinalCountdownMenu(), new FinalCountdownDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :clock) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                gShowClock = (item as WatchUi.ToggleMenuItem).isEnabled();
                TimerView.saveSettings();
            }
        } else if (id == :exit) {
            System.exit();
        }
    }

    function onBack() as Void {
        TimerView.resetTimer();
        gSettingsMenu = null;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// Sub-menu for Alert 1 or Alert 2
class AlertSubMenu extends WatchUi.Menu2 {
    private var _alertNum as Number;
    
    function initialize(alertNum as Number) {
        _alertNum = alertNum;
        var title = "Alert " + alertNum;
        Menu2.initialize({:title => title});
        
        var isEnabled = (alertNum == 1) ? gAlert1Enabled : gAlert2Enabled;
        var seconds = (alertNum == 1) ? gAlert1Seconds : gAlert2Seconds;
        
        addItem(new WatchUi.ToggleMenuItem("Enabled", {:enabled => "On", :disabled => "Off"}, 
            :enabled, isEnabled, {}));
        addItem(new WatchUi.MenuItem("Time", SettingsMenu.formatMin(seconds), :time, {}));
    }
    
    function getAlertNum() as Number { return _alertNum; }
}

class AlertSubMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _alertNum as Number;
    
    function initialize(alertNum as Number) {
        Menu2InputDelegate.initialize();
        _alertNum = alertNum;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        
        if (id == :enabled) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                var enabled = (item as WatchUi.ToggleMenuItem).isEnabled();
                if (_alertNum == 1) {
                    gAlert1Enabled = enabled;
                } else {
                    gAlert2Enabled = enabled;
                }
                TimerView.saveSettings();
                if (gSettingsMenu != null) { gSettingsMenu.updateLabels(); }
            }
        } else if (id == :time) {
            if (_alertNum == 1) {
                WatchUi.pushView(new TimePicker(:alert1, "Alert 1", 0, gDurationSeconds - 1), 
                    new TimePickerDelegate(), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.pushView(new TimePicker(:alert2, "Alert 2", 0, gAlert1Seconds - 1), 
                    new TimePickerDelegate(), WatchUi.SLIDE_LEFT);
            }
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// Final Countdown menu (5 sec, 3 sec, Off)
class FinalCountdownMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Final Count"});
        
        addItem(new WatchUi.MenuItem("5 seconds", null, :five, {}));
        addItem(new WatchUi.MenuItem("3 seconds", null, :three, {}));
        addItem(new WatchUi.MenuItem("Off", null, :off, {}));
    }
}

class FinalCountdownDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        
        if (id == :five) {
            gFinalCountdown = 5;
        } else if (id == :three) {
            gFinalCountdown = 3;
        } else if (id == :off) {
            gFinalCountdown = 0;
        }
        
        TimerView.saveSettings();
        if (gSettingsMenu != null) { gSettingsMenu.updateLabels(); }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
