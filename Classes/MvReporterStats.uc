//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//  Gambino Edition by sn3p (snap@gambino.nl)                        /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterStats expands UBrowserBufferedTCPLink;
// Switched class due to error.
// class MvReporterStats expands Actor;

// Link to our IRC Interface (IMPORTANT)
var MvReporterIRCLink Link;
var MvReporterIRCLink2 Link2;
var MvReporterSpectator Spec;
var MvReporterConfig conf;

var LevelInfo Level;
var GameReplicationInfo GRI;

// Declare some Variables
var string ircBold;
var string ircColor;
var string ircUnderline;
var string ircClear;
var bool bBTScores;

// Initialization Function
function Initialize()
{
  if ((Left(string(Level), 3)=="BT-" || Left(string(Level), 5)=="CTF-BT-") && string(Level.Game.class)!="BotPack.CTFGame")
    bBTScores=True;
  Log("++ [Mv]: Stats Actor Initialized!");
}

// Recieve General Messages (Joins, Parts, etc)
function InClientMessage(coerce string S, optional name Type, optional bool bBeep)
{
}

// Recieve Say Messages
function InTeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep )
{
}

// Recieve Localized Messages
function InLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
}

// Recieve Taunts
function InVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
}

static function string PrePad (coerce string S, int Size, string Pad)
{
  if (Len(S) > Size)
    return Left(S, Size-3)$"...";
  while (Len(S) < Size)
    S = Pad $ S;
  return S;
}

static function string PostPad (coerce string S, int Size, string Pad)
{
  if (Len(S) > Size)
    return Left(S, Size-3)$"...";
  while (Len(S) < Size)
    S = S $ Pad;
  return S;
}

function string GetStrTime(int Time)
{
  local int m;
  local int s;
  // local string str;

  m = (Time % 3600) / 60;
  s = Time % 60;
  return PrePad(string(m),2,"0") $ ":" $ PrePad(string(s),2,"0");
}

function String GetClientVoiceMessageString(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
  local VoicePack V;
  local String sStr;

  if ((Sender == None) || (Sender.voicetype == None))
    return "";

  V = Spawn(Sender.voicetype, self);
  if (V == none)
    return "";

  if (messagetype == 'ACK')
    sStr = sStr $ ChallengeVoicePack(V).static.GetAckString(messageID);
  else
    {
      if (recipient != none)
	{
	  sStr = sStr $ ChallengeVoicePack(V).GetCallSign(Recipient);
	}
      if (messagetype == 'FRIENDLYFIRE')
	{
	  sStr = sStr $ ChallengeVoicePack(V).static.GetFFireString(messageID);
	}
      else if (messagetype == 'TAUNT')
	{
	  sStr = sStr $ ChallengeVoicePack(V).static.GetTauntString(messageID);
	}
      else if (messagetype == 'AUTOTAUNT')
	{
	  sStr = sStr $ ChallengeVoicePack(V).static.GetTauntString(messageID);
	  sStr = "";
	}
      else if (messagetype == 'ORDER')
	{
	  sStr = sStr $ ChallengeVoicePack(V).static.GetOrderString(messageID, "Deathmatch");
	}
      else
	{
	  sStr = sStr $ ChallengeVoicePack(V).static.GetOtherString(messageID);
	}
    }
  V.Destroy();
  return sStr;
}


// IRC Queries
function QueryMap(string sNick)
{
}
function QueryInfo(string sNick)
{
}
function QuerySpecs(string sNick)
{
}
function QueryPlayers(string sNick)
{
}
function QueryScore(string sNick)
{
}

defaultproperties
{
     ircBold=""
     ircColor=""
     ircUnderline=""
     ircClear=""
}
