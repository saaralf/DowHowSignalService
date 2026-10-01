//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

/*
Discord-Kanal: [removed legacy webhook]
 Änderungen Steffen:
18.12.2025
   - bereits vorhanden: in den Eigenschaften können die Farben für TP-Button, -Beschriftung und -Linie auf "none" gestellt werden --> nicht mehr sichtbar
   - Abstand zum Entry-Button auf 0 gestellt
   - Feld für Notizen deaktiviert
   - // Steffen            movingState_R1 = true;
   - Verschieben von R1 deaktiviert
   - in discord_4.15.mqh Zeile 177 deaktiviert
   - Voreinstellungen für TP-Button und -Linie auf "clrnone" gestellt
   - Abstand TP- und Entry-Button auf 0 gestellt
   - die Sperre für mehrfaches Senden entfernt --> Tradenummern werden beim Senden nicht mitgeschickt - bleibt auf 1 stehen

*/
#property copyright "Michael Keller, Steffen Kachold, ChatGPT"
#property link ""
#property version "1.427" // Development V1.04.27, based on colleague V1.04.26.
string tradenummer = "0";
int g_transport_trade=0,g_transport_pos=0;
#include <Trade\Trade.mqh>
CTrade trade;
#include <Controls\Dialog.mqh>
CAppDialog SabioConfirmation;

#include "v126/methoden_4.22.mqh" // Funktionen/Methoden ausgelagert in eine eigene Datei
#include "v126/discord_4.23.mqh" // alles rund ums senden an Discord
#include "v126/LabelundMessageButton.mqh" // Label für die Message Button


// Default values for settings:
double EntryLevel = 0;
double StopLossLevel = 0;
double TakeProfitLevel = 0;
double StopPriceLevel = 0;

// only one button is visible

input group "===== Button ====="
input color SLButton_bgcolor = clrRed; // SL Button   Color
input color SLButton_font_color = clrWhite;  // SL Button   Font Color
input uint SLButton_font_size = 8;  // SL Button   Font Size
input color PriceButton_bgcolor = clrAqua;   // Price Button   Color
input color PriceButton_font_color = clrBlack;  // Price Button   Font Color
input uint PriceButton_font_size = 8;  // Price Button   Font Size
input color SendOnlyButton_bgcolor = clrForestGreen;  // Button Send only  Coloron
input color SendOnlyButton_font_color = clrWhite;  // Button Send only  Font Color
input uint SendOnlyButton_font_size = 10; // Button Send only  Font Size
input color TSButton_bgcolor = clrGray;   // Button Trade & Send  Color
input color TSButton_font_color = clrRed; // Button Trade & Send  Font Color
input uint TSButton_font_size = 10; // Button Trade & Send  Font Size
input group "===== Lines ====="
input color EntryLine = clrAqua; // Entry Line
input color SLLine = clrRed;  // SL Line at SL Button
input color TradeEntryLineLong = clrGreen; // Active Trade SL Line Long
input color TradeSLLineLong = clrRed;  // Active Trade SL Line Long
input color TradeEntryLineShort = clrAqua;   // Active Trade Entry Line Short
input color TradeSLLineShort = clrViolet; // Active Trade SL Line Long
input group "===== Defaults ====="
input int InpMagic = 100; // Magic Number
input bool SendOnlyButton = true;   // Send only (true) or Trade & Send (false)
input bool Sabioedit = false;  // Sabio Prices Edit visible
input bool SabioPrices = false;   // Sabio Prices already insert (true) or not (false)
input color TNLong = clrLime; // Color Tradenumber Longtrade
input color TNShort = clrDarkOrange; // Color Tradenumber Shorttrade
//input bool MessageBoxSound = false;
input int DistancefromRight = 300;  //Distance from right screen edge

#define EntryButton "EntryButton"
#define SLButton "SLButton"
#define BTN2 "SendOnlyButton"
#define SL_HL "SL_HL"
#define PR_HL "PR_HL"
#define TRNB "EingabeTrade"
#define POSNB "EingabePosition"
#define SabioEntry "SabioEntry"
#define SabioSL "SabioSL"
#define SL_Long "SL_Long"
#define SL_Short "SL_Short"
#define LabelSLLong "LabelSLLong"
#define LabelSLShort "LabelSLShort"
#define Entry_Long "Entry_Long"
#define Entry_Short "Entry_Short"
#define LabelEntryLong "LabelEntryLong"
#define LabelEntryShort "LabelEntryShort"
#define ConfirmSabioInserts "ConfirmSabioInserts"

double Entry_Price;
double SL_Price;
double CurrentAskPrice;
double CurrentBidPrice;

string DHFile = ""; // Optional logo absent from colleague archive.

// --- SL Drag / Send-Workflow ---
bool   slDragActive      = false;


color chart_bg_user;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool isBuy=1;
bool is_long_trade=false,is_sell_trade=false;
bool send_SL_buy=false;
bool send_CL_buy=false;
bool send_SL_sell=false;
bool send_CL_sell=false;
bool HitEntryPriceLong = false;
bool HitEntryPriceShort = false;
bool is_sell_trade_pending = false;
bool is_buy_trade_pending = false;
bool prevIsBuy = true;


int
xd2, yd2, xs2, ys2,
     xd3, yd3, xs3, ys3,
     xd5, yd5, xs5, ys5;

datetime dt_Labels = iTime(_Symbol, 0, 0);

// --- Click-Suppression nach UI-Drag ---
bool  uiDragStarted   = false;
bool  uiDragMoved     = false;
int   uiDownX         = 0;
int   uiDownY         = 0;
uint  suppressClickUntilMs = 0;

// Threshold (Pixel) ab wann "Drag" zählt
input int InpDragThresholdPx = 3;

// kurze Sperre nach Drag-Ende (ms)
input int InpSuppressClickMs = 250;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateDirectionFromEntrySL();
//prevIsBuy = isBuy;
//SetEditsFromStoredDirection(); // optional hier statt direkt nach SendButton

#include "v126/SQLiteStore.mqh"
input group "===== SQLite development ====="
input string InpSQLiteFile = "DowHowSignalService_V126_dev.sqlite";
input int InpInitialLastTrade = 0; // Only used when this context is created first.
CDH126Store g_store;
bool g_storage_ok=false;
void SetEditsFromStoredDirection();
void RefreshRestoredPositions();
void CancelStoredPosition(int idx);

