Procedure GenerateRoleMatrix(RoleTree, ObjectData) Export
	
	RightsMap = CurrentRights(ObjectData);
	PictureLibData = Roles_SettingsReUse.PictureList();
	
	ParamStructure = New Structure;
	ParamStructure.Insert("PictureLibData", PictureLibData);
	ParamStructure.Insert("RightsMap", RightsMap);
	ParamStructure.Insert("ObjectData", ObjectData);
	
	For Each Meta In Enums.Roles_MetadataTypes Do
		
		If Meta = Enums.Roles_MetadataTypes.IntegrationService // wait 8.3.17
			OR Meta = Enums.Roles_MetadataTypes.Role Then 
			Continue;
		EndIf;
		GenerateMetaType(RoleTree, ParamStructure, Meta); 
	EndDo;

	RoleTree.Rows.Sort("ObjectPath", True);
EndProcedure

Procedure GenerateMetaType(RoleTree, ParamStructure, Meta) Export
	MetaRow = RoleTree.Rows.Add();
	MetaRow.ObjectType = Meta;
	MetaRow.ObjectFullName = Meta;
	MetaRow.ObjectPath = Roles_Settings.MetaName(Meta);
	Picture = ParamStructure.PictureLibData["Roles_" + Roles_Settings.MetaName(Meta)];
	MetaRow.Picture = Picture;
	
	SetCurrentRights(MetaRow, ParamStructure);
	
	If Meta = Enums.Roles_MetadataTypes.Configuration Then
		MetaRow.ObjectFullName = Metadata.Name;
		Return;
	EndIf;
	
	ParamStructure.Insert("Meta", Meta);
		
	For Each MetaItem In Metadata[Roles_Settings.MetaDataObjectNames().Get(Meta)] Do
		If NOT isNative(MetaItem) Then
			Continue;
		EndIf;
		MetaItemRow = MetaRow.Rows.Add();
		MetaItemRow.ObjectType = Meta;
		MetaItemRow.ObjectName = MetaItem.Name;
		MetaItemRow.ObjectFullName = MetaItem.Name;
		MetaItemRow.Picture = Picture;
		MetaItemRow.ObjectPath = MetaRow.ObjectPath + "." + MetaItemRow.ObjectFullName;
		
		ParamStructure.Insert("MetaItem", MetaItem);
		ParamStructure.Insert("MetaItemRow", MetaItemRow);

		
		SetCurrentRights(MetaItemRow, ParamStructure);			
					
		If Roles_Settings.hasAttributes(Meta) Then
			ParamStructure.Insert("DataType", "Attributes");
			AddChild(ParamStructure);
		EndIf;
		If Roles_Settings.hasDimensions(Meta) Then
			ParamStructure.Insert("DataType", "Dimensions");
			AddChild(ParamStructure);
		EndIf;
		If Roles_Settings.hasResources(Meta) Then
			ParamStructure.Insert("DataType", "Resources");
			AddChild(ParamStructure);
		EndIf;
		If Roles_Settings.hasStandardAttributes(Meta) Then
			ParamStructure.Insert("DataType", "StandardAttributes");
			AddChild(ParamStructure);
		EndIf;
		If Roles_Settings.hasCommands(Meta) Then
			ParamStructure.Insert("DataType", "Commands");
			AddChild(ParamStructure);
		EndIf;			
		If Roles_Settings.hasRecalculations(Meta) Then
			ParamStructure.Insert("DataType", "Recalculations");
			AddChild(ParamStructure);
		EndIf;
		If Roles_Settings.hasAccountingFlags(Meta) Then
			ParamStructure.Insert("DataType", "AccountingFlags");
			AddChild(ParamStructure);
		EndIf;
		If Roles_Settings.hasExtDimensionAccountingFlags(Meta) Then
			ParamStructure.Insert("DataType", "ExtDimensionAccountingFlags");
			AddChild(ParamStructure);
		EndIf;
		If Roles_Settings.hasAddressingAttributes(Meta) Then
			ParamStructure.Insert("DataType", "AddressingAttributes");
			AddChild(ParamStructure);
		EndIf;
		If Roles_Settings.hasTabularSections(Meta) Then
			ParamStructure.Insert("DataType", "TabularSections");
			AddChildTab(ParamStructure);
		EndIf;
		If Roles_Settings.hasStandardTabularSections(Meta) Then
			ParamStructure.Insert("DataType", "StandardTabularSections");
			AddChildStandardTab(ParamStructure);
		EndIf;
		If Roles_Settings.isSubsystem(Meta) Then
			ParamStructure.Insert("DataType", "Subsystems");
			AddChildSubsystem(ParamStructure);
		EndIf;
		If Roles_Settings.hasOperations(Meta) Then
			ParamStructure.Insert("DataType", "Operations");
			AddChildOperations(ParamStructure);
		EndIf;
		If Roles_Settings.hasURLTemplates(Meta) Then
			ParamStructure.Insert("DataType", "URLTemplates");
			AddChildURLTemplates(ParamStructure);
		EndIf;
	EndDo;
