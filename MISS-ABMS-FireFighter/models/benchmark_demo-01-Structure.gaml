model firemen

global { }

grid plot height:30 width: 30 neighbors:4 {
	list<plot> neighbors;
	string state;
	
	rgb color;
}

species firefighter {
	bool busy;		
	plot my_plot;
}

species communicant_firefighter parent:firefighter {
	list<communicant_firefighter> colleagues;
}

