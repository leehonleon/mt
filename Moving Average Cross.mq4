//+------------------------------------------------------------------+
//|                                                festallySwing.mq4 |
//|                            Copyright 2017, Stafec Software Corp. |
//|                                           https://www.stafec.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Stafec Software Corp."
#property link      "https://www.stafec.com"
#property version   "1.00"
#property description "Moving Average Cross expert advisor"
#property strict
#define MAGICMA  20131111

#include "\\LabelObject.mq4"
//--- Inputs
input double Lots          =0.1;
input double MaximumRisk   =0.2;
input double DecreaseFactor=3;
int    MovingPeriodShort  =6;
int    MovingShiftShort   =0;
int    MovingPeriodMid  =12;
int    MovingShiftMid   =0;
int    MovingPeriodLong  =24;
int    MovingShiftLong   =0;
int    MovingPeriodLongDirection  =160;
int    MovingShiftLongDirection   =-30;


double preShortMidValue=0; // >0 表示短线下交中线 <0 表示短线上交中线
double preLongValue=0;     // 前长线值
double beforePreShortMidValue=0; // >0 表示短线下交中线 <0 表示短线上交中线
double beforePreLongValue=0;     // 前长线值
double preLongDirectionValue; //长线操作方向
double crossFlg=0; //相交方向 1为上交 -1为下交
int crossIndex; //相交BarIndex
double reversePercent=0; //反转几率
int preOperation=0; //前操作方向 1为买入,-1为卖出;
double addOperation=0; // 追加操作
int nowOperation=0; // 执行操作
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckOperation()
  {
  // 短均线与中均线在长均线下方交叉,且在6根k线之内形成长线反转即为买入信号
  // 短均线与中均线在长均线上方交叉,且在6根k线之内形成长线反转即为卖出信号
   double maShort,maMid,maLong,maLongDirection;
   string text1,text2,text3,text4;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   // 短均线
   maShort=iMA(NULL,0,MovingPeriodShort,MovingShiftShort,MODE_SMA,PRICE_CLOSE,0);
   // 中均线
   maMid=iMA(NULL,0,MovingPeriodMid,MovingShiftMid,MODE_SMA,PRICE_CLOSE,0);
   // 长均线
   maLong=iMA(NULL,0,MovingPeriodLong,MovingShiftLong,MODE_SMA,PRICE_CLOSE,0);
   // 长线操作方向
   maLongDirection=iMA(NULL,0,MovingPeriodLongDirection,MovingShiftLongDirection,MODE_SMA,PRICE_HIGH,0);
   double maShortMidValue;
   maShortMidValue=maMid-maShort; // 中线减去短线 >0 表示短线下交中线

   //如何判断交叉   
   if(crossFlg==1){
   // 如果上交均线，那么统计在6个k线内形成上涨长均线则买入
      crossIndex++;
      if(crossIndex<6 && preLongValue < maLong){
         // 如果在6根k线内形成了上涨的长均线则买入
         nowOperation=1;
         addOperation=0;
         crossIndex=0;
         if(preOperation==-1){
            addOperation-=1; //清仓
            preOperation=0;
         }
      }
   }
   if(crossFlg==-1){
   // 如果下交均线，那么统计在6个k线内形成下降长均线则卖出
      crossIndex++;
      if(crossIndex<6 && preLongValue > maLong){
         // 如果在6根k线内形成了上扬的长均线则卖出
        nowOperation=-1;
        addOperation=0;
        crossIndex=0;
        if(preOperation==1){
            addOperation-=1; //清仓
            preOperation=0;
         }
      }
   }
   // 设置交叉状态为上交
   if(maShortMidValue>0 && preShortMidValue<0 && maShort<maLong && maMid<maLong){
   // 当前中均线上交
      crossFlg=1;
      crossIndex=0;
      text2=StringConcatenate("交叉状态","为上交");
   }
   // 设置交叉状态为下交
   if(maShortMidValue<0 && preShortMidValue>0 && maShort>maLong && maMid>maLong){
   // 当前中均线下交
      crossFlg=-1;
      crossIndex=0;
      text2=StringConcatenate("交叉状态","为下交");
   }
   double MacdCurrent;
   
      MacdCurrent=iMACD(NULL,0,6,12,9,PRICE_CLOSE,MODE_MAIN,0);
   //前操作为卖出
   if(preOperation==-1){
      if(maShortMidValue>0 && preShortMidValue<0 && MacdCurrent>0){
      // 当前中均线上交， 且 macd value为正值
         addOperation-=0.5; //减仓50%
      }
   }
   //前操作为买入
   if(preOperation==-1){
   // 交叉状态为下交
      if(maShortMidValue<0 && preShortMidValue>0 && MacdCurrent<0){
      // 当前中均线下交， 且 macd value为负值
         addOperation-=0.5; //减仓50%
      }
   }
   
   if(preLongDirectionValue<maLongDirection){
   //长方向为上升
      if(nowOperation==-1){
         nowOperation=0;
      }
   
   }
   if(preLongDirectionValue>maLongDirection){
   //长方向为下降
      if(nowOperation==1){
         nowOperation=0;
      }
   
   }
   text1=StringConcatenate("maShortMidValue:",NormalizeDouble(maShortMidValue,2),"  preShortMidValue:",NormalizeDouble(preShortMidValue,2) );
   ShowProfitLabel(1, text1);
   text2=StringConcatenate("maLong:",NormalizeDouble(maLong,1), " crossIndex:",NormalizeDouble(crossIndex,1), " preLongValue:", NormalizeDouble(preLongValue,1));
   ShowProfitLabel(2, text2);
   
   text3=StringConcatenate("addOperation:",NormalizeDouble(addOperation,1), " preOperation:",NormalizeDouble(preOperation,1));
   ShowProfitLabel(3, text3);
   
   
   if(addOperation<-1) addOperation=-1;
   beforePreShortMidValue=preShortMidValue;
   beforePreLongValue=preLongValue;
   preShortMidValue=maMid-maShort; // 保存前短中线相交flg 
   preLongValue=maLong; // 保存前长线值
   preLongDirectionValue=maLongDirection;
   preOperation=nowOperation;
//---
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen(){
//           res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
//         return;
 //res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
 //     return;

      int    res;
   if(nowOperation==1){
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
         return;
   }
   if(nowOperation==-1){
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
      return;
 
   }
 }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//---
   double keepOff;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(addOperation >=-1 && addOperation < 0){
            keepOff = OrderLots()*MathAbs(addOperation);
            if(keepOff<0.1) keepOff=0.1;
            if(!OrderClose(OrderTicket(),keepOff,Bid,3,White))
               Print("OrderClose error ",GetLastError());
         }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(addOperation >=-1 && addOperation < 0){
            keepOff = OrderLots()*MathAbs(addOperation);
            if(keepOff<0.1) keepOff=0.1;
            if(!OrderClose(OrderTicket(),keepOff,Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   CheckOperation();
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
//---
  }
//+------------------------------------------------------------------+
