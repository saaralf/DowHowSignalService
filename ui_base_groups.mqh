#ifndef __UI_BASE_GROUPS_MQH__
#define __UI_BASE_GROUPS_MQH__

/**
 * Beschreibung: Gemeinsame Mini-Utilities für UI-Gruppen (Create/Set/Delete).
 * Parameter:    -
 * Rückgabewert: -
 * Hinweise:     Nur Chart-Objekte (OBJ_BUTTON/OBJ_EDIT). Keine CDialog Controls hier.
 * Fehlerfälle:  ObjectCreate/ObjectSet* kann fehlschlagen -> Logs via GetLastError().
 */
class CUIObjUtil
{
public:
   /**
    * Beschreibung: Prüft, ob ein Chart-Objekt existiert.
    * Parameter:    chart_id - Chart-ID (meist 0)
    *               name     - Objektname
    * Rückgabewert: bool - true wenn vorhanden
    * Hinweise:     ObjectFind gibt Index >=0 wenn vorhanden.
    * Fehlerfälle:  keine
    */
   static bool Exists(const long chart_id, const string name)
   {
      return (ObjectFind(chart_id, name) >= 0);
   }

   /**
    * Beschreibung: Löscht ein Objekt, wenn es existiert (silent).
    * Parameter:    chart_id - Chart-ID
    *               name     - Objektname
    * Rückgabewert: bool - true wenn gelöscht oder nicht vorhanden
    * Hinweise:     Kein Fehler, wenn Objekt nicht existiert.
    * Fehlerfälle:  ObjectDelete kann fehlschlagen (Print + GetLastError)
    */
   static bool DeleteIfExists(const long chart_id, const string name)
   {
      if(!Exists(chart_id, name))
         return true;

      ResetLastError();
      if(!ObjectDelete(chart_id, name))
      {
         const int err = GetLastError();
         Print("UI: ObjectDelete failed name='", name, "' err=", err);
         return false;
      }
      return true;
   }

   /**
    * Beschreibung: Erstellt/konfiguriert einen Button (Chart-Objekt).
    * Parameter:    chart_id - Chart-ID
    *               name     - Objektname
    *               x,y,w,h  - Position/Größe in Pixeln
    *               text     - Button Text
    *               bg       - Background Color
    *               fg       - Text Color
    * Rückgabewert: bool - true wenn ok
    * Hinweise:     Wenn existiert: nur Properties updaten.
    * Fehlerfälle:  ObjectCreate/ObjectSetInteger/ObjectSetString kann fehlschlagen.
    */
   static bool CreateOrUpdateButton(const long chart_id,
                                   const string name,
                                   const int x, const int y, const int w, const int h,
                                   const string text,
                                   const color bg, const color fg)
   {
      if(!Exists(chart_id, name))
      {
         ResetLastError();
         if(!ObjectCreate(chart_id, name, OBJ_BUTTON, 0, 0, 0))
         {
            const int err = GetLastError();
            Print("UI: ObjectCreate(OBJ_BUTTON) failed name='", name, "' err=", err);
            return false;
         }
      }

      ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(chart_id, name, OBJPROP_XSIZE,     w);
      ObjectSetInteger(chart_id, name, OBJPROP_YSIZE,     h);

      ObjectSetInteger(chart_id, name, OBJPROP_COLOR,     fg);
      ObjectSetInteger(chart_id, name, OBJPROP_BGCOLOR,   bg);

      ObjectSetInteger(chart_id, name, OBJPROP_BACK,      false);
      ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN,    true);
      ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE,true);

      ObjectSetString(chart_id,  name, OBJPROP_TEXT,      text);

      return true;
   }

   /**
    * Beschreibung: Erstellt/konfiguriert ein Editfeld (Chart-Objekt).
    * Parameter:    chart_id - Chart-ID
    *               name     - Objektname
    *               x,y,w,h  - Position/Größe
    *               text     - Initialtext
    *               bg, fg   - Farben
    * Rückgabewert: bool
    * Hinweise:     OBJ_EDIT ist ein Chart-Objekt, Text via OBJPROP_TEXT.
    * Fehlerfälle:  ObjectCreate/ObjectSet* kann fehlschlagen.
    */
   static bool CreateOrUpdateEdit(const long chart_id,
                                 const string name,
                                 const int x, const int y, const int w, const int h,
                                 const string text,
                                 const color bg, const color fg)
   {
      if(!Exists(chart_id, name))
      {
         ResetLastError();
         if(!ObjectCreate(chart_id, name, OBJ_EDIT, 0, 0, 0))
         {
            const int err = GetLastError();
            Print("UI: ObjectCreate(OBJ_EDIT) failed name='", name, "' err=", err);
            return false;
         }
      }

      ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(chart_id, name, OBJPROP_XSIZE,     w);
      ObjectSetInteger(chart_id, name, OBJPROP_YSIZE,     h);

      ObjectSetInteger(chart_id, name, OBJPROP_COLOR,     fg);
      ObjectSetInteger(chart_id, name, OBJPROP_BGCOLOR,   bg);

      ObjectSetInteger(chart_id, name, OBJPROP_BACK,      false);
      ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN,    true);
      ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE,true);

      ObjectSetString(chart_id,  name, OBJPROP_TEXT,      text);

      return true;
   }

   /**
    * Beschreibung: Liest Text aus OBJ_EDIT/OBJ_BUTTON (OBJPROP_TEXT).
    * Parameter:    chart_id - Chart-ID
    *               name     - Objektname
    * Rückgabewert: string - Text (leer falls nicht vorhanden)
    * Hinweise:     Für Edit/Buttons gleich.
    * Fehlerfälle:  ObjectGetString kann fehlschlagen -> leer.
    */
   static string GetText(const long chart_id, const string name)
   {
      string out = "";
      if(!Exists(chart_id, name))
         return out;

      ObjectGetString(chart_id, name, OBJPROP_TEXT, 0, out);
      return out;
   }
};

