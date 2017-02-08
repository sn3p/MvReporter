//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//  Gambino Edition by sn3p (snap@gambino.nl)                        /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterStats_1on1 expands MvReporterStats_DM;

// Override Set Gameinfo :)
function string SetGameInfo()
{
  return conf.ColHead $ "Playing 1on1 on" $ conf.colBody $ " " $ Level.Title $ conf.colHead $ ", Server: " $ conf.colBody $ Level.Game.GameReplicationInfo.ServerName;
}

// Override Detailed Game Information
function OnGameDetails()
{
  local int i;
  local string sName_1, sName_2, sScore_1, sScore_2;
  local PlayerReplicationInfo lPRI, lPRI_1, lPRI_2;
  SendIRCMessage(conf.colHigh$"*** "$GetGameInfo());
  // Post Results!
  for (i = 0; i < 32; i++)
    {
      lPRI = TGRI.PRIArray[i];
      if (lPRI==None)
        continue;
      if (!lPRI.bIsSpectator)
	if (lPRI_1 != none)
	  lPRI_2 = lPRI;
	else
	  lPRI_1 = lPRI;
    }
  if (lPRI_1 == none)
    {
      sScore_1 = "--"; sName_1 = "nobody";
    }
  else
    {
      sScore_1 = string(int(lPRI_1.Score)); sName_1 = lPRI_1.PlayerName;
    }
  if (lPRI_2 == none)
    {
      sScore_2 = "--"; sName_2 = "nobody";
    }
  else
    {
      sScore_2 = string(int(lPRI_2.Score)); sName_2 = lPRI_2.PlayerName;
    }
	if (Link.bUTGLEnabled)
	  SendIRCMessage(">>"$conf.colHead$" Current Score:"$ircColor$"4 "$sName_1$" - Login: "$Spec.ServerMutate("getlogin "$sName_1)$" "$sScore_1$ircColor$":"$ircColor$"12"$ircBold$ircBold$sScore_2$" "$sName_2$" - Login: "$Spec.ServerMutate("getlogin "$sName_2));
	else
	  SendIRCMessage(">>"$conf.colHead$" Current Score:"$ircColor$"4 "$sName_1$" "$sScore_1$ircColor$":"$ircColor$"12"$ircBold$ircBold$sScore_2$" "$sName_2);
}

defaultproperties
{
}
