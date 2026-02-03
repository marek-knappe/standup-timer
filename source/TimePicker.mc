import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

// Global reference to current picker (for older devices without getCurrentView)
var gCurrentPicker as TimePicker?;

class TimePicker extends WatchUi.View {
    private var _id as Symbol;
    private var _title as String;
    private var _min as Number;
    private var _max as Number;
    private var _minutes as Number;
    private var _seconds as Number;
    private var _editMin as Boolean = true;

    function initialize(id as Symbol, title as String, min as Number, max as Number) {
        View.initialize();
        _id = id;
        _title = title;
        _min = min;
        _max = max;

        var current = getCurrentValue();
        if (current > _max) { current = _max; }
        if (current < _min) { current = _min; }
        _minutes = current / 60;
        _seconds = (current % 60) / 5 * 5;
        
        // Store reference globally
        gCurrentPicker = self;
    }

    private function getCurrentValue() as Number {
        if (_id == :duration) { return gDurationSeconds; }
        if (_id == :alert1) { return gAlert1Seconds; }
        if (_id == :alert2) { return gAlert2Seconds; }
        return _min;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, h/4, Graphics.FONT_SMALL, _title, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Minutes (blue if editing)
        dc.setColor(_editMin ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2 - 50, h/2, Graphics.FONT_NUMBER_MEDIUM, _minutes.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Colon
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, h/2, Graphics.FONT_NUMBER_MEDIUM, ":",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Seconds (blue if editing)
        dc.setColor(_editMin ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2 + 50, h/2, Graphics.FONT_NUMBER_MEDIUM, _seconds.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Hint
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, h*3/4, Graphics.FONT_XTINY, "BTN: switch, BACK: save",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function toggleEdit() as Void { _editMin = !_editMin; WatchUi.requestUpdate(); }
    function isEditingMin() as Boolean { return _editMin; }

    function incMin() as Void {
        var v = (_minutes + 1) * 60 + _seconds;
        if (v <= _max) { _minutes++; WatchUi.requestUpdate(); }
    }

    function decMin() as Void {
        if (_minutes > 0) {
            var v = (_minutes - 1) * 60 + _seconds;
            if (v >= _min) { _minutes--; WatchUi.requestUpdate(); }
        }
    }

    function incSec() as Void {
        var ns = _seconds + 5;
        if (ns >= 60) {
            var v = (_minutes + 1) * 60;
            if (v <= _max) { _minutes++; _seconds = 0; WatchUi.requestUpdate(); }
        } else {
            var v = _minutes * 60 + ns;
            if (v <= _max) { _seconds = ns; WatchUi.requestUpdate(); }
        }
    }

    function decSec() as Void {
        if (_seconds >= 5) {
            var v = _minutes * 60 + _seconds - 5;
            if (v >= _min) { _seconds -= 5; WatchUi.requestUpdate(); }
        } else if (_minutes > 0) {
            var v = (_minutes - 1) * 60 + 55;
            if (v >= _min) { _minutes--; _seconds = 55; WatchUi.requestUpdate(); }
        }
    }

    function getValue() as Number { return _minutes * 60 + _seconds; }
    function getId() as Symbol { return _id; }
}

class TimePickerDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onNextPage() as Boolean {
        var p = gCurrentPicker;
        if (p != null) {
            if (p.isEditingMin()) { p.decMin(); } else { p.decSec(); }
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        var p = gCurrentPicker;
        if (p != null) {
            if (p.isEditingMin()) { p.incMin(); } else { p.incSec(); }
        }
        return true;
    }

    function onSelect() as Boolean {
        var p = gCurrentPicker;
        if (p != null) { p.toggleEdit(); }
        return true;
    }

    function onBack() as Boolean {
        var p = gCurrentPicker;
        if (p != null) {
            var val = p.getValue();
            var id = p.getId();

            if (id == :duration) {
                gDurationSeconds = val;
                // Adjust alerts if needed
                if (gAlert1Seconds >= val) { gAlert1Seconds = val - 60; }
                if (gAlert1Seconds < 0) { gAlert1Seconds = 0; }
                if (gAlert2Seconds >= gAlert1Seconds) { gAlert2Seconds = gAlert1Seconds - 30; }
                if (gAlert2Seconds < 0) { gAlert2Seconds = 0; }
            } else if (id == :alert1) {
                gAlert1Seconds = val;
                if (gAlert2Seconds >= val) { gAlert2Seconds = val - 30; }
                if (gAlert2Seconds < 0) { gAlert2Seconds = 0; }
            } else if (id == :alert2) {
                gAlert2Seconds = val;
            }

            TimerView.saveSettings();
            gCurrentPicker = null;
            
            // Update settings menu labels
            if (gSettingsMenu != null) {
                gSettingsMenu.updateLabels();
            }
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