int OnInit()
  {

// Stage 1 handles virtual signals only.
   if(!SendOnlyButton) { Print("SQLite stage 1 requires SendOnly=true"); return INIT_PARAMETERS_INCORRECT; }
   if(!g_store.Open(InpSQLiteFile,InpMagic,InpInitialLastTrade)) { Print("SQLite init failed or context already in use"); return INIT_FAILED; }
   g_storage_ok=true;
   checkDiscord();
   MessageButton();
   InfoLabel();
   LabelTradeNumber();
   DHFileBMP();


// --- Chart Anchor (TP-frei)
   int chartW = getChartWidthInPixels();
   int chartH = getChartHeightInPixels();

   int baseX = chartW - DistancefromRight;
   int baseY = chartH / 2;

// --- Button-Geometrie
   xs3 = 280;
   ys3 = 30;
   xs5 = 280;
   ys5 = 30;

   xd3 = baseX;
   yd3 = baseY;        // Entry
   xd5 = baseX;
   yd5 = baseY + 100;  // SL

// --- Buttons erzeugen
   createButton(EntryButton, "", xd3, yd3, xs3, ys3, PriceButton_font_color, PriceButton_bgcolor, PriceButton_font_size, clrNONE, "Arial Black");
   createButton(SLButton,    "", xd5, yd5, xs5, ys5, SLButton_font_color,    SLButton_bgcolor,    SLButton_font_size,    clrNONE, "Arial Black");

// --- Linien initial an Buttons koppeln
   datetime dt_prc = iTime(_Symbol, 0, 0);
   datetime dt_sl  = iTime(_Symbol, 0, 0);
   double price_prc = iClose(_Symbol, 0, 0);
   double price_sl  = iClose(_Symbol, 0, 0);
   int window = 0;

   ChartXYToTimePrice(0, xd3, yd3 + ys3, window, dt_prc, price_prc);
   ChartXYToTimePrice(0, xd5, yd5 + ys5, window, dt_sl,  price_sl);

   createHL(PR_HL, dt_prc, price_prc, EntryLine);
   createHL(SL_HL, dt_sl,  price_sl,  SLLine);

// --- Optional: Sabio-Edits (TP-frei: SabioEdit musst du unten anpassen)
   if(Sabioedit)
      SabioEdit();

// --- Send Button + Tradenummer Feld
   SendButton();

// --- Initiale Preise
   Entry_Price = Get_Price_d(PR_HL);
   SL_Price    = Get_Price_d(SL_HL);

// --- Richtung aus Entry/SL bestimmen (TP-frei)
   UpdateDirectionFromEntrySL();

   prevIsBuy = isBuy;

// Nach SendButton(), weil TRNB/POSNB erst dort erstellt werden
   SetEditsFromStoredDirection();


// --- Lots + Button Texte
   double lots;
   if(isBuy)
      lots = NormalizeDouble(calcLots(Entry_Price - SL_Price), 2);
   else
      lots = NormalizeDouble(calcLots(SL_Price - Entry_Price), 2);

   if(isBuy)
      update_Text(EntryButton, "Buy Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots,2));
   else
      update_Text(EntryButton, "Sell Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots,2));

   if(isBuy)
      update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(PR_HL) - Get_Price_d(SL_HL))/_Point), 0) + " Points | " + Get_Price_s(SL_HL));
   else
      update_Text(SLButton, "SL: " + DoubleToString(((Get_Price_d(SL_HL) - Get_Price_d(PR_HL))/_Point), 0) + " Points | " + Get_Price_s(SL_HL));

// --- State
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, 0, false);
   ChartSetInteger(0, CHART_SHOW_GRID, 0, false);


   is_long_trade=false;
   is_sell_trade=false;




// --- TradeInfo init (TP-frei)
   InitTradeInfo();
   if(!g_store.Restore(tradeInfo,is_long_trade,is_sell_trade,HitEntryPriceLong,HitEntryPriceShort)) { g_store.Close(); g_storage_ok=false; return INIT_FAILED; }
   RefreshRestoredPositions();
   SetEditsFromStoredDirection();
   if(!EventSetTimer(5)) { g_store.Close(); g_storage_ok=false; return INIT_FAILED; }
   RepositionUIToRight();
   SyncSendFieldsToEntryButton();
   SyncLinesToButtons();

   ChartRedraw(0);
   return INIT_SUCCEEDED;
  }




//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(g_storage_ok) g_store.Event("EA_STOPPED",0,0,"",IntegerToString(reason));
   g_store.Close(); g_storage_ok=false; deleteObjects();
  }
void OnTimer()
  {
   if(!g_storage_ok) return;
   if(!g_store.Renew()) { g_storage_ok=false; isWebRequestEnabled=false; Print("SQLite ownership lost: EA writes and sending blocked; restart required"); }
  }



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CurrentAskPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   CurrentBidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   if(CurrentAskPrice<=0 || CurrentBidPrice<=0) return;
   TPSLReached();

   if(is_long_trade)
     {
      CreateLabelsLong();
     }

   if(is_sell_trade)
     {
      CreateLabelsShort();
     }
  }

//+------------------------------------------------------------------+

int prevMouseState = 0;

int mlbDownX1 = 0;
int mlbDownY1 = 0;

int mlbDownX2 = 0;
int mlbDownY2 = 0;
int mlbDownXD_R2 = 0;
int mlbDownYD_R2 = 0;

int mlbDownX3 = 0;
int mlbDownY3 = 0;
int mlbDownXD_R3 = 0;
int mlbDownYD_R3 = 0;

int mlbDownX4 = 0;
int mlbDownY4 = 0;
int mlbDownXD_R4 = 0;
int mlbDownYD_R4 = 0;

int mlbDownX5 = 0;
int mlbDownY5 = 0;
int mlbDownXD_R5 = 0;
int mlbDownYD_R5 = 0;

bool movingState_R3 = false;
bool movingState_R5 = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {

if(!g_storage_ok) return;
if(id == CHARTEVENT_OBJECT_CLICK)
{
   if(GetTickCount() < suppressClickUntilMs) return;
   if(sparam=="ButtonCancelOrder") { CancelStoredPosition(0); return; }
   if(sparam=="ButtonCancelOrderSell") { CancelStoredPosition(1); return; }
   const int mx = (int)lparam;
   const int my = (int)dparam;

   if(GetTickCount() < suppressClickUntilMs)
      return;

   if(sparam == "SendOnlyButton")
   {
      if(!HitTestButton("SendOnlyButton", mx, my))
         return;

      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_STATE, 0);

      if(Period()==PERIOD_M2 || Period()==PERIOD_M5 || Period()==PERIOD_H1)
      {
         if(Sabioedit)
         {
            int result = MessageBox("Sabio Prices Insert?", NULL, MB_YESNO);
            if(result == IDYES) DiscordSend();
         }
         else
            DiscordSend();
      }
      return;
   }

   return;
}
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      // 🔒 Schutzbedingung gegen Drag-Konflikt
      if(!movingState_R3 && !movingState_R5)
        {
         RepositionUIToRight();
         SyncSendFieldsToEntryButton();
         SyncLinesToButtons();
        }

      // Chart-Hintergrund lesen (auch wenn Drag aktiv ist, kann man das ruhig updaten)
      color new_bg = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);

      if(new_bg != chart_bg_user)   // nur wenn wirklich geändert
        {
         chart_bg_user = new_bg;
         ObjectSetInteger(0,"ActiveLongTrade",  OBJPROP_BORDER_COLOR, chart_bg_user);
         ObjectSetInteger(0,"ActiveShortTrade", OBJPROP_BORDER_COLOR, chart_bg_user);
        }

      ChartRedraw(0);
      return;
     }

