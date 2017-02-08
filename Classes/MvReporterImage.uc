//////////////////////////////////////////////////////////////////////\
//                                                                   /|
//  Unreal Tournament IRC Reporter - Copyright © Thomas Pajor, 2001  /|
//  ---------------------------------------------------------------  /|
//  Programmed by [Mv]DarkViper, Enhanced by Rush (rush@u.one.pl)    /|
//  And given spice by Altgamer (alt@rivalflame.com)                 /|
//  Gambino Edition by sn3p (snap@gambino.nl)                        /|
//                                                                   /|
///////////////////////////////////////////////////////////////////////

class MvReporterImage expands WebApplication;

event Init()
{
  Super.Init();
  Log("++ [Mv]: Webadmin Images Initialized");
}

event Query(WebRequest Request, WebResponse Response)
{
	local string Image;

	Image = Mid(Request.URI, 1);
	if( Right(Caps(Image), 4) == ".JPG" || Right(Caps(Image), 5) == ".JPEG" )
		Response.SendStandardHeaders("image/jpeg");
	else
	if( Right(Caps(Image), 4) == ".GIF" )
		Response.SendStandardHeaders("image/gif");
	else
	if( Right(Caps(Image), 4) == ".BMP" )
		Response.SendStandardHeaders("image/bmp");
	else
	{
		Response.HTTPError(404);
		return;
	}
	Response.IncludeBinaryFile( "images/"$Image );
}

defaultproperties
{
}
