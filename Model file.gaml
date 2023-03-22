model vierkaser

global  {
	// Intergrating external files of pasture Geometry
	file pasture_file <- file("../includes/pasture.geojson");
	file hirschanger_file <- file("../includes/hirschanger.geojson");
	file meadow_file <- file("../includes/meadow.geojson");
	file cutback2020_file <- file("../includes/cutback_2020.geojson");
	file cutback2021_file <- file("../includes/cutback_2021.geojson");
	
	geometry shape <- envelope(pasture_file);
	geometry pasture_polygon;
	geometry hirschanger;
	geometry meadow;
	geometry cutback2020;
	geometry cutback2021;
	geometry pasturecombined;
	list<grass> pasture_cells;
	
	//the step influences step length, but not speed
	float cow_speed <- 20.0 ;
	float cow_amplitude <- 60.0;
	string scenario;
	float counter<-0.0;
	float days<-0;
	
// Adding parameters to each type of cows	
	int no_of_weaned_cows <- 4 parameter: "No of weaned cows";
	int no_of_calf <- 2 parameter: "No of calfs";
	int no_of_suckler_cows <- 0 parameter: "No of suckler cows";
	int no_of_dry_cows <- 2 parameter: "No of dry cows";
	
	//create the agents and objects with their variables
	init {		
		pasture_polygon <- geometry(pasture_file);
		hirschanger <- geometry(hirschanger_file);
		meadow <- geometry(meadow_file);
		cutback2020 <- geometry(cutback2020_file);
		cutback2021 <- geometry(cutback2021_file);
		pasturecombined<-cutback2021+cutback2020+meadow+hirschanger;
		int noWeaned;
		pasture_cells <- grass inside(pasture_polygon);
		//write length(grass);
		//write length(pasture_cells);
		
		// Default pasture cells have shrubs which no biomass
		ask pasture_cells{
			landcover<-"shrubs";
			biomass<-0.0;
		}
		// Overwirte shrub-free parts with other landcover qualities
		ask pasture_cells overlapping hirschanger{
			landcover<-"hirschanger";
			biomass<-5.0;
		}
		ask pasture_cells overlapping meadow{
			landcover<-"meadow";
			biomass<-5.0;
		}
		ask pasture_cells overlapping cutback2020{
			landcover<-"cutback2020";
			biomass<-5.0;
		}
		ask pasture_cells overlapping cutback2021{
			landcover<-"cutback2021";
			biomass<-5.0;
		}
			
		
		create cows number:no_of_dry_cows  {
			location <- any_location_in(meadow);
		}
		create sucklerCow number:no_of_suckler_cows  {
			location <- any_location_in(meadow);
		}
		
		create weanedCalf number:no_of_weaned_cows  {
			location <- any_location_in(meadow);
		}
		
		create calf number:no_of_calf  {
			location <- any_location_in(meadow);
		}
		
	}
// Counter variable equivalent to time of the day	
	reflex updatecount{
		if counter =24{
			days <- days+1;
			//write "No of the day ="+days;
		}
		if counter<24{
			counter<-counter+0.5; // Each time step counter variable increased by 0.5 - equivalent to 30min
			if counter=5{
				write('Grazing start');
			}
			if counter=14{
				write('Grazing stop');
			}
		}else{
			counter<-0;  // when counter is 24, the value reset to 0 which represent the begining of a new day
		}
		//write 'Time of the day ='+counter;
	}
	
	reflex update_biomass {
		ask pasture_cells {
			if biomass < 5.0 {
				biomass <- biomass + 1/24;	// biomass growth every time step
			}			
			color <- rgb([0, biomass * 15, 0]);	
		}
	}
	
//int number_of_cows <- 25 min: 3 max: 60; 	
	float min_separation <- 3.0  min: 0.1  max: 10.0 ;
	int max_separate_turn <- 5 min: 0 max: 20;
	int max_cohere_turn <- 5 min: 0 max: 20;
	int max_align_turn <- 8 min: 0 max: 20;
	float vision <- 30.0  min: 0.0  max: 70.0 ;	
//variables from birds flocking	


}


