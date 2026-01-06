/**
 * Beschreibung: Kapselt den kompletten Drag-State einer TradePos-Linie (Entry/SL je Trade/Pos),
 *               damit Discord/DB nur 1x pro Drag feuern und keine globalen g_tp_drag_* nötig sind.
 * Parameter:    none
 * Rückgabewert: none
 * Hinweise:     Finalize wird sowohl über OBJECT_CHANGE als auch über MouseUp-Fallback getriggert.
 * Fehlerfälle:  Objekt existiert nicht mehr -> Reset ohne Crash.
 */
class CTradePosLineDragController
  {
private:
   bool   m_active;
   string m_name;
   string m_dir;        // "LONG"/"SHORT"
   string m_kind;       // "entry"/"sl"
   int    m_trade_no;
   int    m_pos_no;
   double m_old_price;
   double m_last_price;
   uint   m_last_redraw_ms;

public:
   /**
    * Beschreibung: Konstruktor, initialisiert State.
    * Parameter:    none
    * Rückgabewert: none
    * Hinweise:     Reset() setzt alles in einen definierten Zustand.
    * Fehlerfälle:  keine
    */
   CTradePosLineDragController()
     {
      Reset();
     }

   /**
    * Beschreibung: Liefert ob gerade ein TradePos-Drag aktiv ist.
    * Parameter:    none
    * Rückgabewert: bool
    * Hinweise:     Für DebugTrace/Filter nutzbar.
    * Fehlerfälle:  keine
    */
   bool IsActive() const { return m_active; }

   /**
    * Beschreibung: Wird bei OBJECT_DRAG aufgerufen. Erkennt nur Entry/SL-TradePos-Linien und tracked den Drag.
    * Parameter:    obj_name - Name des gedragten Objekts (sparam)
    * Rückgabewert: bool - true wenn verarbeitet
    * Hinweise:     Holt old_price aus DB (falls vorhanden), sonst nimmt Startpreis.
    * Fehlerfälle:  Parse schlägt fehl -> false (nicht unsere Linie).
    */
   bool OnObjectDrag(const string obj_name)
     {
      string direction, kind;
      int trade_no, pos_no;

      if(!UI_ParseTradePosFromName(obj_name, direction, trade_no, pos_no, kind))
         return false;
      if(kind != "entry" && kind != "sl")
         return false;

      const double cur_price = ObjectGetDouble(0, obj_name, OBJPROP_PRICE);

      // Drag-Start oder Objektwechsel
      if(!m_active || m_name != obj_name)
        {
         m_active   = true;
         m_name     = obj_name;
         m_dir      = direction;
         m_kind     = kind;
         m_trade_no = trade_no;
         m_pos_no   = pos_no;
         m_last_price = cur_price;

         // old aus DB (wenn vorhanden), sonst Startpreis
         m_old_price = 0.0;
         DB_PositionRow row;
         if(g_DB.GetPosition(_Symbol, (ENUM_TIMEFRAMES)_Period, direction, trade_no, pos_no, row))
            m_old_price = (kind == "entry") ? row.entry : row.sl;
         if(m_old_price <= 0.0)
            m_old_price = cur_price;
        }
      else
        {
         // laufender Drag
         m_last_price = cur_price;
        }

      // Tag live nachziehen
      UI_CreateOrUpdateLineTag(obj_name);

      // Redraw gedrosselt
      const uint now = GetTickCount();
      if(now - m_last_redraw_ms > 50)
        {
         UI_RequestRedraw();
         m_last_redraw_ms = now;
        }

      return true;
     }

   /**
    * Beschreibung: Wird bei OBJECT_CHANGE aufgerufen. Finalisiert, wenn es unsere aktive Linie ist.
    * Parameter:    obj_name - sparam
    * Rückgabewert: bool - true wenn verarbeitet
    * Hinweise:     OBJECT_CHANGE kommt nicht immer zuverlässig -> MouseUp-Fallback zusätzlich.
    * Fehlerfälle:  Objekt nicht mehr vorhanden -> Reset.
    */
   bool OnObjectChange(const string obj_name)
     {
      if(!m_active || obj_name != m_name)
         return false;

      m_last_price = ObjectGetDouble(0, obj_name, OBJPROP_PRICE);
      Finalize();
      return true;
     }

   /**
    * Beschreibung: MouseUp-Fallback: wenn Maustaste losgelassen und Drag aktiv -> Finalize.
    * Parameter:    mouse_state - aus CHARTEVENT_MOUSE_MOVE (StringToInteger(sparam))
    * Rückgabewert: void
    * Hinweise:     mouse_state==0 bedeutet MouseUp.
    * Fehlerfälle:  keine
    */
   void OnMouseMoveFinalizeIfNeeded(const int mouse_state)
     {
      if(mouse_state != 0)
         return;
      if(!m_active)
         return;

      Finalize();
     }

private:
   /**
    * Beschreibung: Setzt den Controller-State zurück.
    * Parameter:    none
    * Rückgabewert: void
    * Hinweise:     Nach Reset ist IsActive()==false.
    * Fehlerfälle:  keine
    */
   void Reset()
     {
      m_active = false;
      m_name = "";
      m_dir = "";
      m_kind = "";
      m_trade_no = 0;
      m_pos_no = 0;
      m_old_price = 0.0;
      m_last_price = 0.0;
      m_last_redraw_ms = 0;
     }

   /**
    * Beschreibung: Finalisiert den Drag: Tag aktualisieren, DB speichern, Discord senden (nur bei echter Änderung).
    * Parameter:    none
    * Rückgabewert: void
    * Hinweise:     "changed" nutzt SYMBOL_POINT Toleranz.
    * Fehlerfälle:  ObjectFind schlägt fehl -> Reset.
    */
   void Finalize()
     {
      if(!m_active || m_name == "")
        {
         Reset();
         return;
        }

      if(ObjectFind(0, m_name) < 0)
        {
         Reset();
         return;
        }

      const double new_price = m_last_price;
      const double old_price = m_old_price;

      // UI Tag sauber final
      UI_CreateOrUpdateLineTag(m_name);
      UI_RequestRedraw();

      // DB persistieren
      g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);

      // Discord nur wenn wirklich geändert
      const double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      const bool changed = (old_price <= 0.0) || (MathAbs(new_price - old_price) > pt * 0.25);

      if(changed && (m_kind == "entry" || m_kind == "sl"))
        {
         const string what = (m_kind == "entry") ? "Entry" : "SL";
         string msg = "@everyone\n";
         msg += StringFormat("**UPDATE:** %s %s Trade %d Pos %d (%s)\n",
                             _Symbol, TF_ToString((ENUM_TIMEFRAMES)_Period),
                             m_trade_no, m_pos_no, m_dir);

         if(old_price > 0.0)
            msg += StringFormat("**%s:** %s -> %s\n",
                                what,
                                DoubleToString(old_price, _Digits),
                                DoubleToString(new_price, _Digits));
         else
            msg += StringFormat("**%s:** %s\n", what, DoubleToString(new_price, _Digits));

         msg += "(Linie verschoben, Tag nachgezogen)\n";
         g_Discord.SendMessage(_Symbol, msg);
        }

      Reset();
     }
  };

// Global (file-scope)
static CTradePosLineDragController g_tp_drag;
