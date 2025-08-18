#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <stdint.h>
#include <qstandarditemmodel.h>
#include <QtSerialPort/QSerialPort>
#include <QSerialPortInfo>
#include <QMessageBox>
#include <QThread>
#include "CFApi.h"
#include "hid.h"
#include "qdebug.h"
#include "m_thread.h"

typedef struct
{
    int NO;
    int Ant1;
    int Ant2;
    int Ant3;
    int Ant4;
    QString Data;
    QString Len;
    QString RSSI;
    QString Channel;
}Info;
Q_DECLARE_METATYPE(Info)

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void on_btnOpen_clicked();

    void on_btnClose_clicked();

    void on_btnConnect_clicked();

    void on_btnDisConnect_clicked();

    void on_btnGetRfPower_clicked();

    void on_btnSetRfPower_clicked();

    void on_btnGetWorkMode_clicked();

    void on_btnSetWorkMode_clicked();

    void on_cmbFreqBand_currentIndexChanged(int index);

    void on_btnGetFreqBand_clicked();

    void on_btnSetFreqBand_clicked();

    void on_btnCloseRealy_clicked();

    void on_btnReleaseRealy_clicked();

    void on_btnStart_clicked();

    void on_btnStop_clicked();

    void on_btnScanUSB_clicked();

    void on_btnUSB_clicked();

    void on_btnUSB_2_clicked();

private:
    Ui::MainWindow *ui;

    QStandardItemModel *model;

    static int64_t hComm;
    DevicePara param;
    QList<Info> lstInfo;
};
#endif // MAINWINDOW_H