// Persist active SL only after explicit confirmation; reject restores the line.
   if((id==CHARTEVENT_OBJECT_DRAG || id==CHARTEVENT_OBJECT_CHANGE) && (sparam==SL_Long || sparam==SL_Short))
     {
      int idx=sparam==SL_Long?0:1;
      if(!(idx==0?is_long_trade:is_sell_trade)) return;
      double old_sl=tradeInfo[idx].sl;
      double price=NormalizeDouble(ObjectGetDouble(0,sparam,OBJPROP_PRICE),_Digits);
      bool pending=tradeInfo[idx].is_trade_pending;
      bool valid=price>0 && (!pending || (idx==0?price<tradeInfo[idx].price:price>tradeInfo[idx].price));
      if(MathAbs(price-old_sl)<_Point*0.5) return;
      if(!valid || MessageBox("SL speichern und an TEST senden?","SL Update",MB_YESNO)!=IDYES) { ObjectSetDouble(0,sparam,OBJPROP_PRICE,old_sl); RefreshRestoredPositions(); return; }
      TradeInfo changed=tradeInfo[idx]; changed.sl=price;
      if(!g_store.Change(changed,pending?"PENDING":"OPEN","SL_CHANGED",DoubleToString(old_sl,_Digits),DoubleToString(price,_Digits))) { ObjectSetDouble(0,sparam,OBJPROP_PRICE,old_sl); Print("SQLite SL update failed"); return; }
      tradeInfo[idx]=changed; RefreshRestoredPositions(); SendSLUpdateToDiscord(idx); return;
     }

