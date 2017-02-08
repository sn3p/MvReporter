//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterIRCLink expands UBrowserBufferedTCPLink;

var bool bIsConnected;
var IpAddr ServerIpAddr;
var string UserIdent, ReporterNick;
var int NickCounter;
var int iTimerType;
var bool SwitchLink;
var localized string FullName;
var MvReporter Controller;
var MvReporterConfig conf;
var MvReporterIRCLink2 Link2;
var MvReporterSpectator Spec;

var float iFloodCount, iFloodCurrent, xAFloodDelay;
var string sQueue[32];
var int ifHead, ifFoot, ifCount;
var float GameSpeed;
var bool bUTGLEnabled;

// FUNCTION: Connect / Startup (INIT)
function Connect(MvReporter InController, MvReporterConfig InConfig)
{
  local int i;

  // Get the Variables passed from the Controller
  Controller = InController;
  conf = InConfig;
  bIsConnected = FALSE;

  // Set Nickname
  ReporterNick = conf.NickName;
  FullName = Controller.sVersion$" (Built: "$Controller.sBuild$")";


  // Set User IdentD
  ResetBuffer();
  ResetQueue();
  if (conf.bUseLogin)
      UserIdent = conf.UserName;
  else
    {
      if (conf.jIdent != "" && (conf.jUseIdent))
        UserIdent = conf.jIdent;
      else 
        {
          UserIdent = "xr3-";
          for(i = 0; i < 5; i++)
          UserIdent = UserIdent $ Chr((Rand(10) + 48));      	
        }
    }
  Log("++ [Mv]: Created new UserIdent: "$UserIdent);

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
      Log("++ [Mv]: Primary - Failed to resolve IRC server port!");
      return;
    }

  Log("++ [Mv]: Primary - Successfully resolved Server IP Address...");
  Open(ServerIpAddr);
}

function ResolveFailed()
{
  Log("++ [Mv]: Primary - Failed to resolve IRC server!");
}


// EVENT: Opened / IRC Link Opened
event Opened()
{
  Log("++ [Mv]: Primary - Link to IRC Server opened...");
  Enable('Tick');
  GotoState('LoggingIn');
}

// CLOSED !!? :(
event Closed()
{
  Log("++ [Mv]: Primary - Lost connection to server");
}

