//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterIRCLink2 expands UBrowserBufferedTCPLink;

var bool bIsConnected;
var IpAddr ServerIpAddr;
var string UserIdent, ReporterNick;
var int NickCounter;
var int iTimerType;
var bool SwitchLink;
var localized string FullName;
var MvReporter Controller;
var MvReporterConfig conf;

var float iFloodCount, iFloodCurrent, xAFloodDelay;
var string sQueue[32];
var int ifHead, ifFoot, ifCount;
var float GameSpeed;

// FUNCTION: Connect / Startup (INIT)
function Connect(MvReporter InController, MvReporterConfig InConfig)
{
  local int i;

  // Get the Variables passed from the Controller
  Controller = InController;
  conf = InConfig;
  bIsConnected = FALSE;

  // Set Nickname
  ReporterNick = conf.NickName2;
  FullName = Controller.sVersion$" (Built: "$Controller.sBuild$")";

  // Set User IdentD
  ResetBuffer();
  if (conf.bUseLogin)
    UserIdent = conf.UserName2;
  else
    {
      if (conf.jIdent2 != "" && (conf.jUseIdent))
        UserIdent = conf.jIdent2;
      else 
        {
          UserIdent = "xr3-";
          for(i = 0; i < 5; i++)
          UserIdent = UserIdent $ Chr((Rand(10) + 48));      	
        }
    }
  Log("++ [Mv]: Secondary link - Created new UserIdent: "$UserIdent);

  ServerIpAddr.Port = conf.ServerPort;
  Resolve(conf.ServerAddr);
}


function Disconnect()
{
  SendQuit("Reporter quit!");
  bIsConnected = FALSE;
  Close();
}


// FUNCTION (EVENT): Resolved / Resolved IP Address
function Resolved(IpAddr Addr)
{

  ServerIpAddr.Addr = Addr.Addr;

  if (BindPort() == 0)
    {
      Log("++ [Mv]: Secondary - Failed to resolve IRC server port!");
      return;
    }

  Log("++ [Mv]: Secondary - Successfully resolved Server IP Address...");
  Open(ServerIpAddr);
}

function ResolveFailed() {
  Log("++ [Mv]: Secondary - Failed to resolve IRC server!");
}


// EVENT: Opened / IRC Link Opened
event Opened()
{
  Log("++ [Mv]: Secondary - Link to IRC Server opened...");
  Enable('Tick');
  GotoState('LoggingIn');
}

// CLOSED !!? :(
event Closed()
{
  Log("++ [Mv]: Secondary - Lost connection to server");
}

// STATE: LoggingIn / Logging In to Server
state LoggingIn
{
  function ProcessInput(string Line)
    {
      local string msg, Temp;
      msg = ParseDelimited(Line, " ", 2);

      if (Left(Line, 5) == "PING ")
	SendBufferedData("PONG "$Mid(Line, 5)$CRLF);

      // IF an error occured
      if (ParseDelimited(Line, " ", 1) == "ERROR")
	Log("++ [Mv]: Secondary - "$ParseDelimited(Line, ":", 2, True));

      // Already in use issue
      if (msg == "433")
	{
	  ReporterNick = conf.NickName2$string(NickCounter);
	  SendBufferedData("NICK "$ReporterNick$CRLF);
	  NickCounter++;
	  return;
	}

      // Register First Issue!
      if (msg == "451")
	{
	  SendBufferedData("NICK "$ReporterNick$LF);
	  SendBufferedData("USER "$UserIdent$" 0 * :"$FullName$LF);
	  return;
	}

      if (msg == "NICK")
	{
	  Temp = ParseDelimited(Line, "~@", 2);
	  if (Temp ~= UserIdent) {
	    Temp = ParseDelimited(Line, ":", 3, True);
	    ReporterNick = Temp;
	  }
	}

      // Proceed to next section
      if (Int(msg) != 0)
	{
	  Log("++ [Mv]: Secondary - Switching state to 'LoggedIn'");
	  GotoState('LoggedIn');
	}
      Global.ProcessInput(Line);
    }

 Begin:
  if (conf.bUseLogin)
    SendText("PASS "$conf.Password2$LF);
  SendText("USER "$UserIdent$" 0 * :"$FullName$LF);
  SendText("NICK "$conf.NickName2$LF);
}


