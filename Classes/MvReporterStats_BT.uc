//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//  Gambino Edition by sn3p (snap@gambino.nl)                        /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterStats_BT expands MvReporterStats_TDM;

// Variables to store the Name & Type of the Last Frag (& the message)
var string lastMessage, lastKiller, lastVictim;
var int lastSwitch;
var string droppedName, droppedMessage;
var bool isStateDropping;
var string DiedMsg;

// Override InLocalizedMessage Function
function InLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  local string sHigh, Player_1, Player_2, TmpStr;
  local int Team;
  sHigh = "";

  // *** SUDDEN DEATH / TEAM CHANGE ***
  if (ClassIsChildOf(Message, class'BotPack.DeathMatchMessage'))
    {
      switch(Switch)
	{
	  // Overtime :)
	case 0:
	  SendIRCMessage(GetColoredMessage("", conf.colHigh, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  return;
	  // Team Change
	case 3:
	  SendIRCMessage(GetColoredMessage("* ", conf.colGen, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  return;
	}
    }

  // *** FRAG Messages ***
  if (ClassIsChildOf(Message, class'BotPack.DeathMessagePlus'))
    {
      // Save our message (maybe we need it l8er)
	if (RelatedPRI_2 == None)
	{
	      lastVictim = RelatedPRI_1.PlayerName;
	      Team = RelatedPRI_1.Team;
	}
	else
	{
	      lastVictim = RelatedPRI_2.PlayerName;
	      Team = RelatedPRI_2.Team;
	}
      lastSwitch = Switch;

      if (RelatedPRI_2 != None && RelatedPRI_1 != None)
      {
         if (RelatedPRI_2.Team != RelatedPRI_1.Team)
	      lastMessage = GetColoredMessage("", conf.colHead, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
      }
      else
      {
         TmpStr = Message.static.GetString( Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	 if (InStr(TmpStr, " was slimed.") != -1 || InStr(TmpStr, " was incinerated.") != -1)
	   lastMessage = GetColoredMessage("", conf.colHead, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	 else
	   lastMessage = conf.colHead$GetTeamColor(Team)$lastVictim$ircClear$conf.ColHead@"has died !";
      }
      DiedMsg = lastMessage;
      SetTimer(0.05, false);
      SetTimer(3, TRUE);
      return;
    }

  // *** CTF Messages ***
  if (ClassIsChildOf(Message, class'BotPack.CTFMessage'))
    {
      switch (Switch)
	{
	  // The Flag has been captured!
	case 0:
	  SendIRCMessage(conf.colGen$ircUnderline$Message.static.GetString( Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  SendScoreLine("New Score: ");
	  return;
	  // Dropped the Flag / Just store the Message to get it shown @ the next frag
	case 6:
          SendIRCMessage(conf.colGen$ircUnderline$Message.static.GetString( Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  break;
	case 2:
	  isStateDropping = TRUE;
	  droppedName = RelatedPRI_1.PlayerName;
	  droppedMessage = conf.colGen$Message.static.GetString( Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	  break;
	default:
	  SendIRCMessage(conf.colGen$Message.static.GetString( Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  break;
	}
    }
    if (Switch==0)
    {
	  DiedMsg="";
	  droppedMessage="";
    	  SendIRCMessage(conf.colGen$ircUnderline$GetTeamColor(RelatedPRI_1.Team)$RelatedPRI_1.PlayerName$ircClear$conf.ColHead$ircUnderline@"has captured the flag !"$ircClear$conf.ColHead$" (Best Time: "$ProcessScore(RelatedPRI_1.Score)$")");
	  SendScoreLine("New Score: ");
	  return;
    }
}


// Override Game Over event
function OnGameOver()
{
  SendIRCMessage(conf.colHigh$"Game has ended!");
  SendScoreBoard("** Final Score Information:", TRUE);
}

// Override Score Details
function OnScoreDetails()
{
  local PlayerReplicationInfo lPRI, BestPRI;
  local CTFFlag lFLAG;
  local int i;

  SendScoreBoard("** Current Score: ");

  // Search for Flag Carriers and spamm them
  for (i = 0; i < 32; i++)
    {
      if (TGRI.PRIArray[i] == none || TGRI.PRIArray[i].bIsSpectator)
      	continue;
      lPRI = TGRI.PRIArray[i];
      if (bestPRI == None)
      	bestPRI = lPRI;
      else if ( !bBTScores && bestPRI.Score <= lPRI.Score )
	bestPRI = lPRI;
      else if ( bBTScores && bestPRI.Score >= lPRI.Score )
        bestPRI = lPRI;

      lFLAG = CTFFlag(lPRI.HasFlag);
      if (lFLAG != none)
	    SendIRCMessage(">> "$conf.colHead$lPRI.PlayerName$" has the "$conf.sTeams[lFLAG.Team]$" flag!");
    }
  if (bBTScores && bestPRI.Score!=0)
	  SendIRCMessage(">> " $ conf.colHead $ bestPRI.PlayerName $ " has the best CapTime -"$conf.colHigh$" "$ProcessScore(bestPRI.Score)$conf.colHead$" !");
}


// Send the CTF ScoreLine
function SendScoreLine(string sPreFix)
{
  local int iScore[4];
  SendIRCMessage(conf.colGen$sPreFix$GetTeamColor(0)$conf.sTeams[0]$" "$string(int(TeamGamePlus(Level.Game).Teams[0].Score))$ircColor$":"$GetTeamColor(1)$ircBold$ircBold$string(int(TeamGamePlus(Level.Game).Teams[1].Score))$" "$conf.sTeams[1]);
}


// Send the CTF ScoreBoard!
function SendScoreBoard(string sHeadLine, optional bool bTime)
{
  local int i, iT;
  local PlayerReplicationInfo lPRI;
  local int iPingsArray[4], iPLArray[4];

  // Head
  if (bTime)
    SendIRCMessage(" ", bTime);
  SendIRCMessage(conf.colGen$sHeadLine, bTime);

  // Get Ping & PL 4 ScoreBoard
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      for (i = 0; i < 32; i++)
	{
	  lPRI = TGRI.PRIArray[i];
	  if ((lPRI != none) && (!lPRI.bIsSpectator) && (lPRI.Team == iT) && !lPRI.bIsABot)
	    {
	      iPingsArray[iT] += lPRI.Ping;
	      iPLArray[iT] += lPRI.PacketLoss;
	    }
	}
    }

  // Spamm out our stuff :)
  SendIRCMessage(conf.colHead$PostPad("Team-Name", 22, " ") $ "| " $ PrePad(sScoreStr, 5, " ") $ " | " $ PrePad("Ping", 4, " ") $ " | " $ PrePad("PL", 4, " ") $ " | " $ PrePad("PPL", 3, " ") $ " |", bTime);
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      iPingsArray[iT] = iPingsArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
      iPLArray[iT]    = iPLArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
      SendIRCMessage("> "$GetTeamColor(iT)$PostPad(conf.sTeams[iT], 20, " ") $ conf.colHead $ "| " $ GetTeamColor(iT) $ PrePad(string(int(TeamGamePlus(Level.Game).Teams[iT].Score)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(iPingsArray[iT]), 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(iPLArray[iT])$"%", 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(TeamGamePlus(Level.Game).Teams[iT].Size, 3, " ") $ conf.colHead $ " |", bTime);
    }

  if (bTime)
    SendIRCMessage(" ", bTime);
}

function string ProcessScore(int Score)
{
	local int intScore, secs;
	local string sec;

	if (bBTScores)
	{
		if (Score==0)
			return "0:00";
		else
		{
			intScore = 2000 - Score;
			if ( intScore > 1 && intScore < 1999 )
			{
				secs = int(intScore % 60);
				if ( secs < 10 )
	                  		sec = "0" $string(secs);
	            		else
					sec = "" $string(secs);
				return string(intScore / 60) $":" $sec;
			}
		}
	}
	return string(Score);
}

// Query of the Current Gameinfo (overridden)
function QueryInfo(string sNick)
{
  // Send some nifty stuff to the user!
  Link.SendNotice(sNick, "*** Detailed Game Information for "$Level.Title$":");
  Link.SendNotice(sNick, ">> Timelimit / Caplimit: "$TGRI.TimeLimit $ " / " $ string(int(Level.ConsoleCommand("get "$string(Level.Game.class)$" GoalTeamScore"))));
  if (TGRI.TimeLimit > 0)
    Link.SendNotice(sNick, ">> Time Remaining: "$GetStrTime(TGRI.RemainingTime));
  else
    Link.SendNotice(sNick, ">> Elapsed Time: "$GetStrTime(TGRI.ElapsedTime));
}

// Our Timer Event
event Timer()
{
  local bool bSentDrop, bSentDied;

	if (conf.bSecondaryLink)
	{
		if (!Link.bIsConnected || !Link2.bIsConnected)
			return;
	}
  else if (!Link.bIsConnected)
    return;

 if (droppedMessage!="")
 {
   SendIRCMessage(droppedMessage);
   droppedMessage="";
   bSentDrop=True;
 }
 if (DiedMsg!="")
 {
   SendIRCMessage(DiedMsg);
   DiedMsg="";
   bSentDied=True;
 }
 if (bSentDrop || bSentDied)
 	return;


  // Beim ersten durchlauf!
  // ^ wtf?
  if ((iTimerCnt == 0) && (bFirstRun == TRUE))
    {
      bFirstRun = FALSE;
      SendIRCMessage("Mavericks IRC Reporter "$Link.Controller.sVersion, TRUE);
      SendIRCMessage(conf.colHigh$"*** "$GetGameInfo());
    }

  // Advertising
  if (!bDoneAd && conf.bAdvertise)
    {
      if (TGRI.Timelimit == 0)
	{
	  if (TGRI.ElapsedTime > 0)
	    {
	      OnAdvertise();
	    }
	}
      else
	{
	  //BroadcastMessage(string(TGRI.Timelimit)$" - "$string(TGRI.RemainingTime)$" = "$string(TGRI.Timelimit - TGRI.RemainingTime));
	  if ((TGRI.Timelimit * 60 - TGRI.RemainingTime) > 0)
	    {
	      OnAdvertise();
	    }
	}
    }

  // Map Info (Mapname/Gamename/ServerURL)
  if ((iTimerCnt % xGInfoDelay) == 0)
    {
      if ((TGRI.NumPlayers > 0) && (iTimerCnt != 0))
	SendIRCMessage(conf.colHigh $ "*** " $ GetGameInfo());
    }

  // Detailed Game Information
  if (((iTimerCnt % xGDetailsDelay) == 0) && (iTimerCnt > 0) && (TGRI.NumPlayers > 0))
    {
      if (!Level.Game.bGameEnded)
	OnGameDetails();
    }

  // Detailed Score Information
  if (((iTimerCnt % xSDetailsDelay) == 0) && (iTimerCnt > 0) && (TGRI.NumPlayers > 0))
    {
      if (!Level.Game.bGameEnded)
	OnScoreDetails();
    }

  // Check whether the game is over or not
  if (Level.Game.bGameEnded && (!bGameOver))
    {
      bGameOver = TRUE;
      OnGameOver();
    }

  // Increase Counter 4 Timer
  if (iTimerCnt > 3600)
    iTimerCnt = 0;
  else
    iTimerCnt += 5;
}

// Override QueryPlayers function to provide team based colors
function QueryPlayers(string sNick)
{
  local int i, iT, iNum, iAll;
  local string sMessage;
  local TournamentPlayer lPlr;
  local PlayerReplicationInfo lPRI;

  Link.SendNotice(sNick, "*** Player List for "$Level.Game.GameReplicationInfo.ServerName$":");

  iAll = 0;
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      iNum = 0;
      sMessage = "";
      foreach AllActors(class'TournamentPlayer', lPlr)
	{
	  lPRI = lPlr.PlayerReplicationInfo;
	  if (lPRI.Team == iT) {
	    if (iNum > 0) sMessage = sMessage$", ";
	    else sMessage = conf.colHead$conf.sTeams[iT]$": "$ircColor;
	    if (Link.bUTGLEnabled)
	      sMessage = sMessage $ GetTeamColor(iT) $ ircBold $ ircBold $ lPRI.PlayerName $ " - Login: "$ Spec.ServerMutate("getlogin "$lPRI.PlayerName) $ conf.colBody $ " ("$ProcessScore(lPRI.Score)$")";
	    else
	      sMessage = sMessage $ GetTeamColor(iT) $ ircBold $ ircBold $ lPRI.PlayerName $ conf.colBody $ " ("$ProcessScore(lPRI.Score)$")";
	    iNum++;
	    iAll++;
	  }
	}
      if (iNum > 0)
	Link.SendNotice(sNick, ">> "$sMessage);
    }
  if (iAll == 0)
    Link.SendNotice(sNick, ">> No players on server!");
}

defaultproperties
{
     sScoreStr="Caps"
     xGInfoDelay=240
     xGDetailsDelay=300
     xSDetailsDelay=180
}
