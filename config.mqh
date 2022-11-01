//+------------------------------------------------------------------+
//|                                                 CopierClient.mq4 |
//|                                            Basttyy(IoThings Lab) |
//|                                      https://www.iothings.com.ng |
//+------------------------------------------------------------------+
#property copyright "Basttyy(IoThings Lab)"
#property link      "https://www.iothings.com.ng"
#property version   "1.00"
#property strict

#define TIMER_FREQUENCY_MS    10
// --------------------------------------------------------------------
// Include socket library
// --------------------------------------------------------------------

#include <socket-library-mt4-mt5.mqh>
#include <JAson.mqh>
#include <Base64.mqh>

// --------------------------------------------------------------------
// EA user inputs
// --------------------------------------------------------------------
#define MASTER_CLIENT 1
#define SLAVE_CLIENT 0
#define TRADING_CLIENT 2

input string   Hostname = "localhost";    // Server hostname or IP address
input ushort   ServerPort = 23456;        // Server port
input string Pairs = "XAUUSD,GBPUSD,EURUSD,USDCHF,USDJPY,NZDUSD,GBPJPY,AUDJPY,AUDUSD";     // Can add more pairs with comma (,) separation
input string PairPrefix = "";
input string PairSuffix = "";
input double SlBuff = 4;                 // SL addition for trade signals
input double FixedLotSize = 0.0;          // Set to zero to deactivate
input double LotsPer100Usd = 0.01;        // Lot size to increment per 100usd
input double MinLots = 0.01;              // Minimum Lots that can ever be used
input double MaxLots = 40;                // Maximum Lots that can ever be used
input bool _ECN = true;                 // Is account ECN
input double _MaxSlippage = 3;           // Maximum Slippage
input string _Comment = "basttyydev@gmail.com";
input int MagicNumber=321123; // Magic Number
input int Mode=0;                   //0 for slave_client, 1 for master_client and 2 for trading_client 

// --------------------------------------------------------------------
// Global variables and constants
// --------------------------------------------------------------------

string   hostname;
ushort   server_port;
string pairs;
string pair_prefix;
string pair_suffix;
double slbuff;
double fixedlotsize;
double lotsper100usd;
double minlots;
double maxlots;
bool _ecn;
double _maxslippage;
string _comment;
int magicnumber;

ClientSocket * glbClientSocket = NULL;

string _orders_array[];
string _copier_slaves[];
int _mode = Mode;