/**
 * Beschreibung: Callback-Interface für Entry-Gruppe (z.B. SendButton Verhalten).
 * Parameter:    -
 * Rückgabewert: -
 * Hinweise:     Du kannst später eine konkrete Handler-Klasse an g_entry_ui.SetHandler() übergeben.
 * Fehlerfälle:  keine
 */
class IEntryGroupHandler
{
public:
   /**
    * Beschreibung: Wird aufgerufen, wenn der Send-Button der Entry-Gruppe geklickt wurde.
    * Parameter:    trade_no     - TRNB (int)
    *               pos_no       - POSNB (int)
    *               sabio_entry  - SabioEntry (double)
    * Rückgabewert: void
    * Hinweise:     Default: nur Print. Ersetze per eigener Handler-Implementierung.
    * Fehlerfälle:  keine
    */
   virtual void OnSendClicked(const int trade_no, const int pos_no, const double sabio_entry)
   {
      Print("EntryGroup: OnSendClicked trade=", trade_no, " pos=", pos_no, " sabio_entry=", DoubleToString(sabio_entry, 2));
   }
};

/**
 * Beschreibung: UI-Gruppe #1: EntryButton + TRNB + POSNB + SendTradeBtn + SabioEntry.
 * Parameter:    -
 * Rückgabewert: -
 * Hinweise:     Fokus: Objekte erzeugen, Layout, Werte lesen, Send-Klick handeln.
 * Fehlerfälle:  Create kann scheitern (ObjectCreate). Logs im Journal.
 */
class CEntryGroupUI
{
private:
   long   m_chart_id;
   bool   m_created;

   // Objekt-Namen (aus deinem Projekt via Init())
   string m_entry_btn;
   string m_trnb_edit;
   string m_posnb_edit;
   string m_send_btn;
   string m_sabio_entry_edit;

   // Layout
   int    m_right_margin;
   int    m_top_y;

   // Theme (einfach gehalten)
   color  m_bg;
   color  m_fg;
   color  m_btn_bg;
   color  m_btn_fg;

