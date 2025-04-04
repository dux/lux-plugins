class HtmlForm
  # t=Time.now.utc; TZInfo::Timezone.all_identifiers.map { |name| tz = TZInfo::Timezone.get(name); [name, -((t - tz.utc_to_local(t)) / 60).round] }.select { |el|el[1] == 120 }

  TIME_ZONES ||= {}
  TIME_ZONES[10]  = {daytime: false, value: -720, name:"(GMT-12:00) International Date Line West"}
  TIME_ZONES[20]  = {daytime: false, value: -660, name:"(GMT-11:00) Midway Island, Samoa"}
  TIME_ZONES[30]  = {daytime: false, value: -600, name:"(GMT-10:00) Hawaii"}
  TIME_ZONES[30]  = {daytime: true, value: -540,  name:"(GMT-09:00) Alaska"}
  TIME_ZONES[40]  = {daytime: true, value: -480,  name:"(GMT-08:00) Pacific Time (US & Canada)"}
  TIME_ZONES[50]  = {daytime: true, value: -480,  name:"(GMT-08:00) Tijuana, Baja California"}
  TIME_ZONES[60]  = {daytime: false, value: -420, name:"(GMT-07:00) Arizona"}
  TIME_ZONES[70]  = {daytime: true, value: -420,  name:"(GMT-07:00) Chihuahua, La Paz, Mazatlan"}
  TIME_ZONES[80]  = {daytime: true, value: -420,  name:"(GMT-07:00) Mountain Time (US & Canada)"}
  TIME_ZONES[90]  = {daytime: false, value: -360, name:"(GMT-06:00) Central America"}
  TIME_ZONES[100] = {daytime: true, value: -360,  name:"(GMT-06:00) Central Time (US & Canada)"}
  TIME_ZONES[110] = {daytime: true, value: -360,  name:"(GMT-06:00) Guadalajara, Mexico City, Monterrey"}
  TIME_ZONES[120] = {daytime: false, value: -360, name:"(GMT-06:00) Saskatchewan"}
  TIME_ZONES[130] = {daytime: false, value: -300, name:"(GMT-05:00) Bogota, Lima, Quito, Rio Branco"}
  TIME_ZONES[140] = {daytime: true, value: -300,  name:"(GMT-05:00) Eastern Time (US & Canada)"}
  TIME_ZONES[150] = {daytime: true, value: -300,  name:"(GMT-05:00) Indiana (East)"}
  TIME_ZONES[160] = {daytime: true, value: -240,  name:"(GMT-04:00) Atlantic Time (Canada)"}
  TIME_ZONES[170] = {daytime: false, value: -240, name:"(GMT-04:00) Caracas, La Paz"}
  TIME_ZONES[180] = {daytime: false, value: -240, name:"(GMT-04:00) Manaus"}
  TIME_ZONES[190] = {daytime: true, value: -240,  name:"(GMT-04:00) Santiago"}
  TIME_ZONES[200] = {daytime: true, value: -270,  name:"(GMT-03:30) Newfoundland"}
  TIME_ZONES[210] = {daytime: true, value: -180,  name:"(GMT-03:00) Brasilia"}
  TIME_ZONES[220] = {daytime: false, value: -180, name:"(GMT-03:00) Buenos Aires, Georgetown"}
  TIME_ZONES[230] = {daytime: true, value: -180,  name:"(GMT-03:00) Greenland"}
  TIME_ZONES[240] = {daytime: true, value: -180,  name:"(GMT-03:00) Montevideo"}
  TIME_ZONES[250] = {daytime: true, value: -120,  name:"(GMT-02:00) Mid-Atlantic"}
  TIME_ZONES[260] = {daytime: false, value: -60,  name:"(GMT-01:00) Cape Verde Is."}
  TIME_ZONES[270] = {daytime: true, value: -60,   name:"(GMT-01:00) Azores"}
  TIME_ZONES[280] = {daytime: false, value: 0,    name:"(GMT+00:00) Casablanca, Monrovia, Reykjavik"}
  TIME_ZONES[290] = {daytime: true, value: 0,     name:"(GMT+00:00) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"}
  TIME_ZONES[300] = {daytime: true, value: 60,    name:"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"}
  TIME_ZONES[310] = {daytime: true, value: 60,    name:"(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague"}
  TIME_ZONES[320] = {daytime: true, value: 60,    name:"(GMT+01:00) Brussels, Copenhagen, Madrid, Paris"}
  TIME_ZONES[330] = {daytime: true, value: 60,    name:"(GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb"}
  TIME_ZONES[340] = {daytime: true, value: 60,    name:"(GMT+01:00) West Central Africa"}
  TIME_ZONES[350] = {daytime: true, value: 120,   name:"(GMT+02:00) Amman"}
  TIME_ZONES[360] = {daytime: true, value: 120,   name:"(GMT+02:00) Athens, Bucharest, Istanbul"}
  TIME_ZONES[370] = {daytime: true, value: 120,   name:"(GMT+02:00) Beirut"}
  TIME_ZONES[380] = {daytime: true, value: 120,   name:"(GMT+02:00) Cairo"}
  TIME_ZONES[390] = {daytime: false, value: 120,  name:"(GMT+02:00) Harare, Pretoria"}
  TIME_ZONES[400] = {daytime: true, value: 120,   name:"(GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius"}
  TIME_ZONES[510] = {daytime: true, value: 120,   name:"(GMT+02:00) Jerusalem"}
  TIME_ZONES[520] = {daytime: true, value: 120,   name:"(GMT+02:00) Minsk"}
  TIME_ZONES[530] = {daytime: true, value: 120,   name:"(GMT+02:00) Windhoek"}
  TIME_ZONES[540] = {daytime: false, value: 180,  name:"(GMT+03:00) Kuwait, Riyadh, Baghdad"}
  TIME_ZONES[550] = {daytime: true, value: 180,   name:"(GMT+03:00) Moscow, St. Petersburg, Volgograd"}
  TIME_ZONES[560] = {daytime: false, value: 180,  name:"(GMT+03:00) Nairobi"}
  TIME_ZONES[570] = {daytime: false, value: 180,  name:"(GMT+03:00) Tbilisi"}
  TIME_ZONES[580] = {daytime: true, value: 210,   name:"(GMT+03:30) Tehran"}
  TIME_ZONES[590] = {daytime: false, value: 240,  name:"(GMT+04:00) Abu Dhabi, Muscat"}
  TIME_ZONES[600] = {daytime: true, value: 240,   name:"(GMT+04:00) Baku"}
  TIME_ZONES[610] = {daytime: true, value: 240,   name:"(GMT+04:00) Yerevan"}
  TIME_ZONES[620] = {daytime: false, value: 270,  name:"(GMT+04:30) Kabul"}
  TIME_ZONES[630] = {daytime: true, value: 300,   name:"(GMT+05:00) Yekaterinburg"}
  TIME_ZONES[640] = {daytime: false, value: 300,  name:"(GMT+05:00) Islamabad, Karachi, Tashkent"}
  TIME_ZONES[650] = {daytime: false, value: 330,  name:"(GMT+05:30) Sri Jayawardenapura"}
  TIME_ZONES[660] = {daytime: false, value: 330,  name:"(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi"}
  TIME_ZONES[670] = {daytime: false, value: 345,  name:"(GMT+05:45) Kathmandu"}
  TIME_ZONES[680] = {daytime: true, value: 360,   name:"(GMT+06:00) Almaty, Novosibirsk"}
  TIME_ZONES[690] = {daytime: false, value: 360,  name:"(GMT+06:00) Astana, Dhaka"}
  TIME_ZONES[700] = {daytime: false, value: 390,  name:"(GMT+06:30) Yangon (Rangoon)"}
  TIME_ZONES[710] = {daytime: false, value: 420,  name:"(GMT+07:00) Bangkok, Hanoi, Jakarta"}
  TIME_ZONES[720] = {daytime: true, value: 420,   name:"(GMT+07:00) Krasnoyarsk"}
  TIME_ZONES[730] = {daytime: false, value: 480,  name:"(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi"}
  TIME_ZONES[740] = {daytime: false, value: 480,  name:"(GMT+08:00) Kuala Lumpur, Singapore"}
  TIME_ZONES[750] = {daytime: false, value: 480,  name:"(GMT+08:00) Irkutsk, Ulaan Bataar"}
  TIME_ZONES[760] = {daytime: false, value: 480,  name:"(GMT+08:00) Perth"}
  TIME_ZONES[770] = {daytime: false, value: 480,  name:"(GMT+08:00) Taipei"}
  TIME_ZONES[780] = {daytime: false, value: 540,  name:"(GMT+09:00) Osaka, Sapporo, Tokyo"}
  TIME_ZONES[790] = {daytime: false, value: 540,  name:"(GMT+09:00) Seoul"}
  TIME_ZONES[800] = {daytime: true, value: 540,   name:"(GMT+09:00) Yakutsk"}
  TIME_ZONES[810] = {daytime: false, value: 570,  name:"(GMT+09:30) Adelaide"}
  TIME_ZONES[820] = {daytime: false, value: 570,  name:"(GMT+09:30) Darwin"}
  TIME_ZONES[830] = {daytime: false, value: 600,  name:"(GMT+10:00) Brisbane"}
  TIME_ZONES[840] = {daytime: true, value: 600,   name:"(GMT+10:00) Canberra, Melbourne, Sydney"}
  TIME_ZONES[850] = {daytime: true, value: 600,   name:"(GMT+10:00) Hobart"}
  TIME_ZONES[860] = {daytime: false, value: 600,  name:"(GMT+10:00) Guam, Port Moresby"}
  TIME_ZONES[870] = {daytime: true, value: 600,   name:"(GMT+10:00) Vladivostok"}
  TIME_ZONES[880] = {daytime: true, value: 660,   name:"(GMT+11:00) Magadan, Solomon Is., New Caledonia"}
  TIME_ZONES[890] = {daytime: true, value: 720,   name:"(GMT+12:00) Auckland, Wellington"}
  TIME_ZONES[900] = {daytime: false, value: 720,  name:"(GMT+12:00) Fiji, Kamchatka, Marshall Is."}
  TIME_ZONES[910] = {daytime: false, value: 780,  name:"(GMT+13:00) Nuku'alofa"}
end
