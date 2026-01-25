//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef __EVENTHANDLER__
#define __EVENTHANDLER__
#include "CVirtualTradeGUI.mqh"
#include "CSendButtonController.mqh"
#include "ui_state.mqh"
#include "CChartEventRouter.mqh"

#include "CDiscordClient.mqh"
#include "CTradeManager.mqh"
#include "CTradePosLineDragController.mqh"

// ------------------------------
// UI Layout (Right Anchor)
// ------------------------------
input int InpBaseUI_RightMarginPx = 30;   // Abstand von rechts (EntryButton-Rechte Kante)
input int InpBaseUI_RightShiftPx  = 0;    // optional: gesamtes Paket weiter nach links (+) / rechts (-)

input int InpUI_RedrawMinIntervalMs = 50;

static bool g_ui_redraw_pending = false;
static uint g_ui_last_redraw_ms = 0;




input bool InpDebugEventTrace = false; // true: Events in Experts loggen
extern CVirtualTradeGUI g_vgui;
//extern CVirtualTradeGUI g_vgui;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   bool handled = false;


   CurrentAskPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);





// 2) BaseUI (Drag Lines/Buttons + Sync)
   if(g_vgui.HandleBaseUIEvent(id, lparam, dparam, sparam))
      handled = true;

// 3) Router / restliche Logik wie bisher...

   if(g_evt_router.Dispatch(id, lparam, dparam, sparam))
      handled = true;

// 1) Legacy / restliche Verarbeitung nur wenn Router NICHT handled hat
   /*if(!handled)
     {



      // OBJECT_CLICK (Fallback)
      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(g_send_ctl.OnObjectClick(sparam))
           {
            handled = true;
           }
        }

      // OBJECT_DRAG
      if(!handled && id == CHARTEVENT_OBJECT_DRAG)
        {
         if(g_tp_drag.OnObjectDrag(sparam))
           {
            handled = true;
           }
         else
           {
            if(!handled && UI_IsTradePosLine(sparam))
              {
               UI_RequestRedrawThrottled(15);
               handled = true;
              }
           }
        }

      // OBJECT_CHANGE
      if(!handled && id == CHARTEVENT_OBJECT_CHANGE)
        {
         if(g_tp_drag.OnObjectChange(sparam))
           {
            handled = true;
           }
         else
           {

            if(!handled && UI_IsTradePosLine(sparam))
              {
               UI_RequestRedrawThrottled(15);
               g_TradeMgr.SaveLinePrices(_Symbol, (ENUM_TIMEFRAMES)_Period);
               handled = true;
              }
           }
        }

      // Preise der Linien (wie vorher, aber nur wenn wir noch nicht handled sind)
      if(!handled)
        {
         Entry_Price = Get_Price_d(PR_HL);
         SL_Price    = Get_Price_d(SL_HL);
        }

      // MOUSE_MOVE
      if(!handled && id == CHARTEVENT_MOUSE_MOVE)
        {
         const int mx = (int)lparam;
         const int my = (int)dparam;
         const int MouseState = (int)StringToInteger(sparam);

         // TradePosLine finalize muss bleiben
         g_tp_drag.OnMouseMoveFinalizeIfNeeded(MouseState);

        }

      // CHART_CHANGE
      if(!handled && id == CHARTEVENT_CHART_CHANGE)
        {
         // TradePosLine Tags bleiben separat
         g_tradePosLines.SyncAllTags();


         g_tradePosLines.SyncAllTags();
         UI_ApplyZOrder();
         handled = true;
        }
     } // if(!handled)
   */


// --- Post-Phase: MUSS IMMER laufen ---

// Post-Phase + Redraw wie bisher
   static bool last_is_long = true;
   if(last_is_long != g_ui_state.is_long)
     {
      last_is_long = g_ui_state.is_long;
      TP_RebuildRows();
     }

   UI_ProcessRedraw();
   g_tp.ProcessRebuild();

  }



