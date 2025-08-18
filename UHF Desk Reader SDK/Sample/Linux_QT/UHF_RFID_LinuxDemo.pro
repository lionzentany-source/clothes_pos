QT       += core gui
QT       += serialport

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    m_thread.cpp \
    main.cpp \
    mainwindow.cpp

HEADERS += \
    ../../../projects/UHF_RFID_Run/bin/CFApi.h \
    ../../../projects/UHF_RFID_Run/bin/hid.h \
    m_thread.h \
    mainwindow.h

FORMS += \
    mainwindow.ui

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

win32:CONFIG(release, debug|release): LIBS += -L$$PWD/./release/ -lCFApi
else:win32:CONFIG(debug, debug|release): LIBS += -L$$PWD/./debug/ -lCFApi
else:unix: LIBS += -L$$PWD/./ -lCFApi

INCLUDEPATH += $$PWD/.
DEPENDPATH += $$PWD/.

win32:CONFIG(release, debug|release): LIBS += -L$$PWD/./release/ -lhid
else:win32:CONFIG(debug, debug|release): LIBS += -L$$PWD/./debug/ -lhid
else:unix: LIBS += -L$$PWD/./ -lhid

INCLUDEPATH += $$PWD/.
DEPENDPATH += $$PWD/.
