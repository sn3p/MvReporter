//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterStats_LMS extends MvReporterStats_DM;

// Post Player Statistics
function PostPlayerStats()
{
  local int i;
  local PlayerReplicationInfo lPRI, bestPRI;
  local string sBot;

  // Get the best PRI
  for (i = 0; i < 32; i++)
    {
      lPRI = TGRI.PRIArray[i];
      if ( lPRI == None)
        continue;
      if (bestPRI==None)
        bestPRI = TGRI.PRIArray[i];
      if (bestPRI.Score <= lPRI.Score)
		bestPRI = TGRI.PRIArray[i];
    }
   lPRI = bestPRI;
   if (lPRI == None)
   	return;
  SendIRCMessage(" ", TRUE);
  SendIRCMessage(conf.colGen$"** Final Player Status:", TRUE);
	if (lPRI.bIsABot)
		sBot = " (Bot)";
	else
		sBot = "";

	if (Link.bUTGLEnabled)
		SendIRCMessage("> "$lPRI.PlayerName$sBot$ " - Login: "$Spec.ServerMutate("getlogin "$lPRI.PlayerName)$" is the winner with "$string(int(lPRI.Score))$" lives left!)");
	else
		SendIRCMessage("> "$lPRI.PlayerName$sBot$" is the winner with "$string(int(lPRI.Score))$" lives left!");
}

// Query of the Current Gameinfo (overridden)
function QueryInfo(string sNick)
{
	local int StartLives;
	// Send some nifty stuff to the user!
	Link.SendNotice(sNick, "*** Detailed Game Information for "$Level.Title$":");
	if (TGRI.FragLimit == 0)
		StartLives = 10;
	else
		StartLives = TGRI.FragLimit;
	Link.SendNotice(sNick, ">> Timelimit / Start Lives: "$TGRI.TimeLimit $ " / " $ string(StartLives));
	if (TGRI.TimeLimit > 0)
		Link.SendNotice(sNick, ">> Time Remaining: "$GetStrTime(TGRI.RemainingTime));
	else
		Link.SendNotice(sNick, ">> Elapsed Time: "$GetStrTime(TGRI.ElapsedTime));
}

// Detailed Game Information
function OnGameDetails()
{
  local int i;
  local PlayerReplicationInfo lPRI, bestPRI;
  local int StartLives;

  // Get the best PRI
  for (i = 0; i < 32; i++)
    {
      lPRI = TGRI.PRIArray[i];
      if ( lPRI == None)
        continue;
      if (bestPRI==None)
        bestPRI = TGRI.PRIArray[i];
      if (bestPRI.Score <= lPRI.Score)
	bestPRI = TGRI.PRIArray[i];
    }
  // Post Stuff
  SendIRCMessage(" ");
  SendIRCMessage(conf.colGen$"** Game Details:");
  if (TGRI.FragLimit == 0)
  	StartLives = 10;
  else
  	StartLives = TGRI.FragLimit;
  SendIRCMessage(">> "$conf.colHead$"Timelimit / Start Lives:" $conf.colBody$" "$TGRI.TimeLimit $ " / " $ string(StartLives));
  SendIRCMessage("> " $ GetTeamColor(bestPRI.Team) $ bestPRI.PlayerName $ conf.colHead $ " is in the lead with"$conf.colHigh$" "$string(int(bestPRI.Score))$conf.colHead$" lives left!");
  SendIRCMessage(" ");
}

// Query of the Current Player List (overridden)
function QueryPlayers(string sNick)
{
  local int i, iNum;
  local string sMessage;
  local TournamentPlayer lPlr;
  local PlayerReplicationInfo lPRI;

  Link.SendNotice(sNick, "*** Player List for "$Level.Game.GameReplicationInfo.ServerName$":");
  iNum = 0;
  foreach AllActors(class'TournamentPlayer', lPlr)
    {
      lPRI = lPlr.PlayerReplicationInfo;
      if (iNum > 0) sMessage = sMessage $ ", ";
      if (Link.bUTGLEnabled)
	sMessage = sMessage $ lPRI.PlayerName $ " - Login: "$Spec.ServerMutate("getlogin "$lPRI.PlayerName)$" ("$string(int(lPRI.Score))$" lives)";
      else
	sMessage = sMessage $ lPRI.PlayerName $ " ("$string(int(lPRI.Score))$" lives)";
      iNum++;
    }
  if (iNum == 0)
    sMessage = "No players on server!";
  Link.SendNotice(sNick, ">> "$sMessage);
}

defaultproperties
{
}
