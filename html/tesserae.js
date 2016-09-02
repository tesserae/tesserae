function populate_author(lang, dest) {

	var select_full = document.getElementById(lang.concat('_texts'));
	var select_auth = document.getElementsByName(dest.concat('_auth'))[0];
	
	var authors = {};
	
	for (var i=0; i<select_full.length; i++) { 
	
		var opt_this = select_full.options[i];
		
		var seg_value = opt_this.value.split('.');
		var seg_name = opt_this.text.split(' - ');
						
		authors[seg_value[0]] = seg_name[0];			
	}
	
	for (var i in authors) {
	
		var opt_new = new Option(authors[i], i);
		select_auth.add(opt_new);
	}
	
	populate_work(lang,dest);
}

function populate_work(lang, dest) {

	var select_full = document.getElementById(lang.concat('_texts'));
	var select_auth = document.getElementsByName(dest.concat('_auth'))[0];				
	var select_work = document.getElementsByName(dest.concat('_work'))[0];
	
	var auth_master = select_auth.options[select_auth.selectedIndex].value
	var works = {};
	
	for (var i=0; i<select_full.length; i++) { 
	
		var opt_this = select_full.options[i];
		
		var seg_value = opt_this.value.split('.');
		var seg_name = opt_this.text.split(' - ');
		
		var auth_this = seg_value[0];
		var work_this = seg_value[1];
	
		if (auth_this == auth_master) {
			
			works[work_this] = seg_name[1];			
		}
	}
	
	for (var i=select_work.length-1; i>=0; i -= 1) {
		
		select_work.remove(i);
	}
	
	for (var i in works) {
	
		var opt_new = new Option(works[i], i);
		select_work.add(opt_new);
	}
			
	populate_part(lang,dest);
}

function populate_part(lang, dest) {
	
	var select_full = document.getElementById(lang.concat('_texts'));
	var select_auth = document.getElementsByName(dest.concat('_auth'))[0];
	var select_work = document.getElementsByName(dest.concat('_work'))[0];
	var select_part = document.getElementsByName(dest)[0];
	
	var auth_master = select_auth.options[select_auth.selectedIndex].value;
	var work_master = select_work.options[select_work.selectedIndex].value;
	var parts = {};
	
	for (var i=0; i<select_full.length; i++) { 
	
		var opt_this = select_full.options[i];
		
		var seg_value = opt_this.value.split('.');
		var seg_name = opt_this.text.split(' - ');
		
		var auth_this = seg_value[0];
		var work_this = seg_value[1];
						
		if (auth_this == auth_master && work_this == work_master) {
			
			if (seg_name.length > 2) {
				
				parts[seg_name[2]] = opt_this.value;
			}
			else {
			
				parts['Full Text'] = opt_this.value;
			}
		}
	}
	
	for (var i=select_part.length-1; i>=0; i -= 1) {
		
		select_part.remove(i);
	}
	
	for (var i in parts) {
	
		var opt_new = new Option(i, parts[i]);
		select_part.add(opt_new);
	}		
}

function populate_feature(features, sel_position) {

	var list_feature = document.getElementsByName('feature')[0];

	for (var feat in features) {
		var opt = document.createElement('option');
		opt.value = feat;
		opt.text = features[feat];

		list_feature.add(opt);
		
		list_feature.selectedIndex=sel_position;
	}
}

function set_defaults(lang, selected) {
		
	for (prefix in selected) {
	
		var select_auth = document.getElementsByName(prefix.concat('_auth'))[0];
		var select_work = document.getElementsByName(prefix.concat('_work'))[0];
		var select_part = document.getElementsByName(prefix)[0];
		
		var seg = selected[prefix].split('.');
		var auth = seg[0];
		var work = seg[1];
		
		for (var i=0; i < select_auth.options.length; i++) {
		
			if (select_auth.options[i].value == auth) {
			
				select_auth.selectedIndex = i;
			}
		}
		
		populate_work(lang[prefix],prefix);

		for (var i=0; i < select_work.options.length; i++) {
		
			if (select_work.options[i].value == work) {
		
				select_work.selectedIndex = i;
			}
		}
		
		populate_part(lang[prefix],prefix);

		for (var i=0; i < select_part.options.length; i++) {
		
			if (select_part.options[i].value == selected[prefix]) {
			
				select_part.selectedIndex = i;
			}
		}
	}	
}

function hideshow() {

	var adv = document.getElementById('advanced');
	var msg = document.getElementById('moremsg');
	
	if (adv.style.display !== 'none') {
		adv.style.display = 'none';
		msg.innerHTML = 'show advanced'
	}
	else {
		adv.style.display = 'block';
		msg.innerHTML = 'hide advanced'
	}
}