// --- 1) Mouse move / Drag-Handling (dein schwerster Pfad) ---
   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      const int MouseD_X   = (int)lparam;
      const int MouseD_Y   = (int)dparam;
      const int MouseState = (int)StringToInteger(sparam);

      // --- Drag-Movement-Erkennung (ZENTRAL) ---
      if(uiDragStarted && MouseState==1 && !uiDragMoved)
        {
         if(MathAbs(MouseD_X - uiDownX) >= InpDragThresholdPx ||
            MathAbs(MouseD_Y - uiDownY) >= InpDragThresholdPx)
           {
            uiDragMoved = true;
           }
        }

      bool dirty = false;

      // Button-Geometrie nur lesen, wenn nötig:
      // - beim initialen Click (MouseState 0->1)
      // - oder wenn wir gerade ziehen (movingState_R3/R5)
      int XD_R3=0,YD_R3=0,XS_R3=0,YS_R3=0;
      int XD_R5=0,YD_R5=0,XS_R5=0,YS_R5=0;

      const bool needRects = (prevMouseState==0 && MouseState==1) || movingState_R3 || movingState_R5;
      if(needRects)
        {
         XD_R3 = (int)ObjectGetInteger(0, EntryButton,OBJPROP_XDISTANCE);
         YD_R3 = (int)ObjectGetInteger(0, EntryButton,OBJPROP_YDISTANCE);
         XS_R3 = (int)ObjectGetInteger(0, EntryButton,OBJPROP_XSIZE);
         YS_R3 = (int)ObjectGetInteger(0, EntryButton,OBJPROP_YSIZE);

         XD_R5 = (int)ObjectGetInteger(0, SLButton,   OBJPROP_XDISTANCE);
         YD_R5 = (int)ObjectGetInteger(0, SLButton,   OBJPROP_YDISTANCE);
         XS_R5 = (int)ObjectGetInteger(0, SLButton,   OBJPROP_XSIZE);
         YS_R5 = (int)ObjectGetInteger(0, SLButton,   OBJPROP_YSIZE);
        }

      // MouseDown: Start Drag-State setzen
      if(prevMouseState==0 && MouseState==1)
        {
         uiDragStarted = true;
         uiDragMoved   = false;
         uiDownX       = MouseD_X;
         uiDownY       = MouseD_Y;
         mlbDownX3 = MouseD_X;
         mlbDownY3 = MouseD_Y;
         mlbDownXD_R3 = XD_R3;
         mlbDownYD_R3 = YD_R3;

         mlbDownX5 = MouseD_X;
         mlbDownY5 = MouseD_Y;
         mlbDownXD_R5 = XD_R5;
         mlbDownYD_R5 = YD_R5;

         // R3 hit?
         if(MouseD_X >= XD_R3 && MouseD_X <= XD_R3 + XS_R3 &&
            MouseD_Y >= YD_R3 && MouseD_Y <= YD_R3 + YS_R3)
            movingState_R3 = true;

         // R5 hit?
         if(MouseD_X >= XD_R5 && MouseD_X <= XD_R5 + XS_R5 &&
            MouseD_Y >= YD_R5 && MouseD_Y <= YD_R5 + YS_R5)
            movingState_R5 = true;
        }

      // Wenn gezogen wird -> Scroll aus
      if(movingState_R3 || movingState_R5)
         ChartSetInteger(0, CHART_MOUSE_SCROLL, 0, false);

      // --- Drag SL-Button (R5) ---
      if(movingState_R5)
        {
         // UI verschieben (Pixel)
         ObjectSetInteger(0, SLButton, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y - mlbDownY5);

         // SabioSL nur anfassen, wenn es existiert (Sabioedit true)
         if(Sabioedit && ObjectFind(0, SabioSL) >= 0)
            ObjectSetInteger(0, SabioSL, OBJPROP_YDISTANCE, mlbDownYD_R5 + MouseD_Y + 30 - mlbDownY3);

         // Linie updaten (Preis)
         datetime dt_SL = 0;
         double   price_SL = 0.0;
         int      window = 0;

         if(ChartXYToTimePrice(0, XD_R5, (mlbDownYD_R5 + MouseD_Y - mlbDownY5) + YS_R5, window, dt_SL, price_SL))
           {
            ObjectSetInteger(0, SL_HL, OBJPROP_TIME,  dt_SL);
            ObjectSetDouble(0,  SL_HL, OBJPROP_PRICE, price_SL);
           }

         // Preise aktualisieren
         Entry_Price = Get_Price_d(PR_HL);
         SL_Price    = Get_Price_d(SL_HL);

         // Richtung setzen (SL unter/gleich Entry => BUY)
         isBuy = (SL_Price <= Entry_Price);

         // Sabio Texte aktualisieren (nur wenn Sabioedit aktiv und Objekte existieren)
         // Sabio Texte IMMER aus Linien übernehmen
         if(Sabioedit)
           {
            if(ObjectFind(0, SabioEntry) >= 0)
               update_Text(SabioEntry, "SABIO ENTRY: " + Get_Price_s(PR_HL));

            if(ObjectFind(0, SabioSL) >= 0)
               update_Text(SabioSL,    "SABIO SL: "   + Get_Price_s(SL_HL));
           }

         // Lots + Texte abhängig von Richtung
         double lots = 0.0;
         if(isBuy)
           {
            lots = NormalizeDouble(calcLots(Entry_Price - SL_Price), 2);

            update_Text(EntryButton,
                        "Buy Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));

            update_Text(SLButton,
                        "SL: " + DoubleToString(((Entry_Price - SL_Price) / _Point), 0) +
                        " Points | " + Get_Price_s(SL_HL));
           }
         else
           {
            lots = NormalizeDouble(calcLots(SL_Price - Entry_Price), 2);

            update_Text(EntryButton,
                        "Sell Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));

            update_Text(SLButton,
                        "SL: " + DoubleToString(((SL_Price - Entry_Price) / _Point), 0) +
                        " Points | " + Get_Price_s(SL_HL));
           }

         dirty = true;
        }

      // --- Drag Entry-Button (R3) ---
      if(movingState_R3)
        {
         // Neue Y-Positionen
         int newY_Entry = mlbDownYD_R3 + MouseD_Y - mlbDownY3;
         int newY_SL    = mlbDownYD_R5 + MouseD_Y - mlbDownY5;

         if(uiDragStarted && MouseState==1)
           {
            if(MathAbs(MouseD_X - uiDownX) >= InpDragThresholdPx ||
               MathAbs(MouseD_Y - uiDownY) >= InpDragThresholdPx)
              {
               uiDragMoved = true;
              }
           }

         // Buttons + UI verschieben
         ObjectSetInteger(0, EntryButton, OBJPROP_YDISTANCE, newY_Entry);
         ObjectSetInteger(0, SLButton,    OBJPROP_YDISTANCE, newY_SL);

         // Send/Edits mitziehen (falls vorhanden)
         if(ObjectFind(0, BTN2)  >= 0)
            ObjectSetInteger(0, BTN2,  OBJPROP_YDISTANCE, newY_Entry);
         if(ObjectFind(0, TRNB)  >= 0)
            ObjectSetInteger(0, TRNB,  OBJPROP_YDISTANCE, newY_Entry + 30);
         if(ObjectFind(0, POSNB) >= 0)
            ObjectSetInteger(0, POSNB, OBJPROP_YDISTANCE, newY_Entry + 30);

         // Sabio-Felder nur wenn aktiv + existieren
         if(Sabioedit)
           {
            if(ObjectFind(0, SabioEntry) >= 0)
               ObjectSetInteger(0, SabioEntry, OBJPROP_YDISTANCE, newY_Entry + 30);
            if(ObjectFind(0, SabioSL)    >= 0)
               ObjectSetInteger(0, SabioSL,    OBJPROP_YDISTANCE, newY_SL + 30);
           }

         // Linien updaten
         datetime dt_PRC = 0, dt_SL1 = 0;
         double   price_PRC = 0.0, price_SL1 = 0.0;
         int      window = 0;

         // EntryButton -> PR_HL
         if(ChartXYToTimePrice(0, XD_R3, newY_Entry + YS_R3, window, dt_PRC, price_PRC))
           {
            ObjectSetInteger(0, PR_HL, OBJPROP_TIME,  dt_PRC);
            ObjectSetDouble(0,  PR_HL, OBJPROP_PRICE, price_PRC);
           }

         // SLButton -> SL_HL
         if(ChartXYToTimePrice(0, XD_R5, newY_SL + YS_R5, window, dt_SL1, price_SL1))
           {
            ObjectSetInteger(0, SL_HL, OBJPROP_TIME,  dt_SL1);
            ObjectSetDouble(0,  SL_HL, OBJPROP_PRICE, price_SL1);
           }

         // Preise aktualisieren
         Entry_Price = Get_Price_d(PR_HL);
         SL_Price    = Get_Price_d(SL_HL);

         // Richtung setzen (SL unter/gleich Entry => BUY)
         isBuy = (SL_Price <= Entry_Price);

         // Sabio-Text (falls aktiv)
         // Sabio Texte IMMER aus Linien übernehmen (bei R3 bewegen sich ja beide Buttons/Linien)
         if(Sabioedit)
           {
            if(ObjectFind(0, SabioEntry) >= 0)
               update_Text(SabioEntry, "SABIO ENTRY: " + Get_Price_s(PR_HL));

            if(ObjectFind(0, SabioSL) >= 0)
               update_Text(SabioSL,    "SABIO SL: "   + Get_Price_s(SL_HL));
           }

         // Lots + Texte abhängig von Richtung
         double lots = 0.0;
         if(isBuy)
           {
            lots = NormalizeDouble(calcLots(Entry_Price - SL_Price), 2);

            update_Text(EntryButton,
                        "Buy Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));

            update_Text(SLButton,
                        "SL: " + DoubleToString(((Entry_Price - SL_Price) / _Point), 0) +
                        " Points | " + Get_Price_s(SL_HL));
           }
         else
           {
            lots = NormalizeDouble(calcLots(SL_Price - Entry_Price), 2);

            update_Text(EntryButton,
                        "Sell Stop @ " + Get_Price_s(PR_HL) + " | Lot: " + DoubleToString(lots, 2));

            update_Text(SLButton,
                        "SL: " + DoubleToString(((SL_Price - Entry_Price) / _Point), 0) +
                        " Points | " + Get_Price_s(SL_HL));
           }

         dirty = true;
        }


      // --- Direction-Change nur während Drag (R3/R5) behandeln
      if((movingState_R3 || movingState_R5) && (isBuy != prevIsBuy))
        {

         SetEditsFromStoredDirection();
         prevIsBuy = isBuy;
        }

      // MouseUp: Drag beenden
      if(MouseState == 0)
        {
         // wenn wir wirklich gezogen haben: nächste Click-Events kurz blocken
         if(uiDragStarted && uiDragMoved)
            suppressClickUntilMs = GetTickCount() + (uint)InpSuppressClickMs;

         uiDragStarted = false;
         uiDragMoved   = false;

         movingState_R3 = false;
         movingState_R5 = false;
         ChartSetInteger(0, CHART_MOUSE_SCROLL, 0, true);
        }




      prevMouseState = MouseState;

      if(dirty)
         ChartRedraw(0);

      // Wichtig: mouse move abgearbeitet -> raus
      return;
     }


  }



//+------------------------------------------------------------------+
//| Create Trading Button                                                                 |
//+------------------------------------------------------------------+
bool createButton(string objName, string text, int xD, int yD, int xS, int yS, color clrTxt, color clrBG, int fontsize = 12, color clrBorder = clrNONE, string font = "Calibri")
  {
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, TimeCurrent()))
     {
      Print(__FUNCTION__, ": Failed to create Btn: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, xD);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, yD);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, xS);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, yS);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrTxt);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrBG);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrBorder);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STATE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_CENTER);

   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//| Create Preislinien Trading Buttton                                                                 |
//+------------------------------------------------------------------+
bool createHL(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();
   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      Print(__FUNCTION__, ": Failed to create HL: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_TIME, time1);
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);

   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//| Send und T & S Button                                                                 |
//+------------------------------------------------------------------+
void SendButton()
  {
   ObjectCreate(0, "SendOnlyButton", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_XDISTANCE, xd3-120);   // X position
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_XSIZE, 120);       // width
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_YDISTANCE, yd3);    // Y position
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_YSIZE, 30);        // height
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_CORNER, 0);        // chart corner
   ObjectSetInteger(0,"SendOnlyButton", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,"SendOnlyButton", OBJPROP_SELECTED, false);
   ObjectSetInteger(0,"SendOnlyButton", OBJPROP_STATE, 0);
   ObjectSetInteger(0,"SendOnlyButton", OBJPROP_BACK, false);
   ObjectSetInteger(0,"SendOnlyButton", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,"SendOnlyButton", OBJPROP_CORNER, CORNER_LEFT_UPPER);

   if(!SendOnlyButton)
     {
      ObjectSetString(0, "SendOnlyButton", OBJPROP_TEXT, "T & S"); // label
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_BGCOLOR, TSButton_bgcolor);
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_COLOR, TSButton_font_color);
     }
   else
     {
      ObjectSetString(0, "SendOnlyButton", OBJPROP_TEXT, "Send only"); // label
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_BGCOLOR, SendOnlyButton_bgcolor);
      ObjectSetInteger(0, "SendOnlyButton", OBJPROP_COLOR, SendOnlyButton_font_color);
     }
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_FONTSIZE, SendOnlyButton_font_size);