/**
 * Beschreibung: Wandelt Chart-Event-IDs in lesbaren Text um.
 * Parameter:    id - Event-ID aus OnChartEvent
 * Rückgabewert: string - Name des Events
 * Hinweise:     Nur für Debug/Logs.
 * Fehlerfälle:  Keine.
 */
string UI_EventIdToStr(const int id)
  {
   switch(id)
     {
      case CHARTEVENT_OBJECT_CLICK:
         return "OBJECT_CLICK";
      case CHARTEVENT_OBJECT_DRAG:
         return "OBJECT_DRAG";
      case CHARTEVENT_OBJECT_CHANGE:
         return "OBJECT_CHANGE";
      case CHARTEVENT_OBJECT_ENDEDIT:
         return "OBJECT_ENDEDIT";
      case CHARTEVENT_MOUSE_MOVE:
         return "MOUSE_MOVE";
      case CHARTEVENT_CHART_CHANGE:
         return "CHART_CHANGE";
      default:
         return "OTHER";
     }
  }

/**
 * Beschreibung: Stellt sicher, dass ein angefordertes Redraw auch wirklich ausgeführt wird,
 *               bevor OnChartEvent per early-return endet (z.B. durch Router-Shortcuts).
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Behebt das "Label zieht erst später nach" Verhalten bei Drag/Change.
 * Fehlerfälle:  keine
 */
void UI_FlushRedrawBeforeReturn()
  {
   UI_ProcessRedraw();
  }


/**
 * Beschreibung: Prüft, ob ein Objektname zu den “interessanten” UI/Trade-Objekten gehört.
 * Parameter:    name - Objektname (sparam)
 * Rückgabewert: bool - true wenn relevant für Event-Diagnose
 * Hinweise:     Prefix-Checks für Trade-Linien und Panel-Row-Buttons.
 * Fehlerfälle:  Keine.
 */
bool UI_IsWatchedEventObject(const string name)
  {
   if(name == PR_HL || name == SL_HL)
      return true;
   if(name == EntryButton || name == SLButton)
      return true;
   if(name == SENDTRADEBTN)
      return true;
   if(name == SabioEntry || name == SabioSL)
      return true;

// Trade-Pos Linien
   if(StringFind(name, "Entry_Long_")  == 0)
      return true;
   if(StringFind(name, "SL_Long_")     == 0)
      return true;
   if(StringFind(name, "Entry_Short_") == 0)
      return true;
   if(StringFind(name, "SL_Short_")    == 0)
      return true;

// TradesPanel Row Buttons (Cancel/HitSL)
   if(StringFind(name, TP_ROW_LONG_Cancel_PREFIX)  == 0)
      return true;
   if(StringFind(name, TP_ROW_LONG_hitSL_PREFIX)   == 0)
      return true;
   if(StringFind(name, TP_ROW_SHORT_Cancel_PREFIX) == 0)
      return true;
   if(StringFind(name, TP_ROW_SHORT_hitSL_PREFIX)  == 0)
      return true;
   if(name == "TP_BTN_CANCEL_LONG" || name == "TP_BTN_CANCEL_SHORT")
      return true;
   if(name == "TP_BTN_ACTIVE_LONG" || name == "TP_BTN_ACTIVE_SHORT")
      return true;
   return false;
  }



/**
 * Beschreibung: Merkt, dass ein Redraw nötig ist (ohne sofort zu zeichnen).
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Verwenden statt ChartRedraw in Low-Level UI Funktionen.
 * Fehlerfälle:  keine
 */
void UI_RequestRedraw()
  {
   g_ui_redraw_pending = true;
  }

/**
 * Beschreibung: Führt ein gedrosseltes ChartRedraw aus, wenn angefordert.
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Am Ende von OnChartEvent und/oder OnTick aufrufen.
 * Fehlerfälle:  keine
 */
