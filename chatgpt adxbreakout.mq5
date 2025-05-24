//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handleADX != INVALID_HANDLE)
     {
      IndicatorRelease(handleADX);
      handleADX = INVALID_HANDLE;
     }
  }

//+------------------------------------------------------------------+
//| Função para obter valores ADX, +DI, -DI da barra anterior (index 1) |
//+------------------------------------------------------------------+
bool GetADXValues(double &adx, double &plusDI, double &minusDI)
  {
   double adxBuffer[1];
   double plusDIBuffer[1];
   double minusDIBuffer[1];

   if(CopyBuffer(handleADX, 0, 1, 1, adxBuffer) <= 0) return false;
   if(CopyBuffer(handleADX, 1, 1, 1, plusDIBuffer) <= 0) return false;
   if(CopyBuffer(handleADX, 2, 1, 1, minusDIBuffer) <= 0) return false;

   adx = adxBuffer[0];
   plusDI = plusDIBuffer[0];
   minusDI = minusDIBuffer[0];

   return true;
  }

//+------------------------------------------------------------------+
//| Função para verificar a tendência: 1=alta, -1=baixa, 0=neutro  |
//+------------------------------------------------------------------+
int CheckTrend()
  {
   double adx, plusDI, minusDI;
   if(!GetADXValues(adx, plusDI, minusDI))
     {
      Print("Erro ao obter valores do ADX");
      return 0;
     }

   if(adx < adxLevel)
      return 0;

   if(plusDI > minusDI)
      return 1;

   if(minusDI > plusDI)
      return -1;

   return 0;
  }
//+------------------------------------------------------------------+
//| Função para obter arrays de preço: High, Low, Close             |
//+------------------------------------------------------------------+
bool GetPriceData(int start, int count, double &high[], double &low[], double &close[])
  {
   if(CopyHigh(_Symbol, PERIOD_CURRENT, start, count, high) <= 0) return false;
   if(CopyLow(_Symbol, PERIOD_CURRENT, start, count, low) <= 0) return false;
   if(CopyClose(_Symbol, PERIOD_CURRENT, start, count, close) <= 0) return false;
   return true;
  }

//+------------------------------------------------------------------+
//| Função para confirmar breakout baseado em breakoutLookback barras|
//+------------------------------------------------------------------+
bool ConfirmBreakout(bool isBuy)
  {
   double highs[], lows[], closes[];
   if(!GetPriceData(1, breakoutLookback, highs, lows, closes))
     {
      Print("Erro ao obter dados de preço");
      return false;
     }

   double referencePrice;

   if(isBuy)
     {
      int maxIndex = ArrayMaximum(highs, 0, ArraySize(highs));
      referencePrice = highs[maxIndex];
      double lastClose = closes[0];
      return lastClose > referencePrice;
     }
   else
     {
      int minIndex = ArrayMinimum(lows, 0, ArraySize(lows));
      referencePrice = lows[minIndex];
      double lastClose = closes[0];
      return lastClose < referencePrice;
     }
  }

