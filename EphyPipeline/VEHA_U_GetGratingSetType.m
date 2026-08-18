function [chGratingTypeTag] = VEHA_U_GetGratingSetType(sGRATING_PARAM)
%Analyse the fields in the input structure sGRATING_PARAM and returns a
%character string designating the experiment type performed. The tags are
%of the form Ori-8 where the first three letters represent the grating
%parameter tested and the following number represent the number of
%values tested for the parameter. When combination of parameters where
%tested together tags are listed and separated by underscores (e.g.
%SFr-4_Ctr-4_SSz-4 when testing all 64 combination of 4 Spatial
%frequencies, 4 contrasts and 4 stimulus sizes)

if isfield(sGRATING_PARAM, 'ExperimentType')
    switch sGRATING_PARAM.ExperimentType
        case 'OrientationTuning'
            chGratingTypeTag = strcat('Ori-', num2str(sGRATING_PARAM.TestResolution));
        case 'SpatialFrequencyTuning'
            chGratingTypeTag = strcat('SFr-', num2str(sGRATING_PARAM.TestResolution));
        case 'TemporalFrequencyTuning'
            chGratingTypeTag = strcat('TFr-', num2str(sGRATING_PARAM.TestResolution));
        case 'ContrastModulation'
            chGratingTypeTag = strcat('Ctr-', num2str(sGRATING_PARAM.TestResolution));
        case 'SingleGrating'
            chGratingTypeTag = 'SGr';
    end
else
    bl1SglCond = ones(1, 5);
    cGTTAG = {'','','','',''};
    
    if length(sGRATING_PARAM.Orientation) > 1
        cGTTAG{1} = strcat('Ori-', num2str(length(sGRATING_PARAM.Orientation)));
        bl1SglCond(1) = 0;
    end
    
    if length(sGRATING_PARAM.SpatialFrequency) > 1
        cGTTAG{2} = strcat('SFr-', num2str(length(sGRATING_PARAM.SpatialFrequency)));
        bl1SglCond(2) = 0;
    end
    
    if length(sGRATING_PARAM.TemporalFrequency) > 1
        cGTTAG{3} = strcat('TFr-', num2str(length(sGRATING_PARAM.TemporalFrequency)));
        bl1SglCond(3) = 0;
    end
    
    if length(sGRATING_PARAM.Contrast) > 1
        cGTTAG{4} = strcat('Ctr-', num2str(length(sGRATING_PARAM.Contrast)));
        bl1SglCond(4) = 0;
    end
    
    if sGRATING_PARAM.DrawMask
        if length(sGRATING_PARAM.MaskRadiusInVisualDegree) > 1
            cGTTAG{5} = strcat('SSz-', num2str(length(sGRATING_PARAM.MaskRadiusInVisualDegree)));
            bl1SglCond(5) = 0;
        end
    end
    
    if all(bl1SglCond)
        chGratingTypeTag = 'SGr';
    else 
        chGratingTypeTag = strjoin(cGTTAG, '');
        chGratingTypeTag = regexprep(chGratingTypeTag, '([1-9])(\w)', '$1_$2');
    end
end