void UI_ProcessRedraw()
  {
   if(!g_ui_redraw_pending)
      return;

   uint now = GetTickCount();
   if((now - g_ui_last_redraw_ms) < (uint)InpUI_RedrawMinIntervalMs)
      return;

   ChartRedraw(0);
   g_ui_last_redraw_ms = now;
   g_ui_redraw_pending = false;
  }



// ------------------------------------------------------------------
// Basis-Linien-Drag Tracking (PR_HL / SL_HL)
// Ziel: UI live synchronisieren, Speichern nur 1x beim Loslassen.
// ------------------------------------------------------------------
static bool   g_base_drag_active  = false;
static string g_base_drag_name    = "";
static uint   g_base_drag_last_ms = 0;
// --- Drag-State (nur für Basis-Buttons Entry/SL) ---
static bool   g_base_btn_drag_active   = false;
static string g_base_btn_drag_btn_name = "";
static string g_base_btn_drag_line_name= "";
static int    g_base_btn_drag_offset_y = 0;   // Cursor-Offset innerhalb des Buttons (top->cursor)
static int    g_base_btn_drag_btn_ysize = 0;  // Button-Höhe (für bottom-y -> price)
static bool   g_base_btn_prev_left_down = false;
static string g_base_edit_active = ""; // "", TRNB oder POSNB wenn User gerade tippt

// --- OPTIONAL: Gekoppelter Drag (Abstand Entry<->SL bleibt konstant) ---

// Letzte bekannte Maus-Y aus CHARTEVENT_MOUSE_MOVE (Fallback für Objekt-Drag)
static int g_last_mouse_y = -1;


// ---------------------------------------------------------
// Base UI Right Anchor (relativ zum EntryButton)
// ---------------------------------------------------------
static bool g_base_anchor_inited = false;
static int  g_base_ref_x         = 0;   // EntryButton XDISTANCE (Baseline)
static int  g_base_ref_w         = 0;   // EntryButton XSIZE (Baseline)

static int  g_dx_slbtn   = 0;
static int  g_dx_send    = 0;
static int  g_dx_trnb    = 0;
static int  g_dx_posnb   = 0;
static int  g_dx_sabEnt  = 0;
static int  g_dx_sabSL   = 0;
static bool g_sabio_user_override = false; // sobald User Sabio editiert -> keine Auto-Texte mehr
/**
 * Beschreibung: Merkt die aktuellen X-Offsets der Base-UI relativ zum EntryButton.
 * Parameter:    force - true: immer neu erfassen (z.B. nach Rebuild), false: nur beim ersten Mal
 * Rückgabewert: bool - true wenn EntryButton vorhanden und Baseline gespeichert
 * Hinweise:     Wir ändern hier nichts, wir speichern nur Offsets (Layout bleibt erhalten).
 * Fehlerfälle:  EntryButton fehlt -> false (kein Anchor möglich)
 */

// ------------------------------------------------------------------
// BaseLine-Kopplung / Reentrancy-Guard
// ------------------------------------------------------------------
static bool   g_base_sync_guard   = false;  // schützt vor Rekursion wenn wir SL_HL programmgesteuert setzen
static bool   g_base_lock_distance = true;  // "PR_HL zieht SL_HL mit" aktiv
static double g_base_lock_delta    = 0.0;   // SL - Entry (Preisdelta)
// Mouse-Y Tracking für Live-UI während Linien-Drag (verhindert "Springen" bei SL_HL)

/**
 * Beschreibung: Liefert die aktuelle Chart-Breite in Pixeln.
 * Parameter:    none
 * Rückgabewert: int - Breite in Pixeln (0 bei Fehler)
 * Hinweise:     Wird für Right-Anchoring verwendet.
 * Fehlerfälle:  ChartGetInteger schlägt fehl -> Print + GetLastError
 */
