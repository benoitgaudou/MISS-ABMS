model firemen

global { }

grid plot height:30 width: 30 neighbors:4 {
	string state;
	rgb color;
}

species firefighter {
	string status among: ["patrolling", "fighting fire"];		
	plot my_plot;
}

species communicant_firefighter parent:firefighter {
	list<communicant_firefighter> colleagues;
}

species brigade {
	list<firefighter> members;
}
