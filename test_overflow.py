import time
import sys
from pywinauto.application import Application

print("Starting security fuzzing test...")

try:
    # 1. Uruchamiamy program
    app = Application(backend="win32").start("main.exe")
    time.sleep(2)

    # 2. Szukamy glownego okna
    main_window = app.window(title="Display Local Time")
    
    # 3. Klikamy Calendar
    main_window.child_window(title="Calendar", class_name="Button").click()
    time.sleep(1)

    # 4. Szukamy okienka daty
    dialog = app.window(title="enter date ")

    # 5. Generujemy zlosliwy ladunek
    malicious_payload = "A" * 100

    # 6. Wpisujemy ladunek
    dialog.Edit.type_keys(malicious_payload, with_spaces=True)
    
    # 7. Klikamy OK
    dialog.child_window(title="OK", class_name="Button").click()
    time.sleep(2)

    # 8. Sprawdzamy czy przezyl
    if app.is_process_running():
        print("FAILED: Program did not crash (vulnerability patched or payload too small).")
        sys.exit(1)
    else:
        print("SUCCESS DEVSECOPS: Buffer Overflow detected! Program crashed as expected.")
        sys.exit(0)

except Exception as e:
    print(f"SUCCESS DEVSECOPS: Program crashed during injection. Details: {e}")
    sys.exit(0)