int UI_GetChartWidthPx()
  {
   long w = 0;
   ResetLastError();
   if(!ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, w))
     {
      Print(__FUNCTION__, ": ChartGetInteger(CHART_WIDTH_IN_PIXELS) failed err=", GetLastError());
      return 0;
     }
   return (int)w;
  }



/**
 * Beschreibung: Setzt das X (XDISTANCE) eines Objekts sicher (clamp an Chartbreite).
 * Parameter:    name   - Objektname
 *               x_left - gewünschte X-Position (linke Kante) in Pixel
 *               chart_w- Chartbreite in Pixel
 * Rückgabewert: void
 * Hinweise:     Erzwingt CORNER_LEFT_UPPER.
 * Fehlerfälle:  Objekt fehlt -> silent return
 */
void UI_SetObjectXClamped(const string name, const int x_left, const int chart_w)
  {
   if(ObjectFind(0, name) < 0)
      return;

   UI_ObjSetIntSafe(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);

   int xs = (int)ObjectGetInteger(0, name, OBJPROP_XSIZE);
   if(xs < 0)
      xs = 0;

   int xx = x_left;
   if(xx < 0)
      xx = 0;
   if(chart_w > 0 && xs > 0 && xx > (chart_w - xs))
      xx = (chart_w - xs);
   if(xx < 0)
      xx = 0;

   UI_ObjSetIntSafe(0, name, OBJPROP_XDISTANCE, xx);
  }


/**
 * Beschreibung: Liefert eine robuste Mouse-Y Pixelposition (für Live-UI beim Linien-Drag).
 * Parameter:    dparam - Event dparam (bei OBJECT_DRAG oft MouseY; sonst ggf. 0/unsinnig)
 * Rückgabewert: int - MouseY in Pixeln (0..ChartHeight-1)
 * Hinweise:     Falls dparam unplausibel ist, wird die letzte MouseMove-Y (g_last_mouse_y) genutzt.
 * Fehlerfälle:  Keine harten Fehler; wenn keine MouseMove-Y bekannt ist, wird geclamped.
 */
int UI_GetMouseYPxSafe(const double dparam)
  {
   const int h = UI_GetChartHeightPx();

// dparam versuchen (bei OBJECT_DRAG i.d.R. MouseY)
   int my = (int)MathRound(dparam);

// Wenn dparam Quatsch ist -> Fallback auf letzte MouseMove-Y
   if(h > 0 && (my < 0 || my > (h - 1)))
     {
      if(g_last_mouse_y >= 0)
         my = g_last_mouse_y;
     }

// Clamp
   if(my < 0)
      my = 0;
   if(h > 0 && my > (h - 1))
      my = h - 1;

   return my;
  }