//+------------------------------------------------------------------+
//| Exemplo de função OnTick com uso da tendência e breakout        |
//+------------------------------------------------------------------+
void OnTick()
  {
   int trend = CheckTrend();

   if(trend == 1) // tendência de alta
     {
      if(ConfirmBreakout(true))
        {
         // Coloque aqui sua lógica para abrir ordem BUY
         Print("Sinal de compra confirmado");
        }
     }
   else if(trend == -1) // tendência de baixa
     {
      if(ConfirmBreakout(false))
        {
         // Coloque aqui sua lógica para abrir ordem SELL
         Print("Sinal de venda confirmado");
        }
     }
   else
     {
      // Sem tendência clara
      Print("Sem tendência clara para operação");
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Função para abrir ordem de compra                                |
//+------------------------------------------------------------------+
bool OpenBuyOrder(double lot)
  {
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = _Symbol;
   request.volume   = lot;
   request.type     = ORDER_TYPE_BUY;
   request.price    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.deviation= 10;
   request.magic    = 123456;
   
   if(!OrderSend(request, result))
     {
      Print("Erro ao enviar ordem de compra: ", GetLastError());
      return false;
     }
   
   if(result.retcode != TRADE_RETCODE_DONE)
     {
      Print("Ordem de compra rejeitada: ", result.retcode);
      return false;
     }
   
   Print("Ordem de compra aberta com sucesso, ticket: ", result.order);
   return true;
  }

//+------------------------------------------------------------------+
//| Função para abrir ordem de venda                                 |
//+------------------------------------------------------------------+
bool OpenSellOrder(double lot)
  {
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = _Symbol;
   request.volume   = lot;
   request.type     = ORDER_TYPE_SELL;
   request.price    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation= 10;
   request.magic    = 123456;
   
   if(!OrderSend(request, result))
     {
      Print("Erro ao enviar ordem de venda: ", GetLastError());
      return false;
     }
   
   if(result.retcode != TRADE_RETCODE_DONE
//+------------------------------------------------------------------+
//| Função principal OnTick para executar operações                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   static bool posOpen = false;
   static int posType = 0; // 1 = buy, -1 = sell
   static ulong ticket = 0;
   double lotSize = 0.1; // ajuste conforme necessidade

   int trend = CheckTrend();

   if(trend == 1) // tendência de alta
     {
      if(ConfirmBreakout(true))
        {
         if(!posOpen || posType != 1)
           {
            if(posOpen)
              {
               // fechar venda antes de abrir compra
               ClosePosition(ticket);
              }
            if(OpenBuyOrder(lotSize))
              {
               posOpen = true;
               posType = 1;
               // atualizar ticket, buscar ordem aberta
               ticket = GetLastOrderTicket();
              }
           }
        }
     }
   else if(trend == -1) // tendência de baixa
     {
      if(ConfirmBreakout(false))
        {
         if(!posOpen || posType != -1)
           {
//+------------------------------------------------------------------+
//| Função para verificar se já existe posição aberta do tipo dado  |
//+------------------------------------------------------------------+
bool IsPositionOpen(int type)
  {
   for(int i=0; i<PositionsTotal(); i++)
     {
      if(PositionSelectByIndex(i))
        {
         MqlTradePosition pos = PositionGet();
         if(type == 1 && pos.type == POSITION_TYPE_BUY && pos.symbol == _Symbol)
            return true;
         if(type == -1 && pos.type == POSITION_TYPE_SELL && pos.symbol == _Symbol)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Ajuste na função OnTick para usar IsPositionOpen                 |
//+------------------------------------------------------------------+
void OnTick()
  {
   int trend = CheckTrend();
   double lotSize = 0.1;

   if(trend == 1)
     {
      if(ConfirmBreakout(true) && !IsPositionOpen(1))
        {
         if(IsPositionOpen(-1))
            ClosePositionByType(-1);
         OpenBuyOrder(lotSize);
        }
     }
   else if(trend == -1)
     {
      if(ConfirmBreakout(false) && !IsPositionOpen(-1))
        {
         if(IsPositionOpen(1))
            ClosePositionByType(1);
         OpenSellOrder(lotSize);
        }
     }
   else
     {
      // Fechar todas as posições se sem tendência
      ClosePositionByType(1);
      ClosePositionByType(-1);
     }
  }

//+------------------------------------------------------------------+
//| Fechar posição pelo tipo (compra=1, venda=-1)                   |
//+------------------------------------
//+------------------------------------------------------------------+
//| Função para calcular Stop Loss e Take Profit baseados no BoxWidth|
//+------------------------------------------------------------------+
void CalculateSLTP(double &stopLoss, double &takeProfit, bool isBuy)
  {
   double boxWidth = 0.0;
   double highs[], lows[];

   // Pegar highs e lows das últimas breakoutLookback barras
   if(!GetPriceData(1, breakoutLookback, highs, lows, highs)) // Reaproveitando highs para close temporariamente
     {
      Print("Erro ao obter dados para cálculo SL/TP");
      stopLoss = 0;
      takeProfit = 0;
      return;
     }

   // Cálculo simples do box width: máxima high - mínima low no período
   double maxHigh = ArrayMaximum(highs, 0, ArraySize(highs));
   double minLow = ArrayMini
//+------------------------------------------------------------------+
//| Função CheckTrend: verifica direção da tendência com ADX         |
//+------------------------------------------------------------------+
int CheckTrend()
  {
   double plusDI, minusDI, adxValue;
   int adxPeriod = 14;

   plusDI = iADX(_Symbol, PERIOD_CURRENT, adxPeriod, PRICE_CLOSE, MODE_PLUSDI, 0);
   minusDI = iADX(_Symbol, PERIOD_CURRENT, adxPeriod, PRICE_CLOSE, MODE_MINUSDI, 0);
   adxValue = iADX(_Symbol, PERIOD_CURRENT, adxPeriod, PRICE_CLOSE, MODE_MAIN, 0);

   if(adxValue < adxLowerLevel)
      return 0; // Sem tendência forte

   if(plusDI > minusDI)
      return 1; // Tendência de alta

   if(minusDI > plusDI)
      return -1; // Tendência de baixa

   return 0; // Indefinido
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Função ConfirmBreakout: confirma breakout de alta ou baixa      |
//+------------------------------------------------------------------+
bool ConfirmBreakout(bool isBuy)
  {
   // Aqui, você pode implementar a lógica para confirmar breakout,
   // Exemplo: verificar fechamento do candle acima/abaixo do box
   double closePrice = Close[1];
   double highPrice = High[1];
   double lowPrice = Low[1];
   
   if(isBuy)
     {
      // Confirmar que candle fechou acima de resistência (exemplo)
      return (closePrice > highPrice);
     }
   else
     {
      // Confirmar que candle fechou abaixo de suporte (exemplo)
      return (closePrice < lowPrice);
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Função GetPriceData: obtém arrays de highs, lows, closes        |
//+------------------------------------------------------------------+
bool GetPriceData(int startIndex, int count, double &highs[], double &lows[], double &closes[])
  {
   ArrayResize(highs, count);
   ArrayResize(lows, count);
   ArrayResize(closes, count);

   for(int i = 0; i < count; i++)
     {
      int index = startIndex + i;
      if(index >= Bars)
        {
         Print("Index fora do range em GetPriceData");
         return false;
        }
      highs[i] = High[index];
      lows[i] = Low[index];
      closes[i] = Close[index];
     }
   return true;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Função OpenBuyOrder: abre ordem de compra com SL e TP           |
//+------------------------------------------------------------------+
bool OpenBuyOrder(double lot)
  {
   double stopLoss, takeProfit;
   CalculateSLTP(stopLoss, takeProfit, true);

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = _Symbol;
   request.volume   = lot;
   request.type     = ORDER_TYPE_BUY;
   request.price    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.sl       = stopLoss;
   request.tp       = takeProfit;
   request.deviation= 10;
   request.magic    = ExpertMagicNumber;

   if(!OrderSend(request, result))
     {
      Print("Erro ao abrir ordem de compra: ", GetLastError());
      return false;
     }

   if(result.retcode != TRADE_RETCODE_DONE)
     {
      Print("Falha na abertura da compra: ", result.retcode);
      return false;
     }

   Print("Ordem de compra aberta, ticket: ", result.order);
   return true;
  }
//+------------------------------------------------------------------+
//| Função OpenSellOrder: abre ordem de venda com SL e TP           |
//+------------------------------------------------------------------+
bool OpenSellOrder(double lot)
  {
   double stopLoss, takeProfit;
   CalculateSLTP(stopLoss, takeProfit, false);

   MqlTradeRequest request;
   MqlTradeResult
//+------------------------------------------------------------------+
//| Função ClosePosition: fecha posição por ticket                   |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket)
  {
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   if(!PositionSelectByTicket(ticket))
     {
      Print("Posição não encontrada para fechar: ", ticket);
      return false;
     }

   MqlTradePosition pos = PositionGet();

   request.action   = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol   = pos.symbol;
   request.volume   = pos.volume;
   request.deviation= 10;

   if(pos.type == POSITION_TYPE_BUY)
      request.type = ORDER_TYPE_SELL;
   else if(pos.type == POSITION_TYPE_SELL)
      request.type = ORDER_TYPE_BUY;
   else
     {
      Print("Tipo de posição desconhecido para fechar ticket: ", ticket);
      return false;
     }

   request.price = (request.type == ORDER_TYPE_BUY) ? SymbolInfoDouble(pos.symbol, SYMBOL_ASK) : SymbolInfoDouble(pos.symbol, SYMBOL_BID);

   if(!OrderSend(request, result))
     {
      Print("Erro ao enviar ordem de fechamento: ", GetLastError());
      return false;
     }

   if(result.retcode != TRADE_RETCODE_DONE)
     {
      Print("Falha no fechamento da posição: ", result.retcode);
      return false;
     }

   Print("Posição fechada, ticket: ", ticket);
   return true;
  }
//+------------------------------------------------------------------+
//| Variáveis globais e parâmetros configuráveis                    |
//+------------------------------------------------------------------+
input int breakoutLookback = 20;
input double profitTargetMultiplier = 1.0;
input double stopLossMultiplier = 3.5;
input int ExpertMagicNumber = 123456;

//+------------------------------------------------------------------+
//| Função OnInit: inicialização do Expert Advisor                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("ADX Breakout Expert Advisor iniciado.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Função OnDeinit: finalização do Expert Advisor                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("ADX Breakout Expert Advisor finalizado.");
  }
//+------------------------------------------------------------------+
//| Função principal OnTick                                          |
//+------------------------------------------------------------------+
void OnTick()
  {
   int trend = CheckTrend();
   double lotSize = 0.1;

   if(trend == 1)
     {
      if(ConfirmBreakout(true) && !IsPositionOpen(1))
        {
         if(IsPositionOpen(-1))
            ClosePositionByType(-1);
         OpenBuyOrder(lotSize);
        }
     }
   else if(trend == -1)
     {
      if(ConfirmBreakout(false) && !IsPositionOpen(-1))
        {
         if(IsPositionOpen(1))
            ClosePositionByType(1);
         OpenSellOrder(lotSize);
        }
     }
   else
     {
      ClosePositionByType(1);
      ClosePositionByType(-1);
     }
  }
//+------------------------------------------------------------------+
//| Função IsPositionOpen: verifica se posição de determinado tipo  |
//+------------------------------------------------------------------+
bool IsPositionOpen(int posType)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionGetTicket(i) > 0)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
           {
            MqlTradePosition pos = PositionGet();
            if(pos.type == POSITION_TYPE_BUY && posType == 1)
               return true;
            if(pos.type == POSITION_TYPE_SELL && posType == -1)
               return true;
           }
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Função ClosePositionByType: fecha posição do tipo indicado      |
//+------------------------------------------------------------------+
void ClosePositionByType(int posType)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionGetTicket(i) > 0)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
           {
            MqlTradePosition pos = PositionGet();
            if(pos.type == POSITION_TYPE_BUY && posType == 1)
               ClosePosition(ticket);
            if(pos.type == POSITION_TYPE_SELL && posType == -1)
               ClosePosition(ticket);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Função Principal: controle do Expert Advisor                    |
//+------------------------------------------------------------------+
void OnTimer()
  {
   // Implementar funções periódicas, se necessário
  }
//+------------------------------------------------------------------+
//| Função para inicializar timer no OnInit                         |
//+------------------------------------------------------------------+
void SetupTimer()
  {
   EventSetTimer(60); // Timer a cada 60 segundos
  }

//+------------------------------------------------------------------+
//| Função para parar timer no OnDeinit                             |
//+------------------------------------------------------------------+
void StopTimer()
  {
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Implementação do evento OnTimer                                  |
//+------------------------------------------------------------------+
void OnTimerEvent()
  {
   // Pode ser usado para verificar condições adicionais periodicamente
   // Por enquanto, vazio
  }

//+------------------------------------------------------------------+
//| Função CalculateSLTP: calcula Stop Loss e Take Profit           |
//+------------------------------------------------------------------+
void CalculateSLTP(double &stopLoss, double &takeProfit, bool isBuy)
  {
   double boxWidth = CalculateBoxWidth();
   double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(isBuy)
     {
      stopLoss = price - boxWidth * stopLossMultiplier * _Point;
      takeProfit = price + boxWidth * profitTargetMultiplier * _Point;
     }
   else
     {
      stopLoss = price + boxWidth * stopLossMultiplier * _Point;
      takeProfit = price - boxWidth * profitTargetMultiplier * _Point;
     }
  }

//+------------------------------------------------------------------+
//| Função CalculateBoxWidth: calcula largura da box do breakout   |
//+------------------------------------------------------------------+
double CalculateBoxWidth()
  {
   double highestHigh = High[Highest(_Symbol, PERIOD_CURRENT, MODE_HIGH, breakoutLookback, 1)];
   double lowestLow = Low[Lowest(_Symbol, PERIOD_CURRENT, MODE_LOW, breakoutLookback, 1)];
   return highestHigh - lowestLow;
  }


//+------------------------------------------------------------------+
//| Função Highest: retorna índice da barra com maior valor HIGH    |
//+------------------------------------------------------------------+
int Highest(string symbol, ENUM_TIMEFRAMES timeframe, int mode, int count, int start)
  {
   int highestIndex = start;
   double highestValue = High[start];
   for(int i = start; i < start + count; i++)
     {
      if(High[i] > highestValue)
        {
         highestValue = High[i];
         highestIndex = i;
        }
     }
   return highestIndex;
  }

//+------------------------------------------------------------------+
//| Função Lowest: retorna índice da barra com menor valor LOW      |
//+------------------------------------------------------------------+
int Lowest(string symbol, ENUM_TIMEFRAMES timeframe, int mode, int count, int start)
  {
   int lowestIndex = start;
   double lowestValue = Low[start];
   for(int i = start; i < start + count; i++)
     {
      if(Low[i] < lowestValue)
        {
         lowestValue = Low[i];
         lowestIndex = i;
        }
     }
   return lowestIndex;
  }

//+------------------------------------------------------------------+
//| Função CheckTrend: verifica tendência com ADX                    |
//+------------------------------------------------------------------+
int CheckTrend()
  {
   double plusDI, minusDI, adx;

   int handlePlusDI = iADX(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE, MODE_PLUSDI);
   int handleMinusDI = iADX(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE, MODE_MINUSDI);
   int handleADX = iADX(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE, MODE_MAIN);

   if(handlePlusDI == INVALID_HANDLE || handleMinusDI == INVALID_HANDLE || handleADX == INVALID_HANDLE)
     {
      Print("Falha ao criar handle para ADX");
      return 0;
     }

   if(CopyBuffer(handlePlusDI, 0, 0, 1, plusDI) <= 0 ||
      CopyBuffer(handleMinusDI, 0, 0, 1, minusDI) <= 0 ||
      CopyBuffer(handleADX, 0, 0, 1, adx) <= 0)
     {
      Print("Falha ao copiar buffer do ADX");
      return 0;
     }

   if(adx < 18)
      return 0;
   else if(plusDI > minusDI)
      return 1;
   else if(minusDI > plusDI)
      return -1;
   else
      return 0;
  }
//+------------------------------------------------------------------+
//| Função ConfirmBreakout: confirma rompimento para compra/venda   |
//+------------------------------------------------------------------+
bool ConfirmBreakout(bool isBuy)
  {
   double currentHigh = High[1];
   double currentLow = Low[1];
   double breakoutLevel;

   if(isBuy)
     {
      breakoutLevel = Highest(_Symbol, PERIOD_CURRENT, MODE_HIGH, breakoutLookback, 1);
      if(Close[1] > High[breakoutLevel])
         return true;
     }
   else
     {
      breakoutLevel = Lowest(_Symbol, PERIOD_CURRENT, MODE_LOW, breakoutLookback, 1);
      if(Close[1] < Low[breakoutLevel])
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Função OpenBuyOrder: abre ordem de compra                       |
//+------------------------------------------------------------------+
void OpenBuyOrder(double lot)
  {
   double stopLoss, takeProfit;
   CalculateSLTP(stopLoss, takeProfit, true);

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = _Symbol;
   request.volume   = lot;
   request.type     = ORDER_TYPE_BUY;
   request.price    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.sl       = stopLoss;
   request.tp       = takeProfit;
   request.deviation= 10;
   request.magic    = ExpertMagicNumber;
   request.comment  = "ADX Breakout Buy";

   if(!OrderSend(request, result))
     {
      Print("Falha ao abrir ordem de compra: ", GetLastError());
     }
   else if(result.retcode != TRADE_RETCODE_DONE)
     {
      Print("Erro no retcode da ordem de compra: ", result.retcode);
     }
   else
     {
      Print("Ordem de compra aberta com sucesso. Ticket: ", result.order);
     }
  }

//+------------------------------------------------------------------+
//| Função OpenSellOrder: abre ordem de venda                       |
//+------------------------------------------------------------------+
void OpenSellOrder(double lot)
  {
   double stopLoss, takeProfit;
   CalculateSLTP(stopLoss, takeProfit, false);

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = _Symbol;
   request.volume   = lot;
   request.type     = ORDER_TYPE_SELL;
   request.price    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.sl       = stopLoss;
   request.tp       = takeProfit;
   request.deviation= 10;
   request.magic    = ExpertMagicNumber;
   request.comment  = "ADX Breakout Sell";

   if(!OrderSend(request, result))
     {
      Print("Falha ao abrir ordem de venda: ", GetLastError());
     }
   else if(result.retcode != TRADE_RETCODE_DONE)
     {
      Print("Erro no retcode da ordem de venda: ", result.retcode);
     }
   else
     {
      Print("Ordem de venda aberta com sucesso. Ticket: ", result.order);
     }
  }
//+------------------------------------------------------------------+
//| Função ClosePosition: fecha posição por ticket                   |
//+------------------------------------------------------------------+
void ClosePosition(ulong ticket)
  {
   if(!PositionSelectByTicket(ticket))
     {
      Print("Posição não encontrada para fechamento, ticket: ", ticket);
      return;
     }

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   MqlTradePosition pos = PositionGet();

   request.action   = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol   = pos.symbol;
   request.volume   = pos.volume;
   request.type     = (pos.type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price    = (pos.type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.deviation= 10;
   request.magic    = ExpertMagicNumber;
   request.comment  = "Fechamento via EA";

   if(!OrderSend(request, result))
     {
      Print("Falha ao fechar posição: ", GetLastError());
     }
   else if(result.retcode != TRADE_RETCODE_DONE)
     {
      Print("Erro no retcode ao fechar posição: ", result.retcode);
     }
   else
     {
      Print("Posição fechada com sucesso. Ticket: ", ticket);
     }
  }
//+------------------------------------------------------------------+
//| Função OnInit: inicialização do EA                              |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("EA ADX Breakout iniciado");
   SetupTimer();

   // Inicializar handles dos indicadores, variáveis, etc
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Função OnDeinit: finalização do EA                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   StopTimer();

   // Liberar handles, recursos, etc
   Print("EA ADX Breakout finalizado");
  }
//+------------------------------------------------------------------+
//| Função OnTick: evento a cada tick                               |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Verificar condição de tendência
   int trend = CheckTrend();

   // Exemplo: se tendência é alta e breakout confirmado, abrir compra
   if(trend == 1 && ConfirmBreakout(true))
     {
      if(!IsPositionOpen(1))
        {
         OpenBuyOrder(DefaultLot);
        }
     }
   // Se tendência é baixa e breakout confirmado, abrir venda
   else if(trend == -1 && ConfirmBreakout(false))
     {
      if(!IsPositionOpen(-1))
        {
         OpenSellOrder(DefaultLot);
        }
     }
  }


//+------------------------------------------------------------------+
//| Função IsPositionOpen: verifica se já há posição aberta         |
//| tipoPos = 1 para compra, -1 para venda                           |
//+------------------------------------------------------------------+
bool IsPositionOpen(int tipoPos)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol)
        {
         if((tipoPos == 1 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ||
            (tipoPos == -1 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL))
           return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Função principal de gerenciamento de ordens                      |
//+------------------------------------------------------------------+
void ManageOpenPositions()
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol)
        {
         ulong ticket = PositionGetTicket(i);
         // Aqui poderia implementar trailing stop, verificação de SL/TP, etc.
        }
     }
  }
   
   
   
   //+------------------------------------------------------------------+
//| Função SetupTimer: configura temporizador para OnTimerEvent    |
//+------------------------------------------------------------------+
void SetupTimer()
  {
   EventSetTimer(60); // Chama OnTimerEvent a cada 60 segundos
  }

//+------------------------------------------------------------------+
//| Função StopTimer: para temporizador                             |
//+------------------------------------------------------------------+
void StopTimer()
  {
   EventKillTimer();
  }


//+------------------------------------------------------------------+
//| Função OnTimer: executa ações periódicas                         |
//+------------------------------------------------------------------+
void OnTimer()
  {
   // Pode verificar sinais, gerenciar posições, atualizar variáveis, etc.
   ManageOpenPositions();
  }

