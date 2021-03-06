//+------------------------------------------------------------------+
//|                                                festallySwing.mq4 |
//|                            Copyright 2017, Stafec Software Corp. |
//|                                           https://www.stafec.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Stafec Software Corp."
#property link      "https://www.stafec.com"
#property version   "1.00"
#property strict

#define MAGICMA  20170520

#include "\\LowHighFlag.mq4"
#include "\\LabelObject.mq4"


//---- indicator parameters
input int InpDepth=5;        // 时间周期
input int InpDeviation=100;  // 平缓振幅指数

input int    MovingPeriod =12; // 平均值指数时间周期
input int    MovingShift  =0;  // 平均值指数划线平移
input double Lots         =0.1; // 最小一手
input double MaximumRisk  =0.2; // 资金使用比例
input double DecreaseFactor=3;  // 
int maxDepth=100;
double lastHigh=0,lastLow=0;
int pos,lasthighpos=0,lastlowpos=0;
int trend=0; // 趋势：0=未确认或盘整； 1=上升通道; -1=下降通道

int trendAlleyway[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   // 趋势确认用当前低点或高点取得
   lastHigh = High[iHighest(NULL,0,MODE_LOW,InpDepth,1)];
   lastLow=Low[iLowest(NULL,0,MODE_LOW,InpDepth,1)];
   Print(lastLow,"::",lastHigh);
   Print(InpDeviation*Point);
   ArrayInitialize(preOrderProfitLoss, -100000.0);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   // 确认订单是否需要关闭
   CheckForClose();
   
   if(Volume[0]<=1) { // 新柱开始时运行

 //---
   
   double extremum;
   pos=iHighest(NULL,0,MODE_LOW,InpDepth,1);
   extremum = High[pos];
   int    res;
   if(extremum>lastHigh && pos==1){
      // 新高出现，疑为上升通道
      if(extremum-lastHigh>InpDeviation*Point){
         //如果新高超过前高0.5个点时，确认为上升通道
         trend=1; // 上升通道标记
         lastHigh=extremum;
         // 新高出现后,低点位置上移至最高柱的最低价
         lastLow=High[pos]; // 最高柱的最低价
         // 绘制新高图标
         ArrowHighCreate(0,"newHigh_"+(string)extremum,0,Time[pos],High[pos]);
         // 如果前趋势为下降,切为出现连续下降时
         int preTrend=continuityInArry(trendAlleyway);
         if(preTrend==-1){
            // 尝试做空
            //res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"StafecSell sell at (" + DoubleToStr(Bid, 2) + ")",MAGICMA,0,Red);
         }
         // 添加趋势通道数组
         ArrayPut(trendAlleyway, trend);
         
      }else{
      //if((extremum-lastHigh)<InpDeviation*Point){
         //如果新高超过前高1个点以内时，确认为盘整通道
         trend=0; // 盘整通道标记
         lastHigh=extremum;
      }
     
   }else{
   
      //---
      pos=iLowest(NULL,0,MODE_LOW,InpDepth,1);
      extremum=Low[pos];
      if(extremum<lastLow && pos==1){
         // 新低出现，疑为下降通道
         if((lastLow-extremum)>InpDeviation*Point){
            //如果新低低于前低1个点时，确认为下降通道
            trend=-1; // 下降通道标记
            lastLow=extremum;
            // 新低出现后,高点位置下移至最低柱的最高价
            lastHigh=Low[pos];
            // 绘制新低图标
            ArrowLowCreate(0,"newLow_"+(string)extremum,0,Time[pos],Low[pos]);
            // 如果前趋势为上升,且未出现连续上升时
            int preTrend=continuityInArry(trendAlleyway);
            if(preTrend==1){
               // 尝试做多
               res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"StafecBug buy at (" + DoubleToStr(Ask, 2) + ")",MAGICMA,0,Blue);
            }
            
            // 添加趋势通道数组
            ArrayPut(trendAlleyway, trend);
         }else{
         //if((lastLow-extremum)<InpDeviation*Point){
            //如果新低低于前低1个点以内时，确认为盘整通道
            trend=0; // 盘整通道标记
            lastLow=extremum;
         }
   
      }
   
   }
   
   }
   // 保存最高盈利
   CheckForPreOrderProfitLoss();

  }

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }

//+------------------------------------------------------------------+
//| Push a int to the Array function                                 |
//+------------------------------------------------------------------+
int ArrayPut(
   int &arrayRef[],    // array by reference
   int  trendValue        // true denotes reverse order of indexing
   )
  {
//---
   ArrayResize(arrayRef,ArraySize(arrayRef)+1);
   for(int i=ArraySize(arrayRef)-2; i>=0; i--)
      arrayRef[i]=arrayRef[i+1];
   arrayRef[0]=trendValue;
//---
   return(ArraySize(arrayRef));
  }
//+------------------------------------------------------------------+
//| 查出趋势连续性,如果趋势连续则返回>1或小于-1                      |
//+------------------------------------------------------------------+
int continuityInArry(
   const int &arrayRef[]    // array by reference
   )
  {
//---
   int conCnt=0;
   int preValue=0;
   for(int i=0; i<ArraySize(arrayRef); i++){
      if(preValue==0){
         preValue=arrayRef[i];
         conCnt+=arrayRef[i];
      }else if(preValue==arrayRef[i]){
         conCnt+=arrayRef[i];
      }else{
         break;
      }
   }
//---
   return(conCnt);
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
//|                                  |
//+------------------------------------------------------------------+
struct OrderProfitLoss
  {
   int            ticketId;              // 订单号
   string            type;                  // 买卖
   double            profitLoss;            // 盈亏
  };
OrderProfitLoss orderProfitLoss[];

double preOrderProfitLoss[];

//+------------------------------------------------------------------+
//| Push a int to the Array function                                 |
//+------------------------------------------------------------------+
int ArrayPutOrderProfit(
   double &arrayRef[],    // array by reference
   int ticketId,
   double  trendValue        // true denotes reverse order of indexing
   )
  {
//---
   
   int lastIndex=ArraySize(arrayRef);
   if(ticketId>lastIndex){
      ArrayResize(arrayRef,lastIndex+1);
      arrayRef[lastIndex]=trendValue;
   }else{
      arrayRef[ticketId-1]=trendValue;
   }
//---
   return(ArraySize(arrayRef));
  }
//+------------------------------------------------------------------+
//|  保存最高盈利                                                    |
//+------------------------------------------------------------------+

void CheckForPreOrderProfitLoss()
  {
   string text="";
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      printf(ArraySize(preOrderProfitLoss), ":::", OrderTicket()-1);
      
      if(ArraySize(preOrderProfitLoss)==OrderTicket()-1 || OrderProfit()>preOrderProfitLoss[OrderTicket()-1]){
         //  保存最高盈利
         ArrayPutOrderProfit(preOrderProfitLoss,OrderTicket(),OrderProfit());
      }
      text=StringConcatenate("订单#",OrderTicket(),": 盈利=",OrderProfit(),": 最高盈利=",preOrderProfitLoss[OrderTicket()-1]);
      ShowProfitLabel(OrderTicket(), text);
     }
   
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(OrderProfit() < -1.75*OrderLots()*100 || (preOrderProfitLoss[OrderTicket()-1]>1*OrderLots()*100 && preOrderProfitLoss[OrderTicket()-1]*0.75>OrderProfit()))
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
           if((preOrderProfitLoss[OrderTicket()-1]>1*OrderLots()*100 && preOrderProfitLoss[OrderTicket()-1]*0.65>OrderProfit())){
               // 尝试做空
               int res=OrderSend(Symbol(),OP_SELL,LotsOptimized()*2,Bid,3,0,0,"StafecSell sell at (" + DoubleToStr(Bid, 2) + ")",MAGICMA,0,Red);
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(OrderProfit() < -1.75*OrderLots()*100 || (preOrderProfitLoss[OrderTicket()-1]>1*OrderLots()*100 && preOrderProfitLoss[OrderTicket()-1]*0.75>OrderProfit()))
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
           if((preOrderProfitLoss[OrderTicket()-1]>1*OrderLots()*100 && preOrderProfitLoss[OrderTicket()-1]*0.65>OrderProfit())){
               // 尝试做多
               int res=OrderSend(Symbol(),OP_BUY,LotsOptimized()*2,Ask,3,0,0,"StafecBug buy at (" + DoubleToStr(Ask, 2) + ")",MAGICMA,0,Blue);
           }
         break;
        }
     }
//---
  }
// file end  
//+------------------------------------------------------------------+
