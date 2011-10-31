use warnings;
use strict;

package TessAbbr;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(%abbr);

our %abbr = (

	'catullus.carmina'      	=> 'catull. '		,
	'ennius.annales'		=> 'enn. ann. '		,
	'horace.ars_poetica'    	=> 'hor. ars p. '	,
        'horace.carmen_saeculare' 	=> 'hor. carm. saec. '	,
        'horace.epistles'       	=> 'hor. epist. '	,
        'horace.epodes'         	=> 'hor. epod. '	,
        'horace.odes'           	=> 'hor. carm. '	,
        'horace.satires'        	=> 'hor. sat. '		,
        'juvenal'			=> 'juv. '		,
        'lucan.pharsalia'       	=> 'luc. '		,  
        'lucretius.de_rerum_natura'     => 'lucr. '		,    
	'martial.epigrams'		=> 'mart. '		,
        'ovid.amores'           	=> 'ov. am. '		,
        'ovid.ars_amatoria'     	=> 'ov. ars am. '	,
	'ovid.fasti'			=> 'ov. fast. '		,
        'ovid.heroides'         	=> 'ov. her. '		,  
        'ovid.medicamina_faciei_femineae'       
                                	=> 'ov. medic. '	,
	'ovid.metamorphoses'		=> 'ov. met.'		,
	'paul.carmina'			=> 'paul c.'		,
	'propertius.elegies'    	=> 'prop. '		,
        'silius_italicus.punica'	=> 'sil. pun. '		,
        'statius.thebaid'       	=> 'stat. theb. '	,
        'tibullus'              	=> 'tib. '		,
        'vergil.aeneid'         	=> 'verg. aen. '	,
        'vergil.eclogues'       	=> 'verg. ecl. '	,
        'vergil.georgics'       	=> 'verg. g. '		,          
        'valerius_flaccus'      	=> 'valerius flaccus '
);

1;
