using System;
using System.Collections.Generic;

namespace UHF_Desk
{
    public class ActionManager
    {
        private ActionManager() { }
        static Dictionary<string, Delegate> actionMap = new Dictionary<string, Delegate>();

        public static void Register<T>(string key, Delegate d)
        {
            if (!actionMap.ContainsKey(key))
                actionMap.Add(key, d);
        }

        public static void UnRegister(string key)
        {
            if (actionMap.ContainsKey(key))
                actionMap.Remove(key);
        }

        /// <summary>
        /// 单执行
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="key"></param>
        /// <param name="data"></param>
        public static void Execute<T>(string key, T data)
        {
            if (actionMap.ContainsKey(key))
                actionMap[key].DynamicInvoke(data);
        }

        public static void Execute(string key)
        {
            if (actionMap.ContainsKey(key))
                actionMap[key].DynamicInvoke();
        }

        /// <summary>
        /// 执行并返回状态
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="key"></param>
        /// <param name="data"></param>
        /// <returns></returns>
        public static bool ExecuteAndResult<T>(string key, T data)
        {
            if (actionMap.ContainsKey(key))
            {
                var action = (actionMap[key] as Func<T, bool>);
                if (action == null)
                    return false;

                return action.Invoke(data);
            }
            return false;
        }
    }
}
