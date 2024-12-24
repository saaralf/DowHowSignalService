
/// @brief
class ButtonWithHL
{

  public:
    void ButtonWithHL();
    void ButtonWithHL(string name);
    void CreateButton(void);
    void CreateButton(string _btn_text, int _xdistance, int _xsize, int _ydistance, int _ysize, color _clrTxt, color _bgcolor, int _fontsize, color __color, color hl_color, string hl_name, string _font = "Calibri");
    void ButtonWithHL::setXdistance(int xdistance);
    void ButtonWithHL::setxsize(int xsize);
    void ButtonWithHL::setydistance(int ydistance);
    void ButtonWithHL::setysize(int ysize);
    void ButtonWithHL::setbtnText(string btn_text);
    void ButtonWithHL::setbgcolor(color bgcolor);
    void ButtonWithHL::setcolor(color _color);
    void ButtonWithHL::setfontsize(uint fontsize);
    void ButtonWithHL::setHLPrice();
    int ButtonWithHL::getXdistance();
    int ButtonWithHL::getxsize();
    int ButtonWithHL::getydistance();
    int ButtonWithHL::getysize();
    string ButtonWithHL::getbtnText();
    color ButtonWithHL::getbgcolor();
    color ButtonWithHL::getcolor();
    uint ButtonWithHL::getfontsize();
    void ButtonWithHL::toString();
    void ButtonWithHL::setFont(string _font);
    string ButtonWithHL::getFont();
    void ButtonWithHL::setclrTxt(color _clrTxt);
    color ButtonWithHL::getclrTxt();
 
    void ButtonWithHL::update_Text(string val);
    color getHlLineColor();
    void setHlLineColor(color __color);
    string getHlLineName();
    void setHlLineName(string name);
    double gethlpricedouble();
    double Get_Price_d();
string gethlpricestring();
  private:
    string name;
    string btn_text;
    int xdistance;
    int xsize;
    int ydistance;
    int ysize;
    color bgcolor;
    color _color;
    uint fontsize;
    string font;
    color clrTxt;
    datetime hl_datetime;
    double hl_price;
    int window;
    color hl_line_color;
    string hl_line_name;
};

/**
 * This function fulfills the will of the developer
 * @param  _name: Argument 1
 */
void ButtonWithHL::setHlLineName(string _name)
{
    hl_line_name = _name;
}
/// @brief
/// @return
string ButtonWithHL::getHlLineName()
{
    return hl_line_name;
}
void ButtonWithHL::setHlLineColor(color __color)
{
    hl_line_color = __color;
}
color ButtonWithHL::getHlLineColor()
{
    return hl_line_color;
}
double ButtonWithHL::Get_Price_d()
{
    return ObjectGetDouble(0, getHlLineName(), OBJPROP_PRICE);
}

void ButtonWithHL::setclrTxt(color _clrTxt)
{

    clrTxt = _clrTxt;
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrTxt);
}

color ButtonWithHL::getclrTxt()
{
    return clrTxt;
}

//+------------------------------------------------------------------+
//|  Constructor                                                     |
//+------------------------------------------------------------------+
void ButtonWithHL::ButtonWithHL(string _name)
{
    // Wenn noch kein Name definiert, dann wird NONAME verwendet
    if (name == "" || _name == "")
    {
        name = "NONAME";
    }
    else
    {
        name = _name;
    }

    // Erzeuge den Button mit den Koordinaten 0,0
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);

    ChartRedraw(0);
}
//+------------------------------------------------------------------+
//| Create Button                                                    |
//| Setzt die restlichen Paramater des Button der mit dem Constructor|
//| erstellt wurde                                                   |
//+------------------------------------------------------------------+

void ButtonWithHL::CreateButton(void)
{

    window = 0;
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); // chart corner
    // Ermittelt den Preis für die HL Linie, diese soll in der Mitte des Button verlaufen
    datetime hl_datetime = 0;
    double hl_price = 0;
    ChartXYToTimePrice(0, getXdistance(), getydistance() + getysize() / 2, window, hl_datetime, hl_price); // getysize()/2 = ist die Mitte des Buttons

    ObjectCreate(0, getHlLineName(), OBJ_HLINE, 0, hl_datetime, hl_price);
    ObjectSetInteger(0, getHlLineName(), OBJPROP_COLOR, getHlLineColor());
    ObjectSetInteger(0, getHlLineName(), OBJPROP_BACK, true);
    ObjectSetInteger(0, getHlLineName(), OBJPROP_STYLE, STYLE_SOLID);

    ChartRedraw(0);
}

