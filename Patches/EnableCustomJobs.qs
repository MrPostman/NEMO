function EnableCustomJobs() {

	var max = 4400;
	
	//Step 1 - Find Insert Locations
	
	//1.1 - Get Offset of Novice's paths & name
	var novPath = exe.findString("\xC3\xCA\xBA\xB8\xC0\xDA", RVA).packToHex(4);
	var novHand = exe.findString("\xC3\xCA\xBA\xB8\xC0\xDA\x5C\xC3\xCA\xBA\xB8\xC0\xDA", RVA).packToHex(4);
	var novName = exe.findString("Novice", RVA).packToHex(4);
	
	if (novPath === " FF FF FF FF" || novHand === " FF FF FF FF" || novName === " FF FF FF FF") {
		return "Failed in Part 1.1";
	}
	
	//1.2 - Find the location where novPath is referred (there are 3 we need - jobsprite, imf, palette)
	var validLocs = "";
	for (var j = 0; j < 4; j++) {
		var code = " C7 0" + j + novPath + " 8B";// C7 01 to C7 03 :D just to avoid wildcard fetching other patterns.
			
		var offsets = exe.findCodes(code, PTYPE_HEX, false, " ");
		if (offsets[0]) {
			validLocs += "," + offsets;
		}
	}
	validLocs = validLocs.replace(",", "").split(",").sort();
	
	
	if (validLocs.length != 3) {
		if (exe.getClientDate() >= 20131223) { //TEMPORARY FIX - need to find a pattern that satisfies for all
			validLocs[2] = validLocs[1];//second offset is actually missing , offsets found are actually first & third
			var offset = exe.find(" E8 AB AB AB AB B9", PTYPE_HEX, true, "\xAB", validLocs[0], validLocs[1]);
			if (offset == -1) {
				return "Failed in Part 1.2.1";
			}
			validLocs[1] = offset+16;
		}
	}
	
	if (validLocs.length != 3) {
		return "Failed in Part 1.2";
	}
	
	//1.3 - Calculate Job prefix insert location
	var offset = exe.find(" E8 AB AB AB AB 8B", PTYPE_HEX, true, "\xAB", validLocs[0] - 16, validLocs[0]);
	if (offset == -1) {
		return "Failed in Part 1.3";
	}
	var pathBegin = offset + 5;
	
	//1.4 - Calculate Imf & Pal insert locations
	var imfBegin = validLocs[1] - 6;
	var palBegin = validLocs[2] - 6;
	
	//1.5 - Repeat 1.2 for job weapon/shield prefix
	var code = " E8 AB AB AB AB AB" + novHand + " 8B";
	var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
	var handBegin = -1;
	
	if (offsets.length > 1) {
		for (var i=0; i<offsets.length; i++) {
			var offset = offsets[i];
			var assigner = exe.fetchHex(offset+5, 5);
			
			for (var j = 0xB8; j<0xBB; j++) {
				code = j.packToHex(1) + novHand;
				if (assigner === code) break;
			}
			if (j<0xBB) break;
		}
		if (i !== offsets.length) {			
			handBegin = offsets[i];
		}
	}
	else {
		handBegin = offsets[0];
	}
	
	if (handBegin == -1) {
		return "Failed in Part 1.5";
	}
	
	//1.6 -	Calculate Weap/Shield insert location
	handBegin = handBegin + 10;
	
	//1.7 - Repeat 1.2 for Novice job name
	for (var j = 0; j < 4; j++) {
		code = " C7 0" + j + novName + " 8B";// C7 01 to C7 03 :D just to avoid wildcard fetching other patterns.
			
		offset = exe.findCode(code, PTYPE_HEX, false);
		if (offset == -1) continue;
		break;
	}
	
	if (offset == -1) {
		return "Failed in Part 1.7";
	}

	//1.8 - Calculate JobName insert location
	offset = exe.find(" E8 AB AB AB AB 8B", PTYPE_HEX, true, "\xAB", offset - 16, offset);
	if (offset == -1) {
		return "Failed in Part 1.8";
	}
	var nameBegin = offset + 5;
	
	//Step 2 - Find End Locations to jump to
	//2.1 - Job Path
	var pathEnd = exe.find(" 8B 75 AB C7 AB 28 04 00 00", PTYPE_HEX, true, "\xAB", pathBegin, imfBegin);
	var pathnop = 3;
	if (pathEnd == -1) {
		pathEnd = exe.find(" 8B 75 AB C7 AB 20 04 00 00", PTYPE_HEX, true, "\xAB", pathBegin, imfBegin);
	}
	if (pathEnd == -1) {
		pathEnd = exe.find(" 8B AB AB AB AB AB 8B", PTYPE_HEX, true, "\xAB", pathBegin, imfBegin);
		pathnop = false;
	}
	if (pathEnd == -1) {
		return "Failed in Part 2.1";
	}
	
	//2.2 - Imf Path
	var imfEnd = exe.find(" 8D AB AB AB AB AB 89 AB 20 04 00 00", PTYPE_HEX, true, "\xAB", imfBegin, handBegin);
	var imfnop = 6;	
	if (imfEnd == -1) {
		imfEnd = exe.find(" C7 44 24 AB AB AB AB AB 8B", PTYPE_HEX, true, "\xAB", imfBegin, handBegin);
		imfnop = false;	
	}	
	if (imfEnd == -1) {
		imfEnd = exe.find(" 8B AB AB AB AB AB C7 45", PTYPE_HEX, true, "\xAB", imfBegin, handBegin);	
	}
	if (imfEnd == -1) {
		imfEnd = exe.find(" 8B 8E AB AB 00 00 8B 96 AB AB 00 00", PTYPE_HEX, true, "\xAB", imfBegin, handBegin);
		
	}
	if (imfEnd == -1) {
		return "Failed in Part 2.2";
	}
	
	//2.3 - Hand Path
	var handEnd = exe.find(" 8B AB AB AB AB AB 8B", PTYPE_HEX, true, "\xAB", handBegin, palBegin);
	if (handEnd == -1) {
		return "Failed in Part 2.3";
	}
	
	//2.4 - Pal Path
	var palEnd = exe.find(" 8D AB AB AB AB AB 89 AB 20 04 00 00", PTYPE_HEX, true, "\xAB", palBegin, nameBegin);
	var palnop = 6;
	if (palEnd == -1) {
		palEnd = exe.find(" C7 44 24 AB AB AB AB AB 8D", PTYPE_HEX, true, "\xAB", palBegin, nameBegin);
		palnop = false;	
	}	
	if (palEnd == -1) {
		palEnd = exe.find(" C7 45 AB AB AB AB AB 8B", PTYPE_HEX, true, "\xAB", palBegin, nameBegin);
	}
	if (palEnd == -1) {
		palEnd = exe.find(" 8B 8E AB AB 00 00 8B 96 AB AB 00 00", PTYPE_HEX, true, "\xAB", palBegin, nameBegin);
	}
	if (palEnd == -1) {
		return "Failed in Part 2.4";
	}
	
	//2.5 - Job Name
	var nameEnd = exe.find(" BF 2D 00 00 00 83 CB FF", PTYPE_HEX, false, " ",nameBegin);
	if (nameEnd == -1) {
		return "Failed in Part 2.5";
	}
	
	//Step 3 - Prep Strings & Get Offsets for Lua Function calling
	//3.1 - Find offset of d>s
	var OFDS = exe.findString("d>s",RVA);
	if (OFDS == -1) {
		return "Failed in Part 3.1";
	}
	
	//3.2 - Find offset of d>d
	var OFDD = exe.findString("d>d",RVA);
	if (OFDD == -1) {
		return "Failed in Part 3.2";
	}
	
	//3.3 - Add Function Names into exe (Overwrite some Job names and use those locations)
	var reqPath = WriteFnString("Professor", "ReqPCPath");
	var reqHandPath = WriteFnString("Swordman High", "ReqPCHandPath");
	var reqImf = WriteFnString("Swordman", "ReqPCImf");
	var reqPal = WriteFnString("Magician", "ReqPCPal");
	var mapPath = WriteFnString("Blacksmith", "MapPCPath\x00");
	var mapHandPath = WriteFnString("Magician High", "MapPCHandPath");
	var mapImf = WriteFnString("Assassin", "MapPCImf");
	var mapPal = WriteFnString("Crusader", "MapPCPal");	
	var reqName_M  = WriteFnString("White Smith_W", "ReqPCJobName_M");
	var mapName_M  = WriteFnString("High Wizard_W", "MapPCJobName_M");
	var reqName_F = WriteFnString("High Priest_W", "ReqPCJobName_F");
	var mapName_F = WriteFnString("Lord Knight_W", "MapPCJobName_F");
	var getHalter = WriteFnString("Alchemist", "GetHalter");
	var isDwarf = WriteFnString("Acolyte", "IsDwarf");
	
	//Step 4 - Get Register values & Function addresses used in existing Lua calls
	//4.1 - Find offsets of ReqAccName & ReqJobName
	var reqacc = exe.findString("ReqAccName",RVA).packToHex(4);
	var reqjob = exe.findString("ReqJobName",RVA).packToHex(4);
	
	//4.2 - Find where they are referenced (ReqAccName only have 1 entry but ReqJobName has three or four of which we need the first)
	var offset  = exe.findCode("68" + reqacc, PTYPE_HEX, false);
	var offset2 = exe.findCode("68" + reqjob, PTYPE_HEX, false);
	
	//4.3 - Read out the register and function addresses (Location differs based on Compiler version)
	if (exe.getClientDate() > 20130605) {
		var strAlloc = offset2 + 13 + exe.fetchDWord(offset2+9);
		var dsOff = exe.fetchDWord(offset+24); //used in all other locations.
		var luaCaller = offset2 + 35 + exe.fetchDWord(offset2+31);
		var dsOff_Name = exe.fetchDWord(offset2+22); //used in name caller
	}
	else {
		var strAlloc = exe.fetchDWord(offset+15);
		var dsOff = exe.fetchDWord(offset+29); //used in all other locations.
		var luaCaller = offset + 47 + exe.fetchDWord(offset+43);
		var dsOff_Name = exe.fetchDWord(offset2+21); //used in name caller	
	}
	
	//4.4 - Get the second Register value (ESI + <RG02>) specific for each
	var esiDiff_Path = GetRG02(pathBegin);
	var esiDiff_Imf  = GetRG02(imfBegin);
	var esiDiff_Hand = GetRG02(handBegin);
	var esiDiff_Pal  = GetRG02(palBegin);
	var esiDiff_Name = GetRG02(nameBegin);

	//Step 5 - Prep and Overwrite current storage mechanism to Lua based mechanism
	//5.1 - Job Path
	
	code = BuildInsertString(pathBegin, OFDS, OFDD, "PCPath", reqPath, mapPath, strAlloc, luaCaller, dsOff, esiDiff_Path, false, pathEnd,max) + " 90 90 90 90";
	exe.replace(pathBegin, code, PTYPE_HEX);

	if (pathnop) {
		exe.replace(pathEnd + pathnop, " 8D 40 00 8D 49 00 8D 5B 00 90", PTYPE_HEX);
	}
	
	//5.2 - Imf Path
	code = BuildInsertString(imfBegin, OFDS, OFDD, "PCImf", reqImf, mapImf, strAlloc, luaCaller, dsOff, esiDiff_Imf, false, imfEnd,max);
	exe.replace(imfBegin, code, PTYPE_HEX);
	if (imfnop) {
		exe.replace(imfEnd + imfnop, " 8D 40 00 8D 49 00", PTYPE_HEX);
	}

	//return true;
	//5.3 - Hand Path
	code = BuildInsertString(handBegin, OFDS, OFDD, "PCHandPath", reqHandPath, mapHandPath, strAlloc, luaCaller, dsOff, esiDiff_Hand, false, handEnd,max);
	exe.replace(handBegin, code, PTYPE_HEX);
	
	//5.4 - Pal Path
	code = BuildInsertString(palBegin, OFDS, OFDD, "PCPal", reqPal, mapPal, strAlloc, luaCaller, dsOff, esiDiff_Pal, false, palEnd,max);
	exe.replace(palBegin, code, PTYPE_HEX);
	if (palnop) {
		exe.replace(palEnd + palnop, " 8D 40 00 8D 49 00", PTYPE_HEX);
	}

	//5.5 - Job Name
	code = BuildInsertString(nameBegin, OFDS, OFDD, "PCJobName_M", reqName_M , mapName_M , strAlloc, luaCaller, dsOff_Name, esiDiff_Name, true, nameEnd, max, 0) + " 90 90 90 90";
	exe.replace(nameBegin, code, PTYPE_HEX);
	
	// Step 6 - Build the code to Source the Lua Files
	//6.1 - Location to place the code.
	var lsrcBegin = nameBegin + code.hexlength();
	
	//6.2 - Find NPCIDentity path offset
	var NPCIdentity = exe.findString("Lua Files\\DataInfo\\NPCIdentity", RVA);
	if (NPCIdentity == -1) {
		return "Failed in Part 6.2";
	}
	
	//6.3 - Find where it is referenced (pushed)
	var offset2 = exe.findCode("68" + NPCIdentity.packToHex(4), PTYPE_HEX, false);
	if (offset2 == -1) {
		return "Failed in Part 6.3";
	}
	
	//6.4 - Get the details used for sourcing Lua files
	var luaSourcer = offset2 + 5 + 5 + exe.fetchDWord(offset2 + 6);
	var jmpToLsrc = exe.find(" 8B 8E AB AB 00 00", PTYPE_HEX, true, "\xAB", offset2 - 10, offset2);
	var prefsize = offset2 - jmpToLsrc;
	var prefix = exe.fetchHex(jmpToLsrc, prefsize);
	
	//6.5 - Create jmp to Lua file sourcing code from jmpToLsrc offset
	exe.replace(jmpToLsrc, "E9" + (lsrcBegin - (jmpToLsrc + 5)).packToHex(4), PTYPE_HEX);
	
	//6.6 - Add File paths to be read (Basenames only)
	var offset = exe.findString("Dark Collector", RVA);
	var code =	
			  "Lua Files\\Admin\\PCIds\x00"
			+ "Lua Files\\Admin\\PCPaths\x00" 
			+ "Lua Files\\Admin\\PCImfs\x00"
			+ "Lua Files\\Admin\\PCHands\x00"		
			+ "Lua Files\\Admin\\PCPals\x00"
			+ "Lua Files\\Admin\\PCNames\x00"
			+ "Lua Files\\Admin\\PCFuncs\x00"
			;
	exe.replace(exe.Rva2Raw(offset), code.toHex(), PTYPE_HEX);
	
	//6.7 - Generate & Add Lua Sourcer code for all the files	
	var diff  = luaSourcer - lsrcBegin;
	code  = GenLuaFileLoader(prefix, offset    , 1, diff);// PCIds
	code += GenLuaFileLoader(prefix, offset+22 , 2, diff);// PCPaths
	code += GenLuaFileLoader(prefix, offset+46 , 3, diff);// PCImfs
	code += GenLuaFileLoader(prefix, offset+69 , 4, diff);// PCHands
	code += GenLuaFileLoader(prefix, offset+93 , 5, diff);// PCPals
	code += GenLuaFileLoader(prefix, offset+116, 6, diff);// PCNames
	code += GenLuaFileLoader(prefix, offset+140, 7, diff);// PCFuncs
	code += GenLuaFileLoader(prefix, NPCIdentity,8, diff);//NPCIdentity
	
	
	code += " E9" + ((offset2+10) - (lsrcBegin + 8*(prefsize+10) + 5)).packToHex(4);//Return jmp instruction 
	code += " 90 90 90 90";
	exe.replace(lsrcBegin, code, PTYPE_HEX);
	
	//Step 7 - Build & Add code for Female Name overriding
	//7.1 - Location for insertion
	offset = lsrcBegin + code.hexlength();
	
	//7.2 - Find the reference to TaeKwon Girl
	offset2 = exe.findString("TaeKwon Girl", RVA);
	offset2 = exe.findCode(" C7 AB AB AB 00 00" + offset2.packToHex(4), PTYPE_HEX, true, "\xAB");
	
	//7.3 - Get ds register (Get Base Register Value for Jobname)
	var dsStore = exe.fetchHex(offset2-4, 4);
	
	//7.4 - Replacement Lua calling code buildup
	code = BuildInsertString(offset, OFDS, OFDD, "PCJobName_F", reqName_F, mapName_F, strAlloc, luaCaller, dsOff_Name, 0, true, nameEnd, max, 0) + " 90 90 90 90";
	code = code.replaceAt(3*60, " C3 90 90 90 90");
	exe.replace(offset, code, PTYPE_HEX);
	var o2 = offset + code.hexlength();
	
	code = BuildInsertString(o2, OFDS, OFDD, "PCJobName_M", reqName_M , mapName_M , strAlloc, luaCaller, dsOff_Name, 0, true, nameEnd, max, 0);
	code = code.replaceAt(3*60, " C3 90 90 90 90");
	exe.replace(o2, code, PTYPE_HEX);
	
	//7.5 - Overwrite gender related jump
	code =	  " 60"                     // pushad
			+ " 90"                     // nop
			+ " BE" + dsStore  // mov esi, nameoffset (nameoffset is already present usually but just to be safe)
			+ " 75 0B"			// jne short to call 2nd
			+ " 8D 6D 00"		// lea ebp,[ebp]
			+ " E8" + (offset - (offset2-7 + 17)).packToHex(4)	//call overrider - female
			+ " EB 09"			// jmp short to popad
			+ " 90"                     // nop
			+ " E8" + (o2 - (offset2-7 + 25)).packToHex(4)		//call overrider - male
			+ " 8D 6D 00"             // lea ebp,[ebp]
			+ " 61"                     // popad
			+ " EB 33"                 // jmp short 0083d3f0
			+ " 8D 00"                 // lea eax,[eax]
			+ " 8D 1B"                 // lea ebx,[ebx]
			;
	
	exe.replace(offset2-7, code, PTYPE_HEX);
	
	//Step 8 - Halter Call Modification
	//8.1 - Find the current code
	offset = exe.findCode(" 83 F8 19 75 AB B8 12 10 00 00", PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Issue with Part 8.1 - Skipping";
	}
	
	//8.2 - Get the insert Location	
	if (exe.getClientDate() > 20130605) {
		var halterBegin = offset - 6;
	}
	else {
		var halterBegin = offset - 4;
	}
	
	//8.3 - Build the code and add it to exe
	code  =	  " 55"			//PUSH EBP
			+ " 89 E5"		//MOV EBP,ESP
			+ " 51"			//PUSH ECX
			+ " 52"			//PUSH EDX
			+ " 57"			//PUSH EDI
			+ " 83 EC 0C"	//SUB ESP,0C
			+ " 8B 7D 08"	//MOV EDI,DWORD PTR SS:[EBP+8]
			;

	code += BuildLuaLoader(halterBegin + code.hexlength(), OFDD, "GetHalter", getHalter, strAlloc, luaCaller, dsOff_Name, 0, true, "get");
	
	code +=	  " 8B 44 E4 08"	//MOV EAX,DWORD PTR SS:[ESP+8]
			+ " 83 C4 0C"		//ADD ESP,0C		
			+ " 5F"				//POP EDI
			+ " 5A"				//POP EDX
			+ " 59"				//POP ECX
			+ " 5D"				//POP EBP
			+ " C2 04 00"		//RETN 4
			;
		
	exe.replace(halterBegin, code, PTYPE_HEX);
	
	//Step 9 - Job Class Shrinking (For Baby jobs)
	//9.1 - Find the current code
	offset = exe.findCode(" 3D B7 0F 00 00 7C AB 3D BD 0F 00 00", PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Issue with Part 9.1 - Skipping";
	}
	
	//9.2 - Get the insert Location	
	if (exe.getClientDate() > 20130605) {
		var dwarfBegin = offset - 6;
	}
	else {
		var dwarfBegin = offset - 4;
	}
	
	//9.3 - Build the code and add it to exe
	code =	  " 55"			//PUSH EBP
			+ " 89 E5"		//MOV EBP,ESP
			+ " 57"			//PUSH EDI
			+ " 83 EC 0C"	//SUB ESP,0C
			+ " 8B 7D 08"	//MOV EDI,DWORD PTR SS:[EBP+8]
			;

	code += BuildLuaLoader(dwarfBegin + code.hexlength(), OFDD, "IsDwarf", isDwarf, strAlloc, luaCaller, dsOff_Name, 0, true, "is");
	
	code +=	  " 8B 44 E4 08"	//MOV EAX,DWORD PTR SS:[ESP+8]
			+ " 83 C4 0C"		//ADD ESP,0C
			+ " 5F"				//POP EDI
			+ " 5D"				//POP EBP
			+ " C2 04 00"		//RETN 4
			;
			
	exe.replace(dwarfBegin, code, PTYPE_HEX);	
	return true;
}

function GenLuaFileLoader(prefix, str, i, diff) {
	var prefsize = prefix.hexlength() + 10;
	var code =	prefix
			+ " 68" + str.packToHex(4)
			+ " E8" + (diff - i*prefsize).packToHex(4);
			;
	return code;
}
	
function BuildInsertString(offset, OFDS, OFDD, fname, reqoff, mapoff, strAlloc, luaCaller, dsOff, esiDiff, isNameFn, jmpoff, max, diff) {
	if (typeof(max) === "undefined") max = 4217;
	if (typeof(diff) === "undefined") diff = 3950;
	var val44 = 44;
	var val29 = 29;
	
	var prefix =  
			  " 83 EC 08"			//SUB ESP, 8
			+ " 31 FF"						//XOR EDI,EDI
			+ " BB" + val44.packToHex(4)	//MOV EBX,2C
			+ " E8 00 00 00 00"				//CALL FNRQ - right after prefix
			+ " BF" + (4001 - diff).packToHex(4)	//MOV EDI,0FA1
			+ " BB" + (max - diff).packToHex(4)		//MOV EBX,1079
			+ " E8 00 00 00 00"				//CALL FNRQ - right after prefix
			+ " 31 FF"						//XOR EDI,EDI
			+ " BB" + val29.packToHex(4)	//MOV EBX,2C
			+ " E8 00 00 00 00"				//CALL FNMP
			+ " BF" + (4001 - diff).packToHex(4)	//MOV EDI,0FA1
			+ " BB" + (max - diff).packToHex(4)		//MOV EBX,1079
			+ " E8 00 00 00 00"				//CALL FNMP
			+ " 83 C4 08"					//ADD ESP, 8
			+ " 8D 6D 00"					//LEA EBP,[EBP]
			+ " E9 00 00 00 00"				//JMP JM01
			+ " CC CC CC"					//INT3 - 3
			;
	var prefsize = prefix.hexlength();
	
	if (isNameFn && exe.getClientDate() <= 20130605) {
		prefix = prefix.replaceAt(3*-11, " 31 ED 45"); //XOR EBP, EBP ; INC EBP
	}
	
	var part1 = BuildLuaLoader(offset+prefsize, OFDS, "Req" + fname, reqoff, strAlloc, luaCaller, dsOff, esiDiff, isNameFn, "req");
	var partsize = part1.hexlength();	
	var part2 = BuildLuaLoader(offset+prefsize+partsize, OFDD, "Map" + fname, mapoff, strAlloc, luaCaller, dsOff, esiDiff, isNameFn, "map");
	
	prefix = prefix.replaceAt(3*11, (prefsize-15).packToHex(4));//FNRQ
	prefix = prefix.replaceAt(3*26, (prefsize-30).packToHex(4));//FNRQ
	prefix = prefix.replaceAt(3*38, (prefsize-42 + partsize).packToHex(4));//FNMP
	prefix = prefix.replaceAt(3*53, (prefsize-57 + partsize).packToHex(4));//FNMP
	
	prefix = prefix.replaceAt(3*-7, (jmpoff - (offset+prefsize-3)).packToHex(4)); //JMP instruction
	var code = prefix + part1 + part2;
	
	return code;
}
	
	 
function GetRG02(offset) {
	var esipushers = new Array(
				"\x8B\x06\xC7", //MOV EAX,[ESI]
				"\x8B\x1E\xC7", //MOV EBX,[ESI]
				"\x8B\x0E\xC7", //MOV ECX,[ESI]
				"\x8B\x16\xC7"  //MOV EDX,[ESI]
				);
	var esiDiff = -1;
	var movdata = exe.fetch(offset,3);
	
	for (var i = 0; i < 4; i++) {
		if (movdata === esipushers[i]) {
			esiDiff = 0;
			break;
		}
	}
	
	if (esiDiff == -1) {
		esiDiff = exe.fetchDWord(offset+2);
	}
	return esiDiff;
}
	
function WriteFnString(prevstring, newstring) {
	var offset = exe.findString(prevstring, RAW);
	exe.replace(offset, newstring.toHex(), PTYPE_HEX);
	return exe.Raw2Rva(offset);
}

function BuildLuaLoader(loc, OF01, fn, OFNM, strAlloc, luaCaller, dsOff, esiDiff, isNameFn, fnType) {
	
	if (exe.getClientDate() > 20130605) {
		var part1 =	
				  " C7 44 E4 08 00 00 00 00"//MOV DWORD PTR SS:[ESP+8], 0
				+ " 8D 54 E4 08"			//LEA EDX,[ESP+8]
				+ " 52"						//PUSH EDX
				+ " 57"						//PUSH EDI
				+ " 68" + OF01.packToHex(4)	//PUSH OFFSET OF01 ; d>s or d>d
				+ " 83 EC 1C"				//SUB ESP,1C
				+ " 89 E1"					//MOV ECX,ESP
				+ " 31 C0"					//XOR EAX,EAX
				+ " 6A" + fn.length.packToHex(1)	//PUSH LN01 - Length of OFNM fn name
				+ " C7 41 14 0F 00 00 00"	//MOV DWORD PTR DS:[ECX+14],0F
				+ " 89 41 10"				//MOV DWORD PTR DS:[ECX+10],EAX
				+ " 68" + OFNM.packToHex(4)	//PUSH OFNM - Fname pointer
				+ " 88 01"					//MOV BYTE PTR DS:[ECX],AL
				+ " E8" + (strAlloc-(loc+45+5)).packToHex(4)	//CALL FN01 - String allocator
				;
		var partlen = part1.hexlength();
		
		if (isNameFn == false) {
			var part2 =
					  " 8B 55 F0"					//MOV EDX,DWORD PTR SS:[EBP-10]
					+ " 8B 82" + dsOff.packToHex(4)	//MOV EAX,DWORD PTR DS:[EDX+RG01]
					+ " 50"							//PUSH EAX
					+ " E8" + (luaCaller-(loc+partlen+10+5)).packToHex(4)	//CALL FN02 - Lua Function Caller
					+ " 83 C4 2C"					//ADD ESP,2C
					;
		}
		else {
			var part2 =
					  " 8B 0D" + dsOff.packToHex(4)	//MOV ECX,DWORD PTR DS:[RG01]
					+ " 51"							//PUSH ECX
					+ " E8" + (luaCaller-(loc+partlen+7+5)).packToHex(4)	//CALL FN02 - Lua Function Caller
					+ " 83 C4 2C"					//ADD ESP,2C
					;
		}
	}
	else {
		var part1 =
				  " C7 44 E4 08 00 00 00 00"		//MOV DWORD PTR SS:[ESP+8], 0
				+ " 8D 54 E4 08"					//LEA EDX,[ESP+8]
				+ " 52"								//PUSH EDX
				+ " 57"								//PUSH EDI
				+ " 68" + OF01.packToHex(4)			//PUSH OFFSET OF01 ; d>s or d>d
				+ " 83 EC 1C"						//SUB ESP,1C
				+ " 89 E1"							//MOV ECX,ESP
				+ " 68" + OFNM.packToHex(4)			//PUSH OFNM - Fname pointer
				+ " FF 15" + strAlloc.packToHex(4)	//CALL DWORD PTR DS:[FN01] - String allocator
				;
		var partlen = part1.hexlength();
		
		if (isNameFn == -1) {
			var part2 =	 
					  " 8B 8E" + dsOff.packToHex(4)							//MOV ECX,DWORD PTR DS:[ESI+RG01]
					+ " 51"													//PUSH ECX
					+ " E8" + (luaCaller-(loc+partlen+7+5)).packToHex(4)	//CALL FN02 - Lua Function Caller
					+ " 83 C4 2C"        									//ADD ESP,2C
					;
		}
		else {
			var part2 =
					  " 8B 0D" + dsOff.packToHex(4)							//MOV ECX,DWORD PTR DS:[RG01]
					+ " 51"													//PUSH ECX
					+ " E8" + (luaCaller-(loc+partlen+7+5)).packToHex(4)	//CALL FN02 - Lua Function Caller
					+ " 83 C4 2C"        									//ADD ESP,2C
					;
		}
	}
	var partlen = part1.hexlength() + part2.hexlength();
	
	if (fnType == "req") {
		var part3 =	
				  " 84 C0"			//TEST AL,AL
				+ " 74 15"			//JE SHORT to INC EDI
				+ " 8B 44 E4 08"	//MOV EAX,DWORD PTR SS:[ESP+8]
				+ " 8B 10"			//MOV EDX,DWORD PTR DS:[EAX]
				+ " 84 D2"			//TEST DL,DL
				+ " 74 0B"			//JE SHORT to INC EDI
				+ " 8B 96" + esiDiff.packToHex(4)			//MOV EDX,DWORD PTR DS:[ESI+RG02]
				+ " 8D 0C BA"		//LEA ECX,[EDI*4+EDX]
				+ " 89 01"			//MOV DWORD PTR DS:[ECX],EAX
				+ " 47"				//INC EDI
				+ " 39 DF"			//CMP EDI,EBX
				+ " 7E" + (-(partlen + 30)).packToHex(1)	//JLE SHORT to LEA EDX,[ESP]
				+ " C3"				//RETN
				;
		if (esiDiff == 0) {	
			part3 = part3.replaceAt(3*14, " 8B 16 90 90 90 90");
		}		
	}
	else if(fnType == "map") {
		var part3 =	
				  " 84 C0"			//TEST AL,AL
				+ " 74 1B"			//JE SHORT to INC EDI
				+ " 8B 44 E4 08"	//MOV EAX,DWORD PTR SS:[ESP+8]
				+ " 40"				//INC EAX
				+ " 85 C0"			//TEST EAX, EAX
				+ " 74 12"			//JE SHORT to INC EDI
				+ " 8B 96" + esiDiff.packToHex(4)			//MOV EDX,DWORD PTR DS:[ESI+RG02]
				+ " 8D 0C BA"		//LEA ECX,[EDI*4+EDX]
				+ " 8B 44 E4 08"	//MOV EAX,DWORD PTR SS:[ESP+8]
				+ " 8B 04 82"		//MOV EAX,DWORD PTR SS:[EAX*4 + EDX]
				+ " 89 01"			//MOV DWORD PTR DS:[ECX],EAX
				+ " 47"				//INC EDI
				+ " 39 DF"			//CMP EDI,EBX
				+ " 7E" + (-(partlen + 36)).packToHex(1)	//JLE SHORT to LEA EDX,[ESP]
				+ " C3"				//RETN
				;
		if (esiDiff == 0) {	
			part3 = part3.replaceAt(3*13, " 8B 16 90 90 90 90");
		}
	}
	else {
		var part3 = "";
	}
	var code = part1 + part2 + part3;
	return code;
}