// STATE: LoggedIn / Logged In to Server
state LoggedIn
{
  function ProcessInput(string Line)
    {
      local string Command, OrigNick, DestNick, NickFlags, OrigNickAddr, DisconnectMsg;
      DisconnectMsg = "ERROR :Closing Link";
      Global.ProcessInput(Line);

      // Get Infos about the Message from Server
      Command = ParseDelimited(Line, " ", 2);
      OrigNick = ParseDelimited(Line, ":!", 2);
      OrigNickAddr = ParseDelimited(Line, "! ", 2);

      // Check for Disconnect Message
      if ((Left(Line, Len(DisconnectMsg)) ~= DisconnectMsg)) {
	Log("++ [Mv]: Secondary - "$ParseDelimited(Line, ":", 2, True));
	bIsConnected = FALSE;
	iTimerType = 1;
	SetTimer(15, FALSE);
      }

      // IF an error occured
      if (ParseDelimited(Line, " ", 1) == "ERROR")
	Log("++ [Mv]: Secondary - "$ParseDelimited(Line, ":", 2, True));

      // Nick already in USE!
      if (Command == "433")
	{
	  ReporterNick = conf.NickName2$string(NickCounter);
	  SendBufferedData("NICK "$ReporterNick$CRLF);
	  NickCounter++;
	  return;
	}

      // Banned
      if (Command == "474")
      {
	// Set anti-ban timer!
	iTimerType = 474;
	SetTimer(10, FALSE);
      }

      // KICK command -> rejoin chan :)
      if (Command == "KICK")
	{
	  if (ParseDelimited(Line, " ", 4) == ReporterNick) {
	    // Rejoin the Channel
	    JoinChannel(conf.Channel);
	  }
	}
    }
 Begin:
  Log("++ [Mv]: Secondary - Successfully logged in to IRC Network!");

  // Let's see if we have to auth on srvx :D
  if (conf.bUseSrvx)
    SendBufferedData("PRIVMSG "$conf.SrvxName$" :AUTH "$conf.SrvxAccount$" "$conf.SrvxPassword$CRLF);

  // Execute perform commands - if any, before join.
  if (conf.bDebug)
    Log("++ [Mv Debug]: Secondary - Sending Perform, Before Join");
  if (conf.Perform1 != "") SendBufferedData(conf.Perform1$LF);
  if (conf.Perform2 != "") SendBufferedData(conf.Perform2$LF);
  if (conf.Perform3 != "") SendBufferedData(conf.Perform3$LF);
  

  // Send mode +x?
  if (conf.bModeX)
  {
    Log("++ [Mv]: Secondary - Sent Mode "$conf.NickName2$" +ix");
    SendBufferedData("MODE "$conf.NickName2$" +ix"$LF);
  }
  

  if (conf.nInviteMe)
  {
  	Log ("++ [Mv]: Secondary - Inviting myself to: "$conf.Channel);
  	if (conf.nQuakenet)
  	  SendBufferedData("PRIVMSG "$conf.SrvxChan$" :INVITE "$conf.Channel$" "$CRLF);
  	else
  	  SendBufferedData("PRIVMSG "$conf.SrvxChan$" :INVITEME "$conf.Channel$" "$CRLF);
  }
  

  Log ("++ [Mv]: Secondary - Joining Channel: "$conf.Channel);
  SendBufferedData("JOIN "$conf.Channel$CRLF);


  // Execute perform commands - if any, after join.
  if (conf.bDebug)
    Log("++ [Mv Debug]: Secondary - Sending Perform, After Join");
  if (conf.Perform4 != "") SendBufferedData(conf.Perform4$LF);
  if (conf.Perform5 != "") SendBufferedData(conf.Perform5$LF);
  if (conf.Perform6 != "") SendBufferedData(conf.Perform6$LF);


  // Go into mode "intialized" in 5 seconds
  iTimerType = 2;
  SetTimer(5, FALSE);
}


// FUNCTION: PostBeginPlay
function PostBeginPlay()
{
  Super.PostBeginPlay();
  Disable('Tick');
}


// FUNCTION: Tick
function Tick(float DeltaTime)
{
  local string Line;

  DoBufferQueueIO();
  if (ReadBufferedLine(Line))
    ProcessInput(Line);
}


// FUNCTION ProccessInput / Standard Processing Function
function ProcessInput(string Line)
{
  if (conf.bDebug)
    Log("++ [Mv Debug]: Secondary - "$Line);
  if (Left(Line, 5) == "PING ")
    SendBufferedData("PONG "$Mid(Line, 5)$CRLF);
}

// TIMER EVENT
event Timer()
{
  if (iTimerType == 10)
    {
      if (conf.bUseLogin)
	SendText("PASS "$conf.Password2$LF);
      Log ("++ [Mv]: Secondary - Sent PASS");
      iTimerType = 11;
      SetTimer(1, false);
    }

  else if (iTimerType == 11)
    {
    SendText("USER "$UserIdent$" 0 * :"$FullName$LF);
    Log ("++ [Mv]: Secondary - Sent USER");
    iTimerType = 12;
    SetTimer(1, false);
    }
  else if (iTimerType == 12)
    {
      SendText("NICK "$conf.NickName2$LF);
      Log ("++ [Mv]: Secondary - Sent NICK");
    }

  // Initialize!
  if (iTimerType == 2)
      bIsConnected = TRUE;

  // Reconnect
  if (iTimerType == 1)
      Connect(Controller, conf);

  // If Banned -> reconnect to chan
  if (iTimerType == 474)
    {
      iTimerType = 0;
      if (bIsConnected)
	JoinChannel(conf.Channel);
    }
}

// Join a Channel
function JoinChannel(string Channel)
{
  if (bIsConnected)
    if (Left(Channel, 1) == "#")
      SendBufferedData("JOIN "$Channel$CRLF);
}

// Quit from IRC
function SendQuit(string msg)
{
  if (bIsConnected)
    SendBufferedData("QUIT :"$msg$CRLF);
}

function RelaunchReporter(string msg)
{
  Disconnect();
  iTimerType = 1;
  SetTimer(5, FALSE);
}

defaultproperties
{
     ReporterNick="mvr"
     FullName="mavericks reporter"
     iFloodCount=1.500000
}
