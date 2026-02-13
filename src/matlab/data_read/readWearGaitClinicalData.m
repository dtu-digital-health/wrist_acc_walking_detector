function T = readWearGaitClinicalData(p_pd, p_control)
%READWEARGAITCLINICALDATA Read + harmonize PD/control clinical data, add
%MDS-UPDRS part scores and gait-relevant items (individually), add assistive
%device column, and (optionally) join aggregated walkway metrics.

%% PD data
opts = delimitedTextImportOptions("NumVariables", 94);

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["SubjectID", "ReleaseVersion", "AssistiveDeviceUsedDuringTesting", "TimeOfResearchSession", "Heightin", "Ageyears", "Weightkg", "Gender", "Sex", "Race", "TimeOfLastMedicationDose", "PTOTStatus", "FrequencyOfPTOT", "YearsSincePDDiagnosis", "CurrentMedications", "PDMedicationDose", "DBS", "BilateralVsUilateral", "ElectrodeLocations", "YearsSinceSurgery", "PrimarySourceOfInformation", "MDSUPDRS_11", "MDSUPDRS_12", "MDSUPDRS_13", "MDSUPDRS_14", "MDSUPDRS_15", "MDSUPDRS_16", "WhoIsFillingOutThisQuestionnaire", "MDSUPDRS_17", "MDSUPDRS_18", "MDSUPDRS_19", "MDSUPDRS_110", "MDSUPDRS_111", "MDSUPDRS_112", "MDSUPDRS_113", "MDSUPDRS_21", "MDSUPDRS_22", "MDSUPDRS_23", "MDSUPDRS_24", "MDSUPDRS_25", "MDSUPDRS_26", "MDSUPDRS_27", "MDSUPDRS_28", "MDSUPDRS_29", "MDSUPDRS_210", "MDSUPDRS_211", "MDSUPDRS_212", "MDSUPDRS_213", "DaysSincePartIIIClinicalEvaluation", "ModifiedHoehnYahrScore", "a", "b", "c", "c1", "MDSUPDRS_31", "MDSUPDRS_32", "MDSUPDRS_33Neck", "MDSUPDRS_33RUE", "MDSUPDRS_33LUE", "MDSUPDRS_33RLE", "MDSUPDRS_33LLE", "MDSUPDRS_34R", "MDSUPDRS_34L", "MDSUPDRS_35R", "MDSUPDRS_35L", "MDSUPDRS_36R", "MDSUPDRS_36L", "MDSUPDRS_37R", "MDSUPDRS_37L", "MDSUPDRS_38R", "MDSUPDRS_38L", "MDSUPDRS_39", "MDSUPDRS_310", "MDSUPDRS_311", "MDSUPDRS_312", "MDSUPDRS_313", "MDSUPDRS_314", "MDSUPDRS_315R", "MDSUPDRS_315L", "MDSUPDRS_316R", "MDSUPDRS_316L", "MDSUPDRS_317RUE", "MDSUPDRS_317LUE", "MDSUPDRS_317RLE", "MDSUPDRS_317LLE", "MDSUPDRS_317LipJaw", "MDSUPDRS_318", "MDSUPDRS_41", "MDSUPDRS_42", "MDSUPDRS_43", "MDSUPDRS_44", "MDSUPDRS_45", "MDSUPDRS_46", "OtherNotesOnDyskinesias"];
opts.VariableTypes = ["string", "string", "categorical", "datetime", "double", "double", "double", "categorical", "categorical", "categorical", "datetime", "categorical", "string", "double", "string", "string", "categorical", "categorical", "categorical", "double", "string", "double", "double", "double", "double", "double", "double", "string", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
% opts = setvaropts(opts, ["AssistiveDeviceUsedDuringTesting", "FrequencyOfPTOT", "CurrentMedications", "PDMedicationDose", "PrimarySourceOfInformation", "WhoIsFillingOutThisQuestionnaire", "OtherNotesOnDyskinesias"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["AssistiveDeviceUsedDuringTesting", "Gender", "Sex", "Race", "PTOTStatus", "FrequencyOfPTOT", "CurrentMedications", "PDMedicationDose", "DBS", "BilateralVsUilateral", "ElectrodeLocations", "PrimarySourceOfInformation", "WhoIsFillingOutThisQuestionnaire", "a", "b", "c", "OtherNotesOnDyskinesias"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeOfResearchSession", "InputFormat", "hh:mm a", "DatetimeFormat", "preserveinput");
opts = setvaropts(opts, "TimeOfLastMedicationDose", "InputFormat", "hh:mm a", "DatetimeFormat", "preserveinput");

% Import the data
T_pd = readtable(p_pd, opts);

%% Control data
opts = delimitedTextImportOptions("NumVariables", 91, "Encoding", "UTF-8");

% Specify range and delimiter
opts.DataLines = [3, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["SubjectID", "ReleaseVersion", "AssistiveDeviceUsedDuringTesting", "Age", "Gender", "Sex", "Race", "Heightin", "Weightkg", "TimeOfResearchSession", "PTOTStatus", "FrequencyOfPTOT", "CurrentMedicationstypedosage", "MoCAScore", "Depression", "SleepingProblems", "UrineProblemsincontinence", "VisionProblems", "PrimarySourceOfInformation", "MDSUPDRS_11", "MDSUPDRS_12", "MDSUPDRS_13", "MDSUPDRS_14", "MDSUPDRS_15", "MDSUPDRS_16", "WhoIsFillingOutThisQuestionnaire", "MDSUPDRS_17", "MDSUPDRS_18", "MDSUPDRS_19", "MDSUPDRS_110", "MDSUPDRS_111", "MDSUPDRS_112", "MDSUPDRS_113", "MDSUPDRS_21", "MDSUPDRS_22", "MDSUPDRS_23", "MDSUPDRS_24", "MDSUPDRS_25", "MDSUPDRS_26", "MDSUPDRS_27", "MDSUPDRS_28", "MDSUPDRS_29", "MDSUPDRS_210", "MDSUPDRS_211", "MDSUPDRS_212", "MDSUPDRS_213", "ModifiedHoehnYahrScore", "a", "b", "c", "c1", "MDSUPDRS_31", "MDSUPDRS_32", "MDSUPDRS_33Neck", "MDSUPDRS_33RUE", "MDSUPDRS_33LUE", "MDSUPDRS_33RLE", "MDSUPDRS_33LLE", "MDSUPDRS_34R", "MDSUPDRS_34L", "MDSUPDRS_35R", "MDSUPDRS_35L", "MDSUPDRS_36R", "MDSUPDRS_36L", "MDSUPDRS_37R", "MDSUPDRS_37L", "MDSUPDRS_38R", "MDSUPDRS_38L", "MDSUPDRS_39", "MDSUPDRS_310", "MDSUPDRS_311", "MDSUPDRS_312", "MDSUPDRS_313", "MDSUPDRS_314", "MDSUPDRS_315R", "MDSUPDRS_315L", "MDSUPDRS_316R", "MDSUPDRS_316L", "MDSUPDRS_317RUE", "MDSUPDRS_317LUE", "MDSUPDRS_317RLE", "MDSUPDRS_317LLE", "MDSUPDRS_317LipJaw", "MDSUPDRS_318", "MDSUPDRS_41", "MDSUPDRS_42", "MDSUPDRS_43", "MDSUPDRS_44", "MDSUPDRS_45", "MDSUPDRS_46", "VarName91"];
opts.VariableTypes = ["string", "string", "categorical", "double", "categorical", "categorical", "categorical", "double", "double", "datetime", "categorical", "string", "string", "double", "categorical", "categorical", "categorical", "categorical", "string", "double", "double", "double", "double", "double", "double", "string", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "categorical", "categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
% opts = setvaropts(opts, ["SubjectID", "ReleaseVersion", "FrequencyOfPTOT", "CurrentMedicationstypedosage", "PrimarySourceOfInformation", "WhoIsFillingOutThisQuestionnaire"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["SubjectID", "ReleaseVersion", "AssistiveDeviceUsedDuringTesting", "Gender", "Sex", "Race", "PTOTStatus", "FrequencyOfPTOT", "CurrentMedicationstypedosage", "Depression", "SleepingProblems", "UrineProblemsincontinence", "VisionProblems", "PrimarySourceOfInformation", "WhoIsFillingOutThisQuestionnaire", "a", "b", "c", "c1"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeOfResearchSession", "InputFormat", "hh:mm:ss aa", "DatetimeFormat", "preserveinput");
% Import the data
T_controls = readtable(p_control, opts);

%% Common variables
commonVars = {
    'SubjectID'
    'Group'                  % PD or Control
    'Age'
    'Sex'
    'Gender'
    'Heightin'
    'Weightkg'
    'AssistiveDeviceUsedDuringTesting'
    'ModifiedHoehnYahrScore' % NaN for controls
    'MoCAScore'              % NaN for PD if missing
};

% MDS-UPDRS item sets (must exist in both source tables)
P1 = ["MDSUPDRS_11","MDSUPDRS_12","MDSUPDRS_13","MDSUPDRS_14","MDSUPDRS_15","MDSUPDRS_16"];
P2 = ["MDSUPDRS_21","MDSUPDRS_22","MDSUPDRS_23","MDSUPDRS_24","MDSUPDRS_25","MDSUPDRS_26", ...
      "MDSUPDRS_27","MDSUPDRS_28","MDSUPDRS_29","MDSUPDRS_210","MDSUPDRS_211","MDSUPDRS_212","MDSUPDRS_213"];
P3 = ["MDSUPDRS_31","MDSUPDRS_32", ...
      "MDSUPDRS_33Neck","MDSUPDRS_33RUE","MDSUPDRS_33LUE","MDSUPDRS_33RLE","MDSUPDRS_33LLE", ...
      "MDSUPDRS_34R","MDSUPDRS_34L","MDSUPDRS_35R","MDSUPDRS_35L", ...
      "MDSUPDRS_36R","MDSUPDRS_36L","MDSUPDRS_37R","MDSUPDRS_37L", ...
      "MDSUPDRS_38R","MDSUPDRS_38L", ...
      "MDSUPDRS_39","MDSUPDRS_310","MDSUPDRS_311","MDSUPDRS_312","MDSUPDRS_313","MDSUPDRS_314", ...
      "MDSUPDRS_315R","MDSUPDRS_315L","MDSUPDRS_316R","MDSUPDRS_316L", ...
      "MDSUPDRS_317RUE","MDSUPDRS_317LUE","MDSUPDRS_317RLE","MDSUPDRS_317LLE","MDSUPDRS_317LipJaw", ...
      "MDSUPDRS_318"];
P4 = ["MDSUPDRS_41","MDSUPDRS_42","MDSUPDRS_43","MDSUPDRS_44","MDSUPDRS_45","MDSUPDRS_46"];

% Gait-relevant items (keep individually, plus optional sum)
gaitItems = ["MDSUPDRS_212","MDSUPDRS_213","MDSUPDRS_310","MDSUPDRS_311","MDSUPDRS_312","MDSUPDRS_313","MDSUPDRS_314"];

% Add MDS items + computed scores to the "commonVars" extraction
commonVars = [commonVars; cellstr(P1)'; cellstr(P2)'; cellstr(P3)'; cellstr(P4)'];

%% Harmonize

% Rename PD age
T_pd.Age = T_pd.Ageyears;

% Create MoCA placeholder (not in PD file)
T_pd.MoCAScore = nan(height(T_pd),1);

% Add group label
T_pd.Group = repmat("PD", height(T_pd), 1);

% Rename control age
T_controls.Age = T_controls.Age;

% Add Hoehn–Yahr placeholder
T_controls.ModifiedHoehnYahrScore = nan(height(T_controls),1);

% Add group label
T_controls.Group = repmat("Control", height(T_controls), 1);

% Keep common
T_pd_clean       = T_pd(:, commonVars);
T_controls_clean = T_controls(:, commonVars);

%% Concatenate
T = [T_pd_clean; T_controls_clean];

%% Add MDS-UPDRS
% Helper: only sum columns that actually exist (robust across releases)
P1e = P1(ismember(P1, string(T.Properties.VariableNames)));
P2e = P2(ismember(P2, string(T.Properties.VariableNames)));
P3e = P3(ismember(P3, string(T.Properties.VariableNames)));
P4e = P4(ismember(P4, string(T.Properties.VariableNames)));

T.MDS_Part1 = sum(T{:, P1e}, 2);
T.MDS_Part2 = sum(T{:, P2e}, 2);
T.MDS_Part3 = sum(T{:, P3e}, 2);
T.MDS_Part4 = sum(T{:, P4e}, 2);
T.MDS_Total = T.MDS_Part1 + T.MDS_Part2 + T.MDS_Part3 + T.MDS_Part4;

% Ensure gait items exist; if a column is missing in a future release,
% create it as NaN (so your downstream code never breaks).
for v = gaitItems
    vn = char(v);
    if ~ismember(vn, T.Properties.VariableNames)
        T.(vn) = nan(height(T),1);
    end
end

end