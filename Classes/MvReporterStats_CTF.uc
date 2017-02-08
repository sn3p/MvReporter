//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterStats_CTF expands MvReporterStats_TDM;

// Variables to store the Name & Type of the Last Frag (& the message)
var string lastMessage, lastKiller, lastVictim;
var int lastSwitch;
var string droppedName, droppedMessage;
var bool isStateDropping;

// Override InLocalizedMessage Function
function InLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  local string sHigh, Player_1, Player_2;
  sHigh = "";
  
  // *** SUDDEN DEATH / TEAM CHANGE ***
  if (ClassIsChildOf(Message, class'BotPack.DeathMatchMessage'))
    {
      switch(Switch)
	{
	// 0-overtime, 1-enteredgame, 2-namechange, 3-teamchange, 4-leftgame
	// Overtime :)
	case 0:
	  SendIRCMessage(GetColoredMessage("", conf.colHigh, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  return;
	
        // Team Change
	case 3:
	  SendIRCMessage(GetColoredMessage("* ", conf.colGen, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  return;
	}
      return;
    }

  // *** FIRST BLOOD MESSAGE ***
  if (ClassIsChildOf(Message, class'BotPack.FirstBloodMessage'))
    {
      if (RelatedPRI_1.PlayerName == lastKiller)
	SendIRCMessage(lastMessage);
      sendIRCMessage(GetColoredMessage("", conf.colHigh, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
      return;
    }

  // *** FRAG Messages ***
  //if (ClassIsChildOf(Message, class'BotPack.DeathMessagePlus'))
  if (InStr(Caps(Message), Caps("BotPack.DeathMessagePlus")) != -1)
    {
      // _1-killer, _2-victom, optional-weapon class
      // Save our message (maybe we need it l8er)
      lastKiller = RelatedPRI_1.PlayerName;
      lastVictim = RelatedPRI_2.PlayerName;
      lastSwitch = Switch;
      lastMessage = GetColoredMessage("", conf.colHead, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
      
      // If we have a flag drop in progress -> post that too
      // if (isStateDropping && (((droppedName == RelatedPRI_2.PlayerName) && (Related_PRI2 != none)) || ((droppedName == RelatedPRI_1.PlayerName) && (RelatedPRI_2 == none))){
      if (isStateDropping && (((RelatedPRI_2 == none) && (RelatedPRI_1.PlayerName == droppedName)) || ((RelatedPRI_2.PlayerName == droppedName) && (RelatedPRI_2 != none)) ))
	{
	  isStateDropping = FALSE;
	  SendIRCMessage(lastMessage);
	}

      // Killing Spree ?
      ProcessKillingSpree(Switch, RelatedPRI_1, RelatedPRI_2);
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
	case 2:
	  isStateDropping = TRUE;
	  droppedName = RelatedPRI_1.PlayerName;
	  droppedMessage = conf.colGen$Message.static.GetString( Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	  SendIRCMessage(droppedMessage);
	  return;

        // Default
        default:
	  SendIRCMessage(conf.colGen$Message.static.GetString( Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  return;
	}
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
      lPRI = TGRI.PRIArray[i];
      if (lPRI==None)
        continue;

      if (bestPRI == none)
        bestPRI = lPRI;
      else if (bestPRI.Score <= lPRI.Score)
	bestPRI = lPRI;
      if (!lPRI.bIsSpectator)
	{
	  lFLAG = CTFFlag(lPRI.HasFlag);
	  if (lFLAG != none)
	    SendIRCMessage(">> "$conf.colHead$lPRI.PlayerName$" has the "$conf.sTeams[lFLAG.Team]$" flag!");
	}
    }
  SendIRCMessage(">> " $ conf.colHead $ bestPRI.PlayerName $ " is in the lead with"$conf.colHigh$" "$string(int(bestPRI.Score))$conf.colHead$" frags!");
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
	  if (lPRI==None)
	    continue;
	  if (!lPRI.bIsSpectator && lPRI.Team == iT && !lPRI.bIsABot)
	    {
	      iPingsArray[iT] += lPRI.Ping;
	      iPLArray[iT] += lPRI.PacketLoss;
	    }
	}
    }
  
  // Spam out our stuff :)
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

defaultproperties
{
     sScoreStr="Caps"
     xGInfoDelay=240
     xGDetailsDelay=300
     xSDetailsDelay=180
}
