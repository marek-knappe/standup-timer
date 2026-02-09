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
var gAlert1Seconds as Number = 450;        // Half of duration (7:30)
var gAlert2Seconds as Number = 60;         // 1 min before end
var gAlert1Fired as Boolean = false;
var gAlert2Fired as Boolean = false;
var gAlert1Enabled as Boolean = true;      // Alert 1 on/off
var gAlert2Enabled as Boolean = true;      // Alert 2 on/off
var gFinalCountdown as Number = 5;         // 5, 3, or 0 (none)
var gShowClock as Boolean = true;
var gDarkMode as Boolean = true;           // Dark mode (true) or Light mode (false)
var gTimerView as TimerView?;

class TimerView extends WatchUi.View {
    private var _timer as Timer.Timer?;
    private var _vibeTimer as Timer.Timer?;
    private var _tickCount as Number = 0;

    function initialize() {
        View.initialize();
        loadSettings();
        gRemainingSeconds = gDurationSeconds;
        gTimerView = self;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        // Stop any existing timer first to prevent duplicates
        if (_timer != null) {
            _timer.stop();
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 1000, true);
        _tickCount = 0;
    }

    function onTick() as Void {
        _tickCount++;
        if (gStatus == STATUS_RUNNING) {
            if (gRemainingSeconds > 0) {
                gRemainingSeconds -= 1;
                checkAlerts();
            }
            if (gRemainingSeconds <= 0) {
                gStatus = STATUS_FINISHED;
                startFinishedVibration();
            }
            WatchUi.requestUpdate();
        } else if (gShowClock) {
            // Update once per minute for clock display (READY, PAUSED, or FINISHED)
            if (_tickCount >= 60) {
                _tickCount = 0;
                WatchUi.requestUpdate();
            }
        }
        // No updates needed when clock is hidden and not running
    }

    private function checkAlerts() as Void {
        // Alert 1: 1 vibration (yellow warning)
        if (gAlert1Enabled && !gAlert1Fired && gRemainingSeconds <= gAlert1Seconds && gRemainingSeconds > gAlert2Seconds) {
            gAlert1Fired = true;
            vibrate([new Attention.VibeProfile(100, 500)]);
        }
        
        // Alert 2: 2 vibrations (magenta warning)
        if (gAlert2Enabled && !gAlert2Fired && gRemainingSeconds <= gAlert2Seconds && gRemainingSeconds > gFinalCountdown) {
            gAlert2Fired = true;
            vibrate([
                new Attention.VibeProfile(100, 500),
                new Attention.VibeProfile(0, 300),
                new Attention.VibeProfile(100, 500)
            ]);
        }
        
        // Final countdown - short pulse each second (if enabled)
        if (gFinalCountdown > 0 && gRemainingSeconds <= gFinalCountdown && gRemainingSeconds >= 1) {
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

        // Determine colors based on state and dark/light mode
        var bgColor = gDarkMode ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var textColor = gDarkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var statusText = "";

        if (gStatus == STATUS_FINISHED) {
            // Invert colors when finished
            bgColor = gDarkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            textColor = gDarkMode ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            statusText = "TIME'S UP!";
        } else if (gStatus == STATUS_PAUSED) {
            textColor = gDarkMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
            statusText = "PAUSED";
        } else if (gStatus == STATUS_READY) {
            statusText = "READY";
        } else if (gStatus == STATUS_RUNNING) {
            statusText = "RUNNING";
            // Color changes for alerts (only if enabled)
            if (gFinalCountdown > 0 && gRemainingSeconds <= gFinalCountdown) {
                textColor = 0xFF00FF; // Magenta for final countdown
            } else if (gAlert2Enabled && gRemainingSeconds <= gAlert2Seconds) {
                textColor = 0xFF00FF; // Magenta
            } else if (gAlert1Enabled && gRemainingSeconds <= gAlert1Seconds) {
                textColor = gDarkMode ? Graphics.COLOR_YELLOW : 0xCC8800; // Darker yellow for light mode
            }
        }

        // Clear background
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // Draw clock at top
        var timerY = height / 2;
        if (gShowClock) {
            drawClock(dc, width);
            timerY = height / 2 + 15;
        }

        // Draw remaining time
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        var timeStr = formatTime(gRemainingSeconds);
        dc.drawText(width / 2, timerY - 25, Graphics.FONT_NUMBER_HOT, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw status below timer
        dc.drawText(width / 2, timerY + 45, Graphics.FONT_SMALL, statusText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    }

    private function drawClock(dc as Dc, width as Number) as Void {
        var clockBg = gDarkMode ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
        var clockText = gDarkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        
        // Move clock bar down for round screens
        dc.setColor(clockBg, clockBg);
        dc.fillRectangle(0, 20, width, 35);

        var clockTime = System.getClockTime();
        var timeStr;
        if (gStatus == STATUS_RUNNING) {
            // Show seconds only when timer is running
            timeStr = clockTime.hour.format("%02d") + ":" + 
                      clockTime.min.format("%02d") + ":" + 
                      clockTime.sec.format("%02d");
        } else {
            // Hide seconds when not running (saves power - no need for per-second updates)
            timeStr = clockTime.hour.format("%02d") + ":" + 
                      clockTime.min.format("%02d");
        }

        dc.setColor(clockText, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 38, Graphics.FONT_SMALL, timeStr,
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
        
        var a1e = Storage.getValue("alert1en");
        if (a1e != null && a1e instanceof Boolean) { gAlert1Enabled = a1e as Boolean; }
        
        var a2e = Storage.getValue("alert2en");
        if (a2e != null && a2e instanceof Boolean) { gAlert2Enabled = a2e as Boolean; }
        
        var fc = Storage.getValue("finalcd");
        if (fc != null && fc instanceof Number) { gFinalCountdown = fc as Number; }
        
        var clk = Storage.getValue("clock");
        if (clk != null && clk instanceof Boolean) { gShowClock = clk as Boolean; }
        
        var dm = Storage.getValue("darkmode");
        if (dm != null && dm instanceof Boolean) { gDarkMode = dm as Boolean; }
    }

    // Save settings to storage
    static function saveSettings() as Void {
        Storage.setValue("duration", gDurationSeconds);
        Storage.setValue("alert1", gAlert1Seconds);
        Storage.setValue("alert2", gAlert2Seconds);
        Storage.setValue("alert1en", gAlert1Enabled);
        Storage.setValue("alert2en", gAlert2Enabled);
        Storage.setValue("finalcd", gFinalCountdown);
        Storage.setValue("clock", gShowClock);
        Storage.setValue("darkmode", gDarkMode);
    }

    // Reset timer to ready state
    static function resetTimer() as Void {
        gStatus = STATUS_READY;
        gRemainingSeconds = gDurationSeconds;
        gAlert1Fired = false;
        gAlert2Fired = false;
        // Restart the timer if it was stopped (e.g., after finishing)
        if (gTimerView != null) {
            gTimerView.ensureTimerRunning();
        }
    }
    
    // Ensure the background timer is running (for screen updates)
    function ensureTimerRunning() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
            _timer.start(method(:onTick), 1000, true);
            _tickCount = 0;
        }
    }
}