   IEntryGroupHandler *m_handler;

public:
   /**
    * Beschreibung: Initialisiert die Gruppe (Objektnamen + Layout Defaults).
    * Parameter:    chart_id          - Chart-ID (0)
    *               entry_btn         - Name EntryButton
    *               trnb_edit         - Name TRNB
    *               posnb_edit        - Name POSNB
    *               send_btn          - Name SENDTRADEBTN
    *               sabio_entry_edit  - Name SabioEntry
    * Rückgabewert: void
    * Hinweise:     Init erzeugt noch nichts; Create() macht ObjectCreate.
    * Fehlerfälle:  keine
    */
   void Init(const long chart_id,
             const string entry_btn,
             const string trnb_edit,
             const string posnb_edit,
             const string send_btn,
             const string sabio_entry_edit)
   {
      m_chart_id = chart_id;
      m_created  = false;

      m_entry_btn = entry_btn;
      m_trnb_edit = trnb_edit;
      m_posnb_edit = posnb_edit;
      m_send_btn  = send_btn;
      m_sabio_entry_edit = sabio_entry_edit;

      m_right_margin = 12;
      m_top_y        = 40;

      // Farben: neutral/lesbar; du kannst das später an Entry/SL Theme koppeln
      m_bg     = clrBlack;
      m_fg     = clrWhite;
      m_btn_bg = clrTeal;     // Entry-Gruppe wirkt "aktiv"
      m_btn_fg = clrBlack;

      m_handler = NULL;
      
   }

   /**
    * Beschreibung: Setzt optional einen Handler (für Send-Click).
    * Parameter:    handler - Pointer auf IEntryGroupHandler
    * Rückgabewert: void
    * Hinweise:     Wenn NULL: Default-Verhalten (Print).
    * Fehlerfälle:  keine
    */
   void SetHandler(IEntryGroupHandler *handler)
   {
      m_handler = handler;
   }

   /**
    * Beschreibung: Erzeugt alle Objekte der Entry-Gruppe und positioniert sie.
    * Parameter:    right_margin - Abstand zum rechten Rand
    *               top_y        - Start Y in Pixeln
    * Rückgabewert: bool - true wenn ok
    * Hinweise:     Layout ist kompakt: [EntryButton] oben, darunter TRNB/POSNB, darunter SabioEntry, darunter Send.
    * Fehlerfälle:  ObjectCreate kann fehlschlagen -> Journal prüfen.
    */
   bool Create(const int right_margin, const int top_y)
   {
      m_right_margin = right_margin;
      m_top_y        = top_y;

      const int w_btn  = 130;
      const int h_btn  = 22;
      const int w_edit = 62;
      const int h_edit = 20;
      const int gap    = 6;

      int chart_w = (int)ChartGetInteger(m_chart_id, CHART_WIDTH_IN_PIXELS, 0);
      int x0 = chart_w - m_right_margin - w_btn;

      // Entry Button
      if(!CUIObjUtil::CreateOrUpdateButton(m_chart_id, m_entry_btn, x0, m_top_y, w_btn, h_btn,
                                          "ENTRY", m_btn_bg, m_btn_fg))
         return false;

      // TRNB / POSNB nebeneinander
      int y1 = m_top_y + h_btn + gap;
      if(!CUIObjUtil::CreateOrUpdateEdit(m_chart_id, m_trnb_edit, x0, y1, w_edit, h_edit, "1", m_bg, m_fg))
         return false;

      if(!CUIObjUtil::CreateOrUpdateEdit(m_chart_id, m_posnb_edit, x0 + w_edit + gap, y1, w_edit, h_edit, "1", m_bg, m_fg))
         return false;

      // SabioEntry (breit)
      int y2 = y1 + h_edit + gap;
      if(!CUIObjUtil::CreateOrUpdateEdit(m_chart_id, m_sabio_entry_edit, x0, y2, w_btn, h_edit, "", m_bg, m_fg))
         return false;

      // Send Button
      int y3 = y2 + h_edit + gap;
      if(!CUIObjUtil::CreateOrUpdateButton(m_chart_id, m_send_btn, x0, y3, w_btn, h_btn,
                                          "SEND", clrLime, clrBlack))
         return false;

      m_created = true;
      return true;
   }

