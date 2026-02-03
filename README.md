# Stand-up Timer

A simple, focused countdown timer for Garmin watches - perfect for stand-up meetings, lightning talks, and presentations.

![Garmin Watch App](https://img.shields.io/badge/Garmin-Connect%20IQ-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Countdown Timer**: 1-90 minutes duration
- **Two Alert Points**: Customizable warning times with visual feedback
  - Alert 1: Yellow color + 1 vibration
  - Alert 2: Magenta color + 2 vibrations
- **Final Countdown**: Per-second vibration for the last 5 seconds
- **Time's Up**: Long vibration and white screen when finished
- **Clock Display**: Current time shown at the top (toggleable)
- **Persistent Settings**: Your preferences are saved between sessions

## Controls

| State | Action | Result |
|-------|--------|--------|
| Ready | Tap / Select | Start timer |
| Ready | UP/DOWN | Open settings |
| Running | Tap / Select | Pause timer |
| Running | Back | Reset & restart |
| Paused | Tap / Select | Resume timer |
| Paused | Back | Reset & restart |
| Finished | Tap / Select | Reset to ready |
| Finished | Back | Reset to ready (no auto-start) |

## Settings

- **Duration**: Set timer length (1-90 minutes)
- **Alert 1**: First warning time (turns yellow)
  - Toggle on/off
  - Set custom time - *auto-set to half of duration when you change duration*
- **Alert 2**: Second warning time (turns magenta)
  - Toggle on/off
  - Set custom time - *default 1 minute, unchanged when duration changes*
- **Final Countdown**: Per-second vibration before finish
  - 5 seconds
  - 3 seconds
  - Off
- **Show Clock**: Toggle clock display at top
- **Exit App**: Close the application

### Alert Behavior
- When you change **Duration**, Alert 1 automatically adjusts to **half the duration**
- Alert 2 stays at your last setting (default: 1 minute before end)
- You can manually override both alerts anytime
- Alerts can be individually enabled/disabled

## Vibration Patterns

| Event | Pattern |
|-------|---------|
| Alert 1 | 1 vibration (500ms) |
| Alert 2 | 2 vibrations (500ms each) |
| Final 5 sec | Quick pulse each second |
| Time's up | 1 long vibration (1.5s) |

## Compatibility

Supports 80+ Garmin devices including:
- Fenix 5/6/7/8 series
- Forerunner 245/255/265/745/945/955/965
- Venu / Venu 2 / Venu 3
- Vivoactive 3/4/5
- D2 Delta / D2 Charlie
- MARQ series
- And many more...

## Building

### Prerequisites
- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
- Java 17+
- Developer key

### Build Commands

```bash
# Generate developer key (first time only)
openssl genrsa -out developer_key 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key -out developer_key.der -nocrypt

# Build for simulator
monkeyc -d d2deltapx -f monkey.jungle -o bin/standup-timer.prg -y path/to/developer_key.der

# Run in simulator
connectiq &
monkeydo bin/standup-timer.prg d2deltapx

# Build release package
monkeyc -e -d d2deltapx -f monkey.jungle -o bin/standup-timer.iq -y path/to/developer_key.der -r
```

## CI/CD

This project uses GitHub Actions to automatically build both production and beta versions.

### Setup

1. Encode your developer key as base64:
   ```bash
   base64 -i developer_key.der | tr -d '\n'
   ```

2. Add the output as a repository secret named `DEVELOPER_KEY_BASE64` in GitHub:
   - Go to Settings → Secrets and variables → Actions
   - Create new repository secret

### Builds

- **Production** (`standup-timer.iq`): Uses production app ID
- **Beta** (`standup-timer-beta.iq`): Uses separate beta app ID with "β" suffix in name

Builds are triggered on:
- Push to main/master branch
- Pull requests
- Manual workflow dispatch
- Git tags (creates GitHub release)

## License

MIT License - feel free to use and modify as needed.