species sucklerCow parent: cows {
	float dailyRequirement<-15;
	aspect base {
		draw triangle (4) color: #red;
	}	
}

	
species weanedCalf parent: cows {
	float dailyRequirement<-7;
	aspect base {
		draw square (4) color: #black;
	}
	
}

species calf parent: cows {
	float dailyRequirement<-3;
	aspect base {
		draw circle (4) color: #blue;
	}
}


species cows skills: [moving] {
	
	int age;
	geometry action_area;
	geometry perception_area;
	//the cell that the cow grazes on at a particular time step
	grass grazed_grass ;
	//energy is gained by feeding grass, and lost by metabolism every time step
	float energy <- 10.0;
	float dailyConsumed<-0;
	float dailyRequirement<-10;
	geometry jumptocell;
	
	//from boids flocking
			
		float size <- 2.0;
		rgb colour <- #black;
	
		// flocking variables
	    list<cows> flockmates ; 	    
	    cows nearest_neighbour;	
	    int avg_head;
	    int avg_twds_mates ;
	//from boids flocking

	reflex moving{
		do move_around;
	}
	
	reflex grazeing{
		do graze;
	}
	
	reflex save{
		do savingFiles;
	}
	
	
	action savingFiles{
		//save [self.name, dailyConsumed, string(days),dailyRequirement] to: "../results/save_data.csv" rewrite:false type: csv;
	}
			
	action move_around {
		if counter>=5 and counter<=14{
					//random walk
				if scenario = "random walk" {
					do wander speed: cow_speed bounds:pasturecombined;
					grazed_grass <- one_of (pasture_cells overlapping self) ;
					action_area <- circle(cow_speed) ; 
				}
				//correlated random walk
				if scenario = "correlated random walk" {
					do wander amplitude: cow_amplitude speed: cow_speed bounds:pasturecombined;
					action_area <- circle(cow_speed) intersection cone(heading - cow_amplitude/2, heading + cow_amplitude/2) ; 			
				}	
				//one cow moves with correlated random walk, the others follow this cow.	
				if scenario = "lead cow & followers" {
					if name != "cows0" {
						do goto target: cows[0] speed: cow_speed;
						action_area <- line([self.location, self.location + cows[0]]) intersection circle(cow_speed); 				
					}
					else {
						do wander amplitude: cow_amplitude speed: cow_speed bounds:pasturecombined;			
						action_area <- circle(cow_speed) intersection cone(heading - cow_amplitude/2, heading + cow_amplitude/2) ; 
					}
				}
				//each cow always moves to the spot within reach that has the highest biomass.	
				if scenario = "go to the spot with most grass" {
					action_area <- circle(cow_speed) ; 			
					grazed_grass <- (shuffle(pasture_cells overlapping action_area)) with_max_of each.biomass;
		
					location <- grazed_grass.location;
					
				}	
				// Flocking behaviour of the cows
				if scenario = "Flocking behaviour"{
					if(grazed_grass = nil)	{
						action_area <- circle(cow_speed*10);
						jumptocell <- (one_of(pasture_cells overlapping action_area)); // Jumped to a particular location of pasture if an agent goes beyond pasture limit
						jumptocell <- jumptocell.location;
						do goto target: jumptocell;
						
					}else{
						//write "No overlap";
					}
					do highestbiomass;
					do flock;	
				}
		}
	}
	
	// Cows goto the highest biomass within the range of action area
	action highestbiomass{
		perception_area<-circle(vision); 	
		action_area <- circle(cow_speed/2); 			
		grazed_grass <- (shuffle(pasture_cells overlapping action_area)) with_max_of each.biomass;
		location <- grazed_grass.location;
	}
	
	//Movement from birds flocking
	action flock {
    		// in case all flocking parameters are zero wander randomly  	
			if (max_separate_turn = 0 and max_cohere_turn = 0 and max_align_turn = 0 ) {
				do wander amplitude: 120 speed: cow_speed/2 bounds:pasturecombined;
			}
			// otherwise compute the heading for the next timestep in accordance to my flockmates
			else {
				// search for flockmates
				do find_flockmates ;
				// turn my heading to flock, if there are other agents in vision 
				if (not empty (flockmates)) {
					do find_nearest_neighbour;
					if (distance_to (self, nearest_neighbour) < min_separation) {
						do separate;
					}
					else {
						do align;
						do cohere;
					}
					// move forward in the new direction
					do move speed: cow_speed/2 bounds:pasturecombined;
				}
				// wander randomly, if there are no other agents in vision
				else {
					do wander speed: cow_speed/2 amplitude: 120 bounds:pasturecombined;
				}
			}			
	    }	
//Movement from birds flocking
			//flockmates are defined spatially, within a buffer of vision
		action find_flockmates {
	        flockmates <- ((cows overlapping (circle(vision))) - self);
		}
		
		//find nearest neighbour
		action find_nearest_neighbour {
	        nearest_neighbour <- flockmates with_min_of(distance_to (self.location, each.location)); 
		}		
		
	    // separate from the nearest neighbour of flockmates
	    action separate  {
	    	do turn_away (nearest_neighbour towards self, max_separate_turn);
	    }
	
	    //Reflex to align the boid with the other boids in the range
	    action align  {
	    	avg_head <- avg_mate_heading () ;
	        do turn_towards (avg_head, max_align_turn);
	    }
	
	    //Reflex to apply the cohesion of the boids group in the range of the agent
	    action cohere  {
			avg_twds_mates <- avg_heading_towards_mates ();
			do turn_towards (avg_twds_mates, max_cohere_turn); 
	    }
	    
	    //compute the mean vector of headings of my flockmates
	    int avg_mate_heading {
    		list<cows> flockmates_insideShape <- flockmates where (each.destination != nil);
    		float x_component <- sum (flockmates_insideShape collect (each.destination.x - each.location.x));
    		float y_component <- sum (flockmates_insideShape collect (each.destination.y - each.location.y));
    		//if the flockmates vector is null, return my own, current heading
    		if (x_component = 0 and y_component = 0) {
    			return heading;
    		}
    		//else compute average heading of vector  		
    		else {
    			// note: 0-heading direction in GAMA is east instead of north! -> thus +90
    			return int(-1 * atan2 (x_component, y_component) + 90);
    		}	
	    }  

	    //compute the mean direction from me towards flockmates	    
	    int avg_heading_towards_mates {
	    	float x_component <- mean (flockmates collect (cos (towards(self.location, each.location))));
	    	float y_component <- mean (flockmates collect (sin (towards(self.location, each.location))));
	    	//if the flockmates vector is null, return my own, current heading
	    	if (x_component = 0 and y_component = 0) {
	    		return heading;
	    	}
    		//else compute average direction towards flockmates
	    	else {
	    		// note: 0-heading direction in GAMA is east instead of north! -> thus +90
	    		return int(-1 * atan2 (x_component, y_component) + 90);	
	    	}
	    } 	    
	    
	    // cohere
	    action turn_towards (int new_heading, int max_turn) {
			int subtract_headings <- new_heading - heading;
			if (subtract_headings < -180) {subtract_headings <- subtract_headings + 360;}
			if (subtract_headings > 180) {subtract_headings <- subtract_headings - 360;}
	    	do turn_at_most ((subtract_headings), max_turn);
	    }

		// separate
	    action turn_away (int new_heading, int max_turn) {
			int subtract_headings <- heading - new_heading;
			if (subtract_headings < -180) {subtract_headings <- subtract_headings + 360;}
			if (subtract_headings > 180) {subtract_headings <- subtract_headings - 360;}
	    	do turn_at_most ((-1 * subtract_headings), max_turn);
	    }
	    
	    // align
	    action turn_at_most (int turn, int max_turn) {
	    	if abs (turn) > max_turn {
	    		if turn > 0 {
	    			//right turn
	    			heading <- heading + max_turn;
	    		}
	    		else {
	    			//left turn
	    			heading <- heading - max_turn;
	    		}
	    	}
	    	else {
	    		heading <- heading + turn;
	    	} 
	    }
// Movement from birds flocking
	
	//graze grass within reach
	action graze {
			float difference <- dailyRequirement-dailyConsumed;
			if (counter>=5 and counter<=14) and (difference>0){  // Compare time and daily requirement
				grazed_grass <- one_of (pasture_cells overlapping self);
				energy <- energy - 1;
				
				if grazed_grass != nil {
					ask grazed_grass {
						if biomass > 1 {
							if difference>=1{
								biomass <- biomass - 1 ;
								ask myself {energy <- energy + 1;}
								ask myself {dailyConsumed <- dailyConsumed + 1;}
								color <- rgb([0, biomass * 10, 0]);
								
							}else{
								biomass<-(biomass -difference);
								ask myself {dailyConsumed <- dailyConsumed + difference;}
								color <- rgb([0, biomass * 10, 0]);
							}
							
							}
					}			
				}
		
			}
			if counter=24{	 // At the end of the day, status of each cows' output into the console (whether they reached daily requirement)		
				if dailyConsumed<dailyRequirement{
					save [self.name,dailyConsumed,"failed to reach daily target",string(days),dailyRequirement] to: "../results/scenario7_12cows_1month.csv" rewrite:false type: csv;
					write (self.name+"|"+"Daily consumed ="+dailyConsumed+"|"+" failed to reach daily target on day "+"|"+ string(days)+"|"+dailyRequirement);
					
				}else{
					save [self.name,dailyConsumed,"reach daily target",string(days),dailyRequirement] to: "../results/scenario7_12cows_1month.csv" rewrite:false type: csv;
					write (self.name+"|"+"Daily consumed ="+dailyConsumed+"|"+" reach daily target on day "+"|"+ string(days)+"|"+dailyRequirement);
				}
				dailyConsumed <- 0;
				
				
			}

	}

	
	//viz of cow agent	
aspect base {
		draw circle (2) color: #black;
	}
 	aspect action_neighbourhood {
		draw action_area color: #orange ; 
 	}	
 	aspect vision_neighbourhood {
		draw perception_area color: #yellow ; 
 	}	
}




/* Build a Cellular Automaton (CA) labelled "pasture" with the dimensions of 5 by 5 cells 
 * and a Moore neighbourhood*/
grid grass cell_width:5 cell_height:5 neighbors:6 {
	float biomass <- 5.0;	
	string landcover; 	
}

//run the simulation
experiment Simulation type:gui {
	
	parameter "Scenario" var: scenario <- "Flocking behaviour" among: ["Flocking behaviour","random walk","correlated random walk", "lead cow & followers", "go to the spot with most grass"] ;
	
	output {
		display charts {//how much did each cow eat over time?			
			chart "Dry cows" type: series  position:{0,0} size:{0.5,0.5}{
				loop i from: 0 to:no_of_dry_cows-1 step: 1 {
					data "cow" + i value: cows[i].dailyConsumed color:rgb([i*10, i * 100, i*50]);
					
				}
					data "Daily requirement" value: 10 color:#red;
			}
			chart "Calf" type: series  position:{0,0.5} size:{0.5,0.5}{
				loop i from: 0 to:no_of_calf-1 step: 1 {
					data "calf" + i value: calf[i].dailyConsumed color:rgb([0, i * 25, i*50]);
					
				}
					data "Daily requirement" value: 3 color:#red;
			}
			chart "Weaned Cow" type: series  position:{0.5,0} size:{0.5,0.5}{
				loop i from: 0 to:no_of_weaned_cows-1 step: 1 {
					data "Weaned Cow" + i value: weanedCalf[i].dailyConsumed color:rgb([0, i * 100,0]);
					
				}
					data "Daily requirement" value: 7 color:#red;
			}
			chart "Suckler Cows" type: series  position:{0.5,0.5} size:{0.5,0.5}{
				loop i from: 0 to:no_of_suckler_cows-1 step: 1 {
					data "Suckler Cow" + i value: sucklerCow[i].dailyConsumed color:rgb([i*10, i * 10, i*10]);
					
				}
					data "Daily requirement" value: 15 color:#red;
			}

		}		
		display "Vierkaser map"  {
			
			grid grass ;
			species cows aspect:base refresh:true ;
			species weanedCalf aspect:base refresh:true ;
			species calf aspect:base refresh:true ;
			species sucklerCow aspect:base refresh:true ;
//			species cows aspect:action_neighbourhood refresh:true transparency:0.5;	
//			species cows aspect:vision_neighbourhood refresh:true transparency:0.5;	
		}
	}
}

