import time
import sys
from pywinauto.application import Application

print("Rozpoczynam test bezpieczeństwa (Fuzzing)...")

try:
    # 1. Uruchamiamy Twój program w Asemblerze
    app = Application(backend="win32").start("main.exe")
    time.sleep(2) # Czekamy aż okno się załaduje

    # 2. Łączymy się z głównym oknem (zgodnie z klasą Timer_Demo_Class)
    main_window = app.window(title="Display Local Time")
    
    # 3. Klikamy przycisk "Calendar", żeby otworzyć okno z datą
    main_window.child_window(title="Calendar", class_name="Button").click()
    time.sleep(1)

    # 4. Łączymy się z okienkiem dialogowym "enter date "
    dialog = app.window(title="enter date ")

    # 5. Generujemy złośliwy ładunek: 100 liter 'A' (znacznie powyżej Twoich 20 bajtów)
    malicious_payload = "A" * 100

    # 6. Wpisujemy ładunek do pola tekstowego (Edit)
    dialog.Edit.type_keys(malicious_payload, with_spaces=True)
    
    # 7. Klikamy OK, co wyzwoli funkcję z podatnym lstrcpy
    dialog.child_window(title="OK", class_name="Button").click()
    time.sleep(2)

    # 8. Sprawdzamy czy program przeżył
    if app.is_process_running():
        print("❌ Test zakończony niepowodzeniem: Program nie scrashował (luka zabezpieczona lub payload za mały).")
        sys.exit(1) # Zwraca błąd do GitHuba
    else:
        print("✅ SUKCES DEVSECOPS: Wykryto Buffer Overflow! Program uległ awarii (Crash).")
        sys.exit(0) # Zwraca sukces do GitHuba (skrypt zrobił swoje)

except Exception as e:
    print(f"✅ SUKCES DEVSECOPS: Program uległ awarii podczas wstrzykiwania! Szczegóły: {e}")
    sys.exit(0)