# Aswega SA-94/2

Различные наработки по считыванию текущих данных с приборов учета тепловой энергии Aswega SA-94/2

Aswega_SA942_manual.pdf - паспорт на счетчик. На страницах 47-51 идет описание взаимодействия с прибором и форматов отправляемых/получаемых данных

[aswega.py](aswega.py) - вполне себе рабочий скрипт на Python

[aswega.vbs](aswega.vbs) - вполне себе рабочий скрипт на VBScript

[heat-meter.yaml](aswega.vbs) - начальные наметки конфигурации ESPHome, из которой будет вызываться custom component

[aswega.h](aswega.h) - начальные наметки custom component, содранные с какого-то подобного проекта

https://github.com/rjehangir/struct - реализованная на C++ питоновская функция unpack, куски из нее возможно пригодятся

https://esphome.io/custom/custom_component.html - краткая рекомендация по созданию custom component для ESPHome

https://esphome.io/custom/uart.html - краткая рекомендация по созданию custom component для ESPHome для работы с асинхронным интерфейсом RS-232