   /**
    * Beschreibung: Löscht alle Objekte der Entry-Gruppe.
    * Parameter:    -
    * Rückgabewert: void
    * Hinweise:     Safe delete (wenn nicht existiert, ok).
    * Fehlerfälle:  Delete kann fehlschlagen -> Journal.
    */
   void Destroy()
   {
      CUIObjUtil::DeleteIfExists(m_chart_id, m_entry_btn);
      CUIObjUtil::DeleteIfExists(m_chart_id, m_trnb_edit);
      CUIObjUtil::DeleteIfExists(m_chart_id, m_posnb_edit);
      CUIObjUtil::DeleteIfExists(m_chart_id, m_sabio_entry_edit);
      CUIObjUtil::DeleteIfExists(m_chart_id, m_send_btn);
      m_created = false;
   }

   /**
    * Beschreibung: True wenn Gruppe erzeugt wurde.
    * Parameter:    -
    * Rückgabewert: bool
    * Hinweise:     Nur interner Status.
    * Fehlerfälle:  keine
    */
   bool IsCreated() const { return m_created; }

   /**
    * Beschreibung: Liest TRNB als int aus dem Edit.
    * Parameter:    -
    * Rückgabewert: int - tradenummer (0 wenn leer/invalid)
    * Hinweise:     StringToInteger.
    * Fehlerfälle:  keine
    */
   int GetTradeNo() const
   {
      string t = CUIObjUtil::GetText(m_chart_id, m_trnb_edit);
      return (int)StringToInteger(t);
   }

   /**
    * Beschreibung: Liest POSNB als int aus dem Edit.
    * Parameter:    -
    * Rückgabewert: int
    * Hinweise:     StringToInteger.
    * Fehlerfälle:  keine
    */
   int GetPosNo() const
   {
      string t = CUIObjUtil::GetText(m_chart_id, m_posnb_edit);
      return (int)StringToInteger(t);
   }

   /**
    * Beschreibung: Liest SabioEntry als double aus dem Edit.
    * Parameter:    -
    * Rückgabewert: double
    * Hinweise:     Akzeptiert "" -> 0.0.
    * Fehlerfälle:  keine
    */
   double GetSabioEntry() const
   {
      string t = CUIObjUtil::GetText(m_chart_id, m_sabio_entry_edit);
      return StringToDouble(t);
   }

   /**
    * Beschreibung: Entry-Gruppe Event-Handler (aktuell: Send Button Click).
    * Parameter:    id,lparam,dparam,sparam - OnChartEvent Parameter
    * Rückgabewert: bool - true wenn Event konsumiert wurde
    * Hinweise:     In Etappe 2 können wir hier Button-Drag migrieren.
    * Fehlerfälle:  keine (Handler kann NULL sein).
    */
   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
      if(!m_created) return false;

      if(id == CHARTEVENT_OBJECT_CLICK)
      {
         if(sparam == m_send_btn)
         {
            const int trade_no = GetTradeNo();
            const int pos_no   = GetPosNo();
            const double sabio = GetSabioEntry();

            // Handler: wenn keiner gesetzt, Default Print
            if(m_handler != NULL) m_handler.OnSendClicked(trade_no, pos_no, sabio);
            else
            {
               IEntryGroupHandler def;
               def.OnSendClicked(trade_no, pos_no, sabio);
            }
            return true;
         }
      }
      return false;
   }
};

/**
 * Beschreibung: UI-Gruppe #2: SLButton + SabioSL.
 * Parameter:    -
 * Rückgabewert: -
 * Hinweise:     Fokus: Objekte erzeugen, Layout, Werte lesen.
 * Fehlerfälle:  Create kann scheitern -> Journal.
 */
class CSLGroupUI
{
private:
   long   m_chart_id;
   bool   m_created;

   string m_sl_btn;
   string m_sabio_sl_edit;

   int    m_right_margin;
   int    m_top_y;

