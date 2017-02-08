//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterStats_TDM extends MvReporterStats_DM;

var string sScoreStr;

// Override GetTeamColor Function
function string GetTeamColor(byte iTeam)
{
  // Do a switch and return the proper color
  switch (iTeam)
    {
    case 0:
      return conf.colRed;
    case 1:
      return conf.colBlue;
    case 2:
      return conf.colGreen;
    case 3:
      return conf.colGold;
    default:
      return conf.colBody;
    }
}

// Override InTeamMessage Function
function InTeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep )
{
  if (conf.xCensorText)
      CensorTextIRC(GetTeamColor(PRI.Team) $ PRI.PlayerName $ ": " $ conf.colBody $ Lower(S));
  else
    {
      if (conf.xAllowShouting)
        SendIRCMessage(GetTeamColor(PRI.Team) $ PRI.PlayerName $ ": " $ conf.colBody $ S);
      else
        SendIRCMessage(GetTeamColor(PRI.Team) $ PRI.PlayerName $ ": " $ conf.colBody $ Lower(S));
    }
}

// Post Player Statistics (overridden)
function PostPlayerStats()
{
  local int i, iT;
  local PlayerReplicationInfo lPRI;
  local int iPingsArray[4], iPLArray[4];
  local string sBot;

  SendIRCMessage(" ", TRUE);
  SendIRCMessage(conf.colGen$"** Final Player Status:", TRUE);

  if (Link.bUTGLEnabled)
    SendIRCMessage(conf.colHead$PostPad("Name", 22, " ") $ "| " $ PrePad("Login", 15, " ") $ "| " $ PrePad(sScoreStr, 5, " ") $ " | " $ PrePad("Death", 5, " ") $ " | " $ PrePad("Ping", 4, " ") $ " | " $ PrePad("PL", 4, " ") $ " |", TRUE);
  else
    SendIRCMessage(conf.colHead$PostPad("Name", 22, " ") $ "| " $ PrePad(sScoreStr, 5, " ") $ " | " $ PrePad("Death", 5, " ") $ " | " $ PrePad("Ping", 4, " ") $ " | " $ PrePad("PL", 4, " ") $ " |", TRUE);

  // The outer loop will go through all teams (so that output will be kinda sorted by teams)
  // The inner loop will go thourgh all players of the specific team
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      for (i = 0; i < 32; i++)
	{
	  lPRI = TGRI.PRIArray[i];
	  if (lPRI==None)
	    continue;
	  if (!lPRI.bIsSpectator && lPRI.Team == iT)
	    {
	      if (lPRI.bIsABot) sBot = " (Bot)";
	      else sBot = "";
     	      if (Link.bUTGLEnabled)
		      SendIRCMessage("> "$GetTeamColor(lPRI.Team)$PostPad(lPRI.PlayerName $ sBot, 20, " ")  $ conf.colHead $ "| " $ conf.colBody $ PrePad(Spec.ServerMutate("getlogin "$lPRI.PlayerName), 15, " ") $ "| "  $ GetTeamColor(lPRI.Team) $ PrePad(string(int(lPRI.Score)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(int(lPRI.Deaths)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(lPRI.Ping), 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(lPRI.PacketLoss)$"%", 4, " ") $ conf.colHead $ " |", TRUE);
	      else
	      	  SendIRCMessage("> "$GetTeamColor(lPRI.Team)$PostPad(lPRI.PlayerName $ sBot, 20, " ")  $ conf.colHead $ "| " $ GetTeamColor(lPRI.Team) $ PrePad(string(int(lPRI.Score)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(int(lPRI.Deaths)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(lPRI.Ping), 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(lPRI.PacketLoss)$"%", 4, " ") $ conf.colHead $ " |", TRUE);
	      iPingsArray[iT] += lPRI.Ping;
	      iPLArray[iT] += lPRI.PacketLoss;
	    }
	}
    }
  SendIRCMessage(PostPad("  ", 52, "-"), TRUE);

  // Now spam out the Team Scores!
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      iPingsArray[iT] = iPingsArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
      iPLArray[iT]    = iPLArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
      SendIRCMessage("> "$GetTeamColor(iT)$PostPad(conf.sTeams[iT], 20, " ") $ conf.colHead $ "| " $ PrePad("",15, " ") $ "| " $ GetTeamColor(iT) $ PrePad(string(int(TeamGamePlus(Level.Game).Teams[iT].Score)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad("---", 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(iPingsArray[iT]), 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(iPLArray[iT])$"%", 4, " ") $ conf.colHead $ " |", TRUE);
    }
}

// Detailed Game Information (overridden)
function OnGameDetails()
{
  local string sTimeMsg;
  // Post Stuff
  if (GRI.GameName == class'TeamGamePlus'.Default.GameName)
    SendIRCMessage(" ");
  SendIRCMessage(conf.colGen$"** Game Details:");
  SendIRCMessage(">> "$conf.colHead$"Timelimit / Scorelimit:" $conf.colBody$" "$TGRI.TimeLimit $ " mins / " $ TGRI.GoalTeamScore $ " " $ sScoreStr);
  if (GRI.GameName == class'TeamGamePlus'.Default.GameName)
    SendIRCMessage(">> "$conf.colHead$"Friendly Fire / Weaponstay:" $conf.colBody$" "$string(int(TeamGamePlus(Level.Game).FriendlyFireScale * 100))$"% / "$string(DeathMatchPlus(Level.Game).bMultiWeaponStay));
  // Post remaining / elapsed time!
  if (TGRI.TimeLimit > 0)
    sTimeMsg = "Time Remaining: " $ conf.colBody $ GetStrTime(TGRI.RemainingTime);
  else
    if (TGRI.GoalTeamScore == 0)
      sTimeMsg = "This Game will never end, because Timelimit and Scorelimit are zero!";
    else
      sTimeMsg = "Elapsed Time: " $ conf.colBody $ GetStrTime(TGRI.ElapsedTime);
  SendIRCMessage(">> "$conf.colHead$sTimeMsg);
  if (GRI.GameName == class'TeamGamePlus'.Default.GameName)
    SendIRCMessage(" ");
}

// Detailed Score Information (overridden)
function OnScoreDetails()
{
  local int i, iT;
  local PlayerReplicationInfo lPRI, bestPRI;
  local int iPingsArray[4], iPLArray[4];

  // Head
  SendIRCMessage(" ");
  SendIRCMessage(conf.colGen$"** Team Status Information:");

  // Get the best PRI and save Ping & PL 4 ScoreBoard
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      for (i = 0; i < 32; i++)
	{
	  lPRI = TGRI.PRIArray[i];
	  if (lPRI == None)
	  	continue;
	  if (!lPRI.bIsSpectator && lPRI.Team == iT)
	    {
	      iPingsArray[iT] += lPRI.Ping;
	      iPLArray[iT] += lPRI.PacketLoss;
		if (bestPRI == None)
		  bestPRI = TGRI.PRIArray[i];
		else if (bestPRI.Score <= lPRI.Score)
	          bestPRI = TGRI.PRIArray[i];
	    }
	}
    }

  // Spamm out our stuff :)
  SendIRCMessage(conf.colHead$PostPad("Team-Name", 22, " ") $ "| " $ PrePad(sScoreStr, 5, " ") $ " | " $ PrePad("Ping", 4, " ") $ " | " $ PrePad("PL", 4, " ") $ " | " $ PrePad("PPL", 3, " ") $ " |");
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      iPingsArray[iT] = iPingsArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
      iPLArray[iT]    = iPLArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
      SendIRCMessage("> "$GetTeamColor(iT)$PostPad(conf.sTeams[iT], 20, " ") $ conf.colHead $ "| " $ GetTeamColor(iT) $ PrePad(string(int(TeamGamePlus(Level.Game).Teams[iT].Score)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(iPingsArray[iT]), 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(iPLArray[iT])$"%", 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(TeamGamePlus(Level.Game).Teams[iT].Size, 3, " ") $ conf.colHead $ " |");
    }
  SendIRCMessage(conf.colHead$"Best Player is"$GetTeamColor(bestPRI.Team)$" "$bestPRI.PlayerName$conf.colHead$" with"$conf.colHigh$" "$string(int(bestPRI.Score))$conf.colHead$" Frags!");
  SendIRCMessage(" ");
}

// Override Query Score Function (to broadcast Scoreboard)
function QueryScore(string sNick)
{
  local int i, iT;
  local PlayerReplicationInfo lPRI, bestPRI;
  local int iPingsArray[4], iPLArray[4];

  // Save Ping & PL 4 ScoreBoard
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      for (i = 0; i < 32; i++)
	{
	  lPRI = TGRI.PRIArray[i];
	  if (lPRI == None)
	    continue;
	  if (!lPRI.bIsSpectator && lPRI.Team == iT)
	    {
	      iPingsArray[iT] += lPRI.Ping;
	      iPLArray[iT] += lPRI.PacketLoss;
	    }
	}
    }

  // Spamm out our stuff :)
  Link.SendNotice(sNick, PostPad("Team-Name", 22, " ") $ "| " $ PrePad(sScoreStr, 5, " ") $ " | " $ PrePad("Ping", 4, " ") $ " | " $ PrePad("PL", 4, " ") $ " | " $ PrePad("PPL", 3, " ") $ " |");
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      iPingsArray[iT] = iPingsArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
      iPLArray[iT]    = iPLArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
      Link.SendNotice(sNick, ">"$GetTeamColor(iT)$" "$PostPad(conf.sTeams[iT], 20, " ")$ ircColor $ "| " $ PrePad(string(int(TeamGamePlus(Level.Game).Teams[iT].Score)), 5, " ") $ " | " $ PrePad(string(iPingsArray[iT]), 4, " ") $ " | " $ PrePad(string(iPLArray[iT])$"%", 4, " ") $ " | " $ PrePad(TeamGamePlus(Level.Game).Teams[iT].Size, 3, " ") $ " |");
    }
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
	      sMessage = sMessage $ GetTeamColor(iT) $ ircBold $ ircBold $ lPRI.PlayerName $ " - Login: "$ Spec.ServerMutate("getlogin "$lPRI.PlayerName) $ conf.colBody $ " ("$string(int(lPRI.Score))$")";
	    else
	      sMessage = sMessage $ GetTeamColor(iT) $ ircBold $ ircBold $ lPRI.PlayerName $ conf.colBody $ " ("$string(int(lPRI.Score))$")";
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
     sScoreStr="Frags"
}
