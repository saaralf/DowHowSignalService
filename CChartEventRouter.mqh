/**
 * Beschreibung: Zentraler Router für Chart-Events. Legt die Reihenfolge fest:
 *               1) TradesPanel (C*-GUI) 2) Controller (Send, Drag, ...) 3) Legacy/Rest.
 * Parameter:    id,lparam,dparam,sparam - Standard ChartEvent Parameter
 * Rückgabewert: bool - true wenn Event vollständig verarbeitet wurde
 * Hinweise:     Erst wenn Router false liefert, läuft Legacy-Code weiter.
 * Fehlerfälle:  keine
 */
class CChartEventRouter
  {
public:
   bool Dispatch(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      // 1) Panel zuerst (Row Buttons etc.)
      if(g_tp.OnChartEvent(id, lparam, dparam, sparam))
         return true;

      // 2) Controller Chain
      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(g_send_ctl.OnObjectClick(sparam))
            return true;
        }

      if(id == CHARTEVENT_OBJECT_DRAG)
        {
         
   

         
         }

      if(id == CHARTEVENT_OBJECT_CHANGE)
        {
       
        }

      // MouseUp-Fallback wird im MOUSE_MOVE Block gemacht (weil MouseState benötigt wird)
      return false;
     }
  };

static CChartEventRouter g_evt_router;
