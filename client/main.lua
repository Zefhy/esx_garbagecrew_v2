ESX = nil
local AreaType, AreaMarker, AreaInfo, currentZone = nil, nil, nil, nil
local HasAlreadyEnteredArea, clockedin, vehiclespawned = false, false, false
local work_truck, NewDrop, LastDrop = nil, nil, nil
local Blips = {}


Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerData = ESX.GetPlayerData()
end)



RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	TriggerServerEvent('esx_garbagejob:setconfig')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RegisterNetEvent('esxgarbagejob:movetruckcount')
AddEventHandler('esxgarbagejob:movetruckcount', function(count)
	Config.TruckPlateNumb = count
end)


RegisterNetEvent('esx_garbagecrew:enteredarea')
AddEventHandler('esx_garbagecrew:enteredarea', function(zone)
	lastZone = zone  
	CurrentAction = zone.name

	if CurrentAction == 'timeclock' then
		MenuCloakRoom()
	end

	if CurrentAction == 'vehiclelist' then
		if clockedin  then
			MenuVehicleSpawner()
		end
	end

	if CurrentAction == 'endmission' then
		CurrentActionMsg = _U('cancel_mission')
	end

	if CurrentAction == 'collection' then
		if IsPedInAnyVehicle(GetPlayerPed(-1)) and GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(-1), false)) == worktruckplate then
			CurrentActionMsg = _U('collection')
		else
			CurrentActionMsg = _U('need_work_truck')
		end

	end

	if CurrentAction == 'bags' then


	end

end)

RegisterNetEvent('esx_garbagecrew:leftarea')
AddEventHandler('esx_garbagecrew:leftarea', function()
	ESX.UI.Menu.CloseAll()    
    CurrentAction = nil
	CurrentActionMsg = ''
end)

Citizen.CreateThread( function()
	while true do 
		sleep = 1000
		ply = GetPlayerPed(-1)
		plyloc = GetEntityCoords(ply)

		for i, v in pairs(Config.Zones) do
			if GetDistanceBetweenCoords(plyloc, v.pos, true)  < 20.0 then
				sleep = 0
				if v.name == 'timeclock' and IsGarbageJob() then
					DrawMarker(1, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.size,  v.size, 1.0, 204,204, 0, 100, false, true, 2, false, false, false, false)
				elseif v.name == 'endmission' and vehiclespawned then
					DrawMarker(1, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0,  v.size,  v.size, 1.0, 204,204, 0, 100, false, true, 2, false, false, false, false)
				elseif v.name == 'vehiclelist' and clockedin and not vehiclespawned then
					DrawMarker(1, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0,  v.size,  v.size, 1.0, 204,204, 0, 100, false, true, 2, false, false, false, false)
				end
			end
		end

		if oncollection then
			if GetDistanceBetweenCoords(plyloc, NewDrop.pos, true)  < 20.0 then
				sleep = 0
				DrawMarker(1, NewDrop.pos.x,  NewDrop.pos.y,  NewDrop.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0,  NewDrop.size,  NewDrop.size, 1.0, 204,204, 0, 100, false, true, 2, false, false, false, false)
			end
		end

		Citizen.Wait(sleep)
	end
end)


Citizen.CreateThread( function()
	while true do 
		Citizen.Wait(0)
		while CurrentAction ~= nil and CurrentActionMsg ~= nil do
			Citizen.Wait(0)
			SetTextComponentFormat('STRING')
        	AddTextComponentString(CurrentActionMsg)
			DisplayHelpTextFromStringLabel(0, 0, 1, -1)

			if IsControlJustReleased(0, 38) then

				if CurrentAction == 'endmission' then
					ESX.Game.DeleteVehicle(work_truck)
					vehiclespawned = false
					CurrentAction =nil
					CurrentActionMsg = nil
				end

				if CurrentAction == 'collection' then
					if CurrentActionMsg == _U('collection') then
						SelectBinAndCrew()
					end
				end

				if CurrentActionMsg == 'bags' then
					CollectBagFromBin()
				end

			end
		end

	end
end)
-- thread so the script knows you have entered a markers area - 
Citizen.CreateThread( function()
	while true do 
		sleep = 2500
		ply = GetPlayerPed(-1)
		plyloc = GetEntityCoords(ply)
		IsInArea = false
		currentZone = nil
		
		for i,v in pairs(Config.Zones) do
			if GetDistanceBetweenCoords(plyloc, v.pos, false)  <  v.size then
				IsInArea = true
				currentZone = v
			end
		end

		if oncollection then
			if GetDistanceBetweenCoords(plyloc, NewDrop.pos, true)  <  NewDrop.size then
				IsInArea = true
				currentZone = NewDrop
			end
		end

		if IsInArea and not HasAlreadyEnteredArea then
			HasAlreadyEnteredArea = true
			sleep = 0
			TriggerEvent('esx_garbagecrew:enteredarea', currentZone)
		end
	

		if not IsInArea and HasAlreadyEnteredArea then
			HasAlreadyEnteredArea = false
			sleep = 2500
			TriggerEvent('esx_garbagecrew:leftarea', currentZone)

		end

		Citizen.Wait(sleep)
	end
end)

function SelectBinAndCrew()
	local bin = nil
	for i, v in pairs(Config.DumpstersAvaialbe) do
		bin = GetClosestObjectOfType(NewDrop.pos, 5.0, GetHashKey(v), false, false, false )
		if bin ~= nil then
			break
		end
	end
	
	if bin ~= nil then
		truckplate = GetVehicleNumberPlateText(work_truck)
		TriggerServerEvent('esx_garbagecrew:setworkers', GetEntityCoords(bin), truckplate )
	else
		ESX.ShowNotification('No trash abailable for pickup at this location.')
		FindDeliveryLoc(LastDrop)
	end
end

function FindDeliveryLoc(LastDrop)
	if LastDrop ~= nil then
		lastregion = GetNameOfZone(LastDrop.pos)
	end
	local newdropregion = nil
	while newdropregion == nil or newdropregion == lastregion do
		randomloc = math.random(1, #Config.Collections)
		newdropregion = GetNameOfZone(Config.Collections[randomloc].pos)
	end
	NewDrop = Config.Collections[randomloc]
	LastDrop = NewDrop
	if Blips['delivery'] ~= nil then
		RemoveBlip(Blips['delivery'])
		Blips['delivery'] = nil
	end
	
	if Blips['endmission'] ~= nil then
		RemoveBlip(Blips['endmission'])
		Blips['endmission'] = nil
	end
	
	Blips['delivery'] = AddBlipForCoord(NewDrop.pos)
	SetBlipRoute(Blips['delivery'], true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('blip_delivery'))
	EndTextCommandSetBlipName(Blips['delivery'])
	
	Blips['endmission'] = AddBlipForCoord(Config.Zones[1].pos)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('blip_goal'))
	EndTextCommandSetBlipName(Blips['endmission'])

	oncollection = true
end

function IsGarbageJob()
	if ESX ~= nil then
		local isjob = false
		if PlayerData.job.name == 'garbage' then
			isjob = true
		end
		return isjob
	end
end

function MenuCloakRoom()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open(
		'default', GetCurrentResourceName(), 'cloakroom',
		{
			title    = _U('cloakroom'),
			elements = {
				{label = _U('job_wear'), value = 'job_wear'},
				{label = _U('citizen_wear'), value = 'citizen_wear'}
			}
		},
		function(data, menu)
			if data.current.value == 'citizen_wear' then
				clockedin = false
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					  local model = nil

					  if skin.sex == 0 then
						model = GetHashKey("mp_m_freemode_01")
					  else
						model = GetHashKey("mp_f_freemode_01")
					  end

					  RequestModel(model)
					  while not HasModelLoaded(model) do
						RequestModel(model)
						Citizen.Wait(1)
					  end

					  SetPlayerModel(PlayerId(), model)
					  SetModelAsNoLongerNeeded(model)

					  TriggerEvent('skinchanger:loadSkin', skin)
					  TriggerEvent('esx:restoreLoadout')
        end)
      end
			if data.current.value == 'job_wear' then
				clockedin = true
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
	    			if skin.sex == 0 then
	    				TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
					else
	    				TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)

					RequestModel(model)
					while not HasModelLoaded(model) do
					RequestModel(model)
					Citizen.Wait(0)
					end

				SetPlayerModel(PlayerId(), model)
				SetModelAsNoLongerNeeded(model)
					end
					
				end)

			end	
			menu.close()
		end,
		function(data, menu)
			menu.close()
		end
	)
end

function MenuVehicleSpawner()
	local elements = {}

	for i=1, #Config.Trucks, 1 do
		table.insert(elements, {label = GetLabelText(GetDisplayNameFromVehicleModel(Config.Trucks[i])), value = Config.Trucks[i]})
	end


	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open(
		'default', GetCurrentResourceName(), 'vehiclespawner',
		{
			title    = _U('vehiclespawner'),
			elements = elements
		},
		function(data, menu)
			ESX.Game.SpawnVehicle(data.current.value, Config.VehicleSpawn.pos, 270.0, function(vehicle)
				local trucknumber = Config.TruckPlateNumb + 1
				if trucknumber <=9 then
					SetVehicleNumberPlateText(vehicle, 'GCREW00'..trucknumber)
					worktruckplate =   'GCREW00'..trucknumber 
				elseif trucknumber <=99 then
					SetVehicleNumberPlateText(vehicle, 'GCREW0'..trucknumber)
					worktruckplate =   'GCREW0'..trucknumber 
				else
					SetVehicleNumberPlateText(vehicle, 'GCREW'..trucknumber)
					worktruckplate =   'GCREW'..trucknumber 
				end


				TriggerServerEvent('esxgarbagejob:movetruckcount')   
				SetEntityAsMissionEntity(vehicle,true, true)
				TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)  
				vehiclespawned = true 
				work_truck = vehicle
				FindDeliveryLoc(LastDrop)

			end)

			menu.close()
		end,
		function(data, menu)
			menu.close()
		end
	)
end


Citizen.CreateThread(function()
	local blip = AddBlipForCoord(Config.Zones[2].pos)
  
	SetBlipSprite (blip, 318)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.2)
	SetBlipColour (blip, 5)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('blip_job'))
	EndTextCommandSetBlipName(blip)
end)