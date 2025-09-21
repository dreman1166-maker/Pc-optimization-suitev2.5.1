
import pyautogui
import threading
import time
import keyboard
import tkinter as tk
import traceback
import datetime
import sys
import platform
if platform.system() == 'Windows':
    import ctypes
    import win32gui
    import win32con

pyautogui.PAUSE = 0  # No Pause between keyDown/keyUp
# Safe Standartbuttons (without Windows-/System-Buttons)
keys = [
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','q','r','s','t','u','v','w','x','y','z',
    '0','1','2','3','4','5','6','7','8','9',]




# Settings
TARGET_CPS = 10  # Lowered to 10 CPS for better compatibility
Interval = 1.0 / TARGET_CPS  # Seconds between button presses
key_to_press = 'space'  # Additional press
toggle_key = 'p'  # Start/Stop with button 'p'
mode_toggle_key = 'o'  # Toggle between keyboard and mouse automation with 'o'


# Control-Status
running = False
use_mouse = False
lock = threading.Lock()

def is_bongo_cat_active():
    if platform.system() != 'Windows':
        return True  # Only implemented for Windows
    try:
        hwnd = win32gui.GetForegroundWindow()
        window_title = win32gui.GetWindowText(hwnd)
        # Match exact window title for Bongo Cat
        return window_title.strip() == 'BongoCat'
    except Exception as e:
        print(f"Error checking active window: {e}")
        return False

def is_mouse_over_taskbar():
    if platform.system() != 'Windows':
        return False
    try:
        # Get screen size
        user32 = ctypes.windll.user32
        screen_width = user32.GetSystemMetrics(0)
        screen_height = user32.GetSystemMetrics(1)
        # Get mouse position
        pt = ctypes.wintypes.POINT()
        user32.GetCursorPos(ctypes.byref(pt))
        x, y = pt.x, pt.y
        # Get taskbar position and size
        taskbar_hwnd = win32gui.FindWindow('Shell_TrayWnd', None)
        if not taskbar_hwnd:
            return False
        rect = win32gui.GetWindowRect(taskbar_hwnd)
        left, top, right, bottom = rect
        # Check if mouse is within taskbar rect
        return left <= x <= right and top <= y <= bottom
    except Exception as e:
        print(f"Error checking taskbar hover: {e}")
        return False

import psutil

def log_error(err_msg):
    with open('autokey_error.log', 'a') as f:
        f.write(f"[{datetime.datetime.now()}] {err_msg}\n")

def suggest_fix(err_msg):
    # Placeholder for AI suggestion system
    print("[AutoKey] Suggestion: Please review the error log and consider searching for solutions or asking an AI assistant.")
    print(f"[AutoKey] Error: {err_msg}")

def auto_press():
    global use_mouse, Interval, running
    min_interval = 0.05  # Hard minimum: 50ms (20 CPS)
    max_interval = 0.1   # Don't go above 0.1s (10 CPS)
    adjust_step = 1.1    # How much to adjust interval by (10%)
    cpu_threshold = 90   # % CPU usage to trigger slowdown
    mem_threshold = 90   # % memory usage to trigger slowdown
    failsafe_triggered = False
    while True:
        try:
            with lock:
                if running and is_bongo_cat_active() and not is_mouse_over_taskbar():
                    # Adaptive protection: check CPU and memory usage
                    cpu = psutil.cpu_percent(interval=None)
                    mem = psutil.virtual_memory().percent
                    if cpu > cpu_threshold or mem > mem_threshold:
                        Interval = min(max_interval, Interval * adjust_step)
                        print(f"[AutoKey] High resource usage detected (CPU: {cpu}%, MEM: {mem}%), slowing down: Interval={Interval:.8f}s")
                        if not failsafe_triggered:
                            print("[AutoKey] Failsafe: Automation paused due to high system load. Press F9 to reset.")
                            failsafe_triggered = True
                            running = False
                    elif Interval > min_interval:
                        # Try to speed up if system is fine
                        Interval = max(min_interval, Interval / adjust_step)
                        failsafe_triggered = False
                    if use_mouse:
                        try:
                            pyautogui.click()
                            pyautogui.press('space')
                        except Exception as e:
                            err_msg = f"Error at mouse click or spacebar: {e}\n{traceback.format_exc()}"
                            log_error(err_msg)
                            suggest_fix(err_msg)
                    else:
                        for key in keys:
                            # press all buttons
                            try:
                                pyautogui.keyDown(key)
                            except Exception as e:
                                err_msg = f"Error at {key} (keyDown): {e}\n{traceback.format_exc()}"
                                log_error(err_msg)
                                suggest_fix(err_msg)

                        # let go of all buttons
                        for key in keys:
                            try:
                                pyautogui.keyUp(key)
                            except Exception as e:
                                err_msg = f"Error at {key} (keyUp): {e}\n{traceback.format_exc()}"
                                log_error(err_msg)
                                suggest_fix(err_msg)
                        try:
                            pyautogui.keyDown(key_to_press)
                            pyautogui.keyUp(key_to_press)
                        except Exception as e:
                            err_msg = f"Error at {key_to_press}: {e}\n{traceback.format_exc()}"
                            log_error(err_msg)
                            suggest_fix(err_msg)
            time.sleep(Interval)
        except Exception as e:
            err_msg = f"Critical error in auto_press: {e}\n{traceback.format_exc()}"
            log_error(err_msg)
            suggest_fix(err_msg)

def manual_reset():
    global Interval, running
    while True:
        keyboard.wait('f9')
        with lock:
            Interval = 0.05  # Reset to safe default
            running = False
            print("[AutoKey] Manual reset: Interval set to 0.05s (20 CPS), automation stopped. Press 'p' to start again.")
def toggle_mode():
    global use_mouse
    while True:
        keyboard.wait(mode_toggle_key)
        with lock:
            use_mouse = not use_mouse
            print("Mouse click mode ON" if use_mouse else "Keyboard mode ON")

def toggle_running():
    global running
    while True:
        keyboard.wait(toggle_key)
        with lock:
            running = not running
            print("Started" if running else "stopped")

def exit_on_f12():
    keyboard.wait('f12')
    print("\nClosing Program...")
    root.destroy()
    root.quit()

root = tk.Tk()
root.withdraw() 



# Start threads
threading.Thread(target=auto_press, daemon=True).start()
threading.Thread(target=toggle_running, daemon=True).start()
threading.Thread(target=toggle_mode, daemon=True).start()
threading.Thread(target=exit_on_f12, daemon=True).start()
threading.Thread(target=manual_reset, daemon=True).start()

print("Press 'p' to Start/Stop. Press 'o' to toggle between keyboard and mouse click mode. Press 'F12' to close. Press 'F9' to reset if failsafe triggers.")
print("Automation will only run when the Bongo Cat window is active and the mouse is not over the taskbar.")
print("Failsafe protection enabled: If your PC slows down, AutoKey will pause and require manual reset (F9). Minimum interval is 0.05s (20 CPS). Adaptive protection is also active.")

# Tkinter-Mainloop
root.mainloop()
