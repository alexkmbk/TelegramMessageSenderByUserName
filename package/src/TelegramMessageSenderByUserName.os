////////////////////////////////////////////////////////////////////////////////
//Telegram message sender by User name

Var BotToken_, UsersFilePath, UpdateIDFilePath, UpdateIDMap, UpdateID, TelegramUsersInfo, UsedProxies;

Procedure Init(BotToken, WorkingFolder = "") Export

	BotToken_ = BotToken;
	UsersFilePath = ?(IsBlankString(WorkingFolder), "Users.txt", WorkingFolder + "\Users.txt");	
	UpdateIDFilePath = ?(IsBlankString(WorkingFolder), "UpdateID.txt", WorkingFolder + "\UpdateID.txt");

	UsedProxies = New Array();

	ReadUpdateIDFromStorage();
	ReadUsersFromStorage();

EndProcedure

Function ReadMessages(Body) Export
	
	Result = New Array;
	
	Reader = New JSONReader();
	Reader.SetString(Body);

	Message = New Structure(); 
	
	IsFirst = True;
	
	While Reader.Read() Do
		
		If Reader.CurrentValueType = JSONValueType.PropertyName Then
			If Reader.CurrentValue = "update_id" Then
				If Not IsFirst Тогда
					Result.Add(Message);
				Else 
					IsFirst = False;
				EndIf;
				Message = New Structure(); 
				Reader.Read();
				Message.Insert("update_id", Reader.CurrentValue); 
			EndIf;
		EndIf;
		
		If Reader.CurrentValueType = JSONValueType.PropertyName Then		

			If Reader.CurrentValue = "text" Тогда
				Reader.Read();
				Text = TrimAll(Reader.CurrentValue);
				Message.Insert("text", Text); 		
			EndIf;
		EndIf;
		
		If Reader.CurrentValueType = JSONValueType.PropertyName Then		

			If Reader.CurrentValue = "username" Тогда
				Reader.Read();
				Message.Insert("username", Reader.CurrentValue); 		
			EndIf;
		EndIf;
		
		If Reader.CurrentValueType = JSONValueType.PropertyName Then		

			If Reader.CurrentValue = "first_name" Тогда
				Reader.Read();
				Message.Insert("first_name", Reader.CurrentValue); 		
			EndIf;
		EndIf;

		If Reader.CurrentValueType = JSONValueType.PropertyName Then		

			If Reader.CurrentValue = "last_name" Тогда
				Reader.Read();
				Message.Insert("last_name", Reader.CurrentValue); 		
			EndIf;
		EndIf;
		
		If Reader.CurrentValueType = JSONValueType.PropertyName Then		

			If Reader.CurrentValue = "chat" Тогда
				Reader.Read();
				Reader.Read();
				Reader.Read();
				Message.Insert("ChatID", Reader.CurrentValue); 		
			EndIf;
		EndIf;		
		
	EndDo;
	
	If IsFirst Then
		Return Result;
	EndIf;
	
	Result.Add(Message);
	
	Return Result;
		
EndFunction

Procedure WriteUsersToStorage()

	TextDoc = New TextDocument;
	For Each Item In TelegramUsersInfo Do
		TextDoc.AddLine(BotToken_ + "=" + Item.Key + "=" + Item.Value);
	EndDo; 
	TextDoc.Write(UsersFilePath);	
	
EndProcedure

Procedure ReadUsersFromStorage()

	TelegramUsersInfo = New Map();

	File = New File(UsersFilePath);
	If NOT File.Exist() Then
		Return;
	EndIf; 

	TextDoc = New TextDocument;
	TextDoc.Read(UsersFilePath);
	LineCount = TextDoc.LineCount();
	For LineNum = 1 To LineCount Do
		Line = TextDoc.GetLine(LineNum);
		BotTokenPos = StrFind(Line,"=");
		If BotTokenPos > 0 Then
			If Left(Line, BotTokenPos - 1) = BotToken_ Then
				Pos = StrFind(Line,"=",,BotTokenPos + 1);		
				TelegramUsersInfo.Insert(Mid(Line, BotTokenPos + 1, Pos - BotTokenPos - 1), Mid(Line, Pos + 1, StrLen(Line)));
			EndIf
		EndIf; 
	EndDo;
	
EndProcedure

Procedure ReadUpdateIDFromStorage()
	
	UpdateID = 0;
	UpdateIDMap = New Map;

	File = New File(UpdateIDFilePath);
	If NOT File.Exist() Then
		Return;
	EndIf; 
	
	TextDoc = New TextDocument;
	TextDoc.Read(UpdateIDFilePath);
	LineCount = TextDoc.LineCount();
	For LineNum = 1 To LineCount Do
		Line = TextDoc.GetLine(LineNum);
		Pos = StrFind(Line,"=");
		If Pos > 0 Then
			CurrentBotToken = Left(Line, Pos - 1);
			CurrentUpdateID = Number(Mid(Line, Pos + 1, StrLen(Line)));
			If CurrentBotToken = BotToken_ Then
				UpdateID = CurrentUpdateID;
			EndIf; 
			UpdateIDMap.Insert(CurrentBotToken, CurrentUpdateID);
		EndIf; 
	EndDo;
		
EndProcedure

Procedure WriteUpdateIDToStorage(UpdateIDMap)
	
	TextDoc = New TextDocument;
	For Each Item In UpdateIDMap Do
		TextDoc.AddLine(Item.Key + "=" + Item.Value);
	EndDo; 
	TextDoc.Write(UpdateIDFilePath);	
	
EndProcedure
 
