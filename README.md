# Отправка сообщений через telegram по имени пользователя  

## Введение

Существующие библиотеки OneScript позволяют отправлять сообщения по коду чата, который сам по себе не так то просто получить. Данная библиотека позволят отправить сообщение указав только имя пользователя.
По умолчанию у пользователей телеграм нет имени, они авторизуются по номеру телефона, однако если через интерфейс клиента задать имя пользователю, появляется возможность отправки ему сообщения по этому имени.

## Использование


Пример:

#Использовать TelegramMessageSenderByUserName

TelegramMessageSenderByUserName.Init("DSLJFKDSJLFJLSKJL");
TelegramMessageSenderByUserName.SendTelegramMessage("username", "Hi!");


Перед отправкой сообщения необходимо выполнить инициализацию, с помощью метода Init:

TelegramMessageSenderByUserName.Init(<BotToken>, [Путь к рабочему каталогу]);

где, Путь к рабочему каталогу - необязательный параметр, определяющий путь к каталогу, в котором будут сохранены технические таблицы, которые требуются для работы библиотеки. Желательно сохранять содержимое каталога, при его очистке потребуется оптравить сообщение боту, для возобновления работы.

Отправка сообщения осуществляется с помощью метода SendTelegramMessage:

TelegramMessageSenderByUserName.SendTelegramMessage(<ИмяПользователяТелеграм>, <ТекстСообщения>);
