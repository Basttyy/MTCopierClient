#include "order-helper.mqh"

void HandleIncomingData() {
   string strCommand;
   do {
      strCommand = glbClientSocket.Receive("\n");
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
      else if (StringFind(strCommand, "AddSlave:") > -1) {
         addSlaveClient(strCommand);
      }
      else if (StringFind(strCommand, "RemoveSlave:") > -1) {
         removeSlaveClient(strCommand);
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
      else if (StringFind(strCommand, "SetSettings:") > -1) {
         setSettings(strCommand);
      }
      else if (StringFind(strCommand, "GetSettings:") > -1) {
         getSettings(strCommand);
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
      ticket = OpenBuy(addPairPrefixSuffix(arr[2]), lots, GetSL(OP_BUY, (double)arr[5]),GetTP(OP_BUY, (double)arr[6]),_Comment,MagicNumber,false,0,0);
      
   } else if (arr[1] == "sell") {
      //Print("Sell Order with SL: ", GetSL(OP_SELL, (double)arr[5], arr[2]), " and Lot: ", lots);
      ticket = OpenSell(addPairPrefixSuffix(arr[2]), lots, GetSL(OP_SELL, (double)arr[5]),GetTP(OP_BUY, (double)arr[6]),_Comment,MagicNumber,false,0,0);
   } else if (StringFind(arr[1], "p_") > -1) {
      
   }
   CJAVal data;
   if (ticket < 1) {
      data["message"] = "unable to open order";
      SendJsonResponse(data);
      return ;
   }
   int sz = ArraySize(_orders_array);
   ArrayResize(_orders_array, sz + 1);
   _orders_array[sz] = arr[3] + ":" + (string)ticket + ":" + (string)lots;
   //Print("The ticket ID is: ", _orders_array[sz]);
   
   if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
      data["message"] = "order opened but couldn't get order info";
      SendJsonResponse(data);
      if (_mode == MASTER_CLIENT) {
         data.Clear();
         data["command"] = arr[0]+":"+arr[1]+":"+removePairPrefixSuffix(arr[2])+":"+(string)ticket+":"+arr[4]+":"+arr[5]+":"+arr[6]+":"+arr[7]+":"+arr[8];
         data["clients"] = ConvertArrayToCJAVal(_copier_slaves);
         SendJsonResponse(data);
      }
      return ;
   }
   data["orderticket"] = OrderTicket();
   data["ordermagicnumber"] = OrderMagicNumber();
   data["orderlots"] = OrderLots();
   data["ordersymbol"] = OrderSymbol();
   data["orderprofit"] = OrderProfit();
   data["ordertype"] = OrderTypeToString(OrderType());
   data["orderopenprice"] = OrderOpenPrice();
   data["ordercloseprice"] = OrderClosePrice();
   data["orderopentime"] = (string)OrderOpenTime();
   data["orderclosetime"] = (string)OrderCloseTime();
   data["ordercomment"] = OrderComment();
   data["ordercommission"] = OrderCommission();
   data["orderstoploss"] = OrderStopLoss();
   data["ordertakeprofit"] = OrderTakeProfit();
   data["orderswap"] = OrderSwap();
   
   SendJsonResponse(data); 
   if (_mode == MASTER_CLIENT) {
      data.Clear();
      data["command"] = arr[0]+":"+arr[1]+":"+removePairPrefixSuffix(arr[2])+":"+(string)ticket+":"+arr[4]+":"+arr[5]+":"+arr[6]+":"+arr[7]+":"+arr[8];
      data["clients"] = ConvertArrayToCJAVal(_copier_slaves);
      SendJsonResponse(data, "copytrade");
   }
   return ;
}

void closeOrder(string strCommand) {
   string arr[];
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["Close",   "long/short", "GBPUSD", "Ticket in double", "lots in double"]
   
   Print("Command Close Order");
   int size = ArraySize(_orders_array);
             
   CJAVal data;
   if (size <= 0) {
      data["message"] = "there are no orders currently";
      SendJsonResponse(data);
      return ;
   }
   
   int ticket_pos = SearchArray(_orders_array, arr[3], size, true);
   
   if (ticket_pos < 0) {
      data["message"] = "order with ticket " + arr[3] + " does not exist in the list";
      SendJsonResponse(data);
      return ;
   }
   
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
   if (!CloseOrder(addPairPrefixSuffix(arr[2]), type, ticket, lots, MagicNumber, _Comment)) {
      data["message"] = "unable to close order with ticket " + arr[3];
      SendJsonResponse(data);
      return ;
   }
   
   Print("Closed a ", arr[1], " Order with Lots: ", lots, " and Ticket: ", arr[3]);
   
   _orders_array[ticket_pos] = _orders_array[size-1];
   ArrayResize(_orders_array, size-1);
   
   data["message"] = "close order with ticket " + arr[3] + " successfully";
   SendJsonResponse(data);
   if (_mode == MASTER_CLIENT) {
      data.Clear();
      data["command"] = arr[0]+":"+arr[1]+":"+removePairPrefixSuffix(arr[2])+":"+(string)ticket+":"+DoubleToString(lots);
      data["clients"] = ConvertArrayToCJAVal(_copier_slaves);
      SendJsonResponse(data, "copytrade");
   }
   return ;
}

void modifyOrder (string strCommand) {
   string arr[];
   CJAVal data;
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["Modify", "Ticket in double", "SL in Double", "TP in Double"]
   
   //Print("Command Close Order");
   int size = ArraySize(_orders_array);
   
   if (size <= 0) {
      data["message"] = "there are no orders currently";
      SendJsonResponse(data);
      return ;
   }
   
   int ticket_pos = SearchArray(_orders_array, arr[1], size, true);
   
   if (ticket_pos < 0) {
      data["message"] = "order with ticket " + arr[1] + " does not exist in the list";
      SendJsonResponse(data);
      return ;
   }
   
   string arr2[];
   StringSplit(_orders_array[ticket_pos],':',arr2);
   int ticket = (int)arr2[1];
   //double lots = (double)arr2[2] >= (double)arr[4] ? (double)arr2[2] : (double)arr[4]; 

   if (!ModifyOrder(ticket, (double)arr[2], (double)arr[3])) {
      data["message"] = "unable to modify order with ticket " + arr[3];
      SendJsonResponse(data);
      return ;
   }
   
   Print("Modified a ", arr[1], " Order with Lots: ", arr2[2], " and Ticket: ", arr[3]);
   data["orderticket"] = OrderTicket();
   data["ordermagicnumber"] = OrderMagicNumber();
   data["orderlots"] = OrderLots();
   data["ordersymbol"] = OrderSymbol();
   data["orderprofit"] = OrderProfit();
   data["ordertype"] = OrderTypeToString(OrderType());
   data["orderopenprice"] = OrderOpenPrice();
   data["ordercloseprice"] = OrderClosePrice();
   data["orderopentime"] = (string)OrderOpenTime();
   data["orderclosetime"] = (string)OrderCloseTime();
   data["ordercomment"] = OrderComment();
   data["ordercommission"] = OrderCommission();
   data["orderstoploss"] = OrderStopLoss();
   data["ordertakeprofit"] = OrderTakeProfit();
   data["orderswap"] = OrderSwap();
   
   SendJsonResponse(data);
   if (_mode == MASTER_CLIENT) {
      data.Clear();
      data["command"] = arr[0]+":"+(string)ticket+":"+arr[2]+":"+arr[3];
      data["clients"] = ConvertArrayToCJAVal(_copier_slaves);
      SendJsonResponse(data, "copytrade");
   }
}

void setTerminalMode (string strCommand) {
   Print("got to set terminal mode");
   string arr[];
   CJAVal data;
   if (OrdersTotal() < 1) {
      ArrayResize(_copier_slaves, 0);
      ArrayResize(_orders_array, 0);
      
      ushort sep = StringGetCharacter(":",0);
      int k = StringSplit(strCommand, sep, arr);// results to arr = ["SetMode", "Mode as string"]
      
      if (arr[1] == "slave_client")
         _mode = 0;
      else if (arr[1] == "master_client")
         _mode = 1;
      else if (arr[1] == "trading_client")
         _mode = 2;
      
      data["message"] = "client mode set to " + arr[1];
   } else {
      data["message"] = "unable to change client mode please close open trades first";
   }
   
   SendJsonResponse(data);
}

void addSlaveClient (string strCommand) {
   string arr[];
   CJAVal data;
   if (_mode != MASTER_CLIENT) {
      string client_mode = _mode == SLAVE_CLIENT ? "slave client" : "trading client";
      data["message"] = "you can't add a slave to a " + client_mode;
      SendJsonResponse(data);
      return ;
   }
   
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["AddSlave", "ClientID as string"]
   
   if (ArraySize(arr) < 2) {
      data["message"] = "request parameters are incomplete";
      SendJsonResponse(data);
      return ;
   }
   
   int pos = SearchArray(_copier_slaves, arr[1], ArraySize(_copier_slaves));
   
   if (pos > -1) {
      data["message"] = "this client has already been added to the copy list";
      SendJsonResponse(data);
      return ;
   }
   
   int sz = ArraySize(_copier_slaves);
   ArrayResize(_copier_slaves, sz + 1);
   _copier_slaves[sz] = arr[1];
   
   data["message"] = "slave client added successfully";
   SendJsonResponse(data);
}

void removeSlaveClient (string strCommand) {
   string arr[];
   CJAVal data;
   if (_mode != MASTER_CLIENT) {
      string client_mode = "";
      client_mode = (_mode == SLAVE_CLIENT) ? "slave client" : "trading client";
      data["message"] = "you can't remove a slave from a " + client_mode;
      SendJsonResponse(data);
      return ;
   }
   
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["AddSlave", "ClientID as string"]
   
   if (ArraySize(arr) < 2) {
      data["message"] = "request parameters are incomplete";
      SendJsonResponse(data);
      return ;
   }
   
   int client_pos = SearchArray(_copier_slaves, arr[1], ArraySize(_copier_slaves));
   int sz = ArraySize(_copier_slaves);
   
   if (client_pos < 0) {
      data["message"] = "this client does not exist in the copy list";
      SendJsonResponse(data);
      return ;
   }
   
   _copier_slaves[client_pos] = _copier_slaves[sz - 1];
   ArrayResize(_copier_slaves, sz - 1);
   
   data["message"] = "slave client removed successfully";
   SendJsonResponse(data);
}

void getAccountHistory (string strCommand) {
   string arr[];
   ushort sep = StringGetCharacter(":",0);
   int k = StringSplit(strCommand, sep, arr);// results to arr = ["GetAccHistory",   "client-id", "last ticket Ticket in double"
   
     // retrieving info from trade history
   int i,j=0,hstTotal=OrdersHistoryTotal();
   //if (hstTotal > 0 && arr[1] == (string)AccountNumber()+AccountName()) {  //ensure that the username and account id sent corresponds
   if (hstTotal > 0 && arr[1] == (string)AccountNumber()) {  //ensure that the username and account id sent corresponds
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
     SendJsonResponse(data);
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
   
   SendJsonResponse(data);
}

void getOrders(string strCommand) {
     Print("command get orders");
     string arr[];
     ushort sep = StringGetCharacter(":",0);
     int k = StringSplit(strCommand, sep, arr);// results to arr = ["GetOrders",   "buy/p_buy_s/p_buy_l/sell/p_sell_s/p_sell_l"]
     int type = arr[1] == "all" ? -1 : StringToOrderType(arr[1]);
     
     CJAVal data = GetOpenOrders(type);
     
     SendJsonResponse(data);
}

void getSettings(string strCommand) {
   CJAVal data;
   
   data["hostname"] = hostname;
   data["serverport"] = (string)server_port;
   data["pairs"] = pairs;
   data["slbuff"] = slbuff;
   data["fixedlotsize"] = fixedlotsize;
   data["lotsper100usd"] = lotsper100usd;
   data["minlots"] = minlots;
   data["maxlots"] = maxlots;
   data["ecn"] = _ecn;
   data["maxslippage"] = _maxslippage;
   data["comment"] = _comment;
   data["magicnumber"] = magicnumber;
   if (_mode == 0)  //0 for slave_client, 1 for master_client and 2 for trading_client 
      data["mode"] = "slave_client";
   else if (_mode == 1)
      data["mode"] = "master_client";
   else if (_mode == 2)
      data["mode"] = "trading_client";
   
   SendJsonResponse(data);
}

void setSettings(string strCommand) {
   string arr[];
   CJAVal data;
   if (OrdersTotal() < 1) {      
      ushort sep = StringGetCharacter(":",0);
      int k = StringSplit(strCommand, sep, arr);// results to arr = ["SetMode", "hostname", "serverport", "pairs", "slbuff", "fixedlotsize", "lotsper100usd", "minlots", "maxlots", "ecn", "maxslippage", "comment", "magicnumber", "mode"]
      
      if (arr[1] != "*")
         hostname = arr[1];
      if (arr[2] != "*")
         server_port = (ushort)StrToDouble(arr[2]);
      if (arr[3] != "*")
         pairs = arr[3];
      if (arr[4] != "*")
         slbuff = StringToDouble(arr[4]);
      if (arr[5] != "*")
         fixedlotsize = StringToDouble(arr[5]);
      if (arr[6] != "*")
         lotsper100usd = StringToDouble(arr[6]);
      if (arr[7] != "*")
         minlots = StringToDouble(arr[7]);
      if (arr[8] != "*")
         maxlots = (double)arr[8];
      if (arr[9] != "*")
         _ecn = (bool)StrToInteger(arr[9]);
      if (arr[10] != "*")
         _maxslippage = StringToDouble(arr[10]);
      if (arr[11] != "*")
         _comment = arr[11];
      if (arr[12] != "*")
         magicnumber = StrToInteger(arr[12]);
      if (arr[13] != "*") {         
         if (arr[13] == "slave_client")  //0 for slave_client, 1 for master_client and 2 for trading_client 
            _mode = 0;
         else if (arr[13] == "master_client")
            _mode = 1;
         else if (arr[13] == "trading_client")
            _mode = 2;
      }

      data["message"] = "client settings updated successfully";
   } else {
      data["message"] = "unable to change client mode please close open trades first";
   }
   
   SendJsonResponse(data);
}