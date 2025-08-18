using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;

namespace UHF_Desk
{
    /// <summary>
    /// 转换扩展
    /// </summary>
    public static class ConvertExtend
    {
        /// <summary>
        /// 转换为Int 如果转换失败 则返回默认值
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="errorValue">默认值</param>
        /// <returns></returns>
        public static int Obj2Int(this object value, int errorValue = -1)
        {
            if (value == null) return errorValue;
            int reval;
            if (value is Enum)
                return (int)value;
            string s = value.ToString();
            if (s.Length > 1 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) return s.String2Hex();
            if (value != null && value != DBNull.Value && int.TryParse(value.ToString(), out reval))
                return reval;
            return errorValue;
        }

        /// <summary>
        /// 转换为Double 如果转换失败 则返回默认值
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="errorValue">默认值</param>
        /// <returns></returns>
        public static double Obj2Double(this object value, double errorValue = -1)
        {
            if (value == null) return errorValue;
            double reval;
            if (value != null && value != DBNull.Value && double.TryParse(value.ToString(), out reval))
                return reval;
            return errorValue;
        }

        /// <summary>
        /// 转换为Decimal 如果转换失败 则返回默认值
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="errorValue">默认值</param>
        /// <returns></returns>
        public static decimal Obj2Decimal(this object value, decimal errorValue = -1)
        {
            if (value == null) return errorValue;
            decimal reval;
            if (value != null && value != DBNull.Value && decimal.TryParse(value.ToString(), out reval))
            {
                return reval;
            }
            return errorValue;
        }

        /// <summary>
        /// 转换为String 如果转换失败 则返回默认值
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="errorValue">默认值</param>
        /// <returns></returns>
        public static string Obj2String(this object value, string errorValue = "")
        {
            if (value != null) return value.ToString().Trim();
            return errorValue;
        }

        /// <summary>
        /// 转换为Date 如果转换失败 则返回DateTime.MinValue
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns></returns>
        public static DateTime Obj2Date(this object value)
        {
            DateTime reval = DateTime.MinValue;
            if (value != null && value != DBNull.Value && DateTime.TryParse(value.ToString(), out reval))
            {
                reval = Convert.ToDateTime(value);
            }
            return reval;
        }

        /// <summary>
        /// 转换为Boolean 如果转换失败 则返回false
        /// </summary>
        /// <param name="thisValue"></param>
        /// <returns></returns>
        public static bool Obj2Bool(this object value)
        {
            bool reval = false;
            if (value.ToString() == "0") return false;
            if (value.ToString() == "1") return true;
            if (value != null && value != DBNull.Value && bool.TryParse(value.ToString(), out reval))
            {
                return reval;
            }
            return reval;
        }

        /// <summary>
        /// 将整型转换为规定长度的字符串
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="length"></param>
        /// <returns></returns>
        public static string ToLength(this int value, int length)
        {
            string strValue = value.Obj2String();
            return strValue.ToLength(length);
        }

        public static string ToLength(this string value,int length)
        {
            int valueLength = value.Length;
            if (valueLength < length)
            {
                while (valueLength < length)
                {
                    value = "0" + value;
                    valueLength++;
                }
            }
            return value;
        }

        /// <summary>
        /// 比较差异
        /// </summary>
        /// <param name="thisValue"></param>
        /// <param name="equalValue">比较的对象</param>
        /// <returns>True:相同 False:不同</returns>
        public static bool EqualCase(this string value, string equalValue)
        {
            if (value != null && equalValue != null)
            {
                return value.ToLower() == equalValue.ToLower();
            }
            else
            {
                return value == equalValue;
            }
        }

        /// <summary>
        /// 取得某月的第一天
        /// </summary>
        /// <param name="datetime"></param>
        /// <returns></returns>
        public static DateTime FirstDayOfMonth(this DateTime datetime)
        {
            return datetime.AddDays(1 - datetime.Day);
        }

        /// <summary>
        /// 取得某月的最后一天
        /// </summary>
        /// <param name="datetime"></param>
        /// <returns></returns>
        public static DateTime LastDayOfMonth(this DateTime datetime)
        {
            return datetime.AddDays(1 - datetime.Day).AddMonths(1).AddDays(-1);
        }

        /// <summary>
        /// 首字母大写
        /// </summary>
        /// <param name="input"></param>
        /// <returns></returns>
        public static string FirstCharToUpper(this string input)
        {
            if (string.IsNullOrEmpty(input)) return string.Empty;
            return input.First().ToString().ToUpper() + input.Substring(1);
        }

        /// <summary>
        /// 首字母小写
        /// </summary>
        /// <param name="input"></param>
        /// <returns></returns>
        public static string FirstCharToLower(this string input)
        {
            if (string.IsNullOrEmpty(input)) return string.Empty;
            return input.First().ToString().ToLower() + input.Substring(1);
        }

        /// <summary>
        /// 去除多余的零跟小数点
        /// </summary>
        /// <param name="str"></param>
        /// <returns></returns>
        public static string TrimZero(this string input)
        {
            if (!input.Contains(".")) return input;
            return input.TrimEnd('0').TrimEnd('.');
        }

        /// <summary>
        /// 从String字符转换为Char字符
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static string String2CharString(this string value)
        {
            return string.IsNullOrEmpty(value) ? "" : ((char)int.Parse(value, NumberStyles.HexNumber)).ToString();
        }

        /// <summary>
        /// 从Char字符转换为String字符
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static string CharString2String(this string value)
        {
            return string.IsNullOrEmpty(value) ? null : ((int)value.ToArray()[0]).ToString("x");
        }

        /// <summary>
        /// 将时间戳转换为时间String
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static string LongTime2String(this long value)
        {
            return new DateTime(value * 10000000 + 621355968000000000).ToString("yyyy-MM-dd HH:mm:ss");
        }

        /// <summary>
        /// 将时间String转换为时间错
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static long String2LongTime(this string value)
        {
            return (DateTime.ParseExact(value, "yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture).Ticks - 621355968000000000) / 10000000;
        }

        private static readonly string[] suffixes = new string[] { "B", "KB", "MB", "GB", "TB", "PB" };
        /// <summary>
        /// 将文件长度转换为易读的长度
        /// </summary>
        /// <param name="num"></param>
        /// <returns></returns>
        public static string Bytes2ReadableLength(this int num)
        {
            for (int i = 0; i < suffixes.Length; i++)
            {
                var current = Math.Pow(1024, i + 1);
                if (num / current < 1)
                {
                    return (num / current).ToString("N2") + suffixes[i];
                }
            }
            return num.ToString();
        }

        /// <summary>
        /// 获取字符格式为yyyy-MM-dd HH:mm:ss的时间
        /// </summary>
        /// <param name="time"></param>
        /// <returns></returns>
        public static string ToFullDateTime(this DateTime time)
        {
            return time.ToString("yyyy-MM-dd HH:mm:ss");
        }

        public static readonly byte[] EmptyArray = new byte[0];
        /// <summary>
        /// 将String类型转换为16进制的数组
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static byte[] String2HexArray(this string value)
        {
            if (string.IsNullOrEmpty(value))
                return EmptyArray;

            List<byte> lstHex = new List<byte>(1024);
            String2HexArray(value, lstHex);
            return lstHex.ToArray();
        }

        private static void String2HexArray(string value, List<byte> lstHex)
        {
            // 当前状态
            // ，0 表示当前字节还没数据，等待接收第一个4位数据
            // ，1 表示已经接收第一个4位数据，等待接收第二个4位数据
            int iState = 0;
            byte btCur = 0, btTmp = 0;
            foreach (char ch in value)
            {
                switch (iState)
                {
                    case 0:
                        if (ValidateExtend.IsSpec(ch))
                        {
                            continue;
                        }
                        if (!ValidateExtend.IsHex(ch))
                        {
                            throw new FormatException("错误的十六进制字符串'" + value + "'");
                        }
                        btCur = Char2Hex(ch);
                        iState = 1;
                        break;
                    case 1:
                        if (ValidateExtend.IsSpec(ch))
                        {
                            lstHex.Add(btCur);
                            iState = 0;
                            continue;
                        }
                        if (!ValidateExtend.IsHex(ch))
                        {
                            throw new FormatException("错误的十六进制字符串'" + value + "'");
                        }
                        btTmp = Char2Hex(ch);
                        btCur = (byte)((btCur << 4) + btTmp);
                        lstHex.Add(btCur);
                        iState = 0;
                        break;
                    default:
                        throw new FormatException("错误的十六进制字符串'" + value + "'");
                }
            }
            if (iState == 1)
            {
                lstHex.Add(btCur);
            }
        }

        /// <summary>
        /// 将16进组数组转换为String
        /// </summary>
        /// <param name="arrData"></param>
        /// <returns></returns>
        public static string HexArray2String(this byte[] arrData)
        {
            return HexArray2String(arrData, 0, arrData.Length);
        }

        private static string HexArray2String(byte[] arrData, int index, int len)
        {
            if (len == 0)
                return string.Empty;
            if (len == 1)
                return arrData[0].ToString("X2");
            StringBuilder sb = new StringBuilder(len * 3);
            if (arrData.Length > 0)
            {
                len = index + len - 1;
                for (int i = index; i < len; ++i)
                {
                    sb.Append(arrData[i].ToString("X2"));
                    sb.Append(' ');
                }
                sb.Append(arrData[len].ToString("X2"));
            }
            return sb.ToString();
        }

        /// <summary>
        /// 将Char转换为Hex
        /// </summary>
        /// <param name="ch"></param>
        /// <returns></returns>
        private static byte Char2Hex(char ch)
        {
            byte btHex = 0;
            if (ch >= '0' && ch <= '9')
            {
                btHex = (byte)(ch - '0');
            }
            else if (ch >= 'A' && ch <= 'Z')
            {
                btHex = (byte)(ch - 'A' + 10);
            }
            else if (ch >= 'a' && ch <= 'z')
            {
                btHex = (byte)(ch - 'a' + 10);
            }
            return btHex;
        }

        /// <summary>
        /// 将String转换为Hex
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentNullException"></exception>
        /// <exception cref="FormatException"></exception>
        public static int String2Hex(this string value)
        {
            if (value == null)
                throw new ArgumentNullException("value");
            if (value.Length == 0)
                throw new FormatException("无法将空字符串转换为整数");

            int value2 = 0;
            int numState = 0;
            bool neg = false;
            for (int i = 0; i < value.Length; i++)
            {
                char ch = value[i];
                if (char.IsWhiteSpace(ch))
                {
                    if (numState == 1)
                        numState = 2;
                    continue;
                }
                if (numState == 2)
                    throw new FormatException("无法将十六进制字符串 '" + value + "' 转换为整数");

                if (ch == '+' || ch == '-')
                {
                    if (numState != 0)
                        throw new FormatException("无法将十六进制字符串 '" + value + "' 转换为整数");
                    neg = ch == '-';
                    numState = 1;
                    continue;
                }

                if (ch == 'h' || ch == 'H')
                {
                    if (numState != 1)
                        throw new FormatException("无法将十六进制字符串 '" + value + "' 转换为整数");
                    numState = 2;
                    continue;
                }

                if (ch >= '0' && ch <= '9')
                {
                    if (i + 1 < value.Length && (value[i + 1] == 'x' || value[i + 1] == 'X'))
                    {
                        i++;
                        numState = 1;
                    }
                    else
                    {
                        value2 = value2 * 16 + ch - '0';
                        numState = 1;
                    }
                    continue;
                }
                if (ch >= 'A' && ch <= 'F')
                {
                    value2 = value2 * 16 + ch - 'A' + 10;
                    numState = 1;
                    continue;
                }
                if (ch >= 'a' && ch <= 'f')
                {
                    value2 = value2 * 16 + ch - 'a' + 10;
                    numState = 1;
                    continue;
                }
                throw new FormatException("无法将十六进制字符串 '" + value + "' 转换为整数");
            }

            if (numState == 0)
                throw new FormatException("无法将十六进制字符串 '" + value + "' 转换为整数");
            if (neg && value2 != 0)
                value2 *= -1;
            return value2;
        }

        public static string FormatHexString(this string value)
        {
            if (string.IsNullOrEmpty(value))
                return string.Empty;

            StringBuilder sb = new StringBuilder();
            byte btCur = 0;
            int i = 0;
            int l = 0;
            int k = 0;
            for (; i < value.Length; i++)
            {
                char ch = value[i];
                if (ValidateExtend.IsSpec(ch))
                {
                    if (l == 0)
                    {
                        k = i + 1;
                        continue;
                    }
                }
                else
                {
                    l++;
                    if (l < 3)
                        continue;
                }

                if (l == 1)
                {
                    btCur = Char2Hex(value[k]);
                    sb.Append(btCur.ToString("X"));
                    sb.Append(' ');
                }
                else if (l == 2)
                {
                    btCur = Char2Hex(value[k]);
                    btCur = (byte)((btCur << 4) + Char2Hex(value[k + 1]));
                    sb.Append(btCur.ToString("X2"));
                    sb.Append(' ');
                }
                else
                {
                    btCur = Char2Hex(value[k]);
                    btCur = (byte)((btCur << 4) + Char2Hex(value[k + 1]));
                    sb.Append(btCur.ToString("X2"));
                    sb.Append(' ');
                    i--;
                }
                l = 0;
                k = i + 1;
            }
            if (l > 0)
            {
                if (l == 1)
                {
                    btCur = Char2Hex(value[k]);
                    sb.Append(btCur.ToString("X"));
                }
                else if (l == 2)
                {
                    btCur = Char2Hex(value[k]);
                    btCur = (byte)((btCur << 4) + Char2Hex(value[k + 1]));
                    sb.Append(btCur.ToString("X2"));
                }
            }
            else if (sb.Length > 0)
                sb.Length -= 1;
            value = sb.ToString();
            return value;
        }

        /// <summary>  
        /// 由结构体转换为byte数组  
        /// </summary>  
        public static byte[] StructureToByte<T>(this T structure)
        {
            int size = Marshal.SizeOf(typeof(T));
            byte[] buffer = new byte[size];
            IntPtr bufferIntPtr = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.StructureToPtr(structure, bufferIntPtr, true);
                Marshal.Copy(bufferIntPtr, buffer, 0, size);
            }
            finally
            {
                Marshal.FreeHGlobal(bufferIntPtr);
            }
            return buffer;
        }

        /// <summary>  
        /// 由byte数组转换为结构体  
        /// </summary>  
        public static T ByteToStructure<T>(this byte[] dataBuffer)
        {
            object structure = null;
            int size = Marshal.SizeOf(typeof(T));
            IntPtr allocIntPtr = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.Copy(dataBuffer, 0, allocIntPtr, size);
                structure = Marshal.PtrToStructure(allocIntPtr, typeof(T));
            }
            finally
            {
                Marshal.FreeHGlobal(allocIntPtr);
            }
            return (T)structure;
        }

        public static ObservableCollection<T> ToObservableCollection<T>(this IEnumerable<T> from)
        {
            ObservableCollection<T> to = new ObservableCollection<T>();
            foreach (var f in from)
            {
                to.Add(f);
            }
            return to;
        }

        public static string Unicode2Str(this string unicode)
        {
            string outStr = "";
            if (!string.IsNullOrEmpty(unicode))
            {
                try
                {
                    outStr += (char)int.Parse(unicode, NumberStyles.HexNumber);
                }
                catch (FormatException ex)
                {
                    outStr = ex.Message;
                }
            }
            return outStr;
        }
    }
}