// STATE: LoggingIn / Logging In to Server
state LoggingIn
{
  function ProcessInput(string Line) {
    local string msg, Temp;
    msg = ParseDelimited(Line, " ", 2);

    if (Left(Line, 5) == "PING ")
      SendBufferedData("PONG "$Mid(Line, 5)$CRLF);

    // IF an error occured
    if (ParseDelimited(Line, " ", 1) == "ERROR")
      Log("++ [Mv]: Primary - "$ParseDelimited(Line, ":", 2, True));

    // Already in use issue
    if (msg == "433")
      {
	ReporterNick = conf.NickName$string(NickCounter);
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
	if (Temp ~= UserIdent)
	  {
	    Temp = ParseDelimited(Line, ":", 3, True);
	    ReporterNick = Temp;
	  }
      }

    // Proceed to next section
    if (Int(msg) != 0) {
      Log("++ [Mv]: Primary - Switching state to 'LoggedIn'");
      GotoState('LoggedIn');
    }
    Global.ProcessInput(Line);
  }

Begin:
  if (conf.bUseLogin)
    SendText("PASS "$conf.Password$LF);
  SendText("USER "$UserIdent$" 0 * :"$FullName$LF);
  SendText("NICK "$conf.NickName$LF);
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
      if ((Left(Line, Len(DisconnectMsg)) ~= DisconnectMsg))
	{
	  Log("++ [Mv]: "$ParseDelimited(Line, ":", 2, True));
	  bIsConnected = FALSE;
	  iTimerType = 1;
	  SetTimer(15, FALSE);
	}

      // IF an error occured
      if (ParseDelimited(Line, " ", 1) == "ERROR")
	Log("++ [Mv]: Primary - "$ParseDelimited(Line, ":", 2, True));

      // Nick already in USE!
      if (Command == "433")
	{
	  ReporterNick = conf.NickName$string(NickCounter);
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

    // Handle Messages (Private and/or Public)
    if (Command == "PRIVMSG")
      {
	// Get User Flags and User's Nick
	DestNick = ParseDelimited(Line, " ", 3);
	while(DestNick != "" && InStr(":@+", Left(DestNick, 1)) != -1)
	  {
	    DestNick = Mid(DestNick, 1);
	    log(NickFlags);
	    NickFlags = NickFlags$Left(DestNick,1);
	  }
	ProcessPrivMsg(OrigNick, NickFlags, DestNick, Line);
      }
    }
 Begin:
  Log("++ [Mv]: Primary - Successfully logged in to IRC Network!");

  if (Spec.ServerMutate("getglstatus")=="True")
    bUTGLEnabled=True;

  // Let's see if we have to auth on srvx :D
  if (conf.bUseSrvx)
    SendBufferedData("PRIVMSG "$conf.SrvxName$" :AUTH "$conf.SrvxAccount$" "$conf.SrvxPassword$CRLF);

  // Execute perform commands - if any, before join
  if (conf.bDebug)
    Log("++ [Mv Debug]: Primary - Sending Perform, Before Join");
  if (conf.Perform1 != "") SendBufferedData(conf.Perform1$LF);
  if (conf.Perform2 != "") SendBufferedData(conf.Perform2$LF);
  if (conf.Perform3 != "") SendBufferedData(conf.Perform3$LF);


  // Send mode +x?
  if (conf.bModeX)
  {
    Log("++ [Mv]: Primary - Sent Mode "$conf.NickName$" +ix");
    SendBufferedData("MODE "$conf.NickName$" +ix"$CRLF);
  }


  if (conf.nInviteMe)
  {
  	Log ("++ [Mv]: Primary - Inviting myself to: "$conf.Channel);
  	if (conf.nQuakenet)
  	  SendBufferedData("PRIVMSG "$conf.SrvxChan$" :INVITE "$conf.Channel$" "$CRLF);
  	else
  	  SendBufferedData("PRIVMSG "$conf.SrvxChan$" :INVITEME "$conf.Channel$" "$CRLF);
  }
  

  Log ("++ [Mv]: Primary - Joining Channel: "$conf.Channel);
  SendBufferedData("JOIN "$conf.Channel$CRLF);
  

  // Execute perform commands - if any, after join.
  if (conf.bDebug)
    Log("++ [Mv Debug]: Primary - Sending Perform, After Join");
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

  // Anti Flood Stuff
  iFloodCurrent += (DeltaTime * (1/GameSpeed));
  if (iFloodCurrent > xAFloodDelay)
   {
    iFloodCurrent = 0;
    GameSpeed = DeathMatchPlus(Level.Game).GameSpeed;
    
    //For live xAFloodDelay value changes :P
    if (conf.bSecondaryLink)
      xAFloodDelay = conf.xAFloodDelay/2;
    else
      xAFloodDelay = conf.xAFloodDelay;
    
    SendLine();
   }

  DoBufferQueueIO();
  
  if (ReadBufferedLine(Line))
    ProcessInput(Line);
}


// FUNCTION ProccessInput / Standard Processing Function
function ProcessInput(string Line)
{
  if (conf.bDebug)
    Log("++ [Mv Debug]: Primary - "$Line);
  
  if (Left(Line, 5) == "PING ")
    SendBufferedData("PONG "$Mid(Line, 5)$CRLF);
}

// TIMER EVENT
event Timer()
{
  if (iTimerType == 10)
    {
      if (conf.bUseLogin)
	SendText("PASS "$conf.Password$LF);
      Log ("++ [Mv]: Primary - Sent PASS");
      iTimerType = 11;
      SetTimer(1, false);
    }

  else if (iTimerType == 11)
    {
      SendText("USER "$UserIdent$" 0 * :"$FullName$LF);
      Log ("++ [Mv]: Primary - Sent USER");
      iTimerType = 12;
      SetTimer(1, false);

    }
  else if (iTimerType == 12)
    {
      SendText("NICK "$conf.NickName$LF);
      Log ("++ [Mv]: Primary - Sent NICK");
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


// Process any Private Messages and do the propriet stuff
function ProcessPrivMsg(string sOrigNick, string sNickFlags, string sDestNick, string sLine)
{
  local string sParams[4], IP;
  local Pawn P;
  local int iFound, j;

  sParams[0] = ChopLeft(ParseDelimited(sLine, " ", 4, FALSE));
  // Channel Events
  if (sDestNick ~= ReporterNick)
    {
      sParams[1] = ChopLeft(ParseDelimited(sLine, " ", 5, FALSE));
      sParams[2] = ChopLeft(ParseDelimited(sLine, " ", 6, TRUE));

      // Send a Message to the Server!
      if ((sParams[0] ~= "say") || (sParams[0] ~= "msg"))
		if (CheckPassword(sParams[1], sOrigNick))
		  BroadCastMessage(sOrigNick$" (IRC): "$sParams[2]);

	// Handle mutate commands
	if (sParams[0] ~= "mutate")
	  if (CheckPassword(sParams[1], sOrigNick))
	  {
	   Spec.ServerMutate(sParams[2]);
	  }

      // Set SrvxChan
      if (sParams[0] ~= "srvxchan")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.SrvxChan = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Srvx Chan to '"$sParams[2]$"'!");
	  }
          
      // Set SrvxName
      if (sParams[0] ~= "srvxname")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.SrvxName = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Srvx Name to '"$sParams[2]$"'!");
	  }
      
      // Set SrvxAccount
      if (sParams[0] ~= "srvxaccount")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.SrvxAccount = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Srvx Account '"$sParams[2]$"'!");
	  }
      
      // Set SrvxPassword
      if (sParams[0] ~= "srvxpassword")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.SrvxPassword = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Srvx Password to '"$sParams[2]$"'!");
	  }

      // Set tBindMap
      if (sParams[0] ~= "bindmap")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.tBindMap = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Bind for Map to '"$sParams[2]$"'!");
	  }
      
      // Set tBindGameInfo
      if (sParams[0] ~= "bindgameinfo")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.tBindGameInfo = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Bind for GameInfo to '"$sParams[2]$"'!");
	  }
      
      // Set tBindSpecs
      if (sParams[0] ~= "bindspecs")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.tBindSpecs = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Bind for Specs to '"$sParams[2]$"'!");
	  }
      
      // Set tBindSpectators
      if (sParams[0] ~= "bindspectators")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.tBindSpectators = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Bind for Spectators to '"$sParams[2]$"'!");
	  }
      
      // Set tBindPlayers
      if (sParams[0] ~= "bindplayers")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.tBindPlayers = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Bind for Players to '"$sParams[2]$"'!");
	  }

      // Set tBindSay
      if (sParams[0] ~= "bindsay")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.tBindSay = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Bind for Say to '"$sParams[2]$"'!");
	  }
      
      // Set jIdent
      if (sParams[0] ~= "ident")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.jIdent = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Ident for Primary to '"$sParams[2]$"'!");
	  }

      // Set jIdent2
      if (sParams[0] ~= "ident2")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.jIdent2 = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Ident for Secondary to '"$sParams[2]$"'!");
	  }

      // Set AdMsg (AdMessage)
      if (sParams[0] ~= "AdMessage")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.AdMessage = sParams[2];
	    conf.SaveConfig();
	    SendNotice(sOrigNick, "Changed Ad Message to '"$sParams[2]$"'!");
	  }

      // Set Red Team Name
      if (sParams[0] ~= "teamred")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
            //set also EUT's and SmartCTF's team variables
	    if (Level.Game.GetPropertyText("RedTeamName") != "")
    	      Level.Game.SetPropertyText("RedTeamName", sParams[2]);
	    conf.teamRed = sParams[2];
	    conf.SaveConfig();
	    Controller.LoadTeamNames();
	    SendNotice(sOrigNick, "Changed Team Name of 'red' to '"$sParams[2]$"'!");
	  }
      
      // Set Blue Team Name
      if (sParams[0] ~= "teamblue")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    // set also EUT's and SmartCTF's team variables
	    if (Level.Game.GetPropertyText("BlueTeamName") != "")
    	      Level.Game.SetPropertyText("BlueTeamName", sParams[2]);
	    conf.teamBlue = sParams[2];
	    conf.SaveConfig();
	    Controller.LoadTeamNames();
	    SendNotice(sOrigNick, "Changed Team Name of 'blue' to '"$sParams[2]$"'!");
	  }

      // Set Green Team Name
      if (sParams[0] ~= "teamgreen")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.teamGreen = sParams[2];
	    conf.SaveConfig();
	    Controller.LoadTeamNames();
	    SendNotice(sOrigNick, "Changed Team Name of 'green' to '"$sParams[2]$"'!");
	  }

      // Set Gold Team Name
      if (sParams[0] ~= "teamgold")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.teamGold = sParams[2];
	    conf.SaveConfig();
	    Controller.LoadTeamNames();
	    SendNotice(sOrigNick, "Changed Team Name of 'gold' to '"$sParams[2]$"'!");
	  }
      
      // Team Name Reset
      if (sParams[0] ~= "teamsreset")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    conf.teamRed = "Red Team";
	    conf.teamBlue = "Blue Team";
	    conf.teamGreen = "Green Team";
	    conf.teamGold = "Gold Team";
	    conf.SaveConfig();
	    Controller.LoadTeamNames();
	    SendNotice(sOrigNick, "All Team Names have been reset to standard values!");
	  }

      // Mute Reporter
      if (sParams[0] ~= "mute")
	if (CheckPassword(sParams[1], sOrigNick))
	  {
	    if (!conf.bMuted)
	      self.SendMessage(conf.colHigh$"*** "$conf.colHead$"Output has been muted by "$sOrigNick);
	    conf.bMuted = !conf.bMuted;
	    conf.SaveConfig();
	    if (!conf.bMuted)
	      self.SendMessage(conf.colHigh$"*** "$conf.colHead$"Output has been un-muted by "$sOrigNick);
	  }

      // Enable / Disable Public Commands
      if (sParams[0] ~= "pubcoms")
	if (CheckPassword(sParams[1], sOrigNick)) {
	  if (!conf.bPublicComs)
	    self.SendMessage(conf.colHigh$"*** "$conf.colHead$"Public Commands have been enabled by "$sOrigNick);
	  conf.bPublicComs = !conf.bPublicComs;
	  conf.SaveConfig();
	  if (!conf.bPublicComs)
	    self.SendMessage(conf.colHigh$"*** "$conf.colHead$"Public Commands have been disabled by "$sOrigNick);
	}

    // Change Reporter's NickName
    if (sParams[0] ~= "nick")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  SendNotice(sOrigNick, "Changing Reporter's Nick to: "$sParams[2]);
	  conf.NickName = sParams[2];
	  conf.SaveConfig();
	  SendBufferedData("NICK "$sParams[2]$CRLF);
	}

    // Change Reporter's Channel
    if (sParams[0] ~= "channel")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  SendNotice(sOrigNick, "Switching Channel to: "$sParams[2]);
	  JoinChannel(sParams[2]);
	  Link2.JoinChannel(sParams[2]);
	  SendBufferedData("PART "$conf.Channel$CRLF);
	  conf.Channel = sParams[2];
	  conf.SaveConfig();
	}

    // Change Reporter's Server
    if (sParams[0] ~= "server")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  SendNotice(sOrigNick, "Switching IRC-Server to: "$sParams[2]);
	  conf.ServerAddr = sParams[2];
	  conf.SaveConfig();
	  RelaunchReporter("Changing IRC-Server to "$sParams[2]);
	  Link2.RelaunchReporter("");
	}

    // GOD, FUCK EPICGAMES!!
    // Change Reporter's Port
    //if (sParams[0] ~= "serverport")
    //  if (CheckPassword(sParams[1], sOrigNick))
    //    {
    //      sParams[2] = ChopLeft(ParseDelimited(sLine, " ", 6, FALSE));
    //      SendNotice(sOrigNick, "Changing Port to: "$sParams[2]);
    //      conf.ServerPort = sParams[2];
    //      conf.SaveConfig();
    //    }

    // Change Reporter's Password
    if (sParams[0] ~= "pwd")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  sParams[2] = ChopLeft(ParseDelimited(sLine, " ", 6, FALSE));
	  SendNotice(sOrigNick, "Changing Admin Password to: "$sParams[2]);
	  conf.AdminPassword = sParams[2];
	  conf.SaveConfig();
	}

    // Get OP across the bot!
    if (sParams[0] ~= "op")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  SendBufferedData("MODE "$conf.Channel$" +o :"$sOrigNick$CRLF);
	  SendNotice(sOrigNick, "Oped you on "$conf.Channel$"...");
	}

    // Get HOP across the bot!
    if (sParams[0] ~= "hop")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  SendBufferedData("MODE "$conf.Channel$" +h :"$sOrigNick$CRLF);
	  SendNotice(sOrigNick, "Half-Oped you on "$conf.Channel$"...");
	}

    // Get VOICE across the bot!
    if (sParams[0] ~= "voice")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  SendBufferedData("MODE "$conf.Channel$" +v :"$sOrigNick$CRLF);
	  SendNotice(sOrigNick, "Voiced you on "$conf.Channel$"...");
	}

    // Servertravel
    if (sParams[0] ~= "servertravel")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  SendNotice(sOrigNick, "Travelling to: "$sParams[2]);
	  BroadcastMessage("*** "$sOrigNick$" switches map to "$sParams[2]$" from IRC");
	  ConsoleCommand("servertravel "$sParams[2]);
	}

    // Kick Player!!
    if (sParams[0] ~= "kick" || sParams[0] ~= "kickban")
      if (CheckPassword(sParams[1], sOrigNick))
	{
	  // Now this is some complicated stuff here....
	  iFound = 0;
	  for (P = Level.PawnList; P!=None; P=P.NextPawn)
	    {
	      if (PlayerPawn(P) != none &&  P.PlayerReplicationInfo != none &&  NetConnection(PlayerPawn(P).Player) != none)
		{
		  if (sParams[2] ~= P.PlayerReplicationInfo.PlayerName)
		    {
		      if (sParams[0] ~= "kickban")
			{
			  // do Banning stuff here
			  IP = PlayerPawn(P).GetPlayerNetworkAddress();
			  if (Level.Game.CheckIPPolicy(IP))
			    {
			      IP = Left(IP, InStr(IP, ":"));
			      Log("++ [Mv]: Adding IP Ban for: "$IP);
			      for(j=0;j<50;j++)
				if (Level.Game.IPPolicies[j] == "")
				  break;
			      if (j < 50)
				Level.Game.IPPolicies[j] = "DENY,"$IP;
			      Level.Game.SaveConfig();
			      SendNotice(sOrigNick, "Banning IP: "$IP);
			    }
			  // END OF BANNINGCODE
			}  // END if KICKBAN
		      SendNotice(sOrigNick, "Kicking player: "$sParams[2]);
		      P.Destroy();
		      iFound = 1;
		    }
		}
	    }
	  if (iFound == 0)
            SendNotice(sOrigNick, "Sorry, couldn't find "$sParams[2]$" on server!");
	}

    }

  if ((sDestNick ~= conf.Channel) && (!conf.bMuted) && (conf.bPublicComs))
    {
      sParams[1] = ChopLeft(ParseDelimited(sLine, " ", 5, TRUE));

                if (conf.bUsetBind)
                  {
                        if (sParams[0] == conf.tBindMap)
                           Controller.Spectator.Stats.QueryMap(sOrigNick);

                        if (sParams[0] == conf.tBindGameInfo)
                           Controller.Spectator.Stats.QueryInfo(sOrigNick);

                        if (sParams[0] == conf.tBindSpecs)
                           Controller.Spectator.Stats.QuerySpecs(sOrigNick);

                        if (sParams[0] == conf.tBindSpectators)
                           Controller.Spectator.Stats.QuerySpecs(sOrigNick);

                        if (sParams[0] == conf.tBindPlayers)
                           Controller.Spectator.Stats.QueryPlayers(sOrigNick);

                        if (sParams[0] == conf.tBindSay)
                          {
                                 if (conf.bPublicSay)
                                   {
                                          if (conf.xCensorText)
                                              CensorTextSrv(sOrigNick$" (IRC): "$Lower(sParams[1]));
                                          else
                                            {
                                              if (conf.xAllowShouting)
                                                BroadCastMessage(sOrigNick$" (IRC): "$sParams[1]);
                                              else
                                                BroadCastMessage(sOrigNick$" (IRC): "$Lower(sParams[1]));
                                            }
                                   }
                                 else
                                   SendNotice(sOrigNick, "Sorry, this function is disabled on this server.");
                          }
                  }
                else
                  {
                        if (sParams[0] == "!map")
                            Controller.Spectator.Stats.QueryMap(sOrigNick);

                        if (sParams[0] == "!gameinfo")
                            Controller.Spectator.Stats.QueryInfo(sOrigNick);

                        if (sParams[0] == "!specs")
                            Controller.Spectator.Stats.QuerySpecs(sOrigNick);

                        if (sParams[0] == "!spectators")
                            Controller.Spectator.Stats.QuerySpecs(sOrigNick);

                        if (sParams[0] == "!players")
                            Controller.Spectator.Stats.QueryPlayers(sOrigNick);

                        if (sParams[0] == "!say") 
                          {
                                 if (conf.bPublicSay)
                                   {
                                          if (conf.xCensorText)
                                              CensorTextSrv(sOrigNick$" (IRC): "$Lower(sParams[1]));
                                          else
                                            {
                                              if (conf.xAllowShouting)
                                                BroadCastMessage(sOrigNick$" (IRC): "$sParams[1]);
                                              else
                                                BroadCastMessage(sOrigNick$" (IRC): "$Lower(sParams[1]));
			                    }
                                   }
                                 else
                                   SendNotice(sOrigNick, "Sorry, this function is disabled on this server.");
                          }
                  }
    }
}

// Remove any occurences of ": " on the left side of a string and return the clear string!
function string ChopLeft(string Text)
{
  while(Text != "" && InStr(": ", Left(Text, 1)) != -1)
    Text = Mid(Text, 1);
  return Text;
}

// Censor
static final function string Lower(coerce string Text)
  {
  local int IndexChar;
  for (IndexChar = 0; IndexChar < Len(Text); IndexChar++)
    if (Mid(Text, IndexChar, 1) >= "A" &&
        Mid(Text, IndexChar, 1) <= "Z")
      Text = Left(Text, IndexChar) $ Chr(Asc(Mid(Text, IndexChar, 1)) + 32) $ Mid(Text, IndexChar + 1);
  return Text;
  }
function CensorTextSrv(string Text)
{
  Text = ReplaceText(Text,"anal","****");
  Text = ReplaceText(Text,"asshole","*******");
  Text = ReplaceText(Text,"asstard","*******");
  Text = ReplaceText(Text,"assclown","*******");
  Text = ReplaceText(Text,"bitch","*****");
  Text = ReplaceText(Text,"b1tch","*****");
  Text = ReplaceText(Text,"biotch","******");
  Text = ReplaceText(Text,"bullshit","********");
  Text = ReplaceText(Text,"cock","****");
  Text = ReplaceText(Text,"clitoris","********");
  Text = ReplaceText(Text,"clit","****");
  Text = ReplaceText(Text,"cornhole","********");
  Text = ReplaceText(Text,"cunt","****");
  Text = ReplaceText(Text,"cuntface","********");
  Text = ReplaceText(Text,"damnit","******");
  Text = ReplaceText(Text,"damn","****");
  Text = ReplaceText(Text,"dick","****");
  Text = ReplaceText(Text,"faggot","******");
  Text = ReplaceText(Text,"fucked","******");
  Text = ReplaceText(Text,"fuckface","********");
  Text = ReplaceText(Text,"fucking","*******");
  Text = ReplaceText(Text,"fuking","******");
  Text = ReplaceText(Text,"facking","*******");
  Text = ReplaceText(Text,"fuck","****");
  Text = ReplaceText(Text,"fuk","***");
  Text = ReplaceText(Text,"gaydar","******");
  Text = ReplaceText(Text,"gay","***");
  Text = ReplaceText(Text,"genitalia","*********");
  Text = ReplaceText(Text,"hoe","***");
  Text = ReplaceText(Text,"homo","****");
  Text = ReplaceText(Text,"h0mo","****");
  Text = ReplaceText(Text,"hom0","****");
  Text = ReplaceText(Text,"h0m0","****");
  Text = ReplaceText(Text,"nigga","*****");
  Text = ReplaceText(Text,"nigger","******");
  Text = ReplaceText(Text,"lube","****");
  Text = ReplaceText(Text,"lame","****");
  Text = ReplaceText(Text,"lamer","*****");
  Text = ReplaceText(Text,"masturbate","**********");
  Text = ReplaceText(Text,"masturbation","************");
  Text = ReplaceText(Text,"penis","*****");
  Text = ReplaceText(Text,"pen0r","*****");
  Text = ReplaceText(Text,"piss","****");
  Text = ReplaceText(Text,"pussy","*****");
  Text = ReplaceText(Text,"queer","*****");
  Text = ReplaceText(Text,"retarded","********");
  Text = ReplaceText(Text,"retard","******");
  Text = ReplaceText(Text,"rimjob","******");
  Text = ReplaceText(Text,"shitty","******");
  Text = ReplaceText(Text,"shits","****");
  Text = ReplaceText(Text,"shit","****");
  Text = ReplaceText(Text,"$h1t","****");
  Text = ReplaceText(Text,"$hit","****");
  Text = ReplaceText(Text,"sh1t","****");
  Text = ReplaceText(Text,"slut","****");
  Text = ReplaceText(Text,"suck","****");
  Text = ReplaceText(Text,"sucks","*****");
  Text = ReplaceText(Text,"spic","****");
  Text = ReplaceText(Text,"sp1c","****");
  Text = ReplaceText(Text,"$p1c","****");
  Text = ReplaceText(Text,"$pic","****");
  Text = ReplaceText(Text,"semen","*****");
  Text = ReplaceText(Text,"s3m3n","*****");
  Text = ReplaceText(Text,"sem3n","*****");
  Text = ReplaceText(Text,"s3men","*****");
  Text = ReplaceText(Text,"sexual","******");
  Text = ReplaceText(Text,"intercourse","***********");
  Text = ReplaceText(Text,"vagina","******");
  Text = ReplaceText(Text,"whore","*****");
  Text = ReplaceText(Text,"wh0r3","*****");
  Text = ReplaceText(Text,"wh0re","*****");
  Text = ReplaceText(Text,"whor3","*****");
  Text = ReplaceText(Text,"ass","***");
  Text = ReplaceText(Text,"cum","***");
  Text = ReplaceText(Text,"fags","****");
  Text = ReplaceText(Text,"fag","***");
  Text = ReplaceText(Text,"sex","***");
  BroadCastMessage(Text);
}

// Replace for censor
static final function string ReplaceText(coerce string Text, coerce string Replace, coerce string With)
{
    local int i;
    local string Output;
    
    i = InStr(Text, Replace);
    while (i != -1) {   
        Output = Output $ Left(Text, i) $ With;
        Text = Mid(Text, i + Len(Replace)); 
        i = InStr(Text, Replace);
    }
    Output = Output $ Text;
    return Output;
}


// Check the Admin Password!!
function bool CheckPassword(string sTestPwd, string sNick)
{
  if (sTestPwd == conf.AdminPassword)
    return TRUE;
  else
    {
      SendNotice(sNick, "*** Error: Wrong password provided.");
      return FALSE;
    }
}

// Join a Channel
function JoinChannel(string Channel)
{
  if (bIsConnected)
    if (Left(Channel, 1) == "#")
      SendBufferedData("JOIN "$Channel$CRLF);
}

// Send a Message
function SendMessage(string msg)
{
  if ((conf.bMuted == FALSE) && (bIsConnected))
      AddLine("PRIVMSG "$conf.Channel$" :"$msg$CRLF);
}

// Send a Notice
function SendNotice(string nick, string msg)
{
  if (bIsConnected)
    AddLine("NOTICE "$nick$" :"$msg$CRLF);
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

function AddLine(string S)
{
  local int ilHead;
  ilHead = (ifHead + 1) % 32;
  if (ilHead != ifFoot) {
    sQueue[ifHead] = S;
    ifHead = ilHead;
    ifCount = Min(ifCount + 1, 32);
  }
}

function SendLine()
{
	if (ifCount == 0 || (!bIsConnected && !Link2.bIsConnected))
		return;
	if (!SwitchLink || !conf.bSecondaryLink)
    {
		if (bIsConnected)
			SendBufferedData(sQueue[ifFoot]);
		else
			Link2.SendBufferedData(sQueue[ifFoot]);
		SwitchLink=True;
	}
	else
    {
    	if (Link2.bIsConnected)
			Link2.SendBufferedData(sQueue[ifFoot]);
		else
			SendBufferedData(sQueue[ifFoot]);
		SwitchLink=False;
    }

	ifFoot = (ifFoot + 1) % 32;
	ifCount = Max(ifCount - 1, 0);
}

function ResetQueue()
{
  ifHead  = 0;
  ifFoot  = 0;
  ifCount = 0;
}

defaultproperties
{
     ReporterNick="mvr"
     FullName="mavericks reporter"
     iFloodCount=1.500000
}
