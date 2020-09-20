using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Background;
using Toybox.Position;
using Toybox.System as Sys;
using Toybox.Activity;
using Toybox.ActivityMonitor;

class graph 
{	
	var settings;
	function get_data_type() {
    		return 1;
	}
	
	function get_data_interator(type) {
		if (type == 1) {
		        return Toybox.SensorHistory.getHeartRateHistory({});
		} else if (type == 2) {
		        return Toybox.SensorHistory.getElevationHistory({});   
		} else if (type == 3) {	
			return Toybox.SensorHistory.getPressureHistory({});
		} else if (type == 4) {  	
			return Toybox.SensorHistory.getTemperatureHistory({});
	    }
	    return null;
	}

    
	function parse_data_value(type, value) {
	if (type==1) {
		return value;
	} else if (type==2) {
		if (settings.elevationUnits == System.UNIT_STATUTE) {
			value *= 3.28084;
		}
		return value;
	} else if (type==3) {
	    	return value/100.0;
	} else if (type==4) {
		if (settings.temperatureUnits == System.UNIT_STATUTE) {
			value = value * (9.0 / 5) + 32; // Convert to Farenheit: ensure floating point division.
		} 
		return value;
	    }
    }
    
    function draw(dc) {  	
	    	settings = Sys.getDeviceSettings();
	    	
		var primaryColor = 0xFFFFFF;
		var position_y = dc.getHeight() * 0.70;
		var position_x = dc.getWidth() / 2;
		var smallDigitalFont = 2;
		var graph_height = dc.getHeight() * 0.2;
		var graph_width = dc.getWidth() * 0.60;
	    	
	    	//Calculation
	        var HistoryIter = get_data_interator(1);
	        
	        if (HistoryIter == null) {
	        	dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
	        	dc.drawText(position_x, position_y, smallDigitalFont, "--", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	        	return;
	        }
	        
	        var HistoryMin = HistoryIter.getMin();
	        var HistoryMax = HistoryIter.getMax();
	        
	        if (HistoryMin == null || HistoryMax == null) {
	        	dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
	        	dc.drawText(position_x, position_y, smallDigitalFont, "-", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	        	return;
	        }// else if (HistoryMin.data == null || HistoryMax.data == null) {
	        //	dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
	        //	dc.drawText(position_x, position_y, smallDigitalFont, "-", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	        //	return;
	        //}
	        
	        var minMaxDiff = (HistoryMax - HistoryMin).toFloat();
	        
	        var xStep = graph_width;
	        var height = graph_height;
	        var HistoryPresent = 0;
	        
	        var graphType = 2;
	
		var HistoryNew = 0;
		var lastyStep = 0;
		var step_max = -1;
		var step_min = -1;
			
		var latest_sample = HistoryIter.next();
		if (latest_sample != null) {
			HistoryPresent = latest_sample.data;
			if (HistoryPresent != null) {
				// draw diagram
				var historyDifPers = (HistoryPresent - HistoryMin) / minMaxDiff;
				var yStep = historyDifPers * height;
				yStep = yStep > height ? height : yStep;
				yStep = yStep < 0 ? 0 : yStep;
				lastyStep = yStep;
			} else {
				lastyStep = null;
			}
		}
	        
		dc.setPenWidth(2);
		dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
		
		//Build and draw Iteration
		for(var i = graph_width; i > 0; i--){
			var sample = HistoryIter.next();
			
			if (sample != null) {
				HistoryNew = sample.data;
				if (HistoryNew == HistoryMax) {
					step_max = xStep;
				} else if (HistoryNew == HistoryMin) {
					step_min = xStep;
				}
				if (HistoryNew != null) {
					// draw diagram
					var historyDifPers = ((HistoryNew - HistoryMin))/minMaxDiff;
					var yStep = historyDifPers * height;
					yStep = yStep > height ? height : yStep;
					yStep = yStep < 0 ? 0 : yStep;
							
					if (lastyStep != null){
						// draw diagram
						dc.drawLine(position_x + (xStep - graph_width / 2), 
								((graphType == 1) ? (position_y - (lastyStep - graph_height / 2)) : (dc.getHeight() * 0.83)), 
								position_x + (xStep - graph_width / 2), 
								position_y - (yStep - graph_height / 2));
					}
					lastyStep = yStep;
				}
			}
			xStep--;
		}
		
			
		dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
	
		if (HistoryPresent == null) {
			dc.drawText(position_x, 
				position_y + (position==1?(graph_height/2 + 10):(-graph_height/2-16)), 
				smallDigitalFont, 
				"-", 
				Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			return;
		}
		var value_label = parse_data_value(1, HistoryPresent);
		var labelll = value_label.format("%d");
						
		settings = null;
    }

}

class halfMoon {
	function draw(dc) {
		
	}

}

class complications {
	var init = false;
	var main;
	var methodRight = 1; 
	var methodLeft = 1;
	var methodRightBottom = 1;
	var methodLeftBottom = 1;
	
	function initialize() {
		var app = Application.getApp();
		main = new ClutterlessView();
		methodRight = main.getField(app.getProperty("complicationData1"));
		methodLeft  = main.getField(app.getProperty("complicationData2"));
		methodRightBottom = main.getField(app.getProperty("complicationData3"));
		methodLeftBottom  = main.getField(app.getProperty("complicationData4"));
	}
	
	
	function draw(dc) {
		if (!init){
			initialize();
		}
		data = methodRight.invoke();
		dc.drawText(scrRadius - 30, scrRadius + 25, regfont, data[0], Graphics.TEXT_JUSTIFY_RIGHT);
		dc.drawText(scrRadius - 5, scrRadius + 32, iconfont, data[1], Graphics.TEXT_JUSTIFY_RIGHT);	
		dc.drawText(scrRadius - 5, scrRadius + 32, weatherfont, data[2], Graphics.TEXT_JUSTIFY_RIGHT);	
		
		
		
		data = methodLeft.invoke();
		dc.drawText(scrRadius + 30, scrRadius + 25, regfont, data[0], Graphics.TEXT_JUSTIFY_LEFT);
		dc.drawText(scrRadius + 5, scrRadius + 32, iconfont, data[1], Graphics.TEXT_JUSTIFY_LEFT);
		dc.drawText(scrRadius + 3, scrRadius + 32, weatherfont, data[2], Graphics.TEXT_JUSTIFY_LEFT);
		
		
		
		data = methodLeftBottom.invoke();
		dc.drawText(scrRadius - 30, scrRadius + 48, regfont, data[0], Graphics.TEXT_JUSTIFY_RIGHT);
		dc.drawText(scrRadius - 5, scrRadius + 55, iconfont, data[1], Graphics.TEXT_JUSTIFY_RIGHT);
		dc.drawText(scrRadius - 5, scrRadius + 55, weatherfont, data[2], Graphics.TEXT_JUSTIFY_RIGHT);
		
		
		
		data = methodRightBottom.invoke();
		dc.drawText(scrRadius + 30, scrRadius + 48, regfont, data[0], Graphics.TEXT_JUSTIFY_LEFT);
		dc.drawText(scrRadius + 5, scrRadius + 55, iconfont, data[1], Graphics.TEXT_JUSTIFY_LEFT);			
		dc.drawText(scrRadius + 3, scrRadius + 55, weatherfont, data[2], Graphics.TEXT_JUSTIFY_LEFT);			
		
			
	}
	

}


class ClutterlessView extends WatchUi.WatchFace
{
		var colBG  	 = 0x000000;
		var colDATE 	 = 0x555555;
		var colHOUR 	 = 0xFFFFFF;
		var colMIN 	 = 0x555555;
		var colLINE 	 = 0x555555;
		var colDatafield = 0x555555;
		var info, settings, value, BtInd, zeroformat;
		var barX, barWidth;
		var iconfont;
		var twlveclock = false;
		var showdate = true;
		var BattStats;
		var manualLocX, manualLocY;
		var timeStyle;
		/* ICONS MAPPER*/
		
		
		/*
		 * HEARTRATE:      A
		 * CALORIES:       B
		 * STEPS:          C
		 * ALTITUDE:       D
		 * MESSAGES:       E
		 * STAIRS:         F
		 * ALARM COUNT:    G
		 * BLUETOOTH:      H
		 * ACTIVE MINUTES: I
		 * BATTERY:        J
		 * DISTANCE WEEK:  K
		 * */
		
		
		var methodLeft       = method(:Steps);
		var methodCenter     = method(:Battery);
		var methodRight      = method(:HeartRate);
		var bottomComplication;
		var methodBottomData = method(:Steps);
		var methodCircle     = method(:Battery);
		
		var dayOfWeekArr     = [null, "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
		var monthOfYearArr   = [null, "January", "February", "March", "April", "May", "June", "July",
							         "August", "September", "Octotber", "November", "December"];
		
		
		
		var hourfont, minutefont, weatherfont = WatchUi.loadResource(Rez.Fonts.inheritWeather);
		var regfont = Graphics.FONT_SMALL;
		var scrRadius;
		var scrWidth, scrHeight;
		
		
	
		
		function initialize(){
			WatchFace.initialize();	
		
		}
		
		function getSettings(){
			info = ActivityMonitor.getInfo();
			var app = Application.getApp();
			colLINE = app.getProperty("colLine");
			colHOUR = app.getProperty("colHour");
			colMIN  = app.getProperty("colMin");
			colBG   = app.getProperty("colBg");
			colDATE = app.getProperty("colDate");
			colDatafield = app.getProperty("colDatafield");
			twlveclock   = app.getProperty("twelvehclock");
			showdate     = app.getProperty("showdate");
			BtInd        = app.getProperty("BtIndicator");
			zeroformat   = app.getProperty("zeroformat");
			methodLeft   = getField(app.getProperty("Field1"));
			methodCenter = getField(app.getProperty("Field2"));
			methodRight  = getField(app.getProperty("Field3"));
			bottomComplication = getField(app.getProperty("FieldBottom"));
			methodCircle = getField(app.getProperty("FieldCircle"));
			if (app.getProperty("shortdate") == true) {
			    dayOfWeekArr = [null, "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
			monthOfYearArr   = [null, "Jan", "Feb", "March", "April", "May", "June", "July",
						  "Aug", "Sep", "Oct", "Nov", "Dec"];
			}
			
			timeStyle    = app.getProperty("timeStyle");
			
			  
			
			if (timeStyle == 1) {
				hourfont = WatchUi.loadResource(Rez.Fonts.timeBig);
				minutefont = 15;
			} else if (timeStyle == 2) {
				minutefont = WatchUi.loadResource(Rez.Fonts.timeBigSleek);
				hourfont = WatchUi.loadResource(Rez.Fonts.timeBig);
			} else if (timeStyle == 3){
		 		minutefont = null;
				hourfont = WatchUi.loadResource(Rez.Fonts.timeBig);
			} else if (timeStyle == 4){
				hourfont = WatchUi.loadResource(Rez.Fonts.time);
				minutefont = 14;
			} else {
				hourfont = WatchUi.loadResource(Rez.Fonts.time);

			}

			
		}
		
		function getField(values){
			
			if (values == -1) {
				return method(:EmptyF);
			}
			if (values < 10) {
				if (values == 0) {
					if (info has :getHeartRateHistory) {
						return method(:HeartRate);
					} else {
						return method(:Invalid);
					}
				} else if (values == 1){
					return method(:Calories);
					
				} else if (values == 2){
					return method(:Steps);
					
				} else if (values == 3){
					if ( (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getElevationHistory)) {
						return method(:Altitude);
					} else {
						return method(:Invalid);
					} 
					
				} else if (values == 4){
					return method(:Battery);
					
				} else if (values == 5){
					if (info has :floorsClimbed) {
						return method(:Stairs);
					} else {
						return method(:Invalid);
					}
					
				} else if (values == 6){
					return method(:Messages);
					
				} else if (values == 7){
					return method(:Alarmcount);
				} else if (values == 8){
					return method(:PhoneConn);
				} else if (values == 9){
					if (info has :activeMinutesDay){
						return method(:ActiveMinutesDay);
					} else {
						return method(:Invalid);
					}
				} 
			}else {
				if (values == 10){
					if (info has :activeMinutesWeek){
						return method(:ActiveMinutesWeek);
					} else {
						return method(:Invalid);
					}
				} else if (values == 11){
					return method(:DistanceDay);
				} else if (values == 12) {
					if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory)) {
						return method(:DeviceTemp);
					} else{
						 return method(:Invalid);
					}
				} else if (values == 13) {
					if ((Toybox.System has :ServiceDelegate)) {
						if (Authorize() == true){
							
							weatherfont = WatchUi.loadResource(Rez.Fonts.Weather);
							Background.registerForTemporalEvent(new Time.Duration(Application.getApp().getProperty("updateFreq") * 60));
							return method(:Weather);
							
						} else {
							return method(:Premium);
						}
					}
				} else if (values == 14) {
					return new graph();
				} else if (values == 15) {
					return new halfMoon();
				} else if (values == 16) {
					return new complications();
				} else {
					return method(:Invalid);
				}
			}
		}
		
		function onLayout(dc){
			if ((Toybox.System has :ServiceDelegate)) {
				Background.deleteTemporalEvent();
			}
			getSettings();
			scrWidth = dc.getWidth();
			scrHeight = dc.getHeight();
			scrRadius = scrWidth / 2;
			
	
			if (scrHeight < 209) {
					regfont = Graphics.FONT_MEDIUM;
			}
			
			iconfont = WatchUi.loadResource(Rez.Fonts.Icon);
			hourfont = WatchUi.loadResource(Rez.Fonts.timeBig);
		}
		
		function onUpdate(dc){
			dc.setColor(0, colBG);
			dc.clear();		
			info     = ActivityMonitor.getInfo();
			settings = Sys.getDeviceSettings();
			
			
			if(showdate == true){
				testdate(dc);
			}

		
	
			drawTime(dc);
			dc.setColor(colDatafield, -1);
			if(BtInd && settings.phoneConnected){
				dc.drawText(scrHeight * 0.08, scrRadius + 5, iconfont, "h", Graphics.TEXT_JUSTIFY_CENTER|4);
			}
			
			drawComplication1(dc);
			drawComplication2(dc);
			drawComplication3(dc);
			drawCircle(dc);
			testdate(dc);
			bottomComplication.draw(dc);
		}
		
		
		
		function drawComplication1(dc){	
			var data = methodLeft.invoke();
			dc.drawText(scrRadius - 38, 50, regfont, data[0], Graphics.TEXT_JUSTIFY_RIGHT);
			dc.drawText(scrRadius - 38, 35, iconfont, data[1], Graphics.TEXT_JUSTIFY_RIGHT);	
			dc.drawText(scrRadius - 38, 35, weatherfont, data[2], Graphics.TEXT_JUSTIFY_RIGHT);	
		}
		
		function drawComplication2(dc){
			var data = methodCenter.invoke();
			dc.drawText(scrRadius, 50, regfont, data[0], Graphics.TEXT_JUSTIFY_CENTER);
			dc.drawText(scrRadius, 35, iconfont, data[1], Graphics.TEXT_JUSTIFY_CENTER);
			dc.drawText(scrRadius, 35, weatherfont, data[2], Graphics.TEXT_JUSTIFY_CENTER);
		}
		
		function drawComplication3(dc){
			var data = methodRight.invoke();
			dc.drawText(scrRadius + 38, 50, regfont, data[0], Graphics.TEXT_JUSTIFY_LEFT);
			dc.drawText(scrRadius + 38, 35, iconfont, data[1], Graphics.TEXT_JUSTIFY_LEFT);
			dc.drawText(scrRadius + 38, 35, weatherfont, data[2], Graphics.TEXT_JUSTIFY_LEFT);
		}
		
	
		
		function drawCircle(dc) {
			var data = methodCircle.invoke();
			
			var perc = data[0].toNumber() / data[3];
			for(var i = 0; i < 6; i++){
				dc.drawArc(scrRadius, scrRadius, scrRadius - i, 0, 90, (perc  * 360) + 90);
			}
		}
		
		
		
		
		 
		
		function drawTime(dc){
			var time;
			
			time = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
			dc.setColor(colHOUR, -1);
			var tmp = (twlveclock == false ? time.hour : (time.hour > 12 ? time.hour - 12 : time.hour));
			if (zeroformat ){
				tmp = tmp.format("%02d");
			}
			dc.drawText(scrRadius -2, scrRadius , hourfont, tmp, Graphics.TEXT_JUSTIFY_RIGHT|4);
			dc.setColor(colMIN, -1);
			if ( timeStyle == 1 || timeStyle == 4) {
				dc.drawText(scrRadius + 10, scrRadius * 0.91, minutefont, time.min.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT|4);
				
				dc.drawText(scrRadius + 10, scrHeight * 0.52, 1, time.month + " " + time.day, Graphics.TEXT_JUSTIFY_LEFT);
			} else if (timeStyle == 2) {
				dc.drawText(scrRadius + 2, scrRadius , minutefont, time.min.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT|4);

			} else  if (timeStyle == 3) {
				dc.drawText(scrRadius + 2, scrRadius , hourfont, time.min.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT|4);
			} else {
				dc.drawText(scrRadius + 2, scrRadius , hourfont, time.min.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT|4);

			}
		}
		
		function testdate(dc) {
			dc.drawText(scrRadius + 10, scrRadius * 1.07, 1, "Aug 1", Graphics.TEXT_JUSTIFY_LEFT);
		}
		
	
		
		
		function Authorize() {
		//yes, in theory you could modify this code to always return true, and get the premium features. 
		// if you're going to do that, just realize that i provide everything except weather free of charge,
		// even the source code. a small donation would be appreciated...
		
			var tmpString = Application.getApp().getProperty("keys");
			if (!tmpString) {return false;}
			if (tmpString.hashCode() == null) {return false;}
			 
			
			if (tmpString.hashCode()  == -1258539636) {
				return true;
			} else if (tmpString.hashCode() == -55185590){
				return true;
			} else {
				return false;
			}	
		}
		
	
	
	////////////////////////////
	/////     DATAFIELDS   /////
	/////     ONLY         /////
	/////     DATAFIELDS   /////
	/////     UNDER        /////
	/////     THIS         /////
	/////     PART         /////
	////////////////////////////
	
		
	function HeartRate(){
		value = Activity.getActivityInfo().currentHeartRate;
		if(value == null) {
			value = ActivityMonitor.getHeartRateHistory(1, true).next().heartRate;
		}
		return [value, "a", ""];
	}
	
	
	function Calories(){
		return [info.calories, "b", "" ];
	}
	
	
	function Steps(){
		return [info.steps , "c", "", info.stepGoal];
	}
	

	function Altitude(){
		var value = Activity.getActivityInfo().altitude;
		if(value == null){
			 value = SensorHistory.getElevationHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST }).next();
			if ((value != null) && (value.data != null)) {
					value = value.data;
			}
		}
		
		if (value != null) {
			// Metres (no conversion necessary).
			if (settings.elevationUnits == System.UNIT_METRIC) {
			} else { 
				value *=  3.28084; // every meter is 3.28 feet		
			}
			
		} else {
			value = "-.-";
		}
		
		return [value.toNumber(), "d", ""];
	}
	
	
	function Messages(){		
		return [ settings.notificationCount, "e", ""];
	}
	
	
	function Stairs(){
		return [(info.floorsClimbed), "f", "", info.floorsClimbedGoal];
	}
	
	
	function Alarmcount(){
		return [settings.alarmCount, "g", ""];
		
	}
	
	
	function PhoneConn(){
		
		if (settings.phoneConnected) {
			return ["conn", "h", "" ];
		} else {
			return ["disc", "h", ""];
		}
	}
	
	
	function ActiveMinutesDay(){
			return [info.activeMinutesDay.total.toNumber(), "i", ""];
	}
	
	
	function ActiveMinutesWeek(){
			return [info.activeMinutesWeek.total.toNumber(), "i", "", info.activeMinutesWeekGoal];
	}
	
	
	function Battery(){
		return [((Sys.getSystemStats().battery + 0.5).toNumber().toString() + "%"), "j", "", 100];
	}
	
	function DistanceWeek(){
		
	}
	
	function DistanceDay(){
			var unit;
			value = info.distance.toFloat();
			if(value == null){
				value = 0;
			} else {
				value *= 0.001;
			}
			
			if (settings.distanceUnits == System.UNIT_METRIC) {
				unit = "k";					
			} else {
				value *=  0.621371;  //mile per K;
				unit = "Mi";
			}
			
			return [value.format("%.1f").toString() + unit, "k", ""];
	}
	
	function DeviceTemp() {
		value = SensorHistory.getTemperatureHistory(null).next();
		if ((value != null) && (value.data != null)) {
			if (settings.temperatureUnits == System.UNIT_STATUTE) {
					value = (value.data * (1.8)) + 32; // Convert to Farenheit: ensure floating point division.
			} else {
					value = value.data;
			}
		
			return [value.toNumber().toString() + "°", "m", ""];
		}
		return ["-.-", ""];
	}
	
	function Weather(){
		var location = Activity.getActivityInfo().currentLocation; 
		var app = Application.getApp();
		
		if (location != null) {
				location = location.toDegrees(); // Array of Doubles.
				app.setProperty("lat", (location[0].toFloat()) );
				app.setProperty("lon", (location[1].toFloat()) );
		} else {
				location = Position.getInfo().position;
				if (location != null) {
						location = location.toDegrees();
						app.setProperty("lat", (location[0].toFloat()) );
						app.setProperty("lon", (location[1].toFloat()) );
				}
		}
		
	
		var weatherdata = app.getProperty("weatherdata");
		if (weatherdata == null) {
			return ["noData", "", "i"];
		} 
		
		
		return [weatherdata["temp"].toNumber() + "°", "", weatherdata["icon"] ];
	
	}
	

	function EmptyF(){
		return ["", "", ""];
	}
	

	function Invalid (){
		return ["-", "", "", 1];
	}
	
	function Premium (){
		return ["activate", "", ""];
	}
	
	
}
