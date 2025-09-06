using GalaSoft.MvvmLight.Command;
using System;
using System.Threading;
using System.Windows;
using UHF_Reader_API;

namespace UHF_Desk
{
    public class UpdateEpcDialogViewModel : BaseViewModel
    {
        #region Field

        InquiryViewModel _owner;

        #endregion

        #region Property

        private string _passwordHEX = "00 00 00 00";

        public string PasswordHEX
        {
            get { return _passwordHEX; }
            set
            {
                value = value.FormatHexString();
                if ((value.String2HexArray()).Length > 4) return;
                Set(ref _passwordHEX, value);
            }
        }

        private string _oldCode;

        public string OldCode
        {
            get { return _oldCode; }
            set { Set(ref _oldCode, value); }
        }

        private string _newCode;

        public string NewCode
        {
            get { return _newCode; }
            set
            {
                value = value.FormatHexString();
                if ((value.String2HexArray()).Length > 12) return;
                Set(ref _newCode, value);
            }
        }

        #endregion

        #region Command

        public RelayCommand<object> SettingCommand { get; set; }
        public RelayCommand<object> CloseCommand { get; set; }

        #endregion

        public UpdateEpcDialogViewModel(InquiryViewModel owner)
        {
            this._owner = owner;

            this.SettingCommand = new RelayCommand<object>(OnSetting);
            this.CloseCommand = new RelayCommand<object>(OnClose);
        }

        private void OnSetting(object o)
        {
            try
            {
                CurrentReader.CurrentReader.ISO.SetSelectMask(0, (byte)(OldCode.String2HexArray().Length * 8), OldCode.String2HexArray());
                if (CurrentReader.ConnectType == "COM") Thread.Sleep(50);
                CurrentReader.CurrentReader.ISO.WriteTag(PasswordHEX.String2HexArray(), MemBank.UII, 2, NewCode.String2HexArray());
                Thread.Sleep(20);
                while (true)
                {
                    try
                    {
                        TagRespItem item = CurrentReader.CurrentReader.ISO.GetWriteResp(1000);
                        if (item == null) break;
                    }
                    catch (Exception ex)
                    {
                        if (ex is ReaderException && (((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_COMM_TIMEOUT ||
                            ((ReaderException)ex).ErrorCode == ReaderException.ERROR_CMD_RESP_FORMAT_ERROR)) { }
                        else throw ex;
                    }
                }
                CurrentReader.CurrentReader.ISO.InventoryStop(10000);
                _owner.ModifyCode = NewCode;
                (o as Window).DialogResult = true;
            }
            catch (Exception ex)
            {
            }
        }

        public override void OnClose(object o)
        {
            (o as Window).DialogResult = false;
        }
    }
}
