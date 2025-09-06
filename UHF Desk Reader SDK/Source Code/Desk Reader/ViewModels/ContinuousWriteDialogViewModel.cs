using GalaSoft.MvvmLight.Command;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Emit;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Controls;
using System.Windows;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class ContinuousWriteDialogViewModel : BaseViewModel
    {
        #region Fields

        bool IsStopOperation = true;

        #endregion

        #region Properties

        private TagModel _tag = new TagModel();

        public TagModel Tag
        {
            get { return _tag; }
            set { Set(ref _tag, value); }
        }

        private int _writeInterval = 5;
        /// <summary>
        /// 写入间隔
        /// </summary>
        public int WriteInterval
        {
            get { return _writeInterval; }
            set { Set(ref _writeInterval, value); }
        }

        private bool _isWriting;

        public bool IsWriting
        {
            get { return _isWriting; }
            set
            {
                Set(ref _isWriting, value);
                ButtonText = value ? GlobalModel.IsChinese ? "停止写入" : "Stop Writing" : GlobalModel.IsChinese ? "开始写入" : "Start Writing";
            }
        }

        private string _buttonText = GlobalModel.IsChinese ? "开始写入" : "Start Writing";

        public string ButtonText
        {
            get { return _buttonText; }
            set { Set(ref _buttonText, value); }
        }

        private int _success = 0;

        public int Success
        {
            get { return _success; }
            set { Set(ref _success, value); }
        }

        private int _fail = 0;

        public int Fail
        {
            get { return _fail; }
            set { Set(ref _fail, value); }
        }

        private string _info;

        public string Info
        {
            get { return _info; }
            set { Set(ref _info, value); }
        }

        #endregion

        #region Commands

        public RelayCommand<object> CloseCommand { get => new RelayCommand<object>(o => OnClose(o)); }
        public RelayCommand ButtonClickCommand { get; set; }

        #endregion

        public ContinuousWriteDialogViewModel()
        {
            ButtonClickCommand = new RelayCommand(OnButtonClieck);

            Task.Run(() =>
            {
                while (true)
                {
                    if (IsWriting && IsStopOperation)
                    {
                        IsStopOperation = false;
                        Info = "";
                        OnWriting();
                    }
                }
            });
        }

        private void OnWriting()
        {
            if (string.IsNullOrEmpty(Tag.WriteData))
            {
                IsStopOperation = true;
                OnStop();
                return;
            }
            try
            {
                CurrentReader.CurrentReader.ISO.SetSelectMask(0, (byte)0, GlobalModel.EmptyArray);
                if (CurrentReader.ConnectType == "COM") Thread.Sleep(50);
                CurrentReader.CurrentReader.ISO.WriteTag(Tag.PasswordHEX.String2HexArray(), MemBank.UII, 2, Tag.WriteData.String2HexArray());
                Thread.Sleep(20);
                while (IsWriting)
                {
                    try
                    {
                        TagRespItem item = CurrentReader.CurrentReader.ISO.GetWriteResp(1000);
                        if (item == null)
                        {
                            Fail++;
                            Info = GlobalModel.IsChinese ? $"写入失败，正在重试！（{Fail}）" : $"Write failed, retrying!（{Fail}）";
                            Thread.Sleep(2000);
                            IsStopOperation = true;
                            break;
                        }
                        else
                        {
                            Success++;
                            Fail = 0;
                            Info = GlobalModel.IsChinese ? $"写入成功，请换卡！（{Success}）" : $"Success, please change card!（{Success}）";
                            Tag.WriteData = GetWriteData(Tag.WriteData);
                            Thread.Sleep(WriteInterval * 1000);
                            IsStopOperation = true;
                            break;
                        }
                    }
                    catch (Exception ex)
                    {
                        Fail++;
                        Info = GlobalModel.IsChinese ? $"写入失败，正在重试！（{Fail}）" : $"Write failed, retrying!（{Fail}）";
                        SetTips(EnumMessage.ERROR, Info);
                        Thread.Sleep(2000);
                        IsStopOperation = true;
                        break;
                    }
                }
            }
            catch (Exception ex)
            {
                Fail++;
                Info = GlobalModel.IsChinese ? $"写入失败，正在重试！（{Fail}）" : $"Write failed, retrying!（{Fail}）";
                SetTips(EnumMessage.ERROR, Info);
                Thread.Sleep(2000);
                IsStopOperation = true;
            }
        }

        private string GetWriteData(string writeData)
        {
            string[] hexValuesSplit = writeData.Split(' ');
            if (hexValuesSplit[hexValuesSplit.Length - 1] != "FF")
            {
                int value = Convert.ToInt32(hexValuesSplit[hexValuesSplit.Length - 1], 16) + 1;
                hexValuesSplit[hexValuesSplit.Length - 1] = Convert.ToString(value, 16).ToLength(2);
                return String.Join(" ", hexValuesSplit);
            }
            else
            {
                string newWriteData = writeData.Substring(0, writeData.Length - 3);
                return GetWriteData(newWriteData) + " 00";
            }
        }

        private void OnButtonClieck()
        {
            if (IsWriting)
            {
                OnStop();
            }
            else
            {
                OnStart();
            }
        }

        private void OnStart()
        {
            Success = 0;
            IsWriting = true;
        }

        private void OnStop()
        {
            IsWriting = false;
            Info = "";
            CurrentReader.CurrentReader.ISO.InventoryStop(10000);
        }
    }
}