// -------------------- TP ZORDER DEBUG --------------------
void TP_DumpObj(const string name)
  {
   if(ObjectFind(0, name) < 0)
     {
      PrintFormat("TP_DUMP missing: %s", name);
      return;
     }

   long type = (long)ObjectGetInteger(0, name, OBJPROP_TYPE);
   long z    = (long)ObjectGetInteger(0, name, OBJPROP_ZORDER);
   long back = (long)ObjectGetInteger(0, name, OBJPROP_BACK);
   long sel  = (long)ObjectGetInteger(0, name, OBJPROP_SELECTABLE);
   long tf   = (long)ObjectGetInteger(0, name, OBJPROP_TIMEFRAMES);

   long x = (long)ObjectGetInteger(0, name, OBJPROP_XDISTANCE);
   long y = (long)ObjectGetInteger(0, name, OBJPROP_YDISTANCE);
   long w = (long)ObjectGetInteger(0, name, OBJPROP_XSIZE);
   long h = (long)ObjectGetInteger(0, name, OBJPROP_YSIZE);

   string txt = ObjectGetString(0, name, OBJPROP_TEXT);

   PrintFormat("TP_DUMP name=%s type=%d z=%d back=%d selectable=%d tf=%I64d x=%d y=%d w=%d h=%d text='%s'",
               name, (int)type, (int)z, (int)back, (int)sel, tf, (int)x, (int)y, (int)w, (int)h, txt);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TP_DumpFirstByPrefix(const string prefix)
  {
   int total = ObjectsTotal(0, -1, -1);
   for(int i=0; i<total; i++)
     {
      string n = ObjectName(0, i);
      if(StringFind(n, prefix, 0) == 0)
        {
         TP_DumpObj(n);
         return;
        }
     }
   PrintFormat("TP_DUMP prefix not found: %s", prefix);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TP_DumpPanel()
  {
   Print("=== TP_DUMP_PANEL BEGIN ===");

// Static
   TP_DumpObj("TP_BG");
   TP_DumpObj("TP_HDR_LONG_BG");
   TP_DumpObj("TP_HDR_SHORT_BG");
   TP_DumpObj("TP_LBL_LONG");
   TP_DumpObj("TP_LBL_SHORT");
   TP_DumpObj("TP_BTN_ACTIVE_LONG");
   TP_DumpObj("TP_BTN_CANCEL_LONG");
   TP_DumpObj("TP_BTN_ACTIVE_SHORT");
   TP_DumpObj("TP_BTN_CANCEL_SHORT");

// Dynamic examples (jeweils erstes Objekt, falls vorhanden)
   TP_DumpFirstByPrefix("TP_ROW_LONG_TR_");
   TP_DumpFirstByPrefix("TP_ROW_LONG_");
   TP_DumpFirstByPrefix("TP_ROW_LONG_Cancel_");
   TP_DumpFirstByPrefix("TP_ROW_LONG_sl_");

   TP_DumpFirstByPrefix("TP_ROW_SHORT_TR_");
   TP_DumpFirstByPrefix("TP_ROW_SHORT_");
   TP_DumpFirstByPrefix("TP_ROW_SHORT_Cancel_");
   TP_DumpFirstByPrefix("TP_ROW_SHORT_sl_");

   Print("=== TP_DUMP_PANEL END ===");
  }


/**
 * Beschreibung: Deselektiert beide Basislinien (PR_HL/SL_HL).
 * Parameter:    none
 * Rückgabewert: void
 * Hinweise:     Nützlich bei Chart-Hintergrund-Klick (damit nichts “selected” bleibt).
 * Fehlerfälle:  ObjectSetInteger kann fehlschlagen -> Print.
 */
void UI_DeselectBaseLines()
  {
   if(ObjectFind(0, PR_HL) >= 0)
     {
      ResetLastError();
      if(!ObjectSetInteger(0, PR_HL, OBJPROP_SELECTED, false))
         Print(__FUNCTION__, ": deselect PR_HL failed err=", GetLastError());
     }
   if(ObjectFind(0, SL_HL) >= 0)
     {
      ResetLastError();
      if(!ObjectSetInteger(0, SL_HL, OBJPROP_SELECTED, false))
         Print(__FUNCTION__, ": deselect SL_HL failed err=", GetLastError());
     }
  }

/**
 * Beschreibung: Selektiert genau eine Basislinie exklusiv und deselektiert die andere.
 * Parameter:    clicked_line - PR_HL oder SL_HL
 * Rückgabewert: void
 * Hinweise:     Fix für “beide Linien bleiben selected”.
 * Fehlerfälle:  ObjectSetInteger kann fehlschlagen -> Print.
 */
void UI_SelectBaseLineExclusive(const string clicked_line)
  {
   if(clicked_line != PR_HL && clicked_line != SL_HL)
      return;

   const string other = (clicked_line == PR_HL ? SL_HL : PR_HL);

// Clicked -> selected
   if(ObjectFind(0, clicked_line) >= 0)
     {
      ResetLastError();
      if(!ObjectSetInteger(0, clicked_line, OBJPROP_SELECTED, true))
         Print(__FUNCTION__, ": select ", clicked_line, " failed err=", GetLastError());
     }

// Other -> deselected
   if(ObjectFind(0, other) >= 0)
     {
      ResetLastError();
      if(!ObjectSetInteger(0, other, OBJPROP_SELECTED, false))
         Print(__FUNCTION__, ": deselect other ", other, " failed err=", GetLastError());
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UI_ExtractIntDigits(const string text)
  {
   string digits = "";
   for(int i=0; i<StringLen(text); i++)
     {
      ushort c = StringGetCharacter(text, i);
      if(c >= '0' && c <= '9')
         digits += (string)CharToString((uchar)c);
     }
   if(digits == "")
      return 0;
   return (int)StringToInteger(digits);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UI_CloseOnePositionAndNotify(const string action,
                                  const string direction,
                                  const int trade_no,
                                  const int pos_no)
  {
// 1) Business-Teil (Discord + DB + Cache + Remaining-Check) -> TradeManager
   bool has_pending = true;
   string err = "";

   CTradeManager::EPosAction act =
      (action == "CANCEL" ? CTradeManager::POS_CANCEL : CTradeManager::POS_HIT_SL);

   if(!g_TradeMgr.HandlePositionAction(_Symbol, (ENUM_TIMEFRAMES)_Period,
                                       direction, trade_no, pos_no,
                                       act, has_pending, err))
     {
      CLogger::Add(LOG_LEVEL_WARNING, "HandlePositionAction failed: " + err);
      return false;
     }

// 2) UI-Linien/Tags dieser Position entfernen (wie bisher)
   string suf_tp = "_" + IntegerToString(trade_no) + "_" + IntegerToString(pos_no);

   TradePosLines_DeleteTradePos(direction, trade_no, pos_no);



// 3) Falls letzte pending Position -> Runtime + Meta zurücksetzen
   if(!has_pending)
     {
      if(direction == "LONG")
        {
         if(g_ui_state.active_trade_no_long == trade_no)
           {
            g_ui_state.active_trade_no_long = 0;
            g_DB.SetMetaInt(g_DB.Key("g_ui_state.active_trade_no_long"), 0);
           }

         is_long_trade     = false;
         HitEntryPriceLong = false;

         if(ObjectFind(0, "ActiveLongTrade") >= 0)
           {
            UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
            UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
      else
        {
         if(g_ui_state.active_trade_no_short == trade_no)
           {
            g_ui_state.active_trade_no_short = 0;
            g_DB.SetMetaInt(g_DB.Key("g_ui_state.active_trade_no_short"), 0);
           }

         is_sell_trade         = false;
         is_sell_trade_pending = false;
         HitEntryPriceShort    = false;

         if(ObjectFind(0, "ActiveShortTrade") >= 0)
           {
            UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
            UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
           }
        }
     }

// 4) UI Refresh
   UI_ProcessRedraw();
   g_tp.RequestRebuild();

   g_tp.ProcessRebuild();
   UI_ApplyZOrder();       // <-- HIER
   return true;
  }



//+------------------------------------------------------------------+
//| Cancel active trade (header cancel buttons)                       |
//+------------------------------------------------------------------+
bool UI_CancelActiveTrade(const string direction)
  {
   const bool isLong = (direction == "LONG");
   int trade_no = (isLong ? g_ui_state.active_trade_no_long : g_ui_state.active_trade_no_short);

   if(trade_no <= 0)
     {
      CLogger::Add(LOG_LEVEL_INFO, "UI_CancelActiveTrade: kein aktiver Trade für " + direction);
      return false;
     }

   string err = "";
   if(!g_TradeMgr.CancelTrade(_Symbol, (ENUM_TIMEFRAMES)_Period, direction, trade_no, err))
     {
      CLogger::Add(LOG_LEVEL_WARNING, "UI_CancelActiveTrade: CancelTrade failed: " + err);
      return false;
     }

// Linien/Tags entfernen
   TradePosLines_DeleteTradeByTradeNo(direction, trade_no);



// Runtime + Meta zurücksetzen (damit OnInit NICHT reaktiviert)
   if(isLong)
     {
      if(g_ui_state.active_trade_no_long == trade_no)
        {
         g_ui_state.active_trade_no_long = 0;
         g_DB.SetMetaInt(g_DB.Key("g_ui_state.active_trade_no_long"), 0);
        }
      is_long_trade     = false;
      HitEntryPriceLong = false;

      showActive_long(false);
      showCancel_long(false);

      if(ObjectFind(0, "ActiveLongTrade") >= 0)
        {
         UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_COLOR, clrNONE);
         UI_ObjSetIntSafe(0, "ActiveLongTrade", OBJPROP_BGCOLOR, clrNONE);
        }
     }
   else
     {
      if(g_ui_state.active_trade_no_short == trade_no)
        {
         g_ui_state.active_trade_no_short = 0;
         g_DB.SetMetaInt(g_DB.Key("g_ui_state.active_trade_no_short"), 0);
        }

      is_sell_trade         = false;
      is_sell_trade_pending = false;
      HitEntryPriceShort    = false;

      showActive_short(false);
      showCancel_short(false);

      if(ObjectFind(0, "ActiveShortTrade") >= 0)
        {
         UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_COLOR, clrNONE);
         UI_ObjSetIntSafe(0, "ActiveShortTrade", OBJPROP_BGCOLOR, clrNONE);
        }
     }
   g_tp.RebuildRows();

   ChartRedraw(0);
   return true;
  }










// ------------------------------------------------------------------
// Neuer Basis-Drag-Ansatz (Entry/SL): Linie ist 1 Quelle der Wahrheit
// - Button-Drag setzt nur den Preis der zugehörigen HLine
// - UI (Buttons/Edits) folgt zentral über UI_OnBaseLinesChanged()
// ------------------------------------------------------------------

/**
 * Beschreibung: Liefert die Chart-Höhe in Pixeln robust (0 bei Fehler).
 * Parameter:    none
 * Rückgabewert: int - Höhe in Pixeln (0 bei Fehler)
 * Hinweise:     Wird für Clamp bei Drag verwendet.
 * Fehlerfälle:  ChartGetInteger schlägt fehl -> Print + GetLastError
 */
int UI_GetChartHeightPx()
  {
   long h = 0;
   ResetLastError();
   if(!ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, h))
     {
      Print(__FUNCTION__, ": ChartGetInteger(CHART_HEIGHT_IN_PIXELS) failed err=", GetLastError());
      return 0;
     }
   return (int)h;
  }

/**
 * Beschreibung: Normalisiert einen Preis auf TickSize und Digits (sauberes Snapping).
 * Parameter:    price_raw - Rohpreis (z.B. aus ChartXYToTimePrice)
 * Rückgabewert: double - auf Tick gerundeter Preis
 * Hinweise:     SYMBOL_TRADE_TICK_SIZE wird bevorzugt, sonst _Point.
 * Fehlerfälle:  keine (Fallback auf _Point)
 */
double UI_NormalizeToTick(const double price_raw)
  {
   double tick = 0.0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tick) || tick <= 0.0)
      tick = _Point;

   double snapped = MathRound(price_raw / tick) * tick;
   return NormalizeDouble(snapped, _Digits);
  }

/**
 * Beschreibung: Prüft, ob ein Mouse-Punkt innerhalb eines OBJ_BUTTON-Rechtecks liegt.
 * Parameter:    obj_name - Objektname (Button)
 *               mx,my    - Mauskoordinaten (Pixel)
 *               out_xd   - Rückgabe XDISTANCE
 *               out_yd   - Rückgabe YDISTANCE
 *               out_xs   - Rückgabe XSIZE
 *               out_ys   - Rückgabe YSIZE
 * Rückgabewert: true, wenn innerhalb; sonst false
 * Hinweise:     Liest Button-Props direkt aus dem Objektmodell.
 * Fehlerfälle:  Objekt fehlt -> false (kein Print, um Logs nicht zu fluten)
 */
bool UI_PointInButtonRect(const string obj_name,
                          const int mx, const int my,
                          int &out_xd, int &out_yd, int &out_xs, int &out_ys)
  {
   if(ObjectFind(0, obj_name) < 0)
      return false;

   out_xd = (int)ObjectGetInteger(0, obj_name, OBJPROP_XDISTANCE);
   out_yd = (int)ObjectGetInteger(0, obj_name, OBJPROP_YDISTANCE);
   out_xs = (int)ObjectGetInteger(0, obj_name, OBJPROP_XSIZE);
   out_ys = (int)ObjectGetInteger(0, obj_name, OBJPROP_YSIZE);

   return (mx >= out_xd && mx <= (out_xd + out_xs) &&
           my >= out_yd && my <= (out_yd + out_ys));
  }

/**
 * Beschreibung: Setzt den Preis einer HLine robust (mit Fehlerlog).
 * Parameter:    line_name - Objektname (z.B. PR_HL / SL_HL)
 *               price     - Zielpreis (bereits normalisiert)
 * Rückgabewert: true bei Erfolg, sonst false
 * Hinweise:     Für OBJ_HLINE reicht OBJPROP_PRICE.
 * Fehlerfälle:  Linie fehlt oder ObjectSetDouble scheitert -> Print + GetLastError
 */
bool UI_SetHLinePriceSafe(const string line_name, const double price)
  {

   ResetLastError();
   if(!ObjectSetDouble(0, line_name, OBJPROP_PRICE, price))
     {
      return false;
     }
   return true;
  }


/**
 * Beschreibung: Liest den Preis einer HLine robust.
 * Parameter:    line_name - Objektname (PR_HL/SL_HL)
 *               out_price - Rückgabe Preis
 * Rückgabewert: true bei Erfolg, sonst false
 * Hinweise:     Erwartet OBJ_HLINE.
 * Fehlerfälle:  Linie fehlt -> Print; ObjectGetDouble liefert 0/Fehler -> Print
 */
bool UI_GetHLinePriceSafe(const string line_name, double &out_price)
  {
   if(ObjectFind(0, line_name) < 0)
     {
      Print(__FUNCTION__, ": line not found: ", line_name);
      return false;
     }

   ResetLastError();
   out_price = ObjectGetDouble(0, line_name, OBJPROP_PRICE);
   int err = GetLastError();
   if(err != 0)
     {
      Print(__FUNCTION__, ": ObjectGetDouble failed for ", line_name, " err=", err);
      return false;
     }
   return true;
  }

/**
* Beschreibung: Fordert ein Chart-Redraw an, aber gedrosselt (Throttle), um flüssiges UI beim Drag zu bekommen,
*              ohne die CPU mit ChartRedraw() zu fluten.
* Parameter:    min_interval_ms - Mindestabstand zwischen Redraw-Requests in Millisekunden
* Rückgabewert: void
* Hinweise:     Nutzt UI_RequestRedraw() (dein bestehender Mechanismus). Nur während Drag klein wählen.
* Fehlerfälle:  Keine (rein logisch). Wenn UI_RequestRedraw() fehlt -> Compile-Fehler.
*/
void UI_RequestRedrawThrottled(const uint min_interval_ms)
  {
   static uint s_last_ms = 0;
   const uint now = GetTickCount();
   if(now - s_last_ms < min_interval_ms)
      return;

   UI_RequestRedraw();     // dein bestehender "sanfter" Redraw-Request
   s_last_ms = now;
  }


// Merkt, welche Basislinie der User zuletzt angeklickt hat (wichtig, wenn beide "selected" sind)
static string g_base_last_clicked_line = "";

#endif // __EVENTHANDLER__