//+------------------------------------------------------------------+
//|   TradenummerneingabeFeld
//+------------------------------------------------------------------+

   ObjectCreate(0, TRNB, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,TRNB,OBJPROP_XDISTANCE,xd3-120);
   ObjectSetInteger(0,TRNB,OBJPROP_YDISTANCE,yd3+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,TRNB,OBJPROP_XSIZE,60);
   ObjectSetInteger(0,TRNB,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,TRNB,OBJPROP_TEXT,"0");
//--- Schriftgröße setzen
   ObjectSetInteger(0,TRNB, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, TRNB, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, TRNB, OBJPROP_ALIGN,ALIGN_RIGHT);
//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,true);


//+------------------------------------------------------------------+
//|   PositionsnummerneingabeFeld
//+------------------------------------------------------------------+

   ObjectCreate(0, POSNB, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,POSNB,OBJPROP_XDISTANCE,xd3-60);
   ObjectSetInteger(0,POSNB,OBJPROP_YDISTANCE,yd3+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,POSNB,OBJPROP_XSIZE,60);
   ObjectSetInteger(0,POSNB,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,POSNB,OBJPROP_TEXT,"0");
//--- Schriftgröße setzen
   ObjectSetInteger(0,POSNB, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, POSNB, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, POSNB, OBJPROP_ALIGN,ALIGN_RIGHT);
//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,POSNB,OBJPROP_READONLY,true);
  }


//+------------------------------------------------------------------+
//| Eingabefelder für Sabio Preise                                                                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SabioEdit()
  {
//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
//   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,true);

//SabioSLEdit
   ObjectCreate(0, SabioSL, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,SabioSL,OBJPROP_XDISTANCE,xd3);
   ObjectSetInteger(0,SabioSL,OBJPROP_YDISTANCE,yd5+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,SabioSL,OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SabioSL,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioSL,OBJPROP_TEXT,"SABIO SL: "+ Get_Price_s(SL_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioSL, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioSL, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
//   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,true);

//SabioEntryEdit
   ObjectCreate(0, SabioEntry, OBJ_EDIT, 0, 0, 0);
//--- Objektkoordinaten angeben
   ObjectSetInteger(0,SabioEntry,OBJPROP_XDISTANCE,xd3);
   ObjectSetInteger(0,SabioEntry,OBJPROP_YDISTANCE,yd3+30);
//--- Objektgröße setzen
   ObjectSetInteger(0,SabioEntry,OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SabioEntry,OBJPROP_YSIZE,30);
//--- den Text setzen
   ObjectSetString(0,SabioEntry,OBJPROP_TEXT,"SABIO ENTRY: "+ Get_Price_s(PR_HL));
//--- Schriftgröße setzen
   ObjectSetInteger(0,SabioEntry, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, SabioEntry, OBJPROP_COLOR, clrBlack);

//--- aktivieren (true) oder deaktivieren (false) den schreibgeschützten Modus
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,true);
  }

//+------------------------------------------------------------------+
//| an Discord senden                                                           |
//+------------------------------------------------------------------+
void DiscordSend()
  {
   if(!g_storage_ok || !g_store.Renew()) { Print("SQLite unavailable: signal blocked"); return; }
   if(!isWebRequestEnabled || get_discord_webhook()=="") { MessageBox("TEST webhook unavailable. Check V2 config in MQL5/Files."); return; }
   if(_Period!=PERIOD_M2 && _Period!=PERIOD_M5 && _Period!=PERIOD_H1) return;
   Entry_Price=Get_Price_d(PR_HL); SL_Price=Get_Price_d(SL_HL);
   if(Entry_Price<=0 || SL_Price<=0 || Entry_Price==SL_Price) { MessageBox("Entry and SL must be positive and different."); return; }
   isBuy=SL_Price<Entry_Price;
   int idx=isBuy?0:1;
   if((isBuy && is_long_trade) || (!isBuy && is_sell_trade)) { MessageBox("Stage 1: one active position per direction. Close it before creating another trade."); return; }
   if((isBuy && Entry_Price<=SymbolInfoDouble(_Symbol,SYMBOL_ASK)) || (!isBuy && Entry_Price>=SymbolInfoDouble(_Symbol,SYMBOL_BID))) { MessageBox("Pending entry must be beyond the current Ask/Bid."); return; }
   double lots=calcLots(MathAbs(Entry_Price-SL_Price));
   if(lots<=0) { MessageBox("Invalid risk volume."); return; }
   TradeInfo p;
   p.tradenummer=0; p.position=1; p.symbol=_Symbol; p.type=isBuy?"BUY":"SELL";
   p.price=Entry_Price; p.sl=SL_Price; p.lots=lots;
   p.sabioentry=(Sabioedit && ObjectFind(0,SabioEntry)>=0)?ObjectGetString(0,SabioEntry,OBJPROP_TEXT):"";
   p.sabiosl=(Sabioedit && ObjectFind(0,SabioSL)>=0)?ObjectGetString(0,SabioSL,OBJPROP_TEXT):"";
   p.was_send=false; p.is_trade_pending=true;
   if(!g_store.Create(p)) { MessageBox("SQLite commit failed. Nothing sent; numbering unchanged."); return; }
   tradeInfo[idx]=p;
   if(isBuy) { is_long_trade=true; HitEntryPriceLong=false; send_SL_buy=false; send_CL_buy=false; }
   else { is_sell_trade=true; HitEntryPriceShort=false; send_SL_sell=false; send_CL_sell=false; }
   RefreshRestoredPositions(); SetEditsFromStoredDirection();
   tradeInfo[idx].was_send=SendDiscordMessage(FormatTradeMessage(tradeInfo[idx]));
   if(tradeInfo[idx].was_send) SendScreenShot(_Symbol,_Period,getChartWidthInPixels(),getChartHeightInPixels());
   else Print("Trade stored locally; Discord delivery failed or uncertain. No automatic retry.");
  }

//+------------------------------------------------------------------+
//|  TP or SL reached                                                                |
//+------------------------------------------------------------------+
void TPSLReached()
  {
   if(!g_storage_ok || slDragActive) return;
   for(int idx=0;idx<2;idx++)
     {
      bool active=idx==0?is_long_trade:is_sell_trade;
      if(!active) continue;
      bool hit=idx==0?HitEntryPriceLong:HitEntryPriceShort;
      bool entry=idx==0?CurrentAskPrice>=tradeInfo[idx].price:CurrentBidPrice<=tradeInfo[idx].price;
      if(!hit && entry)
        {
         if(!g_store.Change(tradeInfo[idx],"OPEN","ENTRY_HIT","PENDING","OPEN")) { Print("SQLite ENTRY_HIT failed"); return; }
         hit=true; tradeInfo[idx].is_trade_pending=false;
         if(idx==0) HitEntryPriceLong=true; else HitEntryPriceShort=true;
         RefreshRestoredPositions();
        }
      bool stopped=idx==0?CurrentBidPrice<=tradeInfo[idx].sl:CurrentAskPrice>=tradeInfo[idx].sl;
      if(hit && stopped)
        {
         if(!g_store.Change(tradeInfo[idx],"CLOSED_SL","SL_HIT","OPEN","CLOSED_SL")) { Print("SQLite SL_HIT failed"); return; }
         if(idx==0) { is_long_trade=false; HitEntryPriceLong=false; send_SL_buy=true; DeleteLinesandLabelsLong(); }
         else { is_sell_trade=false; HitEntryPriceShort=false; send_SL_sell=true; DeleteLinesandLabelsShort(); }
         ObjectSetString(0,idx==0?"ActiveLongTrade":"ActiveShortTrade",OBJPROP_TEXT,"");
         SendDiscordMessage(FormatSLMessage(tradeInfo[idx]));
         SetEditsFromStoredDirection();
        }
     }
  }


//+------------------------------------------------------------------+
//| bmp-File erstellen                                               |
//+------------------------------------------------------------------+
void DHFileBMP() {} // Logo resource was not supplied; no compile-time dependency.

//+------------------------------------------------------------------+
//| Label für Tradenummern                                           |
//+------------------------------------------------------------------+
void LabelTradeNumber()
  {
   ObjectCreate(0, "LabelTradenummer", OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_XDISTANCE,100);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_YDISTANCE,90+30+10+30+10);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_XSIZE,330);
   ObjectSetInteger(0,"LabelTradenummer",OBJPROP_YSIZE,30);
