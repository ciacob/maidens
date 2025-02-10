X:1
T:${projectName}
C:${composerName}
H:${creationTimestamp}
H:${modificationTimestamp}
H:${customNotes}
I:abc-creator ${creatorSoftware}
N:${copyrightNote}
L:1/1
<#foreach staff in staves>
	V:${staff.uid} ${staff.nameToken} ${staff.snameToken} clef=${staff.clef}
</#foreach>
%
%%staves ${stavesGrouping}
%%measurenb 0
%
% PAGE LAYOUT
%
%%pageheight 29.7cm
%%pagewidth 21cm
%%topmargin 0cm
%%botmargin 0cm
%%leftmargin 1cm
%%rightmargin 1cm
%%scale 1
%%linebreak <none>
%
% SPACING
%
%%topspace 0cm
%%titlespace 0cm
%%composerspace 0.7cm
%%musicspace 1.2cm
K:Cmaj
%
% FONT
%%titlefont 28
%%subtitlefont 24
%%composerfont 16
%
% MISC. SETTINGS
%%voicecombine -1
%%shiftunison 3
%%beamslope 0
%%flatbeams 1
%%fgcolor ${scoreForeground}
%%bgcolor ${scoreBackground}
%
<#foreach staff in staves>
	<#foreach section in staff.sections>
		% Section "${section.name}" for staff "${staff.uid}"
		[V:${staff.uid}] 
		 <#foreach measure in section.measures>
		 	${measure.timeSignature}<#foreach event in measure.events>${event}</#foreach> ${measure.bar}
		 </#foreach>
	</#foreach>
</#foreach>
