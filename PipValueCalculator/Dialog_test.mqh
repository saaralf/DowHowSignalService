#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\CheckBox.mqh>

input int fontSize = 8;

class CCustomDialog : public CAppDialog {
private:
    CLabel   lblTitle;
    CButton  btnMain, btnDummy1, btnDummy2, btnSettings;
    CLabel   lblTrend, lblTrendNumber, lblEntry, lblSL, lblTP;
    CEdit    editEntry, editSL, editTP;
    CButton  btnTPReached, btnSLReached, btnOrderCanceled;
    CCheckBox chkDiscord, chkRunning;
    int dialogWidth;
    int dialogHeight;
    int margin;
    int buttonWidth;
    int buttonHeight;
public:
                     CCustomDialog(void);
                    ~CCustomDialog(void);
                    
                    void Create();
                     void OnClickButton(int id);
};


CCustomDialog::CCustomDialog() {      
        
    }
    CCustomDialog::~CCustomDialog() {      
        
    }
    void CCustomDialog::Create() {
    
     dialogWidth = 800;
        dialogHeight = 300;
        margin = 10;
        buttonWidth = 100;
        buttonHeight = 25;
        
           if(!CAppDialog::Create(0,"TestDialog",0,100,100,dialogWidth,dialogHeight))
               Print("Fehler");
        int x = margin, y = margin, width = dialogWidth - 2 * margin;
        
        lblTitle.Create(0, "Programmname v1.0", x, y, width, buttonHeight, 0);
        lblTitle.FontSize(fontSize);
        y += 40;
        
        int buttonSpacing = (dialogWidth - 4 * buttonWidth) / 5;
        
        btnMain.Create(0, "Main", x, y, buttonWidth, buttonHeight, 0);
        btnDummy1.Create(0, "", x + buttonWidth + buttonSpacing, y, buttonWidth, buttonHeight, 0);
        btnDummy1.Show();
        btnDummy2.Create(0, "", x + 2 * (buttonWidth + buttonSpacing), y, buttonWidth, buttonHeight, 0);
        btnDummy2.Show();
        btnSettings.Create(0, "⚙", x + 3 * (buttonWidth + buttonSpacing), y, buttonWidth, buttonHeight, 0);
        y += 40;
        
        int colWidth = (dialogWidth - 4 * margin) / 3;
        
        lblTrend.Create(0, "Trendrichtung:", x, y, colWidth, buttonHeight, 0);
        lblTrend.FontSize(fontSize);
        lblTrendNumber.Create(0, "Trend #", x + colWidth + margin, y, colWidth, buttonHeight, 0);
        lblTrendNumber.FontSize(fontSize);
        btnTPReached.Create(0, "TP erreicht", x + 2 * (colWidth + margin), y, colWidth, buttonHeight, 0);
        y += 40;
        
        lblEntry.Create(0, "Entry Preis:", x, y, colWidth, buttonHeight, 0);
        lblEntry.FontSize(fontSize);
        editEntry.Create(0, "", x + colWidth + margin, y, colWidth, buttonHeight, 0);
        lblSL.Create(0, "SL Preis:", x + 2 * (colWidth + margin), y, colWidth, buttonHeight, 0);
        lblSL.FontSize(fontSize);
        editSL.Create(0, "", x + 3 * (colWidth + margin), y, colWidth, buttonHeight, 0);
        lblTP.Create(0, "TP Preis:", x + 4 * (colWidth + margin), y, colWidth, buttonHeight, 0);
        lblTP.FontSize(fontSize);
        editTP.Create(0, "", x + 5 * (colWidth + margin), y, colWidth, buttonHeight, 0);
        y += 40;
        
        chkDiscord.Create(0, "Trend an Discord gesendet", x, y, colWidth, buttonHeight, 0);
      //  chkDiscord.FontSize(fontSize);
        chkRunning.Create(0, "Trend is running", x + colWidth + margin, y, colWidth, buttonHeight, 0);
     //   chkRunning.FontSize(fontSize);
     
     if (!Add(lblTitle))
     Print ("Error");
     
     if (!Add(btnMain))
     Print ("Error");
     
     
    }
    
    void CCustomDialog::OnClickButton(int id) {
        switch (id) {
            case 5: Print("TP erreicht geklickt"); break;
            case 6: Print("SL erreicht geklickt"); break;
            case 7: Print("Order abgebrochen"); break;
            case 1: Print("Main Button geklickt"); break;
            case 4: Print("Einstellungen geöffnet"); break;
        }
    }