//   ObjectSetString(0,"LabelTradenummer",OBJPROP_TEXT,"Last Trade Number: " + tradenummer);
//   ObjectSetString(0,"LabelTradenummer",OBJPROP_TEXT, "Last Trade Number: " + IntegerToString(tradenummer));
   ObjectSetString(0,"LabelTradenummer",OBJPROP_TEXT, "Last Trade Number: -");



   ObjectSetInteger(0,"LabelTradenummer", OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, "LabelTradenummer", OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, "LabelTradenummer", OBJPROP_FONTSIZE, InfoLabelFontSize);
   ObjectSetString(0, "LabelTradenummer", OBJPROP_FONT, "Arial");
  }

//+------------------------------------------------------------------+
//| Sabio TP berechnen                                               |
//+------------------------------------------------------------------+
void UpdateSabioTP()
  {
   if(Entry_Price > CurrentAskPrice)
     {
      string EntryPriceString = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
      int Ergebnis = StringReplace(EntryPriceString,"SABIO ENTRY:","");
      double SabioEntryPrice = (double)EntryPriceString;
      string SabioSLPriceString = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
      int ErgebnisSL = StringReplace(SabioSLPriceString,"SABIO SL:","");
      double SabioSLPrice = (double)SabioSLPriceString;
      //      if(SabioEntryPrice > 0 && SabioSLPrice > 0 && SabioEntryPrice != SabioSLPrice)
      //      {
      // Steffen         double SabioTPPrice = MathAbs(SabioEntryPrice - SabioSLPrice);
      // Steffen         update_Text(SabioTP, "SABIO TP: " + (int)(SabioTPPrice + SabioEntryPrice));
      //       }
     }

   if(Entry_Price < CurrentBidPrice)
     {
      string EntryPriceString = ObjectGetString(0,SabioEntry,OBJPROP_TEXT,0);
      int Ergebnis = StringReplace(EntryPriceString,"SABIO ENTRY:","");
      double SabioEntryPrice = (double)EntryPriceString;
      string SabioSLPriceString = ObjectGetString(0,SabioSL,OBJPROP_TEXT,0);
      int ErgebnisSL = StringReplace(SabioSLPriceString,"SABIO SL:","");

      double SabioSLPrice = (double)SabioSLPriceString;

      //     if(SabioEntryPrice > 0 && SabioSLPrice > 0 && SabioEntryPrice != SabioSLPrice)
      //     {
      // Steffen         double SabioTPPrice = MathAbs(SabioSLPrice -SabioEntryPrice);
      // Steffen         update_Text(SabioTP, "SABIO TP: " + (int)(SabioEntryPrice - SabioTPPrice));
      //   }
     }
  }

//+------------------------------------------------------------------+
//| Create Trading Lines
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateTPSLLines(string objName, datetime time1, double price1, color clr)
  {
   ResetLastError();

   if(!ObjectCreate(0, objName, OBJ_HLINE, 0, time1, price1))
     {
      Print(__FUNCTION__, ": Failed to create HL: Error Code: ", GetLastError());
      return (false);
     }
   ObjectSetInteger(0, objName, OBJPROP_TIME, TimeCurrent());
   ObjectSetDouble(0, objName, OBJPROP_PRICE, price1);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);


   ChartRedraw(0);
   return (true);
  }

//+------------------------------------------------------------------+
//| Create Line Labels
//+------------------------------------------------------------------+

