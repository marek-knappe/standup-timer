import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.System;
import Toybox.Attention;
import Toybox.Application.Storage;

// Timer states
enum TimerStatus {
    STATUS_READY,
    STATUS_RUNNING,
    STATUS_PAUSED,
    STATUS_FINISHED
}

// Global timer state
var gStatus as TimerStatus = STATUS_READY;
var gRemainingSeconds as Number = 900;
var gDurationSeconds as Number = 900;      // 15 min default
var gAlert1Seconds as Number = 300;        // 5 min default
var gAlert2Seconds as Number = 60;         // 1 min default
var gAlert1Fired as Boolean = false;
var gAlert2Fired as Boolean = false;
var gShowClock as Boolean = true;
var gTimerView as TimerView?;

class TimerView extends WatchUi.View {
    private var _timer as Timer.Timer?;
    private var _vibeTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
        loadSettings();
        gRemainingSeconds = gDurationSeconds;
        gTimerView = self;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 1000, true);
    }

    function onTick() as Void {
        if (gStatus == STATUS_RUNNING) {
            if (gRemainingSeconds > 0) {
                gRemainingSeconds -= 1;
                checkAlerts();
            }
            if (gRemainingSeconds <= 0) {
                gStatus = STATUS_FINISHED;
                startFinishedVibration();
            }
        }
        WatchUi.requestUpdate();
    }

    private function checkAlerts() as Void {
        // Alert 1: 1 vibration (yellow warning)
        if (!gAlert1Fired && gRemainingSeconds <= gAlert1Seconds && gRemainingSeconds > gAlert2Seconds) {
            gAlert1Fired = true;
            vibrate([new Attention.VibeProfile(100, 500)]);
        }
        
        // Alert 2: 2 vibrations (magenta warning)
        if (!gAlert2Fired && gRemainingSeconds <= gAlert2Seconds && gRemainingSeconds > 5) {
            gAlert2Fired = true;
            vibrate([
                new Attention.VibeProfile(100, 500),
                new Attention.VibeProfile(0, 300),
                new Attention.VibeProfile(100, 500)
            ]);
        }
        
        // Final 5 second countdown - short pulse each second
        if (gRemainingSeconds <= 5 && gRemainingSeconds >= 1) {
            vibrate([new Attention.VibeProfile(100, 100)]);
        }
    }

    private function startFinishedVibration() as Void {
        // Just one long vibration at the end, no continuous vibration
        vibrate([new Attention.VibeProfile(100, 1500)]);
    }

    function vibeOnce() as Void {
        // No longer used
    }

    function stopFinishedVibration() as Void {
        if (_vibeTimer != null) {
            _vibeTimer.stop();
            _vibeTimer = null;
        }
    }

    private function vibrate(pattern as Array<Attention.VibeProfile>) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate(pattern);
        }
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Determine colors based on state
        var bgColor = Graphics.COLOR_BLACK;
        var textColor = Graphics.COLOR_WHITE;
        var statusText = "";

        if (gStatus == STATUS_FINISHED) {
            bgColor = Graphics.COLOR_WHITE;
            textColor = Graphics.COLOR_BLACK;
            statusText = "TIME'S UP!";
        } else if (gStatus == STATUS_PAUSED) {
            textColor = Graphics.COLOR_LT_GRAY;
            statusText = "PAUSED";
        } else if (gStatus == STATUS_READY) {
            statusText = "READY";
        } else if (gStatus == STATUS_RUNNING) {
            statusText = "RUNNING";
            // Color changes for alerts
            if (gRemainingSeconds <= 5) {
                textColor = 0xFF00FF; // Magenta
            } else if (gRemainingSeconds <= gAlert2Seconds) {
                textColor = 0xFF00FF; // Magenta
            } else if (gRemainingSeconds <= gAlert1Seconds) {
                textColor = Graphics.COLOR_YELLOW;
            }
        }

        // Clear background
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // Draw clock at top
        var timerY = height / 2;
        if (gShowClock && gStatus != STATUS_FINISHED) {
            drawClock(dc, width);
            timerY = height / 2 + 15;
        }

        // Draw remaining time
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        var timeStr = formatTime(gRemainingSeconds);
        dc.drawText(width / 2, timerY - 25, Graphics.FONT_NUMBER_HOT, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw status
        dc.drawText(width / 2, timerY + 45, Graphics.FONT_SMALL, statusText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw hint when ready
        if (gStatus == STATUS_READY) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height - 40, Graphics.FONT_XTINY, "UP/DOWN for Settings",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function drawClock(dc as Dc, width as Number) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.fillRectangle(0, 0, width, 45);

        var clockTime = System.getClockTime();
        var timeStr = clockTime.hour.format("%02d") + ":" + 
                      clockTime.min.format("%02d") + ":" + 
                      clockTime.sec.format("%02d");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 22, Graphics.FONT_MEDIUM, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function formatTime(seconds as Number) as String {
        var min = seconds / 60;
        var sec = seconds % 60;
        return min.format("%02d") + ":" + sec.format("%02d");
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        stopFinishedVibration();
    }

    // Load settings from storage
    function loadSettings() as Void {
        var d = Storage.getValue("duration");
        if (d != null && d instanceof Number) { gDurationSeconds = d as Number; }
        
        var a1 = Storage.getValue("alert1");
        if (a1 != null && a1 instanceof Number) { gAlert1Seconds = a1 as Number; }
        
        var a2 = Storage.getValue("alert2");
        if (a2 != null && a2 instanceof Number) { gAlert2Seconds = a2 as Number; }
        
        var clk = Storage.getValue("clock");
        if (clk != null && clk instanceof Boolean) { gShowClock = clk as Boolean; }
    }

    // Save settings to storage
    static function saveSettings() as Void {
        Storage.setValue("duration", gDurationSeconds);
        Storage.setValue("alert1", gAlert1Seconds);
        Storage.setValue("alert2", gAlert2Seconds);
        Storage.setValue("clock", gShowClock);
    }

    // Reset timer to ready state
    static function resetTimer() as Void {
        gStatus = STATUS_READY;
        gRemainingSeconds = gDurationSeconds;
        gAlert1Fired = false;
        gAlert2Fired = false;
    }
}
