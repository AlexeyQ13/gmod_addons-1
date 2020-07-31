if SERVER then resource.AddWorkshop("1563745153") end
timer.Simple(1,function()
	--файл, множитель громкости, pitch offset
	local AllSounds = {{"subway_trains/bogey/flange_10.wav",3,0}}

	local YazSoundFile = "subway_trains/bogey/skrip_yaz_v2.wav"
	local IsYazSoundFileExists = file.Exists("sound/"..YazSoundFile, "GAME")
	
	if IsYazSoundFileExists then table.insert(AllSounds,{YazSoundFile,4,-0.2})end

	
	local AllSoundsN = #AllSounds
	
	local name_for_all_sounds = "wheels_skrip_"
	
	local bogeysWagons = {}
	local bogeysSkripType = {}
	local bogeys = {}
	
	local entsFindByClass = ents.FindByClass
	
	local paramname1 = "Стандартный рандомный"
	local paramname2 = "by YaZ"
	local paramname3 = "Постоянный рандом"
	local paramname4 = "Рандом для каждой тележки"
	local inserted_index1 = -1
	local inserted_index2 = -1
	local inserted_index3 = -1
	local inserted_index4 = -1
	
	local tablename = "WheelsSkripType"
	local readtablename = "Тип скрипа колес"
	
	local mathrandom = math.random
	
	for k,class in pairs(Metrostroi and Metrostroi.TrainClasses or {}) do
		if class:find("76",1,true) then continue end--у оки как-то иначе работает тележка
		local ENT = scripted_ents.GetStored(class)
		if ENT.t then ENT = ENT.t else continue end
		
		
		if ENT and ENT.Spawner then		
			local foundtable
			for k,v in pairs(ENT.Spawner) do
				if istable(v) and v[1] == tablename then foundtable = k break end
			end
			
			if not foundtable then
				table.insert(ENT.Spawner,#ENT.Spawner,{tablename,readtablename,"List",{"Стандартный",paramname1,paramname2,paramname3,paramname4}})
				inserted_index1 = 2
				inserted_index2 = 3
				inserted_index3 = 4
				inserted_index4 = 5
			else
				inserted_index1 = table.insert(ENT.Spawner[foundtable][4],paramname1)
				inserted_index2 = table.insert(ENT.Spawner[foundtable][4],paramname2)
				inserted_index3 = table.insert(ENT.Spawner[foundtable][4],paramname3)
				inserted_index4 = table.insert(ENT.Spawner[foundtable][4],paramname4)
			end
		end
		
		if CLIENT and ENT and ENT.UpdateWagonNumber then
			local oldupdate = ENT.UpdateWagonNumber
			ENT.UpdateWagonNumber = function(self,...)
				oldupdate(self,...)
				
				for _,bogey in pairs(entsFindByClass("gmod_train_bogey")) do --не совсем крутой вариант, но не думаю, что это так страшно
					if bogeysWagons[bogey] == self then
						bogeysSkripType[bogey] = self:GetNW2Int(tablename,0)
						if bogeysSkripType[bogey] == inserted_index2 and not IsYazSoundFileExists then bogeysSkripType[bogey] = inserted_index1 end
						if bogeysSkripType[bogey] == inserted_index4 then
							local randomsoundindex = mathrandom(1,AllSoundsN)
							bogeys[bogey].CurrentWheelsSkripSound = {name_for_all_sounds..randomsoundindex,AllSounds[randomsoundindex][2],AllSounds[randomsoundindex][3]}
						end
						bogey:ReinitializeSounds()
					end
				end
			end
		end
	end
	if SERVER then return end

	local ENT = scripted_ents.GetStored("gmod_train_bogey")
	if not ENT then return else ENT = ENT.t end
	
	local flangsoundsForYaz = {
		flangea = true,
		flangeb = true,
		flange1 = true,
		--flange2 = true
	}
	
	local flangsounds = {
		flangea = true,
		flangeb = true,
		flange1 = true,
		flange2 = true
	}
	
	local yaz_sound_name = "flange2"
	
	local skip = {[1]=true,[inserted_index1]=true}
	local oldinitsounds = ENT.ReinitializeSounds
	ENT.ReinitializeSounds = function(self,...)
		oldinitsounds(self,...)
		for k,tbl in pairs(AllSounds) do
			local name = name_for_all_sounds..k
			if self.Sounds[name] then self.Sounds[name]:Stop() end
			self.SoundNames[name] = YazSoundFile
			local filename = tbl[1]
			util.PrecacheSound(filename)
			self.Sounds[name] = CreateSound(self, Sound(filename))
		end
		
		--если стандартный или стандартный рандомный, то пропустить, так как заменять звук не нужно
		if skip[bogeysSkripType[self]] then return end
		self.Sounds[yaz_sound_name]:Stop()
		self.SoundNames[yaz_sound_name] = YazSoundFile
		util.PrecacheSound(YazSoundFile)
		self.Sounds[yaz_sound_name] = CreateSound(self, Sound(YazSoundFile))
	end
	
	
	local mathRand = math.Rand
	
	local minpause = 0
	local maxpause = minpause + 2
	
	local minfadein = 0.1
	local minfadeout = 0.4
	
	local minlen = minfadein + minfadeout
	local maxlen = minlen + 5
	
	local tableRandom = table.Random
	
	local oldsetsoundstate = ENT.SetSoundState
	ENT.SetSoundState = function(self,sound,volume,pitch,name,level,...)
		if bogeysSkripType[self] == inserted_index2 then
			if flangsoundsForYaz[sound] then volume = 0
			elseif sound == yaz_sound_name and volume > 0 then
				local self = bogeys[self]
				local CurTime = CurTime()
				if CurTime <= self.EndEmit and CurTime >= self.StartEmit then
					--тут есть звук
					pitch = pitch - 0.2
					volume = volume*4--делаю чуток погромче
					local percentDone = ((CurTime-self.StartEmit)/self.EmitDist)*100
					if percentDone <= self.FadeInPercent then
						--возрастание от 0 до volume
						volume = volume*(percentDone/self.FadeInPercent)
					end
					if percentDone >= self.FadeOutPercent then
						--убывание от volume до 0
						volume = volume*((100-percentDone)/(self.FadeOutPercentR))
					end
				else
					--тут нет звука
					volume = 0
					if CurTime >= self.EndEmit then
						self.StartEmit = CurTime + mathRand(minpause,maxpause)
						self.EndEmit = self.StartEmit + mathRand(minlen,maxlen)
						self.EmitDist = self.EndEmit - self.StartEmit
						
						--даю минимум 0.1 секунды на возрастание и 0.4 на затухание	
						local minstart = (minfadein/self.EmitDist)*100
						local maxend = 100-(minfadeout/self.EmitDist)*100
						
						self.FadeInPercent = mathrandom(minstart,maxend)
						self.FadeOutPercent = mathrandom(self.FadeInPercent,maxend)
						self.FadeOutPercentR = 100-self.FadeOutPercent
					end
				end
			end
		elseif bogeysSkripType[self] == inserted_index1 then
			if flangsounds[sound] and volume > 0 then
				local self = bogeys[self]
				local CurTime = CurTime()
				if CurTime <= self.EndEmit and CurTime >= self.StartEmit then
					--тут есть звук
					volume = volume*1.5--делаю чуток погромче
					local percentDone = ((CurTime-self.StartEmit)/self.EmitDist)*100
					if percentDone <= self.FadeInPercent then
						--возрастание от 0 до volume
						volume = volume*(percentDone/self.FadeInPercent)
					end
					if percentDone >= self.FadeOutPercent then
						--убывание от volume до 0
						volume = volume*((100-percentDone)/(self.FadeOutPercentR))
					end
				else
					--тут нет звука
					volume = 0
					if CurTime >= self.EndEmit then
						self.StartEmit = CurTime + mathRand(minpause,maxpause)
						self.EndEmit = self.StartEmit + mathRand(minlen,maxlen)
						self.EmitDist = self.EndEmit - self.StartEmit
						
						--даю минимум 0.1 секунды на возрастание и 0.4 на затухание	
						local minstart = (minfadein/self.EmitDist)*100
						local maxend = 100-(minfadeout/self.EmitDist)*100
						
						self.FadeInPercent = mathrandom(minstart,maxend)
						self.FadeOutPercent = mathrandom(self.FadeInPercent,maxend)
						self.FadeOutPercentR = 100-self.FadeOutPercent
					end
				end
			end
		elseif bogeysSkripType[self] == inserted_index3 then
			if flangsoundsForYaz[sound] then volume = 0
			elseif sound == yaz_sound_name and volume > 0 then
				local self = bogeys[self]
				local CurTime = CurTime()
				if CurTime <= self.EndEmit and CurTime >= self.StartEmit then
					local soundparams = self.CurrentWheelsSkripSound
					sound = soundparams[1]
					
					--тут есть звук
					volume = volume*soundparams[2]--делаю чуток погромче
					pitch = pitch + soundparams[3]--изменяю pitch
					local percentDone = ((CurTime-self.StartEmit)/self.EmitDist)*100
					if percentDone <= self.FadeInPercent then
						--возрастание от 0 до volume
						volume = volume*(percentDone/self.FadeInPercent)
					end
					if percentDone >= self.FadeOutPercent then
						--убывание от volume до 0
						volume = volume*((100-percentDone)/(self.FadeOutPercentR))
					end
				else
					--тут нет звука
					volume = 0
					if CurTime >= self.EndEmit then
						local randomsoundindex = mathrandom(1,AllSoundsN)
						self.CurrentWheelsSkripSound = {name_for_all_sounds..randomsoundindex,AllSounds[randomsoundindex][2],AllSounds[randomsoundindex][3]}
						self.StartEmit = CurTime + mathRand(minpause,maxpause)
						self.EndEmit = self.StartEmit + mathRand(minlen,maxlen)
						self.EmitDist = self.EndEmit - self.StartEmit
						
						--даю минимум 0.1 секунды на возрастание и 0.4 на затухание	
						local minstart = (minfadein/self.EmitDist)*100
						local maxend = 100-(minfadeout/self.EmitDist)*100
						
						self.FadeInPercent = mathrandom(minstart,maxend)
						self.FadeOutPercent = mathrandom(self.FadeInPercent,maxend)
						self.FadeOutPercentR = 100-self.FadeOutPercent
					end
				end
			end
		elseif bogeysSkripType[self] == inserted_index4 then
			if flangsoundsForYaz[sound] then volume = 0
			elseif sound == yaz_sound_name and volume > 0 then
				local self = bogeys[self]
				local CurTime = CurTime()
				if CurTime <= self.EndEmit and CurTime >= self.StartEmit then
					local soundparams = self.CurrentWheelsSkripSound
					sound = soundparams[1]
					
					--тут есть звук
					volume = volume*soundparams[2]--делаю чуток погромче
					pitch = pitch + soundparams[3]--изменяю pitch
					local percentDone = ((CurTime-self.StartEmit)/self.EmitDist)*100
					if percentDone <= self.FadeInPercent then
						--возрастание от 0 до volume
						volume = volume*(percentDone/self.FadeInPercent)
					end
					if percentDone >= self.FadeOutPercent then
						--убывание от volume до 0
						volume = volume*((100-percentDone)/(self.FadeOutPercentR))
					end
				else
					--тут нет звука
					volume = 0
					if CurTime >= self.EndEmit then
						self.StartEmit = CurTime + mathRand(minpause,maxpause)
						self.EndEmit = self.StartEmit + mathRand(minlen,maxlen)
						self.EmitDist = self.EndEmit - self.StartEmit
						
						--даю минимум 0.1 секунды на возрастание и 0.4 на затухание	
						local minstart = (minfadein/self.EmitDist)*100
						local maxend = 100-(minfadeout/self.EmitDist)*100
						
						self.FadeInPercent = mathrandom(minstart,maxend)
						self.FadeOutPercent = mathrandom(self.FadeInPercent,maxend)
						self.FadeOutPercentR = 100-self.FadeOutPercent
					end
				end
			end
		end
		oldsetsoundstate(self,sound,volume,pitch,name,level,...)
	end
	
	local oldinit = ENT.Initialize
	ENT.Initialize = function(self,...)
		bogeys[self] = {}
		local b = bogeys[self]
		b.FadeInPercent = mathrandom(5,95)
		b.FadeOutPercent = mathrandom(b.FadeInPercent,95)
		b.FadeOutPercentR = 100-b.FadeInPercent
		b.StartEmit = 0
		b.EndEmit = 0
		b.EmitDist = 0
		local randomsoundindex = mathrandom(1,AllSoundsN)
		b.CurrentWheelsSkripSound = {name_for_all_sounds..randomsoundindex,AllSounds[randomsoundindex][2],AllSounds[randomsoundindex][3]}
		bogeysWagons[self] = self:GetNW2Entity("TrainEntity")
		oldinit(self,...)
	end
end)