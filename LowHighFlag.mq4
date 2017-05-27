//+------------------------------------------------------------------+
//|                                                  LowHighFlag.mq4 |
//|                            Copyright 2017, Stafec Software Corp. |
//|                                           https://www.stafec.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2017, Stafec Software Corp."
#property link      "https://www.stafec.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| My function                                                      |
//+------------------------------------------------------------------+
// int MyCalculator(int value,int value2) export
//   {
//    return(value+value2);
//   }
//+------------------------------------------------------------------+


//--- description
#property description "Script draws \"Low\"/\"High\" signs in the chart window."
//--- display window of the input parameters during the script's launch
//--- input parameters of the script
input color InpColor=C'3,95,172'; // Color of signs
//+------------------------------------------------------------------+
//| Create Buy sign                                                  |
//+------------------------------------------------------------------+
bool ArrowHighCreate(const long            chart_ID=0,        // chart's ID
                    const string          name="ArrowBuy",   // sign name
                    const int             sub_window=0,      // subwindow index
                    datetime              time=0,            // anchor point time
                    double                price=0,           // anchor point price
                    const color           clr=C'255,0,0',   // sign color
                    const ENUM_LINE_STYLE style=STYLE_SOLID, // line style (when highlighted)
                    const int             width=1,           // line size (when highlighted)
                    const bool            back=false,        // in the background
                    const bool            selection=false,   // highlight to move
                    const bool            hidden=true,       // hidden in the object list
                    const long            z_order=0)         // priority for mouse click
  {
   return ArrowObjectCreate(chart_ID,name,OBJ_ARROW_THUMB_UP,sub_window,time,price,clr,style,width,back,selection,hidden,z_order);
  }
  
  bool ArrowLowCreate(const long            chart_ID=0,        // chart's ID
                    const string          name="ArrowBuy",   // sign name
                    const int             sub_window=0,      // subwindow index
                    datetime              time=0,            // anchor point time
                    double                price=0,           // anchor point price
                    const color           clr=C'0,255,0',   // sign color
                    const ENUM_LINE_STYLE style=STYLE_SOLID, // line style (when highlighted)
                    const int             width=1,           // line size (when highlighted)
                    const bool            back=false,        // in the background
                    const bool            selection=false,   // highlight to move
                    const bool            hidden=true,       // hidden in the object list
                    const long            z_order=0)         // priority for mouse click
  {
   return ArrowObjectCreate(chart_ID,name,OBJ_ARROW_THUMB_DOWN,sub_window,time,price,clr,style,width,back,selection,hidden,z_order);
  }
  bool ArrowObjectCreate(const long            chart_ID=0,        // chart's ID
                    const string          name="ArrowBuy",   // sign name
                    const ENUM_OBJECT     type=OBJ_ARROW_THUMB_UP,      // sign name
                    const int             sub_window=0,      // subwindow index
                    datetime              time=0,            // anchor point time
                    double                price=0,           // anchor point price
                    const color           clr=C'3,95,172',   // sign color
                    const ENUM_LINE_STYLE style=STYLE_SOLID, // line style (when highlighted)
                    const int             width=1,           // line size (when highlighted)
                    const bool            back=false,        // in the background
                    const bool            selection=false,   // highlight to move
                    const bool            hidden=true,       // hidden in the object list
                    const long            z_order=0)         // priority for mouse click
  {
//--- set anchor point coordinates if they are not set
   ChangeArrowEmptyPoint(time,price);
//--- reset the error value
   ResetLastError();
//--- create the sign

   if(!ObjectCreate(chart_ID,name,type,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Buy\" sign! Error code = ",GetLastError());
      return(false);
     }
//--- set a sign color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set a line style (when highlighted)
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set a line size (when highlighted)
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the sign by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
      //--- check if the script's operation has been forcefully disabled
      if(IsStopped())
         return false;
      //--- redraw the chart
      ChartRedraw();
      // 0.05 seconds of delay
      Sleep(50);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move the anchor point                                            |
//+------------------------------------------------------------------+
bool ArrowBuyMove(const long   chart_ID=0,      // chart's ID
                  const string name="ArrowBuy", // object name
                  datetime     time=0,          // anchor point time coordinate
                  double       price=0)         // anchor point price coordinate
  {
//--- if point position is not set, move it to the current bar having Bid price
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move the anchor point
   if(!ObjectMove(chart_ID,name,0,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Delete Buy sign                                                  |
//+------------------------------------------------------------------+
bool ArrowBuyDelete(const long   chart_ID=0,      // chart's ID
                    const string name="ArrowBuy") // sign name
  {
//--- reset the error value
   ResetLastError();
//--- delete the sign
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete \"Buy\" sign! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Check anchor point values and set default values                 |
//| for empty ones                                                   |
//+------------------------------------------------------------------+
void ChangeArrowEmptyPoint(datetime &time,double &price)
  {
//--- if the point's time is not set, it will be on the current bar
   if(!time)
      time=TimeCurrent();
//--- if the point's price is not set, it will have Bid value
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
  }
  
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
//void OnStart()
//  {
//   datetime date[]; // array for storing dates of visible bars
//   double   low[];  // array for storing Low prices of visible bars
//   double   high[]; // array for storing High prices of visible bars
////--- number of visible bars in the chart window
//   int bars=(int)ChartGetInteger(0,CHART_VISIBLE_BARS);
////--- memory allocation
//   ArrayResize(date,bars);
//   ArrayResize(low,bars);
//   ArrayResize(high,bars);
////--- fill the array of dates
//   ResetLastError();
//   if(CopyTime(Symbol(),Period(),0,bars,date)==-1)
//     {
//      Print("Failed to copy time values! Error code = ",GetLastError());
//      return;
//     }
////--- fill the array of Low prices
//   if(CopyLow(Symbol(),Period(),0,bars,low)==-1)
//     {
//      Print("Failed to copy the values of Low prices! Error code = ",GetLastError());
//      return;
//     }
////--- fill the array of High prices
//   if(CopyHigh(Symbol(),Period(),0,bars,high)==-1)
//     {
//      Print("Failed to copy the values of High prices! Error code = ",GetLastError());
//      return;
//     }
////--- create Buy signs in Low point for each visible bar
//   for(int i=0;i<bars;i++)
//     {
//      if(!ArrowBuyCreate(0,"ArrowBuy_"+(string)i,0,date[i],low[i],InpColor))
//         return;
//      //--- check if the script's operation has been forcefully disabled
//      if(IsStopped())
//         return;
//      //--- redraw the chart
//      ChartRedraw();
//      // 0.05 seconds of delay
//      Sleep(50);
//     }
////--- move Buy signs to High point for each visible bar
//   for(int i=0;i<bars;i++)
//     {
//      if(!ArrowBuyMove(0,"ArrowBuy_"+(string)i,date[i],high[i]))
//         return;
//      //--- check if the script's operation has been forcefully disabled
//      if(IsStopped())
//         return;
//      //--- redraw the chart
//      ChartRedraw();
//      // 0.05 seconds of delay
//      Sleep(50);
//     }
////--- delete Buy signs
//   for(int i=0;i<bars;i++)
//     {
//      if(!ArrowBuyDelete(0,"ArrowBuy_"+(string)i))
//         return;
//      //--- redraw the chart
//      ChartRedraw();
//      // 0.05 seconds of delay
//      Sleep(50);
//     }
////---
//  }