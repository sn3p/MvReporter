//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//  Gambino Edition by sn3p (snap@gambino.nl)                        /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterMutator expands Mutator;

var MvReporterConfig conf;
var MvReporterIRCLink Link;
var MvReporterIRCLink2 Link2;
var MvReporter Controller;

function Mutate(string MutateString, PlayerPawn Sender)
{
	local string CommandString;
	local String ValueString;

	if ( NextMutator != None )
		NextMutator.Mutate(MutateString, Sender);

	if (Left(MutateString, 9) == "mvrstatus")
        	Sender.ClientMessage("True");

	if (Sender.bAdmin)
	{
		if (Left(MutateString, 4) ~= "mvr ")
		{
			CommandString=Mid(MutateString, 4);
			if (Left(CommandString , 5) ~= "START")
			{
				if (!Link.bIsConnected)
					Link.Connect(Controller, conf);
				if (conf.bSecondaryLink && !Link2.bIsConnected)
					Link2.Connect(Controller, conf);
				Sender.ClientMessage("Done.");

			}
			else if (Left(CommandString , 4) ~= "STOP")
			{
				Link.Disconnect();
				if (conf.bSecondaryLink)
					Link2.Disconnect();
				Sender.ClientMessage("Done.");
			}
			else if (Left(CommandString, 7) ~= "RESTART")
			{
				Link.RelaunchReporter("Reporter restart ...");
				if (conf.bSecondaryLink)
					Link2.RelaunchReporter("Reporter restart ...");
				Sender.ClientMessage("Done.");
			}
			else if (Left(CommandString, 6) ~= "STATUS")
			{
				if (conf.bSecondaryLink)
				{
					if (Link.bIsConnected && Link2.bIsConnected)
						Sender.ClientMessage("Connected");
					else if (Link.bIsConnected && !Link2.bIsConnected)
						Sender.ClientMessage("Link2 disconnected");
					else
						Sender.ClientMessage("Disconnected");
				}
				else
				{
					if (Link.bIsConnected)
						Sender.ClientMessage("Connected");
					else
						Sender.ClientMessage("Disconnected");
				}
			}
			else if (Left(CommandString, 10) ~= "MUTEOUTPUT")
			{
				if (!conf.bMuted)
					Link.SendMessage(conf.colHigh$"*** "$conf.colHead$"Output has been muted.");
				conf.bMuted = !conf.bMuted;
				conf.SaveConfig();
				if (!conf.bMuted)
					Link.SendMessage(conf.colHigh$"*** "$conf.colHead$"Output has been un-muted.");
				Sender.ClientMessage("Applied.");
			}
			//For SuperWebAdmin compatibility
			else if (Left(CommandString, 10) ~= "MUTESTATUS")
			{
				if (conf.bMuted)
					Sender.ClientMessage("1");
				else
					Sender.ClientMessage("0");
			}
			//For SuperWebAdmin compatibility
			else if (Left(CommandString, 13) ~= "PUBCOMSSTATUS")
			{
				if (conf.bPublicComs)
					Sender.ClientMessage("1");
				else
					Sender.ClientMessage("0");
			}
			else if (Left(CommandString, 7) ~= "PUBCOMS")
			{
				if (!conf.bPublicComs)
					Link.SendMessage(conf.colHigh$"*** "$conf.colHead$"Public Commands have been enabled.");
				conf.bPublicComs = !conf.bPublicComs;
				conf.SaveConfig();
				if (!conf.bPublicComs)
					Link.SendMessage(conf.colHigh$"*** "$conf.colHead$"Public Commands have been disabled.");
				Sender.ClientMessage("Applied.");
			}
			else if (Left(CommandString, 4) ~= "SET ")
			{
				CommandString=Mid(CommandString, 4);
				ValueString=SepRight(CommandString);
				switch(SepLeft(Caps(CommandString))$" ")
				{
					case "ADMINPASSWORD ":
						conf.AdminPassword = ValueString;
						Sender.ClientMessage("Applied.");break;
					case "SERVERADDR ":
						conf.ServerAddr = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "SERVERPORT ":
						conf.ServerPort = int(ValueString);
						Sender.ClientMessage("Applied."); break;
					case "CHANNEL ":
						conf.Channel = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "NICKNAME ":
						conf.Nickname = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "NICKNAME2 ":
						conf.Nickname2 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "IDENT ":
						conf.jIdent = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "IDENT2 ":
						conf.jIdent2 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "USERNAME ":
						conf.Username = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "USERNAME2 ":
						conf.Username2 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "PASSWORD ":
						conf.Password = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "PASSWORD2 ":
						conf.Password2 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "SRVXCHAN ":
						conf.SrvxChan = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "SRVXNAME ":
						conf.SrvxName = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "SRVXACCOUNT ":
						conf.SrvxAccount = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "SRVXPASSWORD ":
						conf.SrvxPassword = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TBINDMAP ":
						conf.tBindMap = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TBINDGAMEINFO ":
						conf.tBindGameInfo = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TBINDSPECS ":
						conf.tBindSpecs = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TBINDSPECTATORS ":
						conf.tBindSpectators = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TBINDPLAYERS ":
						conf.tBindPlayers = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TBINDSAY ":
						conf.tBindSay = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "PERFORM1 ":
						conf.Perform1 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "PERFORM2 ":
						conf.Perform2 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "PERFORM3 ":
						conf.Perform3 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "PERFORM4 ":
						conf.Perform4 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "PERFORM5 ":
						conf.Perform5 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "PERFORM6 ":
						conf.Perform6 = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "ADMESSAGE ":
						conf.AdMessage = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "BUSELOGIN ":
						if (ValueString == "True")
							conf.bUseLogin = True;
						else if (ValueString == "False" || ValueString=="")
							conf.bUseLogin = False;
						Sender.ClientMessage("Applied."); break;
					case "BMODEX ":
						if (ValueString == "True")
							conf.bModeX = True;
						else if (ValueString == "False" || ValueString=="")
							conf.bModeX = False;
						Sender.ClientMessage("Applied."); break;
					case "XMODEM ":
						if (ValueString == "True")
							conf.xModeM = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xModeM = False;
						Sender.ClientMessage("Applied."); break;
					case "BUSESRVX ":
						if (ValueString == "True")
							conf.bUseSrvx = True;
						else if (ValueString == "False" || ValueString=="")
							conf.bUseSrvx = False;
						Sender.ClientMessage("Applied."); break;
					case "BUSETBIND ":
						if (ValueString == "True")
							conf.bUsetBind = True;
						else if (ValueString == "False" || ValueString=="")
							conf.bUsetBind = False;
						Sender.ClientMessage("Applied."); break;
					case "BSECONDARYLINK ":
						if (ValueString == "True")
							conf.bSecondaryLink = True;
						else if (ValueString == "False" || ValueString=="")
							conf.bSecondaryLink = False;
						Sender.ClientMessage("Applied."); break;
					case "TEAMRED ":
						// set also EUT's and SmartCTF's team variables
						if (Level.Game.GetPropertyText("RedTeamName") != "")
    						  Level.Game.SetPropertyText("RedTeamName", ValueString);
                                                conf.TeamRed = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TEAMBLUE ":
						// set also EUT's and SmartCTF's team variables
						if (Level.Game.GetPropertyText("BlueTeamName") != "")
    						  Level.Game.SetPropertyText("BlueTeamName", ValueString);
						conf.TeamBlue = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TEAMGREEN ":
						conf.TeamGreen = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "TEAMGOLD ":
						conf.TeamGold = ValueString;
						Sender.ClientMessage("Applied."); break;
					case "BEXTRA1ON1STATS ":
						if (ValueString == "True")
							conf.bExtra1on1Stats = True;
						else if (ValueString == "False" || ValueString=="")
							conf.bExtra1on1Stats = False;
						Sender.ClientMessage("Applied."); break;
					case "BPUBLICSAY ":
						if (ValueString == "True")
							conf.bPublicSay = True;
						else if (ValueString == "False" || ValueString=="")
							conf.bPublicSay = False;
						Sender.ClientMessage("Applied."); break;


					case "ENHANCEDSPREES ":
						if (ValueString == "True")
							conf.xEnhancedSprees = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xEnhancedSprees = False;
						Sender.ClientMessage("Applied."); break;
					case "REPORTSPREES ":
						if (ValueString == "True")
							conf.xReportSprees = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xReportSprees = False;
						Sender.ClientMessage("Applied."); break;
					case "REPORTBSPREES ":
						if (ValueString == "True")
							conf.xReportBSprees = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xReportBSprees = False;
						Sender.ClientMessage("Applied."); break;
					case "REPORTESPREES ":
						if (ValueString == "True")
							conf.xReportESprees = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xReportESprees = False;
						Sender.ClientMessage("Applied."); break;
					case "REPORTMMI ":
						if (ValueString == "True")
							conf.xReportMMI = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xReportMMI = False;
						Sender.ClientMessage("Applied."); break;
					case "DEFAULTKILLS ":
						if (ValueString == "True")
							conf.xDefaultKills = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xDefaultKills = False;
						Sender.ClientMessage("Applied."); break;
					case "CENSORTEXT ":
						if (ValueString == "True")
							conf.xCensorText = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xCensorText = False;
						Sender.ClientMessage("Applied."); break;
					case "ALLOWSHOUTING ":
						if (ValueString == "True")
							conf.xAllowShouting = True;
						else if (ValueString == "False" || ValueString=="")
							conf.xAllowShouting = False;
						Sender.ClientMessage("Applied."); break;
					case "INVITEME ":
						if (ValueString == "True")
							conf.nInviteMe = True;
						else if (ValueString == "False" || ValueString=="")
							conf.nInviteMe = False;
						Sender.ClientMessage("Applied."); break;
					case "QUAKENET ":
						if (ValueString == "True")
							conf.nQuakenet = True;
						else if (ValueString == "False" || ValueString=="")
							conf.nQuakenet = False;
						Sender.ClientMessage("Applied."); break;
					case "USEIDENT ":
						if (ValueString == "True")
							conf.jUseIdent = True;
						else if (ValueString == "False" || ValueString=="")
							conf.jUseIdent = False;
						Sender.ClientMessage("Applied."); break;
					case "SILENT ":
						if (ValueString == "True")
							conf.bSilent = True;
						else if (ValueString == "False" || ValueString=="")
							conf.bSilent = False;
						Sender.ClientMessage("Applied."); break;

				}
				conf.SaveConfig();
			}
			else if (Left(CommandString, 4) ~= "GET ")
			{
				CommandString=Mid(CommandString, 4);
				switch(Caps(CommandString))
				{
					// rather not send password
                                        // case "ADMINPASSWORD":
					//	Sender.ClientMessage(conf.AdminPassword); break;
					case "SERVERADDR":
						Sender.ClientMessage(conf.ServerAddr); break;
					case "SERVERPORT":
						Sender.ClientMessage(conf.ServerPort); break;
					case "CHANNEL":
						Sender.ClientMessage(conf.Channel); break;
					case "NICKNAME":
						Sender.ClientMessage(conf.Nickname); break;
					case "NICKNAME2":
						Sender.ClientMessage(conf.Nickname2); break;
					case "USERNAME":
						Sender.ClientMessage(conf.Username); break;
					case "USERNAME2":
						Sender.ClientMessage(conf.Username2); break;
					case "IDENT":
						Sender.ClientMessage(conf.jIdent); break;
					case "IDENT2":
						Sender.ClientMessage(conf.jIdent2); break;
					case "PASSWORD":
						Sender.ClientMessage(conf.Password); break;
					case "PASSWORD2":
						Sender.ClientMessage(conf.Password2); break;
					case "SRVXCHAN":
						Sender.ClientMessage(conf.SrvxChan); break;
					case "SRVXNAME":
						Sender.ClientMessage(conf.SrvxName); break;
					case "SRVXACCOUNT":
						Sender.ClientMessage(conf.SrvxAccount); break;
					case "SRVXPASSWORD":
						Sender.ClientMessage(conf.SrvxPassword); break;
					case "TBINDMAP":
						Sender.ClientMessage(conf.tBindMap); break;
					case "TBINDGAMEINFO":
						Sender.ClientMessage(conf.tBindGameInfo); break;
					case "TBINDSPECS":
						Sender.ClientMessage(conf.tBindSpecs); break;
					case "TBINDSPECTATORS":
						Sender.ClientMessage(conf.tBindSpectators); break;
					case "TBINDPLAYERS":
						Sender.ClientMessage(conf.tBindPlayers); break;
					case "TBINDSAY":
						Sender.ClientMessage(conf.tBindSay); break;
					case "PERFORM1":
						Sender.ClientMessage(conf.Perform1); break;
					case "PERFORM2":
						Sender.ClientMessage(conf.Perform2); break;
					case "PERFORM3":
						Sender.ClientMessage(conf.Perform3); break;
					case "PERFORM4":
						Sender.ClientMessage(conf.Perform4); break;
					case "PERFORM5":
						Sender.ClientMessage(conf.Perform5); break;
					case "PERFORM6":
						Sender.ClientMessage(conf.Perform6); break;
					case "ADMESSAGE":
						Sender.ClientMessage(conf.AdMessage); break;
					case "BUSELOGIN":
						Sender.ClientMessage(string(conf.bUseLogin)); break;
					case "BMODEX":
						Sender.ClientMessage(string(conf.bModeX)); break;
					case "XMODEM":
						Sender.ClientMessage(string(conf.xModeM)); break;
					case "BUSESRVX":
						Sender.ClientMessage(string(conf.bUseSrvx)); break;
					case "BUSETBIND":
						Sender.ClientMessage(string(conf.bUsetBind)); break;
					case "BSECONDARYLINK":
						Sender.ClientMessage(string(conf.bSecondaryLink)); break;
					case "TEAMRED":
						Sender.ClientMessage(conf.TeamRed); break;
					case "TEAMBLUE":
						Sender.ClientMessage(conf.TeamBlue); break;
					case "TEAMGREEN":
						Sender.ClientMessage(conf.TeamGreen); break;
					case "TEAMGOLD":
						Sender.ClientMessage(conf.TeamGold); break;
					case "BEXTRA1ON1STATS":
						Sender.ClientMessage(string(conf.bExtra1on1Stats)); break;
					case "BPUBLICSAY":
						Sender.ClientMessage(string(conf.bPublicSay)); break;

                                        case "ENHANCEDSPREES":
						Sender.ClientMessage(string(conf.xEnhancedSprees)); break;
					case "REPORTSPREES":
						Sender.ClientMessage(string(conf.xReportSprees)); break;
					case "REPORTBSPREES":
						Sender.ClientMessage(string(conf.xReportBSprees)); break;
					case "REPORTESPREES":
						Sender.ClientMessage(string(conf.xReportESprees)); break;
					case "REPORTMMI":
						Sender.ClientMessage(string(conf.xReportMMI)); break;
					case "DEFAULTKILLS":
						Sender.ClientMessage(string(conf.xDefaultKills)); break;
					case "CENSORTEXT":
						Sender.ClientMessage(string(conf.xCensorText)); break;
					case "ALLOWSHOUTING":
						Sender.ClientMessage(string(conf.xAllowShouting)); break;
					case "INVITEME":
						Sender.ClientMessage(string(conf.nInviteMe)); break;
					case "QUAKENET":
						Sender.ClientMessage(string(conf.nQuakenet)); break;
					case "USEIDENT":
						Sender.ClientMessage(string(conf.jUseIdent)); break;
				}
			}
		}
	}
}

function string SepLeft(string Str)
{
	local int StrLenght;
	local int StrTemp;

	StrLenght=Len(Str);

	for(StrTemp=1;StrTemp<StrLenght;StrTemp++)
	{
		if (Right(Left(Str, StrTemp),1)==" ")
			break;
	}
	return Left(Str, StrTemp-1);
}

function string SepRight(string Str)
{
	local int StrLenght;
	local int StrTemp;

	StrLenght=Len(Str);

	for(StrTemp=1;StrTemp<StrLenght;StrTemp++)
	{
		if (Right(Left(Str, StrTemp),1)==" ")
			break;
	}
	return Right(Str, StrLenght-StrTemp);
}

defaultproperties
{
}
