# Touchpad Fix — Dell laptop (PixArt VEN_0488:00 0488:108C)

## Symptom
On Linux, moving a finger on the touchpad produces **no cursor motion**, while
physical button clicks still work. The pad works perfectly in Windows (dual-boot).

## Root cause
The hardware and the Linux kernel are fine — raw `evtest /dev/input/event5`
streams clean multitouch coordinates. The fault is in **libinput**.

libinput used **pressure-based touch detection** with auto-derived thresholds
(~3276–3932), but this PixArt pad's real `ABS_MT_PRESSURE` only reaches ~12 and
flickers between 0 and 1 during movement. As a result libinput classified every
touch as `TOUCH_HOVERING` / "palm detected (pressure)" and dropped it. Clicks are
not pressure-gated, which is why only finger motion broke.

## Fix
Disable the bogus pressure axes so libinput falls back to contact/tip-based touch
detection (same approach as the stock Asus UX302LA Elantech quirk). This is done
by writing a quirk to `/etc/libinput/local-overrides.quirks`:

```
[PixArt 0488:108C pressure fix]
MatchName=VEN_0488:00 0488:108C Touchpad
AttrEventCode=-ABS_MT_PRESSURE;-ABS_PRESSURE;
```

Run `./fix-touchpad.sh` to apply it automatically (it backs up any existing
quirks file first). You will be prompted for your sudo password.

## Verify
```
libinput debug-events --verbose
```
You should see lines about disabling `EV_ABS ABS_MT_PRESSURE`/`ABS_PRESSURE`, and
a clean `POINTER_MOTION` stream when you move your finger.

## Notes
- Works on the current kernel (6.17) — **no kernel downgrade needed**.
- Persists across reboots and package upgrades (it's user config under `/etc`).
- Wi-Fi and Bluetooth are unaffected.
