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
	var targetdatatype, primaryColor, graphFilled;

	function init() {
		var app = Application.getApp();
		settings = Sys.getDeviceSettings();

		primaryColor = app.getProperty("bottomComplCol");
		targetdatatype = app.getProperty("graphData");
		graphFilled = app.getProperty("graphStyleFilled");

	}

	function get_data_interator(type) {
		if (type == 1) {
			if (Toybox.SensorHistory has :getHeartRateHistory) {
		        return Toybox.SensorHistory.getHeartRateHistory({});
		    }
	    } else if (type == 2) {
	    	if (Toybox.SensorHistory has :getElevationHistory) {
		        return Toybox.SensorHistory.getElevationHistory({});
		    }
	    } else if (type == 3) {
	    	if (Toybox.SensorHistory has :getPressureHistory) {
		        return Toybox.SensorHistory.getPressureHistory({});
		    }
	    } else if (type == 4) {
	    	if (Toybox.SensorHistory has :getTemperatureHistory) {
		        return Toybox.SensorHistory.getTemperatureHistory({});
		    }
	    }
	    
	    return null;
	}


    
	function parse_data_value(type, value) {
		if (type == 1) {
			return value;
		} else if (type == 2) {
			if (settings.elevationUnits == System.UNIT_STATUTE) {
				value *= 3.28;
			}
			return value;
		} else if (type == 3) {
				return value/100.0;
		} else if (type == 4) {
			if (settings.temperatureUnits == System.UNIT_STATUTE) {
				value = value * (1.8) + 32; // Convert to Farenheit: ensure floating point division.
			} 
			return value;
	    }
	}
    
    
    
	function draw(dc) {
		
		var position_y = dc.getHeight() * 0.75;
		var position_x = dc.getWidth() / 2;
		var smallDigitalFont = 2;
		var graph_height = dc.getHeight() * 0.15;
		var graph_width = dc.getWidth() * 0.60;
		
		
		var HistoryIter = get_data_interator(targetdatatype);
		
		dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
		if (HistoryIter == null) {
				dc.drawText(position_x, position_y, smallDigitalFont, "--", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
				return;
		}
		
		var HistoryMin = HistoryIter.getMin();
		var HistoryMax = HistoryIter.getMax();
			
		if (HistoryMin == null || HistoryMax == null) {
			dc.drawText(position_x, position_y, smallDigitalFont, "--", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			return;
		}
			
		var minMaxDiff = (HistoryMax - HistoryMin).toFloat();
		
		var xStep = graph_width;
		var HistoryPresent = 0;
			
		
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
				var yStep = historyDifPers * graph_height;
				yStep = yStep > graph_height ? graph_height : yStep;
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
					var yStep = historyDifPers * graph_height;
					yStep = yStep > graph_height ? graph_height : yStep;
					yStep = yStep < 0 ? 0 : yStep;
							
					if (lastyStep != null){
						// draw diagram
						dc.drawLine(position_x + (xStep - graph_width / 2), 
							((!graphFilled) ? (position_y - (lastyStep - graph_height / 2)) : (dc.getHeight() * 0.83)), 
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
				position_y + (position == 1 ? (graph_height / 2 + 10) : ( -graph_height / 2 - 16)), 
				smallDigitalFont, 
				"-", 
				Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			return;
		}
		
		var value_label = parse_data_value(targetdatatype, HistoryPresent);
		var labelll = value_label.format("%d");
    }
}



class ClutterlessView extends WatchUi.WatchFace
{
		var colBG;
		var colDATE;
		var colHOUR;
		var colMIN;
		var colLINE;
		var colDatafield;
		var colBTnSecs;
		var bottomComplCol;
		var info, settings, BtInd, showSecs, zeroformat;
		var iconFont;
		var timeStyle, timeSize;
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
		
	
		
		
		var methodLeft;
		var methodCenter;
		var methodRight;
		var bottomComplication;
		var methodBotCenter;
		var methodCircle;
		
		var methodCompl1, methodCompl2, methodCompl3, methodCompl4;
		
		
		var hourFont, minuteFont, weatherFont = WatchUi.loadResource(Rez.Fonts.inheritWeather);
		var regFont = Graphics.FONT_SMALL;
		var scrRadius;
		var scrWidth, scrHeight;



		function initialize(){
			WatchFace.initialize();	
			if ((Toybox.System has :ServiceDelegate)) {
				Background.deleteTemporalEvent();
			}
			
			getSettings();
		}



		function getSettings(){
			info 				 = ActivityMonitor.getInfo();
			var app				 = Application.getApp();
			colHOUR				 = app.getProperty("colHour");
			colMIN				 = app.getProperty("colMin");
			colBG				 = app.getProperty("colBg");
			colDATE				 = app.getProperty("colDate");
			colLINE				 = app.getProperty("colLine");
			colBTnSecs			 = app.getProperty("colBtnSecs");
			colDatafield		 = app.getProperty("colDatafield");
			timeStyle			 = app.getProperty("timeStyle");
			timeSize			 = app.getProperty("timeSize");
			BtInd				 = app.getProperty("BtIndicator");
			zeroformat			 = app.getProperty("zeroformat");
			showSecs			 = app.getProperty("showSecs");
			methodLeft			 = getField(app.getProperty("Field1"));
			methodCenter		 = getField(app.getProperty("Field2"));
			methodRight			 = getField(app.getProperty("Field3"));
			bottomComplication	 = getField(app.getProperty("FieldBottom"));
			methodCircle		 = getField(app.getProperty("FieldCircle"));
			methodBotCenter		 = getField(app.getProperty("FieldBottomCenter"));
			//Sys.println();
			
			if (bottomComplication == 3) {
				bottomComplCol = app.getProperty("bottomComplCol");
				methodCompl1 = getField(app.getProperty("fieldCompl1"));
				methodCompl2 = getField(app.getProperty("fieldCompl2"));
				methodCompl3 = getField(app.getProperty("fieldCompl3"));
				methodCompl4 = getField(app.getProperty("fieldCompl4"));
			} else { 
				bottomComplication.init();
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
				} else if (values == 1) {
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
			} else {
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
							
							weatherFont = WatchUi.loadResource(Rez.Fonts.Weather);
							Background.registerForTemporalEvent(new Time.Duration(Application.getApp().getProperty("updateFreq") * 60));
							return method(:Weather);
							
						} else {
							return method(:Premium);
						}
					}
				} else if (values == 14) {
					return new graph();
				} else if (values == 15) {
				} else if (values == 16) {
					return 3;
				} else {
					return method(:Invalid);
				}
			}
		}



		function onLayout(dc){
			scrWidth = dc.getWidth();
			scrHeight = dc.getHeight();
			scrRadius = scrWidth / 2;
			
			if (scrHeight < 209) {
					regFont = Graphics.FONT_MEDIUM;
			}
			
			iconFont = WatchUi.loadResource(Rez.Fonts.Icon);
			hourFont = WatchUi.loadResource(Rez.Fonts.Hour);
			
			if (timeStyle == 1) {
				minuteFont = 15;
			} else {
				if (timeSize == 1) {
					hourFont = WatchUi.loadResource(Rez.Fonts.HourSmall);
				} else if (timeSize == 2) {
					hourFont = WatchUi.loadResource(Rez.Fonts.Hour);
				} else if (timeSize == 3) {
					hourFont = WatchUi.loadResource(Rez.Fonts.HourBig);
				} else if (timeSize == 4) {
					hourFont = WatchUi.loadResource(Rez.Fonts.HourBigger);
				}
				minuteFont = null;
			} 
		}



		function onUpdate(dc){
			dc.setColor(0, colBG);
			dc.clear();
			onPartialUpdate(dc);
			
			info     = ActivityMonitor.getInfo();
			settings = Sys.getDeviceSettings();
			
			drawTime(dc);
			
			
			if(BtInd && settings.phoneConnected){
				dc.setColor(colBTnSecs, -1);
				dc.drawText(20, scrRadius, iconFont, "h", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			}
			
			dc.setColor(colDatafield, -1);
			/* reuse existing funtion to save ram */
			drawComplication(scrRadius - 42, scrRadius - 42, 50, 30, 	methodLeft.invoke(), dc, Graphics.TEXT_JUSTIFY_CENTER);
			drawComplication(scrRadius, scrRadius, 50, 30, 				methodCenter.invoke(), dc, Graphics.TEXT_JUSTIFY_CENTER);
			drawComplication(scrRadius + 42, scrRadius + 42, 50, 30, 	methodRight.invoke(), dc, Graphics.TEXT_JUSTIFY_CENTER);
			
			
			dc.drawText(scrRadius, scrHeight - 20, 9, methodBotCenter.invoke()[0], Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);			 
			drawCircle(dc);
			dc.setColor(colDatafield, -1);
			
			if (bottomComplication == 3) {
				drawComplication(scrRadius + 25, scrRadius + 5, scrHeight * 0.63, scrHeight * 0.66, methodCompl1.invoke(), dc, Graphics.TEXT_JUSTIFY_LEFT);
				drawComplication(scrRadius + 25, scrRadius + 5, scrHeight * 0.74, scrHeight * 0.77, methodCompl2.invoke(), dc, Graphics.TEXT_JUSTIFY_LEFT);
				drawComplication(scrRadius - 25, scrRadius - 5, scrHeight * 0.63, scrHeight * 0.66, methodCompl3.invoke(), dc, Graphics.TEXT_JUSTIFY_RIGHT);
				drawComplication(scrRadius - 25, scrRadius - 5, scrHeight * 0.74, scrHeight * 0.77, methodCompl4.invoke(), dc, Graphics.TEXT_JUSTIFY_RIGHT);
			} else {
				bottomComplication.draw(dc);
			}
		}



		function onPartialUpdate(dc) {
			if (showSecs) {
				dc.setColor(colBTnSecs, -1);
				var secs = Sys.getClockTime().sec.format("%02d");
				//dc.setClip(210, 100, 20, 20);
				dc.drawText(scrWidth - 10, scrRadius, 0, secs, Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
			}
		}



		function drawComplication (x1, x2, y1, y2, data, dc, alignment) {
			dc.drawText(x1, y1, regFont, data[0], alignment);
			dc.drawText(x2, y2, iconFont, data[1], alignment);
			dc.drawText(x2, y2, weatherFont, data[2], alignment);
		}





		function drawCircle(dc) {
			var data = methodCircle.invoke();
			var perc = data[0].toNumber() / data[3].toFloat();
			dc.setColor(colLINE, -1);
			for(var i = 0; i < 6; i++){
				dc.drawArc(scrRadius, scrRadius, scrRadius - i, 0, 90, (perc  * 360) + 90);
			}
		}



		



		function drawTime(dc) {
			var time;
			
			// garmin's compiler is stupid, so an enum takes up ram. guess we wont be using enums in actual code, but just a mapper in comments
			// FONT_WITH_DATE
			//
			//
			
			time = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
			dc.setColor(colHOUR, -1);
			
			var tmp = (settings.is24Hour == true ? time.hour : (time.hour > 12 ? time.hour - 12 : time.hour));
			
			if (zeroformat ){
				tmp = tmp.format("%02d");
			}
			
			dc.drawText(scrRadius -2, scrRadius, hourFont, tmp, Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.setColor(colMIN, -1);
			
			
			// add date here to reduce ram
			if (timeStyle == 1) {
				dc.drawText(scrRadius + 10, scrRadius + 5 - Graphics.getFontAscent(minuteFont), minuteFont, ":" + time.min.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
				dc.setColor(colDATE, -1);
				dc.drawText(scrRadius + 10, scrRadius * 1.05, 1, time.day.toString() + " " + time.month, Graphics.TEXT_JUSTIFY_LEFT);
			} else {
				dc.drawText(scrRadius + 2, scrRadius, hourFont, time.min.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
			}
			
		}



		function Authorize() {
		//yes, in theory you could modify this code to always return true, and get the premium features. 
		// if you're going to do that, just realize that i provide everything except weather free of charge,
		// even the source code. a small donation would be appreciated...
		
			var tmpString = Application.getApp().getProperty("keys");
			if (!tmpString) {return false;}
			
			if (tmpString.hashCode()  == -1258539636 || tmpString.hashCode() == -55185590) {
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
			var value = Activity.getActivityInfo().currentHeartRate;
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
					value *=  3.28; // every meter is 3.28 feet		
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



		function DistanceDay(){
			var value = info.distance.toFloat();
			
			if(value == null){
				value = 0;
			} else {
				value *= 0.001;
			}
			
			if (settings.distanceUnits != System.UNIT_METRIC) {
				value *=  0.621;  //mile per K;
			}
			
			if (value > 10) {
				value = value.format("%i");
			} else {
				value = value.format("%.1f");
			}
			
			return [value.toString(), "k", ""];
		}
		
		function DeviceTemp() {
			var value = SensorHistory.getTemperatureHistory(null).next();
			
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
			return ["-", "", "", ""];
		}



		function Premium (){
			return ["activate", "", ""];
		}
}
