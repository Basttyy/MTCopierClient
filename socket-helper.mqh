#include "order-helper.mqh"

void HandleIncomingData() {
   string strCommand;
   do {
      strCommand = glbClientSocket.Receive("\r\n");
      if (StringFind(strCommand, "Open:") > -1) {
         openOrder(strCommand);
      }
      else if (StringFind(strCommand, "Close:") > -1) {
         closeOrder(strCommand);
      }
      else if (StringFind(strCommand, "Modify:") > -1) {
         modifyOrder(strCommand);
      }
      else if (StringFind(strCommand, "SetMode:") > -1) {
         setTerminalMode(strCommand);
      }
      else if (StringFind(strCommand, "GetAccHistory:") > -1) {
         getAccountHistory(strCommand);
      }
      else if (StringFind(strCommand, "GetAccInfo:") > -1) {
         getAccountInfo(strCommand);
      }
      else if (StringFind(strCommand, "GetOrders:") > -1) {
         getOrders(strCommand);
      }
      else if (StringFind(strCommand, "Hi") > -1 || StringFind(strCommand, "welcome") > -1) {
         Print(strCommand);
      }
      
   } while (strCommand != "");
}

void openOrder (string strCommand) {
   string arr[];
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["Open",   "buy/p_buy_s/p_buy_l/sell/p_sell_s/p_sell_l", "GBPUSD", "Ticket in double", "open price in double", "SL in Double", "TP in Double", "Slippage in Double", "Lots in double"]
   
   //Print("Command Open Order");
   int ticket = -1;
   double lots = GetLot();
   if (arr[1] == "buy") {
      //Print("Buy Order with SL: ", GetSL(OP_BUY, (double)arr[5], arr[2]), " and Lot: ", lots);
      ticket = OpenBuy(arr[2], lots, GetSL(OP_BUY, (double)arr[5]),GetTP(OP_BUY, (double)arr[6]),_Comment,MagicNumber,false,0,0);
      
   } else if (arr[1] == "sell") {
      //Print("Sell Order with SL: ", GetSL(OP_SELL, (double)arr[5], arr[2]), " and Lot: ", lots);
      ticket = OpenSell(arr[2], lots, GetSL(OP_SELL, (double)arr[5]),GetTP(OP_BUY, (double)arr[6]),_Comment,MagicNumber,false,0,0);
   } else if (StringFind(arr[1], "p_") > -1) {
      
   }
   if (ticket > 0) {
      int sz = ArraySize(_orders_array);
      ArrayResize(_orders_array, sz + 1);
      _orders_array[sz] = arr[3] + ":" + (string)ticket + ":" + (string)lots;
      //Print("The ticket ID is: ", _orders_array[sz]);
   }
}

void closeOrder(string strCommand) {
   string arr[];
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["Open",   "long/short", "GBPUSD", "Ticket in double", "open price in double", "SL in Double"]
   
   Print("Command Close Order");
   int size = ArraySize(_orders_array);
   
   if (size > 0) {            
      int ticket_pos = SearchArray(_orders_array, arr[3] + ":",true);
      
      if (ticket_pos > -1) {
         string arr2[];
         StringSplit(_orders_array[ticket_pos],':',arr2);
         int ticket = (int)arr2[1];
         double lots = (double)arr2[2] >= (double)arr[4] ? (double)arr2[2] : (double)arr[4]; 
         int type;
         if (arr[1] == "long")
            type = OP_BUY;
         else if (arr[1] == "short")
            type = OP_SELL;
         else
            return;
         if (CloseOrder(arr[2], type, ticket, lots, MagicNumber, _Comment)) {
            Print("Closed a ", arr[1], " Order with Lots: ", lots, " and Ticket: ", arr[3]);
            
            _orders_array[ticket_pos] = _orders_array[size-1];
            ArrayResize(_orders_array, size-1);
         }
      }
   }
}

