//+------------------------------------------------------------------+
//|                                                     VPTS_0.4.mq4 |
//|                                    Copyright 2019, Vitalii Popov |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Vitalii Popov"
#property link      ""
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

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

//Переменные--------------------------------
//Сдвиг при расчёте угла (единица - 15 минут)
input int shift = 4;
//Период индикатора
input int period = 5;
//Допустимый угол в градусах
input double angled = 35;
//Значение линии (0 горизонтальная, 1 вверх, -1 вниз)
int line_val;
//Значение угла в радианах
double angle_rad;
//Значение синуса угла допуска
double sin_dop;
//Разница значений линии
double diff;
//Синус угла атаки
double incidence;
//Значение средней линии в текущий момент
double cur_mid;
//Значение средней линии со сдвигом
double shif_mid;
//Текущий ордер
int current_order = -1;
//Количество лотов
input double num_lots = 1;
//Тип ордера
int order_type;
//Текущая цена продажи
double current_sell;
//Текущая цена покупки
double current_buy;
//Stop-loss
double SL = 0;
//Take-profit
double TP = 0;
//Верхний уровень Bands
double high_level;
//Нижний уровень Bands
double low_level;
//Средний уровень Bands
double mid_level;
//Средняя линия за час
int half_line;

//Константы-------------------------
//Линия входит в диапазон наклона
const int in_angle = 0;
//Линия вверх
const int line_up = 1;
//Линия вниз
const int line_down = -1;
//Коэффициент для вычисления синуса (2000 для часа, 1000 для двух часов)
const int coef = 3804;
//Коэффициент для перевода градусов в радианы
const double rad = 0.0174533;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

//Вычисляем значение индикатора
   get_bands_val();

//Вычисляем текущую цену
   get_current_price();

//Вычисляем наклон линии
   line_val = check_angle(shift);

//Вычисление наклона в середине линии
   half_line = check_angle(shift/2);

//Открытие ордеров
   open_orders();

//Закрытие ордеров
   close_orders();
  }
//+------------------------------------------------------------------+

//Закрывает открытые ордеры в прибыль
void close_orders()
  {
   if(current_order != -1)
     {
      int cnt;
      int total = OrdersTotal();
      for(cnt=0; cnt<total; cnt++)
        {
         if(!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
            continue;
         if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
           {
            if(OrderType()==OP_BUY)
              {

               double dClosePriceBid = MarketInfo(OrderSymbol(),MODE_BID);

               if(current_buy >= (mid_level - (mid_level - low_level)/5)||(current_buy >= iBands(NULL,0,10,2,0,PRICE_WEIGHTED,MODE_MAIN,1) && line_val == line_down))
                 {
                  if(!OrderClose(OrderTicket(), OrderLots(), dClosePriceBid, 5, Violet))
                    {
                     Print("OrderClose error ",GetLastError());
                    }
                  else
                    {
                     Print("Прибыль от покупки: ", OrderProfit());
                     current_order = -1;
                    }
                 }

              }
            else
              {

               double dClosePriceAsk = MarketInfo(OrderSymbol(),MODE_ASK);

               if(current_sell <= (mid_level + (high_level - mid_level)/5) ||(current_sell <= iBands(NULL,0,10,2,0,PRICE_WEIGHTED,MODE_MAIN,1) && line_val == line_up))
                 {
                  if(!OrderClose(OrderTicket(), OrderLots(), dClosePriceAsk, 5, Violet))
                    {
                     Print("OrderClose error ",GetLastError());
                    }
                  else
                    {
                     Print("Прибыль от продажи: ", OrderProfit());
                     current_order = -1;
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void open_orders()
  {
   if(current_order == -1)
     {
      //Проверяем пересечение индикатора и цены
      //Если есть пересечение сверху - открываем ордер на продажу
      if((current_buy >= high_level - (high_level - mid_level)/4) && (line_val == line_down || line_val == in_angle)&&(line_val == half_line))
        {
         current_order = OrderSend(Symbol(),OP_SELL, num_lots, current_buy, 5, SL, TP);
        }
      else
        {
         //Если есть пересечение снизу - открываем ордер на покупку
         if((current_sell <= low_level + (mid_level - low_level)/4) && (line_val == line_up || line_val == in_angle)&&(line_val == half_line))
           {
            current_order = OrderSend(Symbol(),OP_BUY, num_lots, current_sell, 5, SL, TP);
           }
        }
     }
  }

//Вычисление текущих цен
void get_current_price()
  {
//Цена продажи
   current_sell = MarketInfo(OrderSymbol(),MODE_ASK);
//Цена покупки
   current_buy = MarketInfo(OrderSymbol(),MODE_BID);
  }

//Вычисление значений индикатора
void get_bands_val()
  {
//Верхний уровень Bands
   high_level = iBands(NULL,0,period,2,0,PRICE_WEIGHTED,MODE_UPPER,1);
//Нижний уровень Bands
   low_level  = iBands(NULL,0,period,2,0,PRICE_WEIGHTED,MODE_LOWER,1);
//Средний уровень Bands
   mid_level  = iBands(NULL,0,period,2,0,PRICE_WEIGHTED,MODE_MAIN,1);
  }
//+------------------------------------------------------------------+
/*
  Функиця вычисляет наклон средней линии
  На вход подаётся значение угла в градусах и период индикатора
  Если линия меньше угла - выводит 0
  Если линия наклонена вверх - выводит 1 (синус положительный)
  Если линия наклонена вниз - выводит -1 (синус отрицательный)
*/
int check_angle(int sh)
  {
//Значение угла в радианах
   angle_rad = angled * rad;
//Значение средней линии в текущий момент
   cur_mid  = iBands(NULL,0,period,2,0,PRICE_WEIGHTED,MODE_MAIN,1);
//Значение средней линии со сдвигом
   shif_mid = iBands(NULL,0,period,2,0,PRICE_WEIGHTED,MODE_MAIN,sh);
//Вычислим синус угла допуска
   sin_dop = MathSin(angle_rad);
//Берём значение в текущую минуту и час назад
   diff = MathAbs(cur_mid - shif_mid);
//Вычисляем синус индикатора
   incidence = coef * diff * (8/sh);
//Проверяем, в допуске ли угол
   if(incidence >= -sin_dop && incidence <= sin_dop)
      return in_angle;
//Если не в допуске - возвращаем направление линии
   else
      if(cur_mid > shif_mid)
         return line_up;
      else
         return line_down;
  }