void CreateLabelsTPSLLines(string name, string text, double price, color clr)
{
   // Create once
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_TEXT, 0, TimeCurrent(), price))
      {
         Print(__FUNCTION__, ": Failed to create OBJ_TEXT ", name, " err=", GetLastError());
         return;
      }
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12);
   }

   // Update every time
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_TIME,  TimeCurrent());
   ObjectSetDouble (0, name, OBJPROP_PRICE, price);
   ObjectSetString (0, name, OBJPROP_TEXT,  text);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsLong()
  {
   CreateLabelsTPSLLines(LabelSLLong,"SL Long Trade", tradeInfo[0].sl,TradeSLLineLong);
   update_Text(LabelSLLong, "SL Long Trade");
   CreateLabelsTPSLLines(LabelEntryLong,"Entry Long Trade", tradeInfo[0].price,TradeEntryLineLong);
   update_Text(LabelEntryLong, "Entry Long Trade");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabelsShort()
  {
   CreateLabelsTPSLLines(LabelSLShort,"SL Short Trade", tradeInfo[1].sl,TradeSLLineShort);
   update_Text(LabelSLShort, "SL Short Trade");
   CreateLabelsTPSLLines(LabelEntryShort,"Entry Short Trade", tradeInfo[1].price,TradeEntryLineShort);
   update_Text(LabelEntryShort, "Entry Short Trade");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateTextPosition()
  {
   datetime time2 = (datetime)ObjectGetInteger(0, SL_Long, OBJPROP_TIME, 1);
   double   price2 = ObjectGetDouble(0, SL_Long, OBJPROP_PRICE, 1);

   ObjectSetInteger(0, LabelSLLong, OBJPROP_TIME, time2);
   ObjectSetDouble(0, LabelSLLong, OBJPROP_PRICE, price2 + 10 * _Point);
  }


//+------------------------------------------------------------------+
//|   Delete all objects                                 |
//+------------------------------------------------------------------+
void deleteObjects()
  {
   ObjectDelete(0, EntryButton);
   ObjectDelete(0, SLButton);
   ObjectDelete(0, SL_HL);
   ObjectDelete(0, PR_HL);
   ObjectDelete(0, "SendOnlyButton");
   ObjectDelete(0, "ButtonTargetReached");
   ObjectDelete(0, "ButtonStoppedout");
   ObjectDelete(0, "ButtonCancelOrder");
   ObjectDelete(0, "ButtonTargetReachedSell");
   ObjectDelete(0, "ButtonStoppedoutSell");
   ObjectDelete(0, "ButtonCancelOrderSell");
   ObjectDelete(0, "EingabeTrade");
   ObjectDelete(0, "SabioEntry");
   ObjectDelete(0, "SabioSL");
   ObjectDelete(0, "InfoButtonCancelOrder");
   ObjectDelete(0, "ActiveShortTrade");
   ObjectDelete(0, "InfoButtonStoppedoutSell");
   ObjectDelete(0, "InfoButtonCancelOrderSell");
   ObjectDelete(0, "ActiveLongTrade");
   ObjectDelete(0, "InfoButtonStoppedout");
   ObjectDelete(0, "SL_Long");
   ObjectDelete(0, "SL_Short");
   ObjectDelete(0, "LabelSLLong");
   ObjectDelete(0, "LabelSLShort");
   ObjectDelete(0, "LabelTradenummer");
   ObjectDelete(0, POSNB);
   ObjectDelete(0, "Entry_Long");
   ObjectDelete(0, "Entry_Short");
   ObjectDelete(0, "LabelEntryLong");
   ObjectDelete(0, "LabelEntryShort");
   ObjectDelete(0, "DHFileBMP");

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Tradelinien Long löschen                                                                  |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsLong()
  {
   ObjectDelete(0, "SL_Long");
   ObjectDelete(0, "LabelSLLong");
   ObjectDelete(0, "Entry_Long");
   ObjectDelete(0, "LabelEntryLong");

  }
//+------------------------------------------------------------------+
//| Tradelinien Short löschen                                                                 |
//+------------------------------------------------------------------+
void DeleteLinesandLabelsShort()
  {
   ObjectDelete(0, "SL_Short");
   ObjectDelete(0, "LabelSLShort");
   ObjectDelete(0, "Entry_Short");
   ObjectDelete(0, "LabelEntryShort");
  }

//+------------------------------------------------------------------+
void InitTradeInfo()
  {
   for(int i=0;i<2;i++)
     {
      tradeInfo[i].tradenummer=-1;
      tradeInfo[i].symbol=_Symbol;
      tradeInfo[i].price=Entry_Price;
      tradeInfo[i].sl=SL_Price;
      tradeInfo[i].was_send=false;
     }
   tradeInfo[0].type="BUY";
   tradeInfo[1].type="SELL";
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SyncLinesToButtons()
  {
   int window = 0;
   datetime dt;
   double price;

// --- EntryButton -> PR_HL
   int xd = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XDISTANCE);
   int yd = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YDISTANCE);
   int ys = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YSIZE);

   if(ChartXYToTimePrice(0, xd, yd + ys, window, dt, price))
     {
      ObjectSetInteger(0, PR_HL, OBJPROP_TIME, dt);
      ObjectSetDouble(0, PR_HL, OBJPROP_PRICE, price);
     }

// --- SLButton -> SL_HL
   xd = (int)ObjectGetInteger(0, SLButton, OBJPROP_XDISTANCE);
   yd = (int)ObjectGetInteger(0, SLButton, OBJPROP_YDISTANCE);
   ys = (int)ObjectGetInteger(0, SLButton, OBJPROP_YSIZE);

   if(ChartXYToTimePrice(0, xd, yd + ys, window, dt, price))
     {
      ObjectSetInteger(0, SL_HL, OBJPROP_TIME, dt);
      ObjectSetDouble(0, SL_HL, OBJPROP_PRICE, price);
     }
  }


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateDirectionFromEntrySL()
  {
   double entry = Get_Price_d(PR_HL);
   double sl    = Get_Price_d(SL_HL);

   if(sl < entry)
      isBuy = true;
   else
      if(sl > entry)
         isBuy = false;
// sl == entry -> isBuy unverändert lassen
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RepositionUIToRight()
  {
   int chartW = getChartWidthInPixels();
   int chartH = getChartHeightInPixels();

   int baseX = chartW - DistancefromRight;
   int baseY = chartH / 2;

// Entry / SL
   ObjectSetInteger(0, EntryButton, OBJPROP_XDISTANCE, baseX);
   ObjectSetInteger(0, SLButton,    OBJPROP_XDISTANCE, baseX);

// Sabio Felder (falls aktiv)
   if(Sabioedit)
     {
      ObjectSetInteger(0, SabioEntry, OBJPROP_XDISTANCE, baseX);
      ObjectSetInteger(0, SabioSL,    OBJPROP_XDISTANCE, baseX);
     }
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateTextPositionLong()
  {
   datetime t = (datetime)ObjectGetInteger(0, SL_Long, OBJPROP_TIME, 0);
   double   p = ObjectGetDouble(0, SL_Long, OBJPROP_PRICE, 0);
   ObjectSetInteger(0, LabelSLLong, OBJPROP_TIME,  t);
   ObjectSetDouble(0, LabelSLLong, OBJPROP_PRICE, p + 10 * _Point);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateTextPositionShort()
  {
   datetime t = (datetime)ObjectGetInteger(0, SL_Short, OBJPROP_TIME, 0);
   double   p = ObjectGetDouble(0, SL_Short, OBJPROP_PRICE, 0);
   ObjectSetInteger(0, LabelSLShort, OBJPROP_TIME,  t);
   ObjectSetDouble(0, LabelSLShort, OBJPROP_PRICE, p + 10 * _Point);
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendSLUpdateToDiscord(int idx) // idx: 0=BUY, 1=SELL
  {
   string msg = FormatUpdateTradeMessage(tradeInfo[idx]);
   bool ret   = SendDiscordMessage(msg);
   if(!ret)
      Print("Fehler beim SL-Update senden (Discord).");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string BuildTradeTagFromEdits()
  {
   string tn_s = ObjectGetString(0, TRNB,  OBJPROP_TEXT, 0);
   string pn_s = ObjectGetString(0, POSNB, OBJPROP_TEXT, 0);

// Trim/clean
   StringReplace(tn_s, " ",  "");
   StringReplace(tn_s, "\t", "");
   StringReplace(pn_s, " ",  "");
   StringReplace(pn_s, "\t", "");

   int tn = (int)StringToInteger(tn_s);
   int pn = (int)StringToInteger(pn_s);

   if(tn <= 0 || pn <= 0)
      return "";

   return StringFormat("[Trade Nr. %d.%d]", tn, pn);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SyncSendFieldsToEntryButton()
  {
   if(ObjectFind(0, EntryButton) < 0)
      return;

// Referenz: aktuelles X vom EntryButton (das ist das "neue xd3" nach RepositionUIToRight)
   int xEntry = (int)ObjectGetInteger(0, EntryButton, OBJPROP_XDISTANCE);
   int yEntry = (int)ObjectGetInteger(0, EntryButton, OBJPROP_YDISTANCE);

// Einmalig konsistente Verankerung erzwingen (wichtig!)
   FixCorner("SendOnlyButton");
   FixCorner(TRNB);
   FixCorner(POSNB);

// X-Kopplung wie bei deiner Erstellung:
// SendOnlyButton und TRNB links vom Entry-Button, POSNB rechts daneben
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_XDISTANCE, xEntry - 120);
   ObjectSetInteger(0, TRNB,           OBJPROP_XDISTANCE, xEntry - 120);
   ObjectSetInteger(0, POSNB,          OBJPROP_XDISTANCE, xEntry - 60);

// Optional: falls du willst, dass Y auch immer “unter EntryButton” bleibt:
// (du machst das schon beim Drag, aber bei ChartChange kann das auch sinnvoll sein)
   ObjectSetInteger(0, "SendOnlyButton", OBJPROP_YDISTANCE, yEntry);
   ObjectSetInteger(0, TRNB,            OBJPROP_YDISTANCE, yEntry + 30);
   ObjectSetInteger(0, POSNB,           OBJPROP_YDISTANCE, yEntry + 30);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FixCorner(const string name)
  {
   if(ObjectFind(0, name) < 0)
      return;
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); // = 0
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetEditsFromStoredDirection()
  {
   int tn=0; if(!g_storage_ok || !g_store.Next(tn)) return;
   ObjectSetString(0,TRNB,OBJPROP_TEXT,IntegerToString(tn));
   ObjectSetString(0,POSNB,OBJPROP_TEXT,"1");
   ObjectSetInteger(0,TRNB,OBJPROP_READONLY,true);
   ObjectSetInteger(0,POSNB,OBJPROP_READONLY,true);
   update_Text("LabelTradenummer","Next Trade Number: "+IntegerToString(tn)+".1");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SaveCurrentEditsToSlot(const bool dirBuy) {} // Legacy edits are now read-only.


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HitTestButton(const string name, const int mx, const int my)
  {
   if(ObjectFind(0, name) < 0)
      return false;

   int xd = (int)ObjectGetInteger(0, name, OBJPROP_XDISTANCE);
   int yd = (int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE);
   int xs = (int)ObjectGetInteger(0, name, OBJPROP_XSIZE);
   int ys = (int)ObjectGetInteger(0, name, OBJPROP_YSIZE);

   return (mx >= xd && mx <= xd + xs && my >= yd && my <= yd + ys);
  }
//+------------------------------------------------------------------+

void RefreshRestoredPositions()
  {
   for(int idx=0;idx<2;idx++)
     {
      if(!(idx==0?is_long_trade:is_sell_trade)) continue;
      string entry=idx==0?Entry_Long:Entry_Short;
      string sl=idx==0?SL_Long:SL_Short;
      CreateTPSLLines(entry,TimeCurrent(),tradeInfo[idx].price,idx==0?TradeEntryLineLong:TradeEntryLineShort);
      CreateTPSLLines(sl,TimeCurrent(),tradeInfo[idx].sl,idx==0?TradeSLLineLong:TradeSLLineShort);
      ObjectSetInteger(0,entry,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,sl,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(0,sl,OBJPROP_SELECTED,false);
      bool hit=idx==0?HitEntryPriceLong:HitEntryPriceShort;
      ObjectSetInteger(0,entry,OBJPROP_STYLE,hit?STYLE_SOLID:STYLE_DASH);
      ObjectSetInteger(0,sl,OBJPROP_STYLE,hit?STYLE_SOLID:STYLE_DASH);
      if(idx==0) CreateLabelsLong(); else CreateLabelsShort();
      string label=idx==0?"ActiveLongTrade":"ActiveShortTrade";
      ObjectSetString(0,label,OBJPROP_TEXT,"Trade "+IntegerToString(tradeInfo[idx].tradenummer)+".1 "+(hit?"OPEN":"PENDING"));
      ObjectSetInteger(0,label,OBJPROP_COLOR,clrWhite);
      ObjectSetInteger(0,label,OBJPROP_BGCOLOR,idx==0?clrGreen:clrRed);
      ObjectSetInteger(0,label,OBJPROP_BACK,false);
     }
   ChartRedraw();
  }
void CancelStoredPosition(int idx)
  {
   ObjectSetInteger(0,idx==0?"ButtonCancelOrder":"ButtonCancelOrderSell",OBJPROP_STATE,0);
   if(!g_storage_ok || !(idx==0?is_long_trade:is_sell_trade)) return;
   if(MessageBox("Position lokal schliessen und Cancel an TEST senden?","Cancel",MB_YESNO)!=IDYES) return;
   if(!g_store.Change(tradeInfo[idx],"CLOSED_CANCEL","CANCEL",tradeInfo[idx].is_trade_pending?"PENDING":"OPEN","CLOSED_CANCEL")) { Print("SQLite cancel failed"); return; }
   if(idx==0) { is_long_trade=false; HitEntryPriceLong=false; send_CL_buy=true; DeleteLinesandLabelsLong(); }
   else { is_sell_trade=false; HitEntryPriceShort=false; send_CL_sell=true; DeleteLinesandLabelsShort(); }
   ObjectSetString(0,idx==0?"ActiveLongTrade":"ActiveShortTrade",OBJPROP_TEXT,"");
   SendDiscordMessage(FormatCancelTradeMessage(tradeInfo[idx])); SetEditsFromStoredDirection();
  }

bool RecordDiscordAttempt(string kind,int http)
  {
   if(!g_storage_ok) return false;
   bool ok=g_store.Event(kind,g_transport_trade,g_transport_pos,"",IntegerToString(http));
   if(!ok) { isWebRequestEnabled=false; Print("Discord event persistence failed: sending disabled"); }
   return ok;
  }
