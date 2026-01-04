#ifndef __CLASS_SEND_BUTTON_CONTROLLER__
#define __CLASS_SEND_BUTTON_CONTROLLER__


/**
 * Beschreibung: Controller für den Send-Button. Kapselt die Klick-Logik (inkl. Sabio-Confirm),
 *               damit OnChartEvent nicht weiter anwächst und die Klick-Logik nur genau 1x existiert.
 * Parameter:    none
 * Rückgabewert: none
 * Hinweise:     Ruft DiscordSend() auf. Setzt Button-State zurück (OBJPROP_STATE=0).
 * Fehlerfälle:  Wenn SENDTRADEBTN nicht existiert: Logausgabe, aber kein Crash.
 */
class CSendButtonController
  {
public:
   /**
    * Beschreibung: Behandelt OBJECT_CLICK auf SENDTRADEBTN.
    * Parameter:    obj_name - sparam aus OnChartEvent
    * Rückgabewert: bool - true wenn Event verarbeitet wurde
    * Hinweise:     Sabioedit==true -> Confirmation Dialog.
    * Fehlerfälle:  MessageBox liefert nicht IDYES -> Send wird abgebrochen (gewollt).
    */
   bool OnObjectClick(const string obj_name)
     {
      if(obj_name != SENDTRADEBTN)
         return false;

      // Button "nicht gedrückt" setzen (UI-Konsistenz)
      UI_ObjSetIntSafe(0, SENDTRADEBTN, OBJPROP_STATE, 0);

      // Optional: Sabio Confirmation
      if(Sabioedit == true)
        {
         int result = MessageBox(
            "Du hast Sabio an. Willst du wirklich senden?\n\n"
            "Wenn du Sabio nicht senden willst, schalte Sabio aus.",
            "Sabio Confirm",
            MB_YESNO | MB_ICONQUESTION
         );

         if(result != IDYES)
           {
            Print("Send abgebrochen (Sabio Confirm = NO).");
            return true; // Klick wurde verarbeitet (nur abgebrochen)
           }
        }

      // Senden
      DiscordSend();
      return true;
     }
  };

// Global (file-scope) – genau 1 Instanz
static CSendButtonController g_send_ctl;




#endif // __CLASS_SEND_BUTTON_CONTROLLER__