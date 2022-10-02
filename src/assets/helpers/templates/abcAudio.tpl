X:1
T:${projectName}
C:${composerName}
H:${creationTimestamp}
H:${modificationTimestamp}
H:${customNotes}
I:abc-creator ${creatorSoftware}
N:${copyrightNote}
L:1/1
Q:60
<#foreach staff in staves>
	V:${staff.uid} name="${staff.name}" sname="${staff.abrevName}" clef=${staff.clef}
</#foreach>
%
K:Cmaj
%
<#foreach staff in staves>
	<#foreach section in staff.sections>
		% Section "${section.name}" for staff "${staff.uid}"
		[V:${staff.uid}] 
		 <#foreach measure in section.measures>
		 	${measure.timeSignature}[I: MIDI= channel ${staff.channelIndex} MIDI=program ${staff.patchNumber}]<#foreach event in measure.events>${event}</#foreach> ${measure.bar}
		 </#foreach>
	</#foreach>
</#foreach>
	