   color  m_bg;
   color  m_fg;
   color  m_btn_bg;
   color  m_btn_fg;

public:
   /**
    * Beschreibung: Initialisiert Namen/Defaults.
    * Parameter:    chart_id       - Chart-ID (0)
    *               sl_btn         - Name SLButton
    *               sabio_sl_edit  - Name SabioSL
    * Rückgabewert: void
    * Hinweise:     Create() erzeugt Objekte.
    * Fehlerfälle:  keine
    */
   void Init(const long chart_id,
             const string sl_btn,
             const string sabio_sl_edit)
   {
      m_chart_id = chart_id;
      m_created  = false;

      m_sl_btn = sl_btn;
      m_sabio_sl_edit = sabio_sl_edit;

      m_right_margin = 12;
      m_top_y        = 140;

      m_bg     = clrBlack;
      m_fg     = clrWhite;
      m_btn_bg = clrMaroon;   // SL-Gruppe "rot"
      m_btn_fg = clrWhite;
   }

   /**
    * Beschreibung: Erzeugt SLButton + SabioSL.
    * Parameter:    right_margin - Abstand rechts
    *               top_y        - Start Y
    * Rückgabewert: bool
    * Hinweise:     Layout: SLButton oben, SabioSL darunter.
    * Fehlerfälle:  ObjectCreate kann fehlschlagen.
    */
   bool Create(const int right_margin, const int top_y)
   {
      m_right_margin = right_margin;
      m_top_y        = top_y;

      const int w_btn  = 130;
      const int h_btn  = 22;
      const int h_edit = 20;
      const int gap    = 6;

      int chart_w = (int)ChartGetInteger(m_chart_id, CHART_WIDTH_IN_PIXELS, 0);
      int x0 = chart_w - m_right_margin - w_btn;

      if(!CUIObjUtil::CreateOrUpdateButton(m_chart_id, m_sl_btn, x0, m_top_y, w_btn, h_btn,
                                          "SL", m_btn_bg, m_btn_fg))
         return false;

      int y1 = m_top_y + h_btn + gap;
      if(!CUIObjUtil::CreateOrUpdateEdit(m_chart_id, m_sabio_sl_edit, x0, y1, w_btn, h_edit,
                                         "", clrBlack, clrWhite))
         return false;

      m_created = true;
      return true;
   }

   /**
    * Beschreibung: Löscht Objekte der SL-Gruppe.
    * Parameter:    -
    * Rückgabewert: void
    * Hinweise:     Safe delete.
    * Fehlerfälle:  Delete kann fehlschlagen -> Journal.
    */
   void Destroy()
   {
      CUIObjUtil::DeleteIfExists(m_chart_id, m_sl_btn);
      CUIObjUtil::DeleteIfExists(m_chart_id, m_sabio_sl_edit);
      m_created = false;
   }

   /**
    * Beschreibung: True wenn erstellt.
    * Parameter:    -
    * Rückgabewert: bool
    * Hinweise:     -
    * Fehlerfälle:  keine
    */
   bool IsCreated() const { return m_created; }

   /**
    * Beschreibung: Liest SabioSL als double.
    * Parameter:    -
    * Rückgabewert: double
    * Hinweise:     "" -> 0.0
    * Fehlerfälle:  keine
    */
   double GetSabioSL() const
   {
      string t = CUIObjUtil::GetText(m_chart_id, m_sabio_sl_edit);
      return StringToDouble(t);
   }

   /**
    * Beschreibung: SL-Gruppe Event-Handler (derzeit keine Klick-Action).
    * Parameter:    id,lparam,dparam,sparam - OnChartEvent Parameter
    * Rückgabewert: bool - true wenn konsumiert
    * Hinweise:     In Etappe 2 können wir SLButton-Drag hier migrieren.
    * Fehlerfälle:  keine
    */
   bool OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
      if(!m_created) return false;
      return false;
   }
};



// Optional: eigener Handler, der deine echte Send-Logik triggert
class CMyEntryHandler : public IEntryGroupHandler
{
public:
   void OnSendClicked(const int trade_no, const int pos_no, const double sabio_entry)
   {
      // TODO: Hier deine vorhandene Send-Logik aufrufen (DiscordSend / TradeManager / DB etc.)
      Print("SEND -> trade=", trade_no, " pos=", pos_no, " sabio_entry=", DoubleToString(sabio_entry, 2));
   }
};

CMyEntryHandler g_entry_handler;

#endif // __UI_BASE_GROUPS_MQH__
