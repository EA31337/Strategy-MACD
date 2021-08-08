/**
 * @file
 * Implements MACD strategy based on the Moving Averages Convergence/Divergence indicator.
 */

// User input params.
INPUT_GROUP("MACD strategy: strategy params");
INPUT float MACD_LotSize = 0;                // Lot size
INPUT int MACD_SignalOpenMethod = 2;         // Signal open method (-127-127)
INPUT float MACD_SignalOpenLevel = 0.0f;     // Signal open level
INPUT int MACD_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int MACD_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int MACD_SignalCloseMethod = 2;        // Signal close method (-127-127)
INPUT float MACD_SignalCloseLevel = 0.0f;    // Signal close level
INPUT int MACD_PriceStopMethod = 1;          // Price stop method
INPUT float MACD_PriceStopLevel = 0;         // Price stop level
INPUT int MACD_TickFilterMethod = 1;         // Tick filter method
INPUT float MACD_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short MACD_Shift = 0;                  // Shift
INPUT int MACD_OrderCloseTime = -20;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("MACD strategy: MACD indicator params");
INPUT int MACD_Indi_MACD_Period_Fast = 16;                                      // Period Fast
INPUT int MACD_Indi_MACD_Period_Slow = 30;                                      // Period Slow
INPUT int MACD_Indi_MACD_Period_Signal = 8;                                     // Period for signal
INPUT ENUM_APPLIED_PRICE MACD_Indi_MACD_Applied_Price = (ENUM_APPLIED_PRICE)3;  // Applied Price
INPUT int MACD_Indi_MACD_Shift = 0;                                             // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_MACD_Params_Defaults : MACDParams {
  Indi_MACD_Params_Defaults()
      : MACDParams(::MACD_Indi_MACD_Period_Fast, ::MACD_Indi_MACD_Period_Slow, ::MACD_Indi_MACD_Period_Signal,
                   ::MACD_Indi_MACD_Applied_Price, ::MACD_Indi_MACD_Shift) {}
} indi_macd_defaults;

// Defines struct with default user strategy values.
struct Stg_MACD_Params_Defaults : StgParams {
  Stg_MACD_Params_Defaults()
      : StgParams(::MACD_SignalOpenMethod, ::MACD_SignalOpenFilterMethod, ::MACD_SignalOpenLevel,
                  ::MACD_SignalOpenBoostMethod, ::MACD_SignalCloseMethod, ::MACD_SignalCloseLevel,
                  ::MACD_PriceStopMethod, ::MACD_PriceStopLevel, ::MACD_TickFilterMethod, ::MACD_MaxSpread,
                  ::MACD_Shift, ::MACD_OrderCloseTime) {}
} stg_macd_defaults;

// Struct to define strategy parameters to override.
struct Stg_MACD_Params : StgParams {
  MACDParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_MACD_Params(MACDParams &_iparams, StgParams &_sparams)
      : iparams(indi_macd_defaults, _iparams.tf.GetTf()), sparams(stg_macd_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_MACD : public Strategy {
 public:
  Stg_MACD(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_MACD *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    MACDParams _indi_params(indi_macd_defaults, _tf);
    StgParams _stg_params(stg_macd_defaults);
#ifdef __config__
    SetParamsByTf<MACDParams>(_indi_params, _tf, indi_macd_m1, indi_macd_m5, indi_macd_m15, indi_macd_m30, indi_macd_h1,
                              indi_macd_h4, indi_macd_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_macd_m1, stg_macd_m5, stg_macd_m15, stg_macd_m30, stg_macd_h1,
                             stg_macd_h4, stg_macd_h8);
#endif
    // Initialize indicator.
    MACDParams macd_params(_indi_params);
    _stg_params.SetIndicator(new Indi_MACD(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_MACD(_stg_params, _tparams, _cparams, "MACD");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_MACD *_indi = GetIndicator();
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift, LINE_MAIN, LINE_SIGNAL);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi.IsIncreasing(2, LINE_SIGNAL);
        _result &= _indi[_shift][(int)LINE_SIGNAL] > _indi[_shift][(int)LINE_MAIN];
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi.IsDecreasing(2, LINE_SIGNAL);
        _result &= _indi[_shift][(int)LINE_SIGNAL] < _indi[_shift][(int)LINE_MAIN];
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};
