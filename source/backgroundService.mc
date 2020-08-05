using Toybox.Background;
using Toybox.Activity;
using Toybox.Application;
using Toybox.Communications as Comms;
using Toybox.System as Sys;

(:background)
class ClutterlessServiceDelegate extends Toybox.System.ServiceDelegate{ 
	var unit = "metric";
	(:background_method)
	function initialize() {
		Sys.ServiceDelegate.initialize();
		if (Sys.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE){
			unit = "imperial";
		}
	}
	(:background_method)
    function onTemporalEvent() {
       
		getWeather();
       
    }
    (:background_method)
    function getWeather(){
		var lat, lon;
	
		lat = Application.getApp().getProperty("lat");
		lon = Application.getApp().getProperty("lon");
		
	
		Comms.makeWebRequest("https://api.openweathermap.org/data/2.5/weather", 
					/*
					 * URL
					 */ 
					
					{
						"lat"   => lat,
						"lon"   => lon,
						"appid" => "d72271af214d870eb94fe8f9af450db4",
						"units" => unit // Celcius.
					},
					
					/*
					 * PARAMS 
					 */
					
					{
						:method       => Comms.HTTP_REQUEST_METHOD_GET,
						:headers      => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
						:responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
					},
					/*
					 * OPTIONS
					 */
					
					method(:onReceiveWeatherdata));
		
	}
	
	(:background_method)
	function onReceiveWeatherdata(response, data){
		if(response != 200){
			Sys.println(response);
			Background.exit({"response" => response});
		} else {
			var weatherlookuptable = {// Day icon               Night icon                Description
								"01d" => "h" /* 61453 */, "01n" => "f" /* 61486 */, // clear sky
								"02d" => "d" /* 61452 */, "02n" => "g" /* 61569 */, // few clouds
								"03d" => "f" /* 61442 */, "03n" => "h" /* 61574 */, // scattered clouds
								"04d" => "f" /* 61459 */, "04n" => "I" /* 61459 */, // broken clouds: day and night use same icon
								"09d" => "c" /* 61449 */, "09n" => "d" /* 61481 */, // shower rain
								"10d" => "g" /* 61448 */, "10n" => "c" /* 61480 */, // rain
								"11d" => "a" /* 61445 */, "11n" => "b" /* 61477 */, // thunderstorm
								"13d" => "b" /* 61450 */, "13n" => "e" /* 61482 */, // snow
								"50d" => "e" /* 61441 */, "50n" => "a" /* 61475 */, // mist
			};
			var result = {
				"cod" => data["cod"],
				"lat" => data["coord"]["lat"],
				"lon" => data["coord"]["lon"],
				"dt" => data["dt"],
				"temp" => data["main"]["temp"],
				"humidity" => data["main"]["humidity"],
				"icon" => weatherlookuptable[data["weather"][0]["icon"]]
			};
			Background.exit([response, result]);
		}
	}

}
