#ifndef M_THREAD_H
#define M_THREAD_H

#include <QObject>
#include "CFApi.h"
#include <QDebug>
#include <QThread>

class m_thread : public QObject
{
    Q_OBJECT
public:
    explicit m_thread(QObject *parent = nullptr);

    // 工作函数
    void working();

signals:
    void curInfo(TagInfo tag);

public slots:

public:
    int64_t hComm;
    bool isMonitor;
};

#endif // M_THREAD_H
