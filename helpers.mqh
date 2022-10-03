#include "config.mqh"

// seach an array for a string or substring
int SearchArray(string &arr[], string needle, bool substr = false)
{
   int len = ArraySize(arr);
   for (int i = 0; i < len; i++) {
      if (substr)
         if (StringFind(arr[i], needle) > -1)
            return i;
      else
         if (arr[i] == needle)
            return i;
   }
   return -1;
}

// seach an array of integer
int SearchArray(int &arr[], int needle)
{
   int len = ArraySize(arr);
   for (int i = 0; i < len; i++) {
      if (arr[i] == needle)
         return i;
   }
   return -1;
}

// seach an array of double
int SearchArray(double &arr[], double needle)
{
   int len = ArraySize(arr);
   for (int i = 0; i < len; i++) {
      if (arr[i] == needle)
         return i;
   }
   return -1;
}

void SendJsonResponse(CJAVal &data)
{
   string data_str;
   string strCommand = "";
   
   data_str = data.Serialize();
   Base64Encode(data_str, strCommand);
   Print(strCommand+"\r\n\r\n");
   Print(data_str+"\r\n");
   if (glbClientSocket.Send(strCommand)) {
     Print("sent response to server successfully");
   } else {
     Print("unable to send response to the server");
   }  
}

double GetLot()
{
   double nextOrderLots = FixedLotSize;
   if (LotsPer100Usd > 0 && nextOrderLots == 0) {
      nextOrderLots = AccountBalance()/100 * LotsPer100Usd;
   }
   if (nextOrderLots <= 0)
      nextOrderLots = MinLots;
   if (nextOrderLots > MaxLots)
      nextOrderLots = MaxLots;
      
   return NormalizeDouble(nextOrderLots, 2);
}
//2022.03.28 02:18:57.959	CopierClient GBPJPY,M15: shutdown by timeout

double GetSL(int type, double sl, string symbol=NULL)
{
   if (type == OP_BUY) {
      sl = sl - SlBuff * GetPip(symbol);
   } else if (type == OP_SELL) {
      sl = sl + SlBuff * GetPip(symbol);
   }
   return sl;
}

double GetTP(int type, double tp, string symbol=NULL)
{
   if (type == OP_BUY) {
      tp = tp + SlBuff * GetPip(symbol);
   } else if (type == OP_SELL) {
      tp = tp - SlBuff * GetPip(symbol);
   }
   return tp;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPip(string symbol=NULL)
{

   if(symbol==NULL)
      symbol=Symbol();

#ifdef PipValue
   return  PipValue;
#endif

   double point=MarketInfo(symbol,MODE_POINT);

   //if(_UsePointInsteadOfPip)
      //return point;

   double _pip=point;
   if(point==0.00001 || point==0.001) {
      _pip=point*10;
   }
   //else {
   //   _pip=point;
   //}
   if(StringFind(symbol,"XAU")==0) {
      _pip=1;
   }

   if(StringFind(symbol,"XAG")==0) {
      _pip=0.1;
   }

   if(MarketInfo(symbol,MODE_BID)>1000) {
      _pip = 1;
   }
   return _pip;
}

string OrderTypeToString(int type) {
   string resp;
   switch (type) {
      case (OP_BUY):
         resp = "buy";
         break;
      case (OP_BUYSTOP):
         resp = "buystop";
         break;
      case (OP_BUYLIMIT):
         resp = "buylimit";
         break;
      case (OP_SELL):
         resp = "sell";
         break;
      case (OP_SELLSTOP):
         resp = "sellstop";
         break;
      case (OP_SELLLIMIT):
         resp = "selllimit";
         break;
      default:
         resp = "";
         break;
   }
   return resp;
}

bool MarketOpen(string symbol = "")
{
   symbol = symbol == "" ? Symbol() : symbol;
   
   if((MarketInfo(symbol, MODE_TRADEALLOWED))>0) {
      Print(" Market is Open and Trade is Allowed on This Symbol.");
      return true;
   }
   else {
      Print ("Trade is not Allowed on This Symbol RightNow.");
      return false;
   }

//Combination of the three methods below works on mt4 and mt5   
//SymbolInfoSessionTrade() => to find the last session start/end time

//SymbolInfoInteger(_Symbol,SYMBOL_TIME) => to find out the last known tick time for the symbol

//TimeCurrent() and TerminalInfoInteger(TERMINAL_CONNECTED) => to find out if the server is "ON"
}

int StringToOrderType(string type) {
   if (type == "buy")
      return OP_BUY;
   else if (type == "p_buy_s")
      return OP_BUYSTOP;
   else if (type == "p_buy_l")
      return OP_BUYLIMIT;
   else if (type == "sell")
      return OP_SELL;
   else if (type == "p_sell_s")
      return OP_SELLSTOP;
   else if (type == "p_sell_l")
      return OP_SELLLIMIT;
      
   return -2;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WaitTradeContext()
{
   datetime tstart=TimeLocal();
//Print("enter WaitTradeContext");
   while(!IsTradeAllowed() && TimeLocal()-tstart<60) {
      Sleep(100);
   }
   if(!IsTradeAllowed()) {
      Print("Trade not allowed");
   }
   else {
      //Print("Trade allowed!");
   }

   while(IsTradeContextBusy() && TimeLocal()-tstart<60) {
      Sleep(100);
   }
   if(IsTradeContextBusy()) {
      Print("Trade context busy");
   }
   else {
      //Print("Trade context free!");
   }
//Print("leave WaitTradeContext");
}

string err_msg(int e)
//+------------------------------------------------------------------+
// Returns error message text for a given MQL4 error number
// Usage:   string s=err_msg(146) returns s="Error 0146:  Trade context is busy."
{
   switch(e) {
      case 0:
         return("Error 0000:  No error returned.");
      case 1:
         return("Error 0001:  No error returned, but the result is unknown.");
      case 2:
         return("Error 0002:  Common error.");
      case 3:
         return("Error 0003:  Invalid trade parameters.");
      case 4:
         return("Error 0004:  Trade server is busy.");
      case 5:
         return("Error 0005:  Old version of the client terminal.");
      case 6:
         return("Error 0006:  No connection with trade server.");
      case 7:
         return("Error 0007:  Not enough rights.");
      case 8:
         return("Error 0008:  Too frequent requests.");
      case 9:
         return("Error 0009:  Malfunctional trade operation.");
      case 64:
         return("Error 0064:  Account disabled.");
      case 65:
         return("Error 0065:  Invalid account.");
      case 128:
         return("Error 0128:  Trade timeout.");
      case 129:
         return("Error 0129:  Invalid price.");
      case 130:
         return("Error 0130:  Invalid stops.");
      case 131:
         return("Error 0131:  Invalid trade volume.");
      case 132:
         return("Error 0132:  Market is closed.");
      case 133:
         return("Error 0133:  Trade is disabled.");
      case 134:
         return("Error 0134:  Not enough money.");
      case 135:
         return("Error 0135:  Price changed.");
      case 136:
         return("Error 0136:  Off quotes.");
      case 137:
         return("Error 0137:  Broker is busy.");
      case 138:
         return("Error 0138:  Requote.");
      case 139:
         return("Error 0139:  Order is locked.");
      case 140:
         return("Error 0140:  Long positions only allowed.");
      case 141:
         return("Error 0141:  Too many requests.");
      case 145:
         return("Error 0145:  Modification denied because order too close to market.");
      case 146:
         return("Error 0146:  Trade context is busy.");
      case 147:
         return("Error 0147:  Expirations are denied by broker.");
      case 148:
         return("Error 0148:  The amount of open and pending orders has reached the limit set by the broker.");
      case 149:
         return("Error 0149:  An attempt to open a position opposite to the existing one when hedging is disabled.");
      case 150:
         return("Error 0150:  An attempt to close a position contravening the FIFO rule.");
      case 4000:
         return("Error 4000:  No error.");
      case 4001:
         return("Error 4001:  Wrong function pointer.");
      case 4002:
         return("Error 4002:  Array index is out of range.");
      case 4003:
         return("Error 4003:  No memory for function call stack.");
      case 4004:
         return("Error 4004:  Recursive stack overflow.");
      case 4005:
         return("Error 4005:  Not enough stack for parameter.");
      case 4006:
         return("Error 4006:  No memory for parameter string.");
      case 4007:
         return("Error 4007:  No memory for temp string.");
      case 4008:
         return("Error 4008:  Not initialized string.");
      case 4009:
         return("Error 4009:  Not initialized string in array.");
      case 4010:
         return("Error 4010:  No memory for array string.");
      case 4011:
         return("Error 4011:  Too long string.");
      case 4012:
         return("Error 4012:  Remainder from zero divide.");
      case 4013:
         return("Error 4013:  Zero divide.");
      case 4014:
         return("Error 4014:  Unknown command.");
      case 4015:
         return("Error 4015:  Wrong jump (never generated error).");
      case 4016:
         return("Error 4016:  Not initialized array.");
      case 4017:
         return("Error 4017:  DLL calls are not allowed.");
      case 4018:
         return("Error 4018:  Cannot load library.");
      case 4019:
         return("Error 4019:  Cannot call function.");
      case 4020:
         return("Error 4020:  Expert function calls are not allowed.");
      case 4021:
         return("Error 4021:  Not enough memory for temp string returned from function.");
      case 4022:
         return("Error 4022:  System is busy (never generated error).");
      case 4050:
         return("Error 4050:  Invalid function parameters count.");
      case 4051:
         return("Error 4051:  Invalid function parameter value.");
      case 4052:
         return("Error 4052:  String function internal error.");
      case 4053:
         return("Error 4053:  Some array error.");
      case 4054:
         return("Error 4054:  Incorrect series array using.");
      case 4055:
         return("Error 4055:  Custom indicator error.");
      case 4056:
         return("Error 4056:  Arrays are incompatible.");
      case 4057:
         return("Error 4057:  Global variables processing error.");
      case 4058:
         return("Error 4058:  Global variable not found.");
      case 4059:
         return("Error 4059:  Function is not allowed in testing mode.");
      case 4060:
         return("Error 4060:  Function is not confirmed.");
      case 4061:
         return("Error 4061:  Send mail error.");
      case 4062:
         return("Error 4062:  String parameter expected.");
      case 4063:
         return("Error 4063:  Integer parameter expected.");
      case 4064:
         return("Error 4064:  Double parameter expected.");
      case 4065:
         return("Error 4065:  Array as parameter expected.");
      case 4066:
         return("Error 4066:  Requested history data in updating state.");
      case 4067:
         return("Error 4067:  Some error in trading function.");
      case 4099:
         return("Error 4099:  End of file.");
      case 4100:
         return("Error 4100:  Some file error.");
      case 4101:
         return("Error 4101:  Wrong file name.");
      case 4102:
         return("Error 4102:  Too many opened files.");
      case 4103:
         return("Error 4103:  Cannot open file.");
      case 4104:
         return("Error 4104:  Incompatible access to a file.");
      case 4105:
         return("Error 4105:  No order selected.");
      case 4106:
         return("Error 4106:  Unknown symbol.");
      case 4107:
         return("Error 4107:  Invalid price.");
      case 4108:
         return("Error 4108:  Invalid ticket.");
      case 4109:
         return("Error 4109:  Trade is not allowed. Enable checkbox 'Allow live trading' in the expert properties.");
      case 4110:
         return("Error 4110:  Longs are not allowed. Check the expert properties.");
      case 4111:
         return("Error 4111:  Shorts are not allowed. Check the expert properties.");
      case 4200:
         return("Error 4200:  Object exists already.");
      case 4201:
         return("Error 4201:  Unknown object property.");
      case 4202:
         return("Error 4202:  Object does not exist.");
      case 4203:
         return("Error 4203:  Unknown object type.");
      case 4204:
         return("Error 4204:  No object name.");
      case 4205:
         return("Error 4205:  Object coordinates error.");
      case 4206:
         return("Error 4206:  No specified subwindow.");
      case 4207:
         return("Error 4207:  Some error in object function.");
      //    case 9001:  return("Error 9001:  Cannot close entire order - insufficient volume previously open.");
      //    case 9002:  return("Error 9002:  Incorrect net position.");
      //    case 9003:  return("Error 9003:  Orders not completed correctly - details in log file.");
      default:
         return("Error " + IntegerToString(OrderTicket()) + ": ??? Unknown error.");
   }
   return("n/a");
}