EndProcedure


Procedure AddChildOperations(Val StrData)
	If NOT StrData.MetaItem[StrData.DataType].Count() Then
		Return;
	EndIf;
	
	ObjectSubtype = Enums.Roles_MetadataSubtype[
			Left(StrData.DataType, StrLen(StrData.DataType) - 1)];
	Picture = StrData.PictureLibData["Roles_" + ObjectSubtype];
	For Each AddChild In StrData.MetaItem[StrData.DataType] Do
		
		If NOT isNative(AddChild) Then
			Continue;
		EndIf;
		
		AddChildRow = StrData.MetaItemRow.Rows.Add();
		AddChildRow.ObjectName = AddChild.Name;
		AddChildRow.ObjectFullName = AddChild.Name;	
		AddChildRow.Picture = Picture;
		AddChildRow.ObjectSubtype = ObjectSubtype;
				
		AddChildRow.ObjectPath = StrData.MetaItemRow.ObjectPath + ".Operation." + AddChildRow.ObjectName;
		SetCurrentRights(AddChildRow, StrData);
	EndDo;
EndProcedure

Procedure AddChildURLTemplates(Val StrData)
	If NOT StrData.MetaItem[StrData.DataType].Count() Then
		Return;
	EndIf;
	
	AddChildRows = StrData.MetaItemRow.Rows.Add();
	ObjectSubtype = Enums.Roles_MetadataSubtype[Left(StrData.DataType, StrLen(StrData.DataType) - 1)];
	Picture = StrData.PictureLibData["Roles_" + ObjectSubtype];
	PictureURLTemplate = StrData.PictureLibData["Roles_URLTemplate"];
	PictureMethod = StrData.PictureLibData["Roles_Method"];
	AddChildRows.ObjectPath = StrData.MetaItemRow.ObjectPath + "." + ObjectSubtype;
	For Each AddChild In StrData.MetaItem[StrData.DataType] Do
		
		If NOT isNative(AddChild) Then
			Continue;
		EndIf;
		
		If AddChildRows.ObjectFullName = "" Then
			NamePart = StrSplit(AddChild.FullName(), ".");
			AddChildRows.ObjectFullName = NamePart[3];
		EndIf;
		For Each AddChildAttribute In AddChild.Methods Do
			If NOT isNative(AddChildAttribute) Then
				Continue;
			EndIf;
			
			AddChildNewRow = AddChildRows.Rows.Add();
			AddChildNewRow.ObjectName = AddChildAttribute.Name;
			AddChildNewRow.ObjectFullName = AddChildAttribute.Name;
			AddChildNewRow.Picture = PictureMethod;
			AddChildNewRow.ObjectSubtype = Enums.Roles_MetadataSubtype.Method;
			
			// read data from object
			
			AddChildNewRow.ObjectPath = AddChildRows.ObjectPath + "." + AddChild.Name + ".Method." + 
							AddChildNewRow.ObjectName;
			SetCurrentRights(AddChildNewRow, StrData);

		EndDo;
		
	EndDo;
	AddChildRows.Picture = StrData.PictureLibData["Roles_" + ObjectSubtype];
	AddChildRows.ObjectName = StrData.DataType;
	AddChildRows.ObjectSubtype = ObjectSubtype;
EndProcedure

Procedure AddChildSubsystem(Val StrData)

	
	If NOT StrData.MetaItem[StrData.DataType].Count() Then
		Return;
	EndIf;
	ObjectSubtypeName = Left(StrData.DataType, StrLen(StrData.DataType) - 1);
	Picture = StrData.PictureLibData["Roles_Subsystem"];
	For Each AddChild In StrData.MetaItem[StrData.DataType] Do
		
		If NOT isNative(AddChild) Then
			Continue;
		EndIf;
		
		AddChildRow = StrData.MetaItemRow.Rows.Add();		
		AddChildRow.ObjectName = AddChild.Name;
		AddChildRow.Picture = Picture;
		AddChildRow.ObjectFullName = AddChild.Name;
		AddChildRow.ObjectType = StrData.Meta;		
		// read data from object
		If StrData.MetaItemRow.ObjectPath = "" Then
			AddChildRow.ObjectPath = ObjectSubtypeName + "." + AddChildRow.ObjectName;
		Else
			AddChildRow.ObjectPath = StrData.MetaItemRow.ObjectPath + "." + 
					ObjectSubtypeName + "." + AddChildRow.ObjectName;
		EndIf;
		SetCurrentRights(AddChildRow, StrData);
		
		StrData.MetaItem = AddChild;
		AddChildSubsystem(StrData);
	EndDo;
EndProcedure

Procedure AddChild(Val StrData)

	First = True;
	For Each AddChild In StrData.MetaItem[StrData.DataType] Do
		
		If First Then
			ObjectSubtypeName = Left(StrData.DataType, StrLen(StrData.DataType) - 1);
			ObjectSubtype = Enums.Roles_MetadataSubtype[ObjectSubtypeName];
			
			AddChildRows = StrData.MetaItemRow.Rows.Add();
			AddChildRows.ObjectPath = StrData.MetaItemRow.ObjectPath + "." + ObjectSubtypeName;
			Picture = StrData.PictureLibData["Roles_" + StrData.DataType];
			First = False;
		EndIf;
		
		If NOT StrData.DataType = "StandardAttributes" 
			AND NOT isNative(AddChild) Then
			Continue;
		EndIf;
		
		AddChildRow = AddChildRows.Rows.Add();
		AddChildRow.ObjectName = AddChild.Name;
		AddChildRow.Picture = Picture;
		AddChildRow.ObjectFullName = AddChild.Name;
		If StrData.DataType = "StandardAttributes" Then		
			If AddChildRows.ObjectFullName = "" Then
				AddChildRows.ObjectFullName = "StandardAttribute";
			EndIf;
		Else	
			If AddChildRows.ObjectFullName = "" Then
				NamePart = StrSplit(AddChild.FullName(), ".");
				AddChildRows.ObjectFullName = NamePart[2];
			EndIf;
		EndIf;		
		
		AddChildRow.ObjectSubtype = ObjectSubtype;
		
		// read data from object
		
		AddChildRow.ObjectPath = AddChildRows.ObjectPath + "." + AddChildRow.ObjectName;
		SetCurrentRights(AddChildRow, StrData);
	EndDo;
	If Not First Then
		AddChildRows.ObjectSubtype = ObjectSubtype;
		AddChildRows.ObjectName = StrData.DataType;
		AddChildRows.Picture = StrData.PictureLibData["Roles_" + StrData.DataType];
	EndIf;
EndProcedure

Procedure AddChildTab(Val StrData)
	If NOT StrData.MetaItem[StrData.DataType].Count() Then
		Return;
	EndIf;
	
	AddChildRows = StrData.MetaItemRow.Rows.Add();
	ObjectSubtypeName = Left(StrData.DataType, StrLen(StrData.DataType) - 1);
	ObjectSubtype = Enums.Roles_MetadataSubtype[ObjectSubtypeName];
	Picture = StrData.PictureLibData["Roles_" + StrData.DataType];
	PictureAttributes = StrData.PictureLibData["Roles_Attributes"];
	AddChildRows.ObjectPath = StrData.MetaItemRow.ObjectPath + "." + ObjectSubtypeName;
	For Each AddChild In StrData.MetaItem[StrData.DataType] Do
		
		If NOT isNative(AddChild) Then
			Continue;
		EndIf;
		
		AddChildRow = AddChildRows.Rows.Add();
		AddChildRow.ObjectName = AddChild.Name;
		AddChildRow.ObjectFullName = AddChild.Name;	
		AddChildRow.Picture = Picture;
		AddChildRow.ObjectSubtype = ObjectSubtype;
		
		If AddChildRows.ObjectFullName = "" Then
			NamePart = StrSplit(AddChild.FullName(), ".");
			AddChildRows.ObjectFullName = NamePart[2];
		EndIf;
		
		AddChildRow.ObjectPath = AddChildRows.ObjectPath + "." + AddChildRow.ObjectName;
		SetCurrentRights(AddChildRow, StrData);
		
		For Each AddChildAttribute In AddChild.Attributes Do
			If NOT isNative(AddChildAttribute) Then
				Continue;
			EndIf;
			
			AddChildNewRow = AddChildRow.Rows.Add();
			AddChildNewRow.ObjectName = AddChildAttribute.Name;
			AddChildNewRow.ObjectFullName = AddChildAttribute.Name;
			AddChildNewRow.Picture = PictureAttributes;
			AddChildNewRow.ObjectSubtype = ObjectSubtype;
			
			// read data from object
			
			AddChildNewRow.ObjectPath = AddChildRow.ObjectPath + ".Attribute." + 
							AddChildNewRow.ObjectName;
			SetCurrentRights(AddChildNewRow, StrData);

		EndDo;
		
	EndDo;
	AddChildRows.Picture = StrData.PictureLibData["Roles_" + StrData.DataType];
	AddChildRows.ObjectName = StrData.DataType;
	AddChildRows.ObjectSubtype = ObjectSubtype;
EndProcedure

Procedure AddChildStandardTab(Val StrData)
	AddChildRows = StrData.MetaItemRow.Rows.Add();
	AddChildRows.ObjectFullName = "StandardTabularSection";
	ObjectSubtypeName = Left(StrData.DataType, StrLen(StrData.DataType) - 1);
	ObjectSubtype = Enums.Roles_MetadataSubtype[ObjectSubtypeName];
	AddChildRows.ObjectPath = StrData.MetaItemRow.ObjectPath + "." + ObjectSubtype;
	For Each AddChild In StrData.MetaItem[StrData.DataType] Do
		AddChildRow = AddChildRows.Rows.Add();
		AddChildRow.ObjectName = AddChild.Name;
		AddChildRow.ObjectFullName = AddChild.Name;
		AddChildRow.Picture = StrData.PictureLibData["Roles_" + StrData.DataType];
		AddChildRow.ObjectSubtype = ObjectSubtype;
		
		AddChildRow.ObjectPath = AddChildRows.ObjectPath + "." + AddChildRow.ObjectName;
		SetCurrentRights(AddChildRow, StrData);
		
		For Each AddChildAttribute In AddChild.StandardAttributes Do
			AddChildNewRow = AddChildRow.Rows.Add();
			AddChildNewRow.ObjectName = AddChildAttribute.Name;
			AddChildNewRow.ObjectFullName = AddChildAttribute.Name;	
			AddChildNewRow.Picture = StrData.PictureLibData["Roles_StandardAttributes"];
			AddChildNewRow.ObjectSubtype = ObjectSubtype;
			
			// read data from object
			
			AddChildNewRow.ObjectPath = AddChildRow.ObjectPath + ".Attribute." + 
							AddChildNewRow.ObjectName;
			SetCurrentRights(AddChildNewRow, StrData);

		EndDo;	
	EndDo;
	AddChildRows.Picture = StrData.PictureLibData["Roles_" + StrData.DataType];
	AddChildRows.ObjectName = StrData.DataType;
	AddChildRows.ObjectSubtype = ObjectSubtype;
EndProcedure

Function CurrentRights(DataTables)
	RightMap = New Map;
	
	TempVT = DataTables.RightTable.Copy();
	TempVT.GroupBy("ObjectPath");
	For Each RowVT In TempVT Do
		RightsStructure = New Structure;
		FindRows = DataTables.RightTable.FindRows(New Structure("ObjectPath", RowVT.ObjectPath));
		For Each Row In FindRows Do
			
			
			FindRLSRows = DataTables.RestrictionByCondition.FindRows(New Structure("RowID", Row.RowID));
			RLSMap = New Map;
			For Each RLSRow In FindRLSRows Do
				RLSMap.Insert(?(ValueIsFilled(RLSRow.Fields), RLSRow.Fields, "All Fields"), RLSRow.Condition);
			EndDo;
			RightValue = New Structure;
			RightValue.Insert("Value", Row.RightValue);
			RightValue.Insert("RLS", RLSMap);
			RightsStructure.Insert(Roles_Settings.MetaName(Row.RightName), RightValue);
			
		EndDo;
		
		RightMap.Insert(RowVT.ObjectPath, RightsStructure);
	EndDo;
	Return RightMap
EndFunction

Procedure SetCurrentRights(Row, StrData)
	
	//For Each roleStr In Roles_SettingsReUse.MetaRolesName() Do
	//	If NOT Roles_SettingsReUse.Skip(Row.ObjectType, Row.ObjectSubtype, roleStr.Key) Then
	//		Row[roleStr.Key] = 2;
	//	EndIf;
	//EndDo;
	
	RightData = StrData.RightsMap.Get(Row.ObjectPath);
	If RightData = Undefined Then
		Return;
	EndIf;
	
	For Each Data In RightData Do
		Row[Data.Key] = ?(Data.Value.Value, 1, 2);
	EndDo;
	Row.Edited = True;
	SetEditedInfo(Row);
EndProcedure

Procedure SetEditedInfo(Row)
	If Row.Parent = Undefined Then
		Return;
	EndIf;
	If Row.Parent.Edited Then
		Return;
	EndIf;
	Row.Parent.Edited = True;
	SetEditedInfo(Row.Parent)
EndProcedure


#Region Service
Function isNative(TestObject)
	
	Return TestObject.ObjectBelonging = Metadata.ObjectBelonging;

EndFunction


#EndRegion