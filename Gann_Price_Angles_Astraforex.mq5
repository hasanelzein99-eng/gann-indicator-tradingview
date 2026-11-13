//+------------------------------------------------------------------+
//| Gann Price Angles by Astraforex - MetaTrader 5 port              |
//| Converted from the Pine Script supplied by the user.             |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_plots 0

input group "Core Calculations"
input bool   use_auto          = true;       // Use 360-Bar Cycle Auto Anchor
input int    lookback_bars     = 360;        // Cycle Lookback Window (Bars)
input int    manual_lookback   = 360;        // Manual Lookback (Bars)
input double price_origin      = 0.0;        // Manual Starting Price (If Auto Off)
input double scale            = 1.0;        // Spacing / Price Scale
input string dir_input         = "Down";     // Up Or Down Wheel: Up / Down
input string shape_type        = "04-Square";// Shape Type
input double num_cycles        = 1.0;        // Number Of Cycles (1 Cycle = 360 degrees)

input group "Style: Line Settings"
input color  col_full          = clrRed;     // Full Cycle (360) Color
input string sty_full          = "Solid";    // Full Cycle Style: Solid/Dashed/Dotted
input color  col_half          = clrOrange;  // Half Cycle (180) Color
input string sty_half          = "Solid";    // Half Cycle Style
input color  col_prim          = clrBlue;    // Primary Angles Color
input string sty_prim          = "Solid";    // Primary Angles Style
input color  col_sec           = clrTeal;    // Secondary Angles Color
input string sty_sec           = "Dotted";  // Secondary Angles Style

input group "Style: Label Display"
input string label_style       = "Text Above Ray"; // Text Above Ray / Pill Box
input string lbl_size_inp      = "Small";   // Auto / Small / Normal / Large
input int    lbl_offset        = 25;         // Label Horizontal Offset (Bars)
input double lbl_vert_adj      = 0.0;        // Label Vertical Offset (Price Units)

input group "Style: End Cycle Vertical Rays"
input color  end_col           = clrRed;     // End Cycle Ray Color
input string end_style_in      = "Dotted";  // End Cycle Ray Style

input group "Vertical Interval Lines"
input bool   show_vert_lines   = true;       // Show Vertical Interval Lines
input int    vert_interval     = 45;         // Draw A Line Every X Candles
input int    vert_total_range  = 360;        // Total Range To Cover (Candles)
input color  vert_col          = clrYellow;  // Vertical Line Color
input string vert_style_in     = "Dotted";  // Vertical Line Style
input int    vert_width        = 1;          // Vertical Line Width
input bool   vert_show_labels  = true;       // Show Bar-Count Labels
input string vert_label_pos    = "Bottom";   // Top / Bottom
input double vert_label_offset = 0.0;        // Vertical Label Offset (Price Units)

string g_prefix;
int    g_object_id = 0;

ENUM_LINE_STYLE LineStyle(const string value)
{
   if(value == "Dashed") return STYLE_DASH;
   if(value == "Dotted") return STYLE_DOT;
   return STYLE_SOLID;
}

int LabelFontSize()
{
   if(lbl_size_inp == "Large")  return 12;
   if(lbl_size_inp == "Normal") return 10;
   if(lbl_size_inp == "Auto")   return 8;
   return 8; // Small
}

int PeriodSecondsSafe()
{
   int seconds = PeriodSeconds(_Period);
   return (seconds > 0 ? seconds : 60);
}

datetime BarTimeAtOffset(const datetime current_bar_time, const int offset)
{
   return (datetime)((long)current_bar_time + (long)offset * PeriodSecondsSafe());
}

string NextName(const string kind)
{
   g_object_id++;
   return g_prefix + kind + "_" + IntegerToString(g_object_id);
}

void AddHorizontalRay(const datetime anchor_time, const double price,
                      const color line_color, const ENUM_LINE_STYLE style,
                      const int width)
{
   string name = NextName("H");
   datetime end_time = (datetime)((long)anchor_time + PeriodSecondsSafe());
   if(ObjectCreate(0, name, OBJ_TREND, 0, anchor_time, price, end_time, price))
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, line_color);
      ObjectSetInteger(0, name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
}

void AddVerticalRay(const datetime at_time, const color line_color,
                    const ENUM_LINE_STYLE style, const int width)
{
   string name = NextName("V");
   if(ObjectCreate(0, name, OBJ_VLINE, 0, at_time, 0.0))
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, line_color);
      ObjectSetInteger(0, name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
}

void AddText(const datetime at_time, const double price, const string text,
             const color text_color, const color background_color,
             const ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT)
{
   string name = NextName("T");
   if(ObjectCreate(0, name, OBJ_TEXT, 0, at_time, price))
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, LabelFontSize());
      ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      // OBJ_TEXT has no native filled-pill background in MT5. Preserve the
      // chosen text color; background_color is retained for easy extension.
      if(label_style == "Pill Box")
         ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
}

double ShapeDegrees()
{
   if(shape_type == "01-Circle")   return 360.0;
   if(shape_type == "02-Straight") return 180.0;
   if(shape_type == "03-Triangle") return 120.0;
   if(shape_type == "04-Square")   return 90.0;
   if(shape_type == "05-Pentagon") return 72.0;
   if(shape_type == "06-Hexagon")  return 60.0;
   return 45.0;
}

