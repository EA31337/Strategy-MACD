/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_MACD_Params_M30 : MACDParams {
  Indi_MACD_Params_M30() : MACDParams(indi_macd_defaults, PERIOD_M30) {
    applied_price = (ENUM_APPLIED_PRICE)3;
    ema_fast_period = 8;
    ema_slow_period = 34;
    shift = 0;
    signal_period = 12;
  }
} indi_macd_m30;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_MACD_Params_M30 : StgParams {
  // Struct constructor.
  Stg_MACD_Params_M30() : StgParams(stg_macd_defaults) {
    lot_size = 0;
    signal_close_level = (float)20;
    signal_close_method = 0;
    signal_open_boost = 0;
    signal_open_filter = 1;
    signal_open_level = (float)20;
    signal_open_method = 0;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_macd_m30;
