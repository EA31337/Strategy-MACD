/**
 * @file
 * Implements MACD strategy based on the Moving Averages Convergence/Divergence indicator.
 */

// User input params.
INPUT_GROUP("MACD strategy: strategy params");
INPUT float MACD_LotSize = 0;                // Lot size
INPUT int MACD_SignalOpenMethod = 0;         // Signal open method (-127-127)
INPUT float MACD_SignalOpenLevel = 2.0f;     // Signal open level
INPUT int MACD_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int MACD_SignalOpenFilterTime = 3;     // Signal open filter time
INPUT int MACD_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int MACD_SignalCloseMethod = 0;        // Signal close method (-127-127)
INPUT int MACD_SignalCloseFilter = 0;        // Signal close filter (-127-127)
INPUT float MACD_SignalCloseLevel = 2.0f;    // Signal close level
INPUT int MACD_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float MACD_PriceStopLevel = 2;         // Price stop level
INPUT int MACD_TickFilterMethod = 32;        // Tick filter method
INPUT float MACD_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short MACD_Shift = 0;                  // Shift
INPUT float MACD_OrderCloseLoss = 80;        // Order close loss
INPUT float MACD_OrderCloseProfit = 80;      // Order close profit
INPUT int MACD_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("MACD strategy: MACD indicator params");
INPUT int MACD_Indi_MACD_Period_Fast = 6;                            // Period Fast
INPUT int MACD_Indi_MACD_Period_Slow = 34;                           // Period Slow
INPUT int MACD_Indi_MACD_Period_Signal = 10;                         // Period Signal
INPUT ENUM_APPLIED_PRICE MACD_Indi_MACD_Applied_Price = PRICE_OPEN;  // Applied Price
INPUT int MACD_Indi_MACD_Shift = 0;                                  // Shift

// Structs.

// Defines struct with default user strategy values.
struct Stg_MACD_Params_Defaults : StgParams {
  Stg_MACD_Params_Defaults()
      : StgParams(::MACD_SignalOpenMethod, ::MACD_SignalOpenFilterMethod, ::MACD_SignalOpenLevel,
                  ::MACD_SignalOpenBoostMethod, ::MACD_SignalCloseMethod, ::MACD_SignalCloseFilter,
                  ::MACD_SignalCloseLevel, ::MACD_PriceStopMethod, ::MACD_PriceStopLevel, ::MACD_TickFilterMethod,
                  ::MACD_MaxSpread, ::MACD_Shift) {
    Set(STRAT_PARAM_LS, MACD_LotSize);
    Set(STRAT_PARAM_OCL, MACD_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, MACD_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, MACD_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, MACD_SignalOpenFilterTime);
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_MACD : public Strategy {
 public:
  Stg_MACD(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_MACD *Init(ENUM_TIMEFRAMES _tf = NULL) {
    // Initialize strategy initial values.
    Stg_MACD_Params_Defaults stg_macd_defaults;
    StgParams _stg_params(stg_macd_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_macd_m1, stg_macd_m5, stg_macd_m15, stg_macd_m30, stg_macd_h1,
                             stg_macd_h4, stg_macd_h8);
#endif
    // Initialize indicator.
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_MACD(_stg_params, _tparams, _cparams, "MACD");
    return _strat;
  }

  /**
   * Event on strategy's init.
   */
  void OnInit() {
    IndiMACDParams _indi_params(::MACD_Indi_MACD_Period_Fast, ::MACD_Indi_MACD_Period_Slow,
                                ::MACD_Indi_MACD_Period_Signal, ::MACD_Indi_MACD_Applied_Price, ::MACD_Indi_MACD_Shift);
    _indi_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
    SetIndicator(new Indi_MACD(_indi_params));
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_MACD *_indi = GetIndicator();
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift, LINE_MAIN, LINE_SIGNAL);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi[_shift][(int)LINE_SIGNAL] > _indi[_shift][(int)LINE_MAIN];
        _result &= _indi.IsIncreasing(2, LINE_SIGNAL);
        _result &= _indi.IsIncByPct(_level, 0, _shift, 3);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi[_shift][(int)LINE_SIGNAL] < _indi[_shift][(int)LINE_MAIN];
        _result &= _indi.IsDecreasing(2, LINE_SIGNAL);
        _result &= _indi.IsDecByPct(-_level, 0, _shift, 3);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};
