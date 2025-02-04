
//+------------------------------------------------------------------+
//| Die Funktion erhält den Wert der Höhe des Charts in Pixeln       |
//+------------------------------------------------------------------+
int getChartHeightInPixels(const long chartID = 0, const int subwindow = 0)
{
    //--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
    long result = -1;
    //--- Setzen den Wert des Fehlers zurück
    ResetLastError();
    //--- Erhalten wir den Wert der Eigenschaft
    if (!ChartGetInteger(chartID, CHART_HEIGHT_IN_PIXELS, 0, result))
    {
        //--- Schreiben die Fehlermeldung in den Log "Experten"
        Print(__FUNCTION__ + ", Error Code = ", GetLastError());
    }
    //--- Geben den Wert der Eigenschaft zurück
    return ((int)result);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Die Funktion erhält den Wert der Breite des Charts in Pixeln     |
//+------------------------------------------------------------------+
int getChartWidthInPixels(const long chart_ID = 0)
{
    //--- Bereiten wir eine Variable, um den Wert der Eigenschaft zu erhalten
    long result = -1;
    //--- Setzen den Wert des Fehlers zurück
    ResetLastError();
    //--- Erhalten wir den Wert der Eigenschaft
    if (!ChartGetInteger(chart_ID, CHART_WIDTH_IN_PIXELS, 0, result))
    {
        //--- Schreiben die Fehlermeldung in den Log "Experten"
        Print(__FUNCTION__ + ", Error Code = ", GetLastError());
    }
    //--- Geben den Wert der Eigenschaft zurück
    return ((int)result);
}




double Get_Price_d(string name)
{
   return ObjectGetDouble(0, name, OBJPROP_PRICE);
}

string Get_Price_s(string name)
{
   return DoubleToString(ObjectGetDouble(0, name, OBJPROP_PRICE), _Digits);
}


string update_Text(string name, string val)
{
   return (string)ObjectSetString(0, name, OBJPROP_TEXT, val);
}

double calcLots(double slDistance)
{
   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if (ticksize == 0 || tickvalue == 0 || lotstep == 0)
   {
      Print(__FUNCTION__, "> Lotsize cannot be calculated");
      return 0;
   }

   double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * DefaultRisk / 100;
   double moneyLotstep = (slDistance / ticksize) * tickvalue * lotstep;
   if (moneyLotstep == 0)
   {
      Print(__FUNCTION__, "> Lotsize cannot be calculated");
      return 0;
   }
   double lots = MathFloor(riskMoney / moneyLotstep) * lotstep;
   lots = NormalizeDouble(lots, 2);
   Print(lots);

   return lots;
}