Function GetNextProxy()

		ServerName = "https://www.proxy-list.download";
		URL = "api/v1/get?type=https&anon=transparent&country=NL";
		
		HTTPRequest = New HTTPRequest(URL);
		Connection = New HTTPConnection(ServerName);
		Res = Connection.Get(HTTPRequest);
		ResStr = Res.GetBodyAsString();
		
		StringsArray = New Array();
		LineCount = StrLineCount(ResStr);

		if LineCount <= UsedProxies.Count() Then
			Return Undefined;	
		EndIf;
	
		For StrNum = 1 To LineCount Do
			Str = StrReplace(StrGetLine(ResStr, StrNum), Chars.CR, "");
			StringsArray.Add(StrSplit(Str, ":"));
		EndDo;
		
		ProxyIP = StringsArray[UsedProxies.Count()][0];
		ProxyPort = Number(StringsArray[UsedProxies.Count()][1]);
		Proxy = New InternetProxy(False);
		Proxy.Set("https", ProxyIP, ProxyPort, "", "", False);
		UsedProxies.Add(Proxy);
		Return Proxy;
			
EndFunction

Function SendMessage(UserName, Message) Export

	if SendMessageInner(UserName, Message) then
		Return True;
	EndIf;

	Message(nstr("ru='Попытаемся найти подходящий прокси:'; en='Will try to find an appropriate proxy:'"));

	For Count = 1 to 25 Do
		Proxy = GetNextProxy();
		if SendMessageInner(UserName, Message, Proxy) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function SendMessageInner(UserName, Message, Proxy = Undefined)
	
	If Not ValueIsFilled(BotToken_) Then
		Message(nstr("ru='Не задан API Bot Token. Необходимо вызвать метод Init и передать в него значение API Bot Token';
		|en='The API Bot Token was not specified. it's necessary to call Init method firstly'"));
		Return False;
	EndIf; 
						
		Попытка
			if Proxy <> Undefined Then
				Connection = New HTTPConnection("https://api.telegram.org", ,, , Proxy);
			Else
				Connection = New HTTPConnection("https://api.telegram.org");
			EndIf;
		Исключение
			Сообщить("Ошибка создания объекта подключения к серверу Telegram:" + ОписаниеОшибки());
			Return False;
		КонецПопытки;

	CurrentChatID = TelegramUsersInfo.Get(UserName); 	

	If CurrentChatID = Undefined Then
	ReadUsersFromStorage();
	CurrentChatID = TelegramUsersInfo.Get(UserName); 	
	EndIf;

	If CurrentChatID = Undefined Then

		UpdateID = 0;
	
		UpdateIDMap = New Map(); 
		
		If UpdateID = 0 Then 
			ReadUpdateIDFromStorage();	
		EndIf;
		
		If UpdateID = 0 Then
			Request = New HTTPRequest("/bot" + BotToken_ + "/getUpdates");
		Else
			Request = New HTTPRequest("/bot" + BotToken_ + "/getUpdates?offset=" + Format(UpdateID + 1, "NG=")); 
		EndIf;
		
		Res = Connection.Get(Request);
		If Res.StatusCode = 200 Then
		MessageList = ReadMessages(Res.GetBodyAsString("UTF-8"));	
		EndIf;
		
		IndexLastMessage = MessageList.Count() - 1;	
		If MessageList.Count() > 0 Then		
			UpdateIDMap.Insert(BotToken_, MessageList[IndexLastMessage].update_id);
		EndIf;
			
		WriteUpdateIDToStorage(UpdateIDMap);

		ChatID = Undefined;
	
	For Each Item In MessageList Do

		PropertyUsername = Undefined;
		If NOT Item.Property("username", PropertyUsername) OR PropertyUsername <> UserName Then
			Continue;
		EndIf; 
	
		CurrentChatID = TelegramUsersInfo.Get(PropertyUsername);
		If CurrentChatID = Undefined OR CurrentChatID <> Item.ChatID AND ValueIsFilled(Item.ChatID) Then
			TelegramUsersInfo.Insert(Item.username, Item.ChatID);
			If CurrentChatID <> Undefined Then
				CurrentChatID = Item.ChatID;	
			EndIf; 
			
			If PropertyUsername = UserName Then
				ChatID = Item.ChatID;
			EndIf; 
		EndIf;
	EndDo; 
		
	Else
		ChatID = CurrentChatID;	
	EndIf; 
	
	If ChatID = Undefined then
		Message(nstr("ru='Не удалось получить идентификатор чата, пожалуйста попробуйте отправить боту от имени пользователя сообщение с текстом ""/start""';
		|en='there is a failure of obtaining chat id, please try to send the message ""/start"" to the bot'"));
		Return False;
	EndIf;

	WriteUsersToStorage();	

	Request = New HTTPRequest("/bot" + BotToken_ + "/sendMessage?chat_id=" + ChatID + "&text=" + Message + "&parse_mode=HTML");
	Res = Connection.Get(Request);
	
	If Res.StatusCode <> 200 Then
		if Proxy = Undefined Then
		Message(nstr("ru='Ошибка отправки сообщения '; en='Sending message error: '") + Res.GetBodyAsString("UTF-8"));			
		Else
		Message(nstr("ru='Ошибка отправки сообщения через прокси:'; en='Sending message error through proxy: '") + Res.GetBodyAsString("UTF-8"));				
		EndIf;			
		Return False;
	EndIf;
	
	Message(nstr("ru='Ok. Сообщение отравлено.'; en='Ok. The message has been sent.'"));

	Return True;
	
EndFunction
