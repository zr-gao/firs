function trace(niv,txt,warning=false)
{
	if(GSController.GetSetting("log_level")>=niv)
	{
	if(warning)
		GSLog.Warning(txt);
	else
		GSLog.Info(txt);
	}
}