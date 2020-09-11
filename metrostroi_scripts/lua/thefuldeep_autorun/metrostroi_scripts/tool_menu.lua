if SERVER then return end

CreateClientConVar("metrostroi_custom_time", "3", true, false, "" )

CreateClientConVar("hideothertrains", "0", true, false, "" )

CreateClientConVar("hidealltrains","0",true,false,"")

CreateClientConVar("hidetrains_behind_props","1",true,false,"")

CreateClientConVar("hidetrains_behind_player","1",true,false,"")

CreateClientConVar("draw_signal_routes","1",true,false,"")

CreateClientConVar("metrostroi_custom_passengers","0",true,false,"")

hook.Add( "PopulateToolMenu", "MetrostroiCustomPanel", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Metrostroi", "metrostroi_client_panel2", "Клиент2", "", "", function(panel)
		panel:ClearControls()
		panel:CheckBox("Показывать интервальные часы","showintervalclocks")
		panel:CheckBox("Режим съемки","metrostroi_screenshotmode")
		panel:CheckBox("Не прогружать все составы","hidealltrains")
		panel:CheckBox("Не прогружать чужие составы","hideothertrains")
		panel:CheckBox("Не прогружать составы за спиной","hidetrains_behind_player")
		panel:CheckBox("Не прогружать составы за пропами","hidetrains_behind_props")
		panel:CheckBox("Отображать команды светофоров","draw_signal_routes")
		panel:CheckBox("Кастомные пассажиры","metrostroi_custom_passengers")
		panel:NumSlider("Часовой пояс","metrostroi_custom_time",-12, 12,0)
	end)
end)