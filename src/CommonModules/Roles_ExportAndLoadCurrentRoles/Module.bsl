Procedure UpdateRoleExt(Settings) Export
	If NOT ValueIsFilled(Settings.PathToXML) Then
		Path = TempFilesDir() + "TemplateRoles";
		DeleteFiles(Path);
		
		// unload to xml
		CommandToUploadExt = """" + BinDir() + "1cv8.exe"" designer " + "/N """ + Settings.Login + """" +
		" /P """ + Settings.Password + """" + " " + 
		?(Settings.SQL, "/s " + Settings.Server + "\" + Settings.BaseName, "/f " + Path) +
		" /DumpConfigToFiles " + Path + " -Right /DumpResult " + Path + 
		"\Event.log /DisableStartupMessages /DisableStartupDialogs";
		RunApp(CommandToUploadExt, , True);
		
		Settings.PathToXML = Path + "\";
		
	EndIf;
	
	BeginTransaction();
	
	Rights = FindFiles(Settings.PathToXML + "Roles", "*.xml", False);
	
	For Each Right In Rights Do
		TextReader = New TextReader();
		TextReader.Open(Right.FullName, TextEncoding.UTF8);
		Text = TextReader.Read();
		TextReader.Close();
		
		RoleInfo = Roles_ServiceServer.DeserializeXMLUseXDTOFactory(Text);
		
		UUID = New UUID(RoleInfo.Role.uuid);
		
		RightRef = Catalogs.Roles_AccessRoles.GetRef(UUID);
		If RightRef.Description = "" Then
			RightObject = Catalogs.Roles_AccessRoles.CreateItem();
			RightObject.SetNewObjectRef(RightRef);
		Else
			RightObject = RightRef.GetObject();
		EndIf;
		
		RightObject.Rights.Clear();
		RightObject.LangInfo.Clear();
		RightObject.RestrictionByCondition.Clear();
		RightObject.Templates.Clear();
		
		RightObject.Description = RoleInfo.Role.Properties.Name;
		RightObject.ConfigRoles = True;
		
		For Each Lang In RoleInfo.Role.Properties.Synonym.item Do
			NewLang = RightObject.LangInfo.Add();
			NewLang.LangCode = Lang.lang;
			NewLang.LangDescription = Lang.Content;
		EndDo;
		
		If TypeOf(RoleInfo.Role.Properties.Comment) = Type("String") Then
			RightObject.Comment = RoleInfo.Role.Properties.Comment;
		Else
			RightObject.Comment = "";
		EndIf;
		
		TextReader = New TextReader();
		TextReader.Open(Settings.PathToXML + "Roles\" + RightObject.Description + "\Ext\Rights.xml", TextEncoding.UTF8);
		Text = TextReader.Read();
		TextReader.Close();
		
		RightInfo = Roles_ServiceServer.DeserializeXMLUseXDTOFactory(Text);
		
		RightObject.SetRightsForAttributesAndTabularSectionsByDefault = 
			RightInfo.setForAttributesByDefault;
		RightObject.SetRightsForNewNativeObjects = 
			RightInfo.setForNewObjects;
		RightObject.SubordinateObjectsHaveIndependentRights = 
			RightInfo.independentRightsOfChildObjects;
		
		For Each Object In RightInfo.object Do
			ObjectFullName = StrSplit(Object.Name, ".", False);
			ObjectType = Enums.Roles_MetadataTypes[ObjectFullName[0]];
			ObjectName = ObjectFullName[1];		
			For Each ObjectRight In Object.right Do
				NewObject = RightObject.Rights.Add();
				NewObject.ObjectName = ObjectName;
				NewObject.ObjectType = ObjectType;
				NewObject.ObjectPath = Object.Name;
				If ObjectRight.name = "AllFunctionsMode" Then	
					NewObject.RightName = Enums.Roles_Rights.TechnicalSpecialistMode;
				Else
					NewObject.RightName = Enums.Roles_Rights[ObjectRight.name];
				EndIf;
				
				NewObject.RowID = New UUID();
				NewObject.RightValue = ObjectRight.value;
				For Each RestrictionByCondition In ObjectRight.restrictionByCondition Do
					Condition = RightObject.RestrictionByCondition.Add();
					Condition.RowID = NewObject.RowID;
					Condition.Condition = RestrictionByCondition.condition;
				EndDo;
				
			EndDo;
		EndDo;
		For Each restrictionTemplate In RightInfo.restrictionTemplate Do
			Condition = RightObject.Templates.Add();
			Condition.Name = restrictionTemplate.Name;
			
			
			
			TemplateUUID = New UUID(Roles_ServiceServer.HashMD5(restrictionTemplate.condition));
			TemplateRef  = Catalogs.Roles_Templates.GetRef(TemplateUUID);
			
			If TemplateRef.Description = "" Then
				TemplateObject = Catalogs.Roles_Templates.CreateItem();
				TemplateObject.Description = restrictionTemplate.Name;
				TemplateObject.Template = restrictionTemplate.condition;
				TemplateObject.SetNewObjectRef(TemplateRef);
				
				If NOT Catalogs.Roles_Templates.FindByDescription(restrictionTemplate.Name).IsEmpty() Then
					TemplateObject.Description = TemplateObject.Description + "(" + RightObject.Description + ")";
				EndIf;
				
				TemplateObject.Write();
				TemplateRef = TemplateObject.Ref;
			EndIf;
			
			Condition.Template = TemplateRef;
		EndDo;
		RightObject.Write();
	EndDo;	
	CommitTransaction();
EndProcedure