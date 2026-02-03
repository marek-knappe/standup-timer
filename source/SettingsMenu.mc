import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// Global reference to settings menu for updating
var gSettingsMenu as SettingsMenu?;

class SettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Settings"});

        addItem(new WatchUi.MenuItem("Duration", formatMin(gDurationSeconds), :duration, {}));
        addItem(new WatchUi.MenuItem("Alert 1", formatMin(gAlert1Seconds), :alert1, {}));
        addItem(new WatchUi.MenuItem("Alert 2", formatMin(gAlert2Seconds), :alert2, {}));
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

    // Update menu item labels after changes
    function updateLabels() as Void {
        var item0 = getItem(0);
        var item1 = getItem(1);
        var item2 = getItem(2);
        
        if (item0 != null) { item0.setSubLabel(formatMin(gDurationSeconds)); }
        if (item1 != null) { item1.setSubLabel(formatMin(gAlert1Seconds)); }
        if (item2 != null) { item2.setSubLabel(formatMin(gAlert2Seconds)); }
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
            WatchUi.pushView(new TimePicker(:alert1, "Alert 1", 0, gDurationSeconds - 1), 
                new TimePickerDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :alert2) {
            WatchUi.pushView(new TimePicker(:alert2, "Alert 2", 0, gAlert1Seconds - 1), 
                new TimePickerDelegate(), WatchUi.SLIDE_LEFT);
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