void ButtonWithHL::CreateButton(string _btn_text, int _xdistance, int _xsize, int _ydistance, int _ysize, color _clrTxt, color _bgcolor, int _fontsize, color __color, color hl_color, string hl_name, string _font = "Calibri")
{

    setXdistance(_xdistance); // X position
    setxsize(_xsize);         // width
    setydistance(_ydistance); // Y position
    setysize(_ysize);         // height
    setbtnText(_btn_text);    // label
    setbgcolor(_bgcolor);
    setcolor(__color);
    setfontsize(_fontsize);
    setFont(_font);
    setclrTxt(_clrTxt);
    setHlLineColor(hl_color);
    setHlLineName(hl_name);
    CreateButton();
}

void ButtonWithHL::toString()
{
    Print("Button: " + name + " hat folgende Koordinaten ");
    Print("X Position: " + (string)getXdistance());
    Print("Y Position: " + getydistance());
    Print("X Size: " + getxsize());
    Print("Y Size: " + getysize());
    Print("HL Line Price:" + getHlLineName() + " : " + Get_Price_d());
}

void ButtonWithHL::setFont(string _font)
{
    font = _font;
    ObjectSetString(0, name, OBJPROP_FONT, font);
}
void ButtonWithHL::setXdistance(int _xdistance)
{
    xdistance = _xdistance;
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xdistance); // X position
}

void ButtonWithHL::setxsize(int _xsize)
{
    xsize = _xsize;
    ObjectSetInteger(0, name, OBJPROP_XSIZE, xsize); // width
}
void ButtonWithHL::setydistance(int _ydistance)
{
    ydistance = _ydistance;
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, ydistance); // Y position

    setHLPrice();
}
void ButtonWithHL::setysize(int _ysize)
{
    ysize = _ysize;
    ObjectSetInteger(0, name, OBJPROP_YSIZE, ysize); // height
}

void ButtonWithHL::setbtnText(string _btn_text)
{
    btn_text = _btn_text;
    ObjectSetString(0, name, OBJPROP_TEXT, btn_text); // label
}
void ButtonWithHL::setbgcolor(color _bgcolor)
{
    bgcolor = _bgcolor;
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgcolor);
}
void ButtonWithHL::setcolor(color __color)
{
    _color = __color;

    ObjectSetInteger(0, name, OBJPROP_COLOR, _color);
}

void ButtonWithHL::setfontsize(uint _fontsize)
{
    fontsize = _fontsize;

    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
}

int ButtonWithHL::getXdistance()
{
    return (int)ObjectGetInteger(0, name, OBJPROP_XDISTANCE);
}

int ButtonWithHL::getxsize()
{
    return xsize;
}
int ButtonWithHL::getydistance()
{
    return (int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE);
    ;
}
int ButtonWithHL::getysize()
{
    return ysize;
}

string ButtonWithHL::getbtnText()
{
    return btn_text;
}
color ButtonWithHL::getbgcolor()
{
    return bgcolor;
}
color ButtonWithHL::getcolor()
{
    return _color;
}
uint ButtonWithHL::getfontsize()
{
    return fontsize;
}

void ButtonWithHL::setHLPrice()
{
    // Preise der HL Linie anpassen
    datetime hl_datetime = 0;
    double hl_price = 0;

    ChartXYToTimePrice(0, getXdistance(), getydistance() + getysize() / 2, window, hl_datetime, hl_price);

    ObjectSetInteger(0, getHlLineName(), OBJPROP_TIME, hl_datetime);
    ObjectSetDouble(0, getHlLineName(), OBJPROP_PRICE, hl_price);
    ChartRedraw(0);
}

double ButtonWithHL::gethlpricedouble()
{
    return   ObjectGetDouble(0, getHlLineName(), OBJPROP_PRICE);
}

string ButtonWithHL::gethlpricestring()
{
    return  DoubleToString(ObjectGetDouble(0, getHlLineName(), OBJPROP_PRICE), _Digits);
}

void ButtonWithHL::update_Text(string val)
{
  string result =    (string)ObjectSetString(0, name, OBJPROP_TEXT, val);
    ChartRedraw(0);
}