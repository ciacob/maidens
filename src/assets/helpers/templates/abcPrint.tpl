X:1
T:${projectName}
C:${composerName}
H:${creationTimestamp}
H:${modificationTimestamp}
H:${customNotes}
I:abc-creator ${creatorSoftware}
N:${copyrightNote}
L:1/1
Q:1/4=60
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
%%topmargin 3.5cm
%%botmargin 1cm
%%leftmargin 1cm
%%rightmargin 1cm
%%scale 0.8
%
% SPACING
%
%%topspace 1cm
%%titlespace 0cm
%%composerspace 2cm
%%musicspace 0.75cm
K:Cmaj
%
% FONT
%%titlefont Times-Roman 32
%%subtitlefont Times-Roman 24
%%composerfont Times-Italics 16
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
	[V:${staff.uid}]
	[I: MIDI=channel ${staff.channelIndex} MIDI=program ${staff.patchNumber}]
	<#foreach section in staff.sections>
		% Section "${section.name}" for staff "${staff.uid}"
		 <#foreach measure in section.measures>
		 	${measure.timeSignature}<#foreach event in measure.events>${event}</#foreach> ${measure.bar}
		 </#foreach>
	</#foreach>
</#foreach>
