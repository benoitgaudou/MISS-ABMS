/**
* Name: Model0
* Based on the internal empty template. 
* Author: JB07E36L
* Tags: 
*/

 
model Model0

/* Insert your model definition here */
global{
	
	geometry shape<-square(3000#m);
	
	init{
		int nb <- length(plot) * 1;
		
		ask nb among plot {
			state <-"forest";
			color <-#green;
		}
		
		ask one_of(plot where (each.state="forest")){
			state <-"fire";
			color <-#red;
		}
	}
	
}

grid plot height:30 width:30 neighbors:8 schedules:plot where (each.state="fire") {
	string prev_state;	
	string state<-"clear" among:["forest","clear","fire"];
	rgb color<-#white;
	
	
	
	reflex burn {
		ask neighbors where (each.state="forest"){
			state <-"fire";
			color <-#red;
		}
	}
	
	
}

species firefighter{
	float speed;
	plot my_plot;
}


experiment myView type:gui{
	
	output{
		
		display visu type:opengl{
			grid plot border:#black;
		}
		
	}
}




