#include "helpers.mqh"
//+------------------------------------------------------------------+
//|                   Open a BUY Order                               |
//+------------------------------------------------------------------+
int OpenBuy(string pair,double lot,double sl,double tp,string comment,int magic,bool fifo=false,double martingaleMult=0,int maxMultiplications=0)
{
   int ticket=0,tries=0;
   static datetime last=0;
   static int ordersThisBar=0;
   
   //if(!IsTesting())
      //ChartBringToTop();
   double SL=0,TP=0;
   if(sl>0)
      SL=sl;
   if(tp>0)
      TP=tp;

   int tries_main=0;
   while(ticket<=0) {
      WaitTradeContext();
      RefreshRates();
      int digits=(int) MarketInfo(pair,MODE_DIGITS);
      double point=MarketInfo(pair,MODE_POINT);
      double price= MarketInfo(pair,MODE_ASK);
      double spread=MarketInfo(pair,MODE_SPREAD);
      double _pip=GetPip(pair);

      //if(spread*(point/_pip)>_MaxSpread && _MaxSpread!=0) {
      //   Print("Order not opened because spread ("+(string)(spread*(point/_pip))+") is higher than max allowed spread ("+(string)_MaxSpread);
      //   return false;
      //}

      if(!AccountFreeMarginCheck(Symbol(),OP_BUY,lot)>0) {
         Print("Order not opened because there's not enough money to buy "+DoubleToStr(lot,2)+" lots, try to lower the volume, ett="+(string)GetLastError());
         return false;
      }
      
      color arrowColor=clrNONE;
      if(SL!=0 && SL>MarketInfo(pair,MODE_BID)-MarketInfo(pair,MODE_STOPLEVEL)*point)
         SL=MarketInfo(pair,MODE_BID)-MarketInfo(pair,MODE_STOPLEVEL)*point;
      if(TP!=0 && TP<MarketInfo(pair,MODE_BID)+MarketInfo(pair,MODE_STOPLEVEL)*point)
         TP=MarketInfo(pair,MODE_BID)+MarketInfo(pair,MODE_STOPLEVEL)*point;

      if(_ECN) {
         ticket=OrderSend(pair,OP_BUY,lot,price,(int)(_MaxSlippage*_pip/point),0,0,comment,magic,Period(),arrowColor);
      }
      else {
         //Print(price,NormalizeDouble(SL,digits),NormalizeDouble(TP,digits));
         ticket=OrderSend(pair,OP_BUY,lot,price,(int)(_MaxSlippage*_pip/point),NormalizeDouble(SL,digits),NormalizeDouble(TP,digits),comment,magic,Period(),arrowColor);
      }
      if(ticket<0)
         Print(err_msg(GetLastError()));
      if(ticket>0 && _ECN && (SL>0 || TP>0)) {
         if(OrderSelect(ticket,SELECT_BY_TICKET)) {
            while(tries<10) {
               WaitTradeContext();
               RefreshRates();
               if(OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(SL,digits),NormalizeDouble(TP,digits),0))
                  break;
               tries++;
            }
         }
      }
      tries_main++;
      if(tries_main>10)
         break;
   }

   if(ticket>0) {
      if(last!=Time[0])
         ordersThisBar=0;
      ordersThisBar++;
      last=Time[0];
      //Print("Order Buy was opened");
      //  AddSpreadCheckFor(pair);
   }
   return(ticket);
}

//+------------------------------------------------------------------+
//|         Open a SELL Order                                        |
//+------------------------------------------------------------------+
int OpenSell(string pair,double lot,double sl,double tp,string comment,int magic,bool fifo=false,double martingaleMult=0,int maxMultiplications=0)
{
   int ticket=0;
   static datetime last=0;
   static int ordersThisBar=0;
   
   //if(!IsTesting())
      //ChartBringToTop();
   int tries=0;
   double SL=0,TP=0;
   if(sl>0)
      SL=sl;
   if(tp>0)
      TP=tp;

   int tries_main=0;
   while(ticket<=0) {
      WaitTradeContext();
      RefreshRates();
      int digits=(int)MarketInfo(pair,MODE_DIGITS);
      double point=MarketInfo(pair,MODE_POINT);
      double price= MarketInfo(pair,MODE_BID);
      double spread=MarketInfo(pair,MODE_SPREAD);
      double _pip=GetPip(pair);

      //if(spread*(point/_pip)>_MaxSpread && _MaxSpread!=0) {
         //Print("Order not opened because spread ("+(string)(spread*(point/_pip))+") is higher than max allowed spread ("+(string)_MaxSpread);
         //return false;
      //}
      if(!AccountFreeMarginCheck(Symbol(),OP_SELL,lot)>0) {
         Print("Order not opened because there's not enough money, try to lower the volume, ett="+(string)GetLastError());
         return false;
      }

      color arrowColor=clrNONE;
      if(SL!=0 && SL<MarketInfo(pair,MODE_ASK)+MarketInfo(pair,MODE_STOPLEVEL)*point)
         SL=MarketInfo(pair,MODE_ASK)+MarketInfo(pair,MODE_STOPLEVEL)*point;
      if(TP!=0 && TP>MarketInfo(pair,MODE_ASK)-MarketInfo(pair,MODE_STOPLEVEL)*point)
         TP=MarketInfo(pair,MODE_ASK)-MarketInfo(pair,MODE_STOPLEVEL)*point;

      if(_ECN) {
         ticket=OrderSend(pair,OP_SELL,lot,price,(int)(_MaxSlippage*_pip/point),0,0,comment,magic,0,arrowColor);
      } else {
         ticket=OrderSend(pair,OP_SELL,lot,price,(int)(_MaxSlippage*_pip/point),NormalizeDouble(SL,digits),NormalizeDouble(TP,digits),comment,magic,0,arrowColor);
      }
      if(ticket<0)
         Print(err_msg(GetLastError()));
      if(ticket>0 && _ECN && (SL>0 || TP>0)) {
         if(OrderSelect(ticket,SELECT_BY_TICKET)) {
            while(tries<10) {
               WaitTradeContext();
               RefreshRates();
               if(OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(SL,digits),NormalizeDouble(TP,digits),0))
                  break;
               tries++;
            }
         }
      }
      tries_main++;
      if(tries_main>10)
         break;
   }

   if(ticket>0) {
      if(last!=Time[0])
         ordersThisBar=0;
      ordersThisBar++;
      last=Time[0];
      //Print("Order Sell was opened");
      // AddSpreadCheckFor(pair);
   }
   return (ticket);
}

bool ModifyOrder(int orderTicket, double orderOpenPrice, double sl, double tp)
{
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseOrder(string symbol, int type, int ticket, double lots, int magicNumber=-1,string comment="", double closePercentage=100)
{
   ResetLastError();
   color arrowColor=clrNONE;
   
   //Print("Bearish signal - close BUY orders");
   int mode = MODE_BID;
   if (type == OP_SELL)
      mode = MODE_ASK;
   if(!OrderClose(ticket,lots*closePercentage/100,MarketInfo(symbol,mode),10,arrowColor)) {
      Print("Failed to close order in "+__FUNCTION__+", error="+(string)GetLastError());
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CJAVal GetOpenOrders(int type = -1)
{
   int total=OrdersTotal(), j = 0;
   CJAVal data;
   bool add = false;
   for(int b=0; b<=total-1; b++) {
      if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES)) {
         if (type == -1) {
            add = true;
         } else if (OrderType() == type) {
            add = true;
         }
         if (add) {
            data[j]["orderticket"] = OrderTicket();
            data[j]["orderticket"] = OrderMagicNumber();
            data[j]["orderticket"] = OrderLots();
            data[j]["orderticket"] = OrderSymbol();
            data[j]["orderticket"] = OrderProfit();
            data[j]["orderticket"] = OrderTypeToString(OrderType());
            data[j]["orderticket"] = OrderOpenPrice();
            data[j]["orderticket"] = OrderClosePrice();
            data[j]["orderticket"] = OrderOpenTime();
            data[j]["orderticket"] = OrderCloseTime();
            data[j]["orderticket"] = OrderComment();
            data[j]["orderticket"] = OrderCommission();
            data[j]["orderticket"] = OrderStopLoss();
            data[j]["orderticket"] = OrderTakeProfit();
            data[j]["orderticket"] = OrderSwap();
         }
      }
   }
   return data;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseBuyOrders(string symbol=NULL,int magicNumber=-1,string comment="",double closePercentage=100)
{
   int total=OrdersTotal();
   for(int b=0; b<=total-1; b++) {
      if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES)) {
         if((OrderMagicNumber()==magicNumber || magicNumber==-1) && (OrderSymbol()==symbol || StringLen(symbol)==0)
            && (StringLen(comment)==0 || StringFind(OrderComment(),comment)>=0) && OrderType()==OP_BUY)
           {
            ResetLastError();
            color arrowColor=clrNONE;
            
            Print("Bearish signal - close BUY orders");
            if(!OrderClose(OrderTicket(),OrderLots()*closePercentage/100,MarketInfo(OrderSymbol(),MODE_BID),10,arrowColor)) {
               Print("Failed to close order in "+__FUNCTION__+", error="+(string)GetLastError());
               return;
            } else {
               total=OrdersTotal();
               b--;
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseSellOrders(string symbol=NULL,int magicNumber=-1,string comment="",double closePercentage=100)
{
   int total=OrdersTotal();
   int closed=0;

   for(int b=0; b<=total-1; b++) {
      if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES)) {
         if((OrderMagicNumber()==magicNumber || magicNumber==-1) && (OrderSymbol()==symbol || StringLen(symbol)==0)
            && (StringLen(comment)==0 || StringFind(OrderComment(),comment)>=0))
           {
            ResetLastError();
            color arrowColor=clrNONE;

            if(!OrderClose(OrderTicket(),OrderLots()*closePercentage/100,MarketInfo(OrderSymbol(),MODE_ASK),10,arrowColor)) {
               Print("Failed to close order in "+__FUNCTION__+", error="+(string)GetLastError());
               return;
            } else {
               total=OrdersTotal();
               b--;
            }
         }
      }
   }
}