//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//  Gambino Edition by sn3p (snap@gambino.nl)                        /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterStats_EUT expands MvReporterStats_TDM;

// Variables to store the Name & Type of the Last Frag (& the message)
var string lastMessage, lastKiller, newKiller, lastVictim, newVictom, sPlayer_1, sPlayer_2;
var int lastSwitch;
var string droppedName, droppedMessage;
var bool isStateDropping;

// Override InLocalizedMessage Function
function InLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  // Sudden death / Team change
  if (InStr(Caps(Message), Caps("BotPack.DeathMatchMessage")) != -1)
    {
      switch(Switch)
	{
	// 0-overtime, 1-enteredgame, 2-namechange, 3-teamchange, 4-leftgame
	case 0:
	  SendIRCMessage(GetColoredMessage("", conf.colHigh, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  return;
	case 3:
	  SendIRCMessage(GetColoredMessage("* ", conf.colGen, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
	  return;
	}
    }

  // First blood message.
  if (InStr(Caps(Message), Caps("BotPack.FirstBloodMessage")) != -1)
    {
      if (RelatedPRI_1.PlayerName == lastKiller)
	SendIRCMessage(lastMessage);
      sendIRCMessage(GetColoredMessage("", conf.colHigh, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
      return;
    }



  // Frags
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


  // Eut messages
  if (InStr(Caps(Message), Caps("PCL_DeathMessagePlus")) != -1)
    {
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

      // Hotfix for EUT kills
      if (conf.xDefaultKills)
        {
           // Show kills
           if (InStr(Caps(OptionalObject), Caps("ZP_SuperShockRifle")) != -1)
             {
               // Team color
               if (RelatedPRI_1.Team == 0)
                   newKiller = conf.colRed$RelatedPRI_1.PlayerName;
               if (RelatedPRI_1.Team == 1)
                   newKiller = conf.colBlue$RelatedPRI_1.PlayerName;
               if (RelatedPRI_1.Team == 2)
                   newKiller = conf.colGreen$RelatedPRI_1.PlayerName;
               if (RelatedPRI_1.Team == 3)
                   newKiller = conf.colGold$RelatedPRI_1.PlayerName;

               if (RelatedPRI_2.Team == 0)
                   newVictom = conf.colRed$RelatedPRI_2.PlayerName;
               if (RelatedPRI_2.Team == 1)
                   newVictom = conf.colBlue$RelatedPRI_2.PlayerName;
               if (RelatedPRI_2.Team == 2)
                   newVictom = conf.colGreen$RelatedPRI_2.PlayerName;
               if (RelatedPRI_2.Team == 3)
                   newVictom = conf.colGold$RelatedPRI_2.PlayerName;

               // Send
               if (newVictom != "" && newKiller != "")
                 SendIRCMessage(newKiller$conf.colHead$" inflicted mortal damage upon "$newVictom$conf.colHead$" with the Enhanced Shock Rifle.");
             }
        }

      // Killing Spree ?
      ProcessKillingSpree(Switch, RelatedPRI_1, RelatedPRI_2);
      return;
    }

  // Ctf messages
  if (InStr(Caps(Message), Caps("BotPack.CTFMessage")) != -1)
    {
      switch (Switch)
	{
	// 0-captured, 1-returned, 2-dropped, 3-was returned, 4-has flag, 5-auto home, 6-pickup stray
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
    return;
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
