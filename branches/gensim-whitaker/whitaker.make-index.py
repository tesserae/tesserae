import pickle

path_data = "/Volumes/CWFDATA/semantics"

full_defs = pickle.load(path_data + "/whitaker.full_defs.pickle")

letters = set([])

for line in full_defs:
	
	letters.add(line[1])

last_letter = "none"

for i, line in enumerate(full_defs):
	
	this_head, this_body = line.split(" :: ")
	this_code = this_head[-7:]
	this_head = this_head[1:-7].strip()
	this_head, this_pos = this_head.split("  ")
	
	this_letter = this_head[0]
	if this_letter != last_letter:
		
	
	
	print "<tr>",
	print "<td>{0}</td>".format(i),
	print "<td><a href=\"cgi-bin/whitaker.test.py?lineno={0}\">{1}</a></td>".format(i, this_head),
	print "<td>{0}</td><td>{1}</td>".format(this_pos, this_code),
	print "<td>{0}</td>".format(this_body),
	print "</tr>"
	
def new_index_page(this_letter):
	
	if l != "a"
	
	print "<html>"
	print "<head>"
	print "   <title>{0}</title>".format(this_letter.upper)
	print "</head>"
	print 
	print "<body>"

	for l in sorted(letters):
		
		if l != this_letter:
			print "<a href=\"http://localhost/~chris/whitaker/{0}.html\">{0}</a>".format(l),
		else:
			print l,
	
	print
	
	print "<table>"