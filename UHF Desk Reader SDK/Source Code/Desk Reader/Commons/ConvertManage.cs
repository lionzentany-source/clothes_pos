using System.Windows.Media.Effects;
using System.Windows.Media;
using System.Windows;

namespace UHF_Desk
{
    public class ConvertManage
    {
        public static object? ConvertValue(string result, string enumStr)
        {
            EnumConvert enumConvert = (EnumConvert)int.Parse(enumStr);
            switch (enumConvert)
            {
                case EnumConvert.Boolean:
                    return System.Convert.ToBoolean(result);
                case EnumConvert.Visibility:
                    return result.ToLower().Equals("collapsed") ? Visibility.Collapsed : Visibility.Visible;
                case EnumConvert.Brush:
                    return System.Convert.ToBoolean(result) ? new BlurEffect() { Radius = 10 } : null;
                case EnumConvert.Int:
                    return System.Convert.ToInt32(result);
                case EnumConvert.Color:
                    return new SolidColorBrush((Color)ColorConverter.ConvertFromString(result));
                case EnumConvert.String:
                    return result.ToString();
                default:
                    return null;
            }
        }
    }
}