int OnInit()
{
   g_prefix = "GPA_ASTRA_" + IntegerToString((int)ChartID()) + "_";
   IndicatorSetString(INDICATOR_SHORTNAME, "Gann Price Angles by Astraforex");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, g_prefix);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < 1)
      return 0;

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);

   int anchor_shift = 0;
   double actual_origin = price_origin;
   int available = MathMin(MathMax(lookback_bars, 1), rates_total);

   if(use_auto)
   {
      int high_shift = 0;
      int low_shift = 0;
      for(int i = 1; i < available; i++)
      {
         if(high[i] > high[high_shift]) high_shift = i;
         if(low[i] < low[low_shift])   low_shift = i;
      }
      if(dir_input == "Down")
      {
         anchor_shift = high_shift;
         actual_origin = high[high_shift];
      }
      else
      {
         anchor_shift = low_shift;
         actual_origin = low[low_shift];
      }
   }
   else
   {
      anchor_shift = MathMax(manual_lookback, 0);
      if(anchor_shift < rates_total)
         actual_origin = price_origin;
   }

   datetime anchor_time;
   if(anchor_shift < rates_total)
      anchor_time = time[anchor_shift];
   else
      anchor_time = BarTimeAtOffset(time[0], -anchor_shift);

   // Rebuild objects on the latest calculation, matching Pine's barstate.islast.
   ObjectsDeleteAll(0, g_prefix);
   g_object_id = 0;

   int direction = (dir_input == "Up" ? 1 : -1);
   int label_offset_bars = lbl_offset;
   datetime label_time = BarTimeAtOffset(time[0], label_offset_bars);

   double vert_base = low[0];
   int sample = MathMin(10, rates_total);
   for(int i = 1; i < sample; i++)
   {
      if(vert_label_pos == "Bottom") vert_base = MathMin(vert_base, low[i]);
      else                           vert_base = MathMax(vert_base, high[i]);
   }
   if(vert_label_pos == "Top")
      vert_base = high[0];
   if(vert_label_pos == "Top")
      for(int i = 1; i < sample; i++) vert_base = MathMax(vert_base, high[i]);

   // 1. Anchor line and label.
   AddHorizontalRay(anchor_time, actual_origin, clrWhite, STYLE_SOLID, 2);
   AddText(label_time, actual_origin + lbl_vert_adj, "0 deg | ASTRAFX", clrWhite, clrBlack, ANCHOR_LEFT);

   // 2. End-of-cycle vertical rays.
   for(int j = 1; j <= 5; j++)
   {
      int offset = 360 * j;
      if(anchor_shift - offset <= 500)
      {
         datetime x = BarTimeAtOffset(anchor_time, offset);
         AddVerticalRay(x, end_col, LineStyle(end_style_in), 2);
         AddText(x, vert_base + vert_label_offset, "END CYCLE", clrWhite, end_col,
                 (vert_label_pos == "Bottom" ? ANCHOR_UPPER : ANCHOR_LOWER));
      }
   }

   // 2b. Vertical interval lines and bar-count labels.
   if(show_vert_lines && vert_interval > 0 && vert_total_range > 0)
   {
      int count = (int)MathFloor((double)vert_total_range / (double)vert_interval);
      for(int k = 1; k <= count; k++)
      {
         int offset = vert_interval * k;
         datetime x = BarTimeAtOffset(anchor_time, offset);
         AddVerticalRay(x, vert_col, LineStyle(vert_style_in), vert_width);
         if(vert_show_labels)
         {
            AddText(x, vert_base + vert_label_offset,
                    IntegerToString(offset), vert_col, clrNONE,
                    (vert_label_pos == "Bottom" ? ANCHOR_UPPER : ANCHOR_LOWER));
         }
      }
   }

   // 3. Price-angle levels. Limit the count to keep chart object use bounded.
   if(scale > 0.0 && actual_origin / scale >= 0.0)
   {
      double shape_deg = ShapeDegrees();
      double step_deg = shape_deg / 2.0;
      int total_steps = (int)MathRound((num_cycles * 360.0) / step_deg);
      total_steps = MathMax(0, MathMin(total_steps, 450));
      double sqrt_entry = MathSqrt(actual_origin / scale);
      int shape_mod = (int)MathRound(shape_deg);

      for(int i = 1; i <= total_steps; i++)
      {
         double current_deg = i * step_deg;
         double factor = current_deg / 180.0;
         double root = sqrt_entry + direction * factor;
         double level_price = root * root * scale;
         int rounded_deg = (int)MathRound(current_deg);

         bool is_full = (rounded_deg % 360 == 0);
         bool is_half = ((rounded_deg % 180 == 0) && !is_full);
         bool is_prim = ((rounded_deg % shape_mod == 0) && !is_full && !is_half);

         color line_color = (is_full ? col_full : (is_half ? col_half : (is_prim ? col_prim : col_sec)));
         string style_text = (is_full ? sty_full : (is_half ? sty_half : (is_prim ? sty_prim : sty_sec)));
         string tag = (is_full ? "CYCLE " : (is_half ? "HALF CYCLE " : "ANGLE "));
         string text = tag + IntegerToString(rounded_deg) + " deg = " + DoubleToString(level_price, 2);

         AddHorizontalRay(anchor_time, level_price, line_color, LineStyle(style_text), 1);
         AddText(label_time, level_price + lbl_vert_adj, text, line_color, line_color, ANCHOR_LEFT);
      }
   }

   ChartRedraw(0);
   return rates_total;
}
