//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//  Gambino Edition by sn3p (snap@gambino.nl)                        /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterStats_DOM expands MvReporterStats_TDM;

var string lastMessage, lastKiller, lastVictim;
var int lastSwitch;

// Override InLocalizedMessage Function
function InLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  local string sHigh, Player_1, Player_2, sMessage, slt, sgt;
  local int i, iNum;
  local TeamInfo lTI;
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

  // *** FIRST BLOOD MESSAGE ***
  if (ClassIsChildOf(Message, class'BotPack.FirstBloodMessage'))
    {
      if (RelatedPRI_1.PlayerName == lastKiller)
	SendIRCMessage(lastMessage);
      SendIRCMessage(GetColoredMessage("", conf.colHigh, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
    }

  // *** FRAG Messages ***
  if (ClassIsChildOf(Message, class'BotPack.DeathMessagePlus'))
    {
      // Save our message (maybe we need it l8er)
      lastKiller = RelatedPRI_1.PlayerName;
      lastVictim = RelatedPRI_2.PlayerName;
      lastSwitch = Switch;
      lastMessage = GetColoredMessage("", conf.colHead, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

      // Killing Spree ?
      ProcessKillingSpree(Switch, RelatedPRI_1, RelatedPRI_2);

      return;
    }

  // *** CONTROL POINT Messages ***
  if (ClassIsChildOf(Message, class'ControlPointMessage'))
    {
      iNum = 0;
      for (i = 0; i < 16; i++)
	{
	  if (Domination(Level.Game).ControlPoints[i] != none)
	    {
	      if (iNum > 0) sMessage = sMessage $ conf.colBody $ " - ";
	      if (Domination(Level.Game).ControlPoints[i] == ControlPoint(OptionalObject))
		{
		  slt = "["; sgt = "]";
		}
	      else
		{
		  slt = ""; sgt = "";
		}

	      lTI = Domination(Level.Game).ControlPoints[i].ControllingTeam;
	      if (lTI != none)
		sMessage = sMessage $ GetTeamColor(lTI.TeamIndex) $ slt $ Domination(Level.Game).ControlPoints[i].PointName $ sgt;
	      else sMessage = sMessage $ GetTeamColor(255) $ slt $ Domination(Level.Game).ControlPoints[i].PointName $ sgt;
	      iNum++;
	    }
	}
      SendIRCMessage(conf.colHead$"Control Points Updated: "$sMessage);
    }
}

// Detailed Score Information (overridden)
function OnScoreDetails()
{
  local int i, iT;
  local PlayerReplicationInfo lPRI, bestPRI;
  local int iPingsArray[4], iPLArray[4];

  SendIRCMessage(conf.colGen$"** Team Status Information:");

  // Get the best PRI and save Ping & PL 4 ScoreBoard
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
    {
      for (i = 0; i < 32; i++)
	{
	  lPRI = TGRI.PRIArray[i];
	  if ( lPRI == None)
	    continue;
	  if (!lPRI.bIsSpectator && lPRI.Team == iT)
	    {
	      iPingsArray[iT] += lPRI.Ping;
	      iPLArray[iT] += lPRI.PacketLoss;
              if ( bestPRI == None)
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
      SendIRCMessage(">> "$GetTeamColor(iT)$PostPad(conf.sTeams[iT], 20, " ") $ conf.colHead $ "| " $ GetTeamColor(iT) $ PrePad(string(int(TeamGamePlus(Level.Game).Teams[iT].Score)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(iPingsArray[iT]), 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(iPLArray[iT])$"%", 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(TeamGamePlus(Level.Game).Teams[iT].Size, 3, " ") $ conf.colHead $ " |");
    }
  SendIRCMessage(conf.colHead$"Best Player is"$GetTeamColor(bestPRI.Team)$" "$bestPRI.PlayerName$conf.colHead$" with"$conf.colHigh$" "$string(int(bestPRI.Score))$conf.colHead$" Frags!");
}

defaultproperties
{
     sScoreStr="Pnts"
}
