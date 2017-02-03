"""
Input: List of tuples. Each tuple represents a race, which consists
of a title, number, a list of candidates. Each candidate is 
represented by a tuple: (name, party).

Output: string of races, with added xml tags

Note: you'll still need to add the <info> section manually
"""

def xmlparser(raceList):
	xml = "<election>\n"
	for raceTuple in raceList:
		title = raceTuple[0]
		number = raceTuple[1]
		candidateList = raceTuple[2]
		xml = xml + "<race>\n<title>" + title + "</title>\n" + \
		"<number>"+number+"</number>\n"
		for candidateTuple in candidateList:
			if candidateTuple[1] == "r":
				party = "REP"
			elif candidateTuple[1] == "d":
				party = "DEM"	
			elif candidateTuple[1] == "g":
				party = "GB"
			elif candidateTuple[1] == "l":
				party = "LIB"
			else:
				party = candidateTuple[1]	
			xml = xml + "<candidate>\n<name>" + candidateTuple[0] + "</name>\n<party>" \
			+ party + "</party>\n</candidate>\n"
		xml = xml + "</race>\n</election>"
	return xml



print xmlparser([("Railroad Commissioner", "3", [("Wayne Christian", "REP"), ("Grady Yarbrough", "DEM"),("Mark Miller", "LIB"),("Martina Salinas", "GB")]),\
	("Justice, Supreme Court, Place 3", "4", [("Debra Lehrmann", "REP"),("Mike Westergren", "DEM"), ("Kathie Glass", "LIB"),("Rodolfo Rivera Munoz", "GB")]),\
	("Justice, Supreme Court, Place 5", "5",[("Paul Green", "REP"), ("Dori Contreras Garza", "DEM"), ("Tom Oxford", "LIB"), ("Charles E. Waterbury", "GB")]),\
	("Justice, Supreme Court, Place 9", "6", [("Eva Guzman", "REP"), ("Savannah Robinson", "DEM"), ("Don Fulton", "LIB"), ("Jim Chisholm", "GB")]),\
	("Judge, Court of Criminal Appeals, Place 2", "7", [("Mary Lou Keel", "REP"), ("Lawrence \"Larry\" Meyers", "DEM"), ("Mark Ash", "LIB"), ("Adam King Blackwell Reposa", "GB")]),\
	("Judge, Court of Criminal Appeals, Place 5", "8", [("Scott Walker", "REP"), ("Betsy Johnson", "DEM"), ("William Bryan Strange, III", "LIB"), ("Judith Sanders-Castro", "GB")]),\
	("Judge, Court of Criminal Appeals, Place 6", "9", [("Michael E. Keasler", "REP"), ("Robert Burns", "DEM"), ("Mark W. Bennett", "LIB")]),\
	("Member, State Board of Education, District 6", "10", [("Donna Bahorich", "REP"), ("R. Dakota Carter", "DEM"), ("Whitney Bilyeu", "LIB")]),\
	("State Representative, District 134", "11", [("Sarah Davis", "REP"), ("Ben Rose", "DEM"), ("Gilberto \"Gil\" Velasquez Jr.", "LIB")]),\
	("Chief Justice, 1st Court of Appeals", "12", [("Sheery Radack", "REP"), ("Jim Peacock", "DEM")]),\
	("Justice, 1st Court of Appeals District, Place 4", "13", [("Evelyn Keyes", "REP"), ("Barbara Gardner", "d")]),\
	("Justice, 14th Court of Appeals District, Place 2", "14", [("Kevin Jewell", "r"), ("Candance White", "d")]),\
	("Justice, 14th Court of Appeals District, Place 9", "15", [("Tracy Elizabeth Christopher", "r"), ("Peter M. Kelly", "d")]),\
	("District Judge, 11th Judicial District", "16", [("Kevin Fulton", "r"), ("Kristen Hawkins", "d")]),\
	("District Judge, 61st Judicial District", "17", [("Erin Elizabeth Lunceford", "r"), ("Fredericka Phillips", "d")]),\
	("District Judge, 80th Judicial District", "18", [("Will Archer", "r"), ("Larry Weiman", "d")]),\
	("District Judge, 125th Judicial District", "19", [("Sharon Hemphill", "r"), ("Kyle Carter", "d")]),\
	("District Judge, 127th Judicial District", "20", [("Sarahjane Swanson", "r"), ("R. K. Sandhill", "d")]),\
	("District Judge, 129th Judicial District", "21", [("Sophia Mafrige", "r"), ("Michael Gomez", "d")]),\
	("District Judge, 133rd Judicial District", "22", [("Cindy Bennett Smith", "r"), ("Jaclanel McFarland", "d")]),\
	("District Judge, 151st Judicial District", "23", [("Jeff Hastings", "r"), ("Mike Engelhart", "d")]),\
	("District Judge, 152nd Judicial District", "24", [("Don Self", "r"), ("Robert K. Schaffer", "d")]),\
	("District Judge, 164th Judicial District", "25", [("Bruce Bain", "r"), ("Alexandra Smoots-Hogan", "d")]),\
	("District Judge, 165th Judicial District", "26", [("Debra Ibarra Mayfield", "r"), ("Ursula A. Hall", "d")]),\
	("District Judge, 174th Judicial District", "27", [("Katherine McDaniel", "R"), ("Hazel B. Jones", "d")]),\
	("District Judge, 176th Judicial District", "28", [("Stacey W. Bond", "r"), ("Nikita \"Niki\" Harmon", "d")]),\
	("District Judge, 177th Judicial District", "29", [("Ryan Patrick", "r"), ("Robert Johnson", "d")]),\
	("District Judge, 178th Judicial District", "30", [("Phil Gommels", "r"), ("Kelli Johnson", "d")]),\
	("District Judge, 179th Judicial District", "31", [("Kristin M. Guiney", "r"), ("Randy Roll", "d")]),\
	("District Judge, 215th Judicial District", "32", [("Fred Shuchart", "r"), ("Elaine Palmer", "d")]),\
	("District Judge, 333rd Judicial District", "33", [("Joseph \"Tad\" Halbach", "r"), ("Daryl Moore", "d")]),\
	("District Judge, 334th Judicial District", "34", [("Grant Dorfman", "r"), ("Steven Kirkland", "d")]),\
	("District Judge, 337th Judicial District", "35", [("Renee Magee", "r"), ("Herb Ritchie", "d")]),\
	("District Judge, 338th Judicial District", "36", [("Brock Thomas", "r"), ("Ramona Franklin", "d")]),\
	("District Judge, 339th Judicial District", "37", [("Mary McFaden", "r"), ("Maria T. (Terri) Jackson", "d")]),\
	("District Judge, 351st Judicial District", "38", [("Mark Kent Ellis", "r"), ("George Powell", "d")]),\
	("District Judge, 507th Judicial District", "39", [("Alyssa Lemkuil", "r"), ("Julia Maldonado", "d")]),\
	("District Attorney", "40", [("Devon Anderson", "r"), ("Kim Ogg", "d")]),\
	("Judge, County Civil Court at Law No. 1 (Unexpired Term)", "41", [("Clyde Raymond Leuchtag", "r"), ("George Barnstone", "d")]),\
	("Judge, County Criminal Court No. 16", "42", [("Linda Garcia", "r"), ("Darrell William Jordan", "d")]),\
	("County Attorney", "43", [("Jim Leitner", "r"), ("Vince Ryan", "d")]),\
	("Sheriff", "44", [("Ron Hickman", "r"), ("Ed Gonzalez", "d")]),\
	("County Tax Assessor-Collector", "45", [("Mike Sullivan", "r"), ("Ann Harris Bennett", "d")]),\
	("County Commissioner, Precinct 1", "46", [("Rodney Ellis", "d")]),\
	("Justice of the Peace, Precinct 1, Place 1", "47", [("SaraJane Milligan", "r"), ("Eric William Carter", "d")]),\
	("Constable, Precinct 1", "48", [("Joe Danna", "r"), ("Alan Rosen", "d")]),\
	])