void modifyOrder (string strCommand) {
   string arr[];
   CJAVal data;
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["Modify", "Ticket in double", "SL in Double", "TP in Double"]
   
   //Print("Command Close Order");
   int size = ArraySize(_orders_array);
   
   if (size > 0) {            
      int ticket_pos = SearchArray(_orders_array, arr[3] + ":",true);
      
      if (ticket_pos > -1) {
         string arr2[];
         StringSplit(_orders_array[ticket_pos],':',arr2);
         int ticket = (int)arr2[1];
         //double lots = (double)arr2[2] >= (double)arr[4] ? (double)arr2[2] : (double)arr[4]; 

         if (ModifyOrder(ticket, arr[2], arr[3])) {
            Print("Modified a ", arr[1], " Order with Lots: ", lots, " and Ticket: ", arr[3]);
            data["orderticket"] = OrderTicket();
            data["orderticket"] = OrderMagicNumber();
            data["orderticket"] = OrderLots();
            data["orderticket"] = OrderSymbol();
            data["orderticket"] = OrderProfit();
            data["orderticket"] = OrderTypeToString(OrderType());
            data["orderticket"] = OrderOpenPrice();
            data["orderticket"] = OrderClosePrice();
            data["orderticket"] = (string)OrderOpenTime();
            data["orderticket"] = (string)OrderCloseTime();
            data["orderticket"] = OrderComment();
            data["orderticket"] = OrderCommission();
            data["orderticket"] = OrderStopLoss();
            data["orderticket"] = OrderTakeProfit();
            data["orderticket"] = OrderSwap();
         }
      }
   }
   string data_str;
   
   data_str = data.Serialize();
   strCommand = "";
   Base64Encode(data_str, strCommand);
   Print(strCommand+"\r\n\r\n");
   Print(data_str+"\r\n");
   
   if (glbClientSocket.Send(strCommand)) {
      Print("sent response to server successfully");
   } else {
      Print("unable to send response to the server");
   }
}

void setTerminalMode (string strCommand) {
   string arr[];
   CJAVal data;
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["SetMode", "Mode as string"]
   
   if (arr[1] == "trading_client")
      _mode = 0;
   else if (arr[1] == "slave_client")
      _mode = 1;
   else if (arr[1] == "master_client")
      _mode = 2;
   
   data["message"] = "client mode set to " + arr[1];
   
   string data_str;
   
   data_str = data.Serialize();
   strCommand = "";
   Base64Encode(data_str, strCommand);
   Print(strCommand+"\r\n\r\n");
   Print(data_str+"\r\n");
   if (glbClientSocket.Send(strCommand)) {
     Print("sent response to server successfully");
   } else {
     Print("unable to send response to the server");
   }
}

void getAccountHistory (string strCommand) {
   string arr[];
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["GetAccHistory",   "client-id", "last ticket Ticket in double"
   
     // retrieving info from trade history
   int i,j=0,hstTotal=OrdersHistoryTotal();
   if (hstTotal > 0 && arr[1] == (string)AccountNumber()+AccountName()) {  //ensure that the username and account id sent corresponds
     CJAVal data; bool found = false;
     string ticket, opentime, type, lots, symbol, openprice, sl, tp, closetime, closeprice, swap, profit;
     
     for(i=0;i<hstTotal-1;i++) {
        //---- check selection result
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) {
           Print("Access to history failed with error (",GetLastError(),")");
           break;
        }
        ticket = (string)OrderTicket();
        opentime = (string)OrderOpenTime();
        type = OrderTypeToString(OrderType());
        lots = (string)OrderLots();
        symbol = OrderSymbol();
        openprice = (string)OrderOpenPrice();
        sl = (string)OrderStopLoss();
        tp = (string)OrderTakeProfit();
        closetime = (string)OrderCloseTime();
        closeprice = (string)OrderClosePrice();
        swap = (string)OrderSwap();
        profit = (string)OrderProfit();
        
        /*Print(ticket+"\r\n");
        Print(opentime+"\r\n");
        Print(type+"\r\n");
        Print((string)lots+"\r\n");
        Print(symbol+"\r\n");
        Print((string)openprice+"\r\n");
        Print((string)sl+"\r\n");
        Print((string)tp+"\r\n");
        Print(closetime+"\r\n");
        Print((string)closeprice+"\r\n");
        Print((string)swap+"\r\n");
        Print((string)profit+"\r\n");*/

        if (arr[2] != "" || arr[2] != NULL) {
           data[j]["ticket"] = ticket;
           data[j]["opentime"] = opentime;
           data[j]["type"] = type;
           data[j]["lots"] = lots;
           data[j]["symbol"] = symbol;
           data[j]["openprice"] = openprice;
           data[j]["sl"] = sl;
           data[j]["tp"] = tp;
           data[j]["closetime"] = closetime;
           data[j]["closeprice"] = closeprice;
           data[j]["swap"] = swap;
           data[j]["profit"] = profit;
           j++;
        } else if (arr[2] != NULL) {
           if (arr[2] != (string)OrderTicket() || found != true) {
              return;
           }
           found = true;
           data[j]["ticket"] = ticket;
           data[j]["opentime"] = opentime;
           data[j]["type"] = type;
           data[j]["lots"] = lots;
           data[j]["symbol"] = symbol;
           data[j]["openprice"] = openprice;
           data[j]["sl"] = sl;
           data[j]["tp"] = tp;
           data[j]["closetime"] = closetime;
           data[j]["closeprice"] = closeprice;
           data[j]["swap"] = swap;
           data[j]["profit"] = profit;
           j++;
        }
     }
     string data_str;
     
     data_str = data.Serialize();
     strCommand = "";
     Base64Encode(data_str, strCommand);
     Print(strCommand+"\r\n\r\n");
     Print(data_str+"\r\n");
     if (glbClientSocket.Send(strCommand)) {
        Print("sent response to server successfully");
     } else {
        Print("unable to send response to the server");
     }
     /*while (!glbClientSocket.Send(data_str) && j < 5) {
         ++j;
         Sleep(50);
     }*/
   }
}

void getAccountInfo(string strCommand) {
   CJAVal data;
   
   data["account_name"] = AccountName();
   data["account_login"] = AccountNumber();
   data["account_balance"] = AccountBalance();
   data["account_equity"] = AccountEquity();
   data["account_margin"] = AccountMargin();
   data["account_free_margin"] = AccountFreeMargin();
   data["account_leverage"] = AccountLeverage();
   data["account_company"] = AccountCompany();
   data["account_currency"] = AccountCurrency();
   
   string data_str;
   
   data_str = data.Serialize();
   strCommand = "";
   Base64Encode(data_str, strCommand);
   Print(strCommand+"\r\n\r\n");
   Print(data_str+"\r\n");
   if (glbClientSocket.Send(strCommand)) {
     Print("sent response to server successfully");
   } else {
     Print("unable to send response to the server");
   }
}

void getOrders(string strCommand) {
     Print("command get orders");
     string data_str;
     string arr[];
     ushort sep = StringGetCharacter(":",0);
     int k = StringSplit(strCommand, sep, arr);// results to arr = ["GetOrders",   "buy/p_buy_s/p_buy_l/sell/p_sell_s/p_sell_l"]
     int type = arr[1] == "all" ? -1 : StringToOrderType(arr[1]);
     
     CJAVal data = GetOpenOrders(type);
     
     data_str = data.Serialize();
     strCommand = "";
     Base64Encode(data_str, strCommand);
     Print(strCommand+"\r\n\r\n");
     Print(data_str+"\r\n");
     if (glbClientSocket.Send(strCommand)) {
        Print("sent response to server successfully");
     } else {
        Print("unable to send response to the server");
     }
}