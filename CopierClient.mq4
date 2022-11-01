#include "socket-helper.mqh"


// --------------------------------------------------------------------
// Initialisation (no action required)
// --------------------------------------------------------------------

void OnInit() {
   EventSetMillisecondTimer(TIMER_FREQUENCY_MS);
   initGlobals();
}

// --------------------------------------------------------------------
// Termination - free the client socket, if created
// --------------------------------------------------------------------

void OnDeinit(const int reason)
{
   EventKillTimer();
   if (glbClientSocket) {
      delete glbClientSocket;
      glbClientSocket = NULL;
   }
}

// --------------------------------------------------------------------
// Tick handling - set up a connection, if none already active,
// and send the current price quote
// --------------------------------------------------------------------

void OnTick()
{
   if (!glbClientSocket) {
      glbClientSocket = new ClientSocket(Hostname, ServerPort);
      if (glbClientSocket.IsSocketConnected()) {
         //glbClientSocket.Send((string)AccountNumber()+AccountName());
         Sleep(5);
         glbClientSocket.Send((string)AccountNumber()+"\n");
         Sleep(5);
         Print("Client connection succeeded");
      } else {
         Print("Client connection failed");
      }
   }

   if (glbClientSocket.IsSocketConnected()) {
      // Send the current price as a CRLF-terminated message
      //string strMsg = Symbol() + "," + DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_BID), 6) + "," + DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_ASK), 6);
      //glbClientSocket.Send(strMsg);
      HandleIncomingData();
   } else {
      // If the socket is closed, destroy it, and attempt a new connection
      // on the next call to OnTick()/OnTimer
      // Destroy the server socket. A new connection
      // will be attempted on the next tick
      //Print("Client disconnected. Will retry.");
      delete glbClientSocket;
      glbClientSocket = NULL;
   }
}

void OnTimer()
{
   if (!glbClientSocket) {
      glbClientSocket = new ClientSocket(Hostname, ServerPort);
      if (glbClientSocket.IsSocketConnected()) {
         //glbClientSocket.Send((string)AccountNumber()+AccountName());
         Sleep(5);
         glbClientSocket.Send((string)AccountNumber()+"\n");
         Print("Client connection succeeded");
         Sleep(5);
      } else {
         Print("Client connection failed");
      }
   }

   if (glbClientSocket.IsSocketConnected()) {
      // Send the current price as a CRLF-terminated message
      //string strMsg = Symbol() + "," + DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_BID), 6) + "," + DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_ASK), 6);
      //glbClientSocket.Send(strMsg);
      HandleIncomingData();
   } else {
      // If the socket is closed, destroy it, and attempt a new connection
      // on the next call to OnTick()/OnTimer
      // Destroy the server socket. A new connection
      // will be attempted on the next tick
      //Print("Client disconnected. Will retry.");
      delete glbClientSocket;
      glbClientSocket = NULL;
   }
}