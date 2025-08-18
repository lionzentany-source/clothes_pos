/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 5.12.12
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLabel>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QTableView>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QWidget *centralwidget;
    QGroupBox *groupBox;
    QLabel *label;
    QLabel *label_2;
    QComboBox *cmbComPort;
    QComboBox *cmbComBuad;
    QPushButton *btnOpen;
    QPushButton *btnClose;
    QGroupBox *groupBox_2;
    QLabel *label_3;
    QLabel *label_4;
    QPushButton *btnConnect;
    QPushButton *btnDisConnect;
    QTextEdit *txtIPAddr;
    QTextEdit *txtPort;
    QGroupBox *groupBox_3;
    QLabel *label_9;
    QLabel *label_8;
    QLabel *label_6;
    QPushButton *btnSetFreqBand;
    QPushButton *btnGetFreqBand;
    QComboBox *cmbFreqBand;
    QComboBox *cmbFreqStart;
    QComboBox *cmbFreqEnd;
    QPushButton *btnReleaseRealy;
    QPushButton *btnCloseRealy;
    QLabel *label_5;
    QLabel *label_7;
    QComboBox *cmbRfPower;
    QPushButton *btnGetRfPower;
    QPushButton *btnSetRfPower;
    QPushButton *btnSetWorkMode;
    QPushButton *btnGetWorkMode;
    QComboBox *cmbWorkMode;
    QPushButton *btnStop;
    QPushButton *btnStart;
    QTableView *tableView;
    QPushButton *btnScanUSB;
    QComboBox *cmbUSB;
    QPushButton *btnUSB;
    QPushButton *btnUSB_2;
    QMenuBar *menubar;
    QStatusBar *statusbar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName(QString::fromUtf8("MainWindow"));
        MainWindow->resize(800, 600);
        centralwidget = new QWidget(MainWindow);
        centralwidget->setObjectName(QString::fromUtf8("centralwidget"));
        groupBox = new QGroupBox(centralwidget);
        groupBox->setObjectName(QString::fromUtf8("groupBox"));
        groupBox->setGeometry(QRect(20, 20, 271, 121));
        label = new QLabel(groupBox);
        label->setObjectName(QString::fromUtf8("label"));
        label->setGeometry(QRect(10, 30, 63, 20));
        label_2 = new QLabel(groupBox);
        label_2->setObjectName(QString::fromUtf8("label_2"));
        label_2->setGeometry(QRect(10, 60, 63, 20));
        cmbComPort = new QComboBox(groupBox);
        cmbComPort->setObjectName(QString::fromUtf8("cmbComPort"));
        cmbComPort->setGeometry(QRect(50, 30, 211, 28));
        cmbComBuad = new QComboBox(groupBox);
        cmbComBuad->addItem(QString());
        cmbComBuad->addItem(QString());
        cmbComBuad->addItem(QString());
        cmbComBuad->addItem(QString());
        cmbComBuad->addItem(QString());
        cmbComBuad->setObjectName(QString::fromUtf8("cmbComBuad"));
        cmbComBuad->setGeometry(QRect(50, 60, 211, 28));
        btnOpen = new QPushButton(groupBox);
        btnOpen->setObjectName(QString::fromUtf8("btnOpen"));
        btnOpen->setGeometry(QRect(20, 90, 84, 28));
        btnClose = new QPushButton(groupBox);
        btnClose->setObjectName(QString::fromUtf8("btnClose"));
        btnClose->setEnabled(false);
        btnClose->setGeometry(QRect(160, 90, 84, 28));
        groupBox_2 = new QGroupBox(centralwidget);
        groupBox_2->setObjectName(QString::fromUtf8("groupBox_2"));
        groupBox_2->setGeometry(QRect(20, 140, 271, 141));
        label_3 = new QLabel(groupBox_2);
        label_3->setObjectName(QString::fromUtf8("label_3"));
        label_3->setGeometry(QRect(10, 70, 63, 20));
        label_4 = new QLabel(groupBox_2);
        label_4->setObjectName(QString::fromUtf8("label_4"));
        label_4->setGeometry(QRect(10, 30, 63, 20));
        btnConnect = new QPushButton(groupBox_2);
        btnConnect->setObjectName(QString::fromUtf8("btnConnect"));
        btnConnect->setGeometry(QRect(20, 110, 101, 28));
        btnDisConnect = new QPushButton(groupBox_2);
        btnDisConnect->setObjectName(QString::fromUtf8("btnDisConnect"));
        btnDisConnect->setEnabled(false);
        btnDisConnect->setGeometry(QRect(143, 110, 101, 28));
        txtIPAddr = new QTextEdit(groupBox_2);
        txtIPAddr->setObjectName(QString::fromUtf8("txtIPAddr"));
        txtIPAddr->setGeometry(QRect(60, 30, 201, 31));
        txtPort = new QTextEdit(groupBox_2);
        txtPort->setObjectName(QString::fromUtf8("txtPort"));
        txtPort->setGeometry(QRect(60, 70, 201, 31));
        groupBox_3 = new QGroupBox(centralwidget);
        groupBox_3->setObjectName(QString::fromUtf8("groupBox_3"));
        groupBox_3->setGeometry(QRect(300, 90, 451, 121));
        label_9 = new QLabel(groupBox_3);
        label_9->setObjectName(QString::fromUtf8("label_9"));
        label_9->setGeometry(QRect(250, 80, 63, 20));
        label_8 = new QLabel(groupBox_3);
        label_8->setObjectName(QString::fromUtf8("label_8"));
        label_8->setGeometry(QRect(30, 80, 91, 20));
        label_6 = new QLabel(groupBox_3);
        label_6->setObjectName(QString::fromUtf8("label_6"));
        label_6->setGeometry(QRect(30, 40, 111, 20));
        btnSetFreqBand = new QPushButton(groupBox_3);
        btnSetFreqBand->setObjectName(QString::fromUtf8("btnSetFreqBand"));
        btnSetFreqBand->setEnabled(false);
        btnSetFreqBand->setGeometry(QRect(340, 40, 84, 28));
        btnGetFreqBand = new QPushButton(groupBox_3);
        btnGetFreqBand->setObjectName(QString::fromUtf8("btnGetFreqBand"));
        btnGetFreqBand->setEnabled(false);
        btnGetFreqBand->setGeometry(QRect(250, 40, 84, 28));
        cmbFreqBand = new QComboBox(groupBox_3);
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->addItem(QString());
        cmbFreqBand->setObjectName(QString::fromUtf8("cmbFreqBand"));
        cmbFreqBand->setGeometry(QRect(130, 40, 111, 28));
        cmbFreqStart = new QComboBox(groupBox_3);
        cmbFreqStart->setObjectName(QString::fromUtf8("cmbFreqStart"));
        cmbFreqStart->setGeometry(QRect(130, 80, 111, 28));
        cmbFreqEnd = new QComboBox(groupBox_3);
        cmbFreqEnd->setObjectName(QString::fromUtf8("cmbFreqEnd"));
        cmbFreqEnd->setGeometry(QRect(310, 80, 111, 28));
        btnReleaseRealy = new QPushButton(centralwidget);
        btnReleaseRealy->setObjectName(QString::fromUtf8("btnReleaseRealy"));
        btnReleaseRealy->setEnabled(false);
        btnReleaseRealy->setGeometry(QRect(460, 220, 121, 28));
        btnCloseRealy = new QPushButton(centralwidget);
        btnCloseRealy->setObjectName(QString::fromUtf8("btnCloseRealy"));
        btnCloseRealy->setEnabled(false);
        btnCloseRealy->setGeometry(QRect(310, 220, 121, 28));
        label_5 = new QLabel(centralwidget);
        label_5->setObjectName(QString::fromUtf8("label_5"));
        label_5->setGeometry(QRect(330, 30, 121, 20));
        label_7 = new QLabel(centralwidget);
        label_7->setObjectName(QString::fromUtf8("label_7"));
        label_7->setGeometry(QRect(330, 70, 101, 20));
        cmbRfPower = new QComboBox(centralwidget);
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->addItem(QString());
        cmbRfPower->setObjectName(QString::fromUtf8("cmbRfPower"));
        cmbRfPower->setGeometry(QRect(430, 30, 111, 28));
        btnGetRfPower = new QPushButton(centralwidget);
        btnGetRfPower->setObjectName(QString::fromUtf8("btnGetRfPower"));
        btnGetRfPower->setEnabled(false);
        btnGetRfPower->setGeometry(QRect(550, 30, 84, 28));
        btnSetRfPower = new QPushButton(centralwidget);
        btnSetRfPower->setObjectName(QString::fromUtf8("btnSetRfPower"));
        btnSetRfPower->setEnabled(false);
        btnSetRfPower->setGeometry(QRect(640, 30, 84, 28));
        btnSetWorkMode = new QPushButton(centralwidget);
        btnSetWorkMode->setObjectName(QString::fromUtf8("btnSetWorkMode"));
        btnSetWorkMode->setEnabled(false);
        btnSetWorkMode->setGeometry(QRect(640, 70, 84, 28));
        btnGetWorkMode = new QPushButton(centralwidget);
        btnGetWorkMode->setObjectName(QString::fromUtf8("btnGetWorkMode"));
        btnGetWorkMode->setEnabled(false);
        btnGetWorkMode->setGeometry(QRect(550, 70, 84, 28));
        cmbWorkMode = new QComboBox(centralwidget);
        cmbWorkMode->addItem(QString());
        cmbWorkMode->addItem(QString());
        cmbWorkMode->addItem(QString());
        cmbWorkMode->setObjectName(QString::fromUtf8("cmbWorkMode"));
        cmbWorkMode->setGeometry(QRect(430, 70, 111, 28));
        btnStop = new QPushButton(centralwidget);
        btnStop->setObjectName(QString::fromUtf8("btnStop"));
        btnStop->setEnabled(false);
        btnStop->setGeometry(QRect(460, 250, 121, 28));
        btnStart = new QPushButton(centralwidget);
        btnStart->setObjectName(QString::fromUtf8("btnStart"));
        btnStart->setEnabled(false);
        btnStart->setGeometry(QRect(310, 250, 121, 28));
        tableView = new QTableView(centralwidget);
        tableView->setObjectName(QString::fromUtf8("tableView"));
        tableView->setGeometry(QRect(10, 290, 781, 251));
        btnScanUSB = new QPushButton(centralwidget);
        btnScanUSB->setObjectName(QString::fromUtf8("btnScanUSB"));
        btnScanUSB->setGeometry(QRect(740, 220, 31, 28));
        cmbUSB = new QComboBox(centralwidget);
        cmbUSB->setObjectName(QString::fromUtf8("cmbUSB"));
        cmbUSB->setGeometry(QRect(600, 220, 131, 28));
        btnUSB = new QPushButton(centralwidget);
        btnUSB->setObjectName(QString::fromUtf8("btnUSB"));
        btnUSB->setGeometry(QRect(600, 250, 91, 28));
        btnUSB_2 = new QPushButton(centralwidget);
        btnUSB_2->setObjectName(QString::fromUtf8("btnUSB_2"));
        btnUSB_2->setEnabled(false);
        btnUSB_2->setGeometry(QRect(700, 250, 71, 28));
        MainWindow->setCentralWidget(centralwidget);
        menubar = new QMenuBar(MainWindow);
        menubar->setObjectName(QString::fromUtf8("menubar"));
        menubar->setGeometry(QRect(0, 0, 800, 25));
        MainWindow->setMenuBar(menubar);
        statusbar = new QStatusBar(MainWindow);
        statusbar->setObjectName(QString::fromUtf8("statusbar"));
        MainWindow->setStatusBar(statusbar);

        retranslateUi(MainWindow);

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QApplication::translate("MainWindow", "MainWindow", nullptr));
        groupBox->setTitle(QApplication::translate("MainWindow", "Serial Connect  ", nullptr));
        label->setText(QApplication::translate("MainWindow", "port", nullptr));
        label_2->setText(QApplication::translate("MainWindow", "buad", nullptr));
        cmbComBuad->setItemText(0, QApplication::translate("MainWindow", "9200", nullptr));
        cmbComBuad->setItemText(1, QApplication::translate("MainWindow", "19200", nullptr));
        cmbComBuad->setItemText(2, QApplication::translate("MainWindow", "38400", nullptr));
        cmbComBuad->setItemText(3, QApplication::translate("MainWindow", "57600", nullptr));
        cmbComBuad->setItemText(4, QApplication::translate("MainWindow", "115200", nullptr));

        cmbComBuad->setCurrentText(QApplication::translate("MainWindow", "115200", nullptr));
        btnOpen->setText(QApplication::translate("MainWindow", "OPEN", nullptr));
        btnClose->setText(QApplication::translate("MainWindow", "CLOSE", nullptr));
        groupBox_2->setTitle(QApplication::translate("MainWindow", "Net Connect", nullptr));
        label_3->setText(QApplication::translate("MainWindow", "port", nullptr));
        label_4->setText(QApplication::translate("MainWindow", "IpAddr.", nullptr));
        btnConnect->setText(QApplication::translate("MainWindow", "CONNECT", nullptr));
        btnDisConnect->setText(QApplication::translate("MainWindow", "DISCONNECT", nullptr));
        txtIPAddr->setHtml(QApplication::translate("MainWindow", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:'Cantarell'; font-size:11pt; font-weight:400; font-style:normal;\">\n"
"<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">192.168.1.216</p></body></html>", nullptr));
        txtPort->setHtml(QApplication::translate("MainWindow", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:'Cantarell'; font-size:11pt; font-weight:400; font-style:normal;\">\n"
"<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">2022</p></body></html>", nullptr));
        groupBox_3->setTitle(QString());
        label_9->setText(QApplication::translate("MainWindow", "Freq End", nullptr));
        label_8->setText(QApplication::translate("MainWindow", "Freq Start", nullptr));
        label_6->setText(QApplication::translate("MainWindow", "Freq Band", nullptr));
        btnSetFreqBand->setText(QApplication::translate("MainWindow", "Set", nullptr));
        btnGetFreqBand->setText(QApplication::translate("MainWindow", "Get", nullptr));
        cmbFreqBand->setItemText(0, QString());
        cmbFreqBand->setItemText(1, QApplication::translate("MainWindow", "Custom", nullptr));
        cmbFreqBand->setItemText(2, QApplication::translate("MainWindow", "USA", nullptr));
        cmbFreqBand->setItemText(3, QApplication::translate("MainWindow", "Korea", nullptr));
        cmbFreqBand->setItemText(4, QApplication::translate("MainWindow", "Europe", nullptr));
        cmbFreqBand->setItemText(5, QApplication::translate("MainWindow", "Japan", nullptr));
        cmbFreqBand->setItemText(6, QApplication::translate("MainWindow", "Malaysia", nullptr));
        cmbFreqBand->setItemText(7, QApplication::translate("MainWindow", "Europe3", nullptr));
        cmbFreqBand->setItemText(8, QApplication::translate("MainWindow", "China_1", nullptr));
        cmbFreqBand->setItemText(9, QApplication::translate("MainWindow", "China_2", nullptr));

        btnReleaseRealy->setText(QApplication::translate("MainWindow", "Release_Realy", nullptr));
        btnCloseRealy->setText(QApplication::translate("MainWindow", "Close_Realy", nullptr));
        label_5->setText(QApplication::translate("MainWindow", "RfPower(dbm)", nullptr));
        label_7->setText(QApplication::translate("MainWindow", "WorkMode", nullptr));
        cmbRfPower->setItemText(0, QString());
        cmbRfPower->setItemText(1, QApplication::translate("MainWindow", "0", nullptr));
        cmbRfPower->setItemText(2, QApplication::translate("MainWindow", "1", nullptr));
        cmbRfPower->setItemText(3, QApplication::translate("MainWindow", "2", nullptr));
        cmbRfPower->setItemText(4, QApplication::translate("MainWindow", "3", nullptr));
        cmbRfPower->setItemText(5, QApplication::translate("MainWindow", "4", nullptr));
        cmbRfPower->setItemText(6, QApplication::translate("MainWindow", "5", nullptr));
        cmbRfPower->setItemText(7, QApplication::translate("MainWindow", "6", nullptr));
        cmbRfPower->setItemText(8, QApplication::translate("MainWindow", "7", nullptr));
        cmbRfPower->setItemText(9, QApplication::translate("MainWindow", "8", nullptr));
        cmbRfPower->setItemText(10, QApplication::translate("MainWindow", "9", nullptr));
        cmbRfPower->setItemText(11, QApplication::translate("MainWindow", "10", nullptr));
        cmbRfPower->setItemText(12, QApplication::translate("MainWindow", "11", nullptr));
        cmbRfPower->setItemText(13, QApplication::translate("MainWindow", "12", nullptr));
        cmbRfPower->setItemText(14, QApplication::translate("MainWindow", "13", nullptr));
        cmbRfPower->setItemText(15, QApplication::translate("MainWindow", "14", nullptr));
        cmbRfPower->setItemText(16, QApplication::translate("MainWindow", "15", nullptr));
        cmbRfPower->setItemText(17, QApplication::translate("MainWindow", "16", nullptr));
        cmbRfPower->setItemText(18, QApplication::translate("MainWindow", "17", nullptr));
        cmbRfPower->setItemText(19, QApplication::translate("MainWindow", "18", nullptr));
        cmbRfPower->setItemText(20, QApplication::translate("MainWindow", "19", nullptr));
        cmbRfPower->setItemText(21, QApplication::translate("MainWindow", "20", nullptr));
        cmbRfPower->setItemText(22, QApplication::translate("MainWindow", "21", nullptr));
        cmbRfPower->setItemText(23, QApplication::translate("MainWindow", "22", nullptr));
        cmbRfPower->setItemText(24, QApplication::translate("MainWindow", "23", nullptr));
        cmbRfPower->setItemText(25, QApplication::translate("MainWindow", "24", nullptr));
        cmbRfPower->setItemText(26, QApplication::translate("MainWindow", "25", nullptr));
        cmbRfPower->setItemText(27, QApplication::translate("MainWindow", "26", nullptr));
        cmbRfPower->setItemText(28, QApplication::translate("MainWindow", "27", nullptr));
        cmbRfPower->setItemText(29, QApplication::translate("MainWindow", "28", nullptr));
        cmbRfPower->setItemText(30, QApplication::translate("MainWindow", "29", nullptr));
        cmbRfPower->setItemText(31, QApplication::translate("MainWindow", "30", nullptr));
        cmbRfPower->setItemText(32, QApplication::translate("MainWindow", "31", nullptr));
        cmbRfPower->setItemText(33, QApplication::translate("MainWindow", "32", nullptr));
        cmbRfPower->setItemText(34, QApplication::translate("MainWindow", "33", nullptr));

        cmbRfPower->setCurrentText(QString());
        btnGetRfPower->setText(QApplication::translate("MainWindow", "Get", nullptr));
        btnSetRfPower->setText(QApplication::translate("MainWindow", "Set", nullptr));
        btnSetWorkMode->setText(QApplication::translate("MainWindow", "Set", nullptr));
        btnGetWorkMode->setText(QApplication::translate("MainWindow", "Get", nullptr));
        cmbWorkMode->setItemText(0, QString());
        cmbWorkMode->setItemText(1, QApplication::translate("MainWindow", "AnserMode", nullptr));
        cmbWorkMode->setItemText(2, QApplication::translate("MainWindow", "ActiveMode", nullptr));

        btnStop->setText(QApplication::translate("MainWindow", "STOP", nullptr));
        btnStart->setText(QApplication::translate("MainWindow", "START", nullptr));
        btnScanUSB->setText(QApplication::translate("MainWindow", "...", nullptr));
        btnUSB->setText(QApplication::translate("MainWindow", "USB Connect", nullptr));
        btnUSB_2->setText(QApplication::translate("MainWindow", "USB Close", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
