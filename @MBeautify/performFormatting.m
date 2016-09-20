function formattedSource = performFormatting(source, settingConf)



nMaximalNewLines = str2double(settingConf.SpecialRules.MaximalNewLinesValue);
newLine = sprintf('\n');

tokStruct = MBeautify.getTokenStruct();

contTokenStruct = tokStruct('ContinueToken');


%%
textArray = regexp(source, newLine, 'split');

replacedTextArray = cell(1, numel(textArray) * 4);
isInContinousLine = 0;
contLineArray = cell(0, 2);

isInBlockComment = false;
blockCommentDepth = 0;
lastIndexUsed = 0;
nNewLinesFound = 0;
for j = 1:numel(textArray) % in textArray)
    line = textArray{j};
    
    %% Process the maximal new-line count
    [isAcceptable, nNewLinesFound] = MBeautify.handleMaximalNewLines(line, nNewLinesFound, nMaximalNewLines);
    
    if ~isAcceptable
        continue;
    end
    
    %% Determine the position where the line shall be splitted into code and comment
    [commPos, exclamationPos, isInBlockComment, blockCommentDepth] = findComment(line, isInBlockComment, blockCommentDepth);
    splittingPos = max(commPos, exclamationPos);
    
    %% Split the line into two parts: code and comment
    [actCode, actComment] = getCodeAndComment(line, splittingPos);
    
    %% Check for line continousment (...)
    trimmedCode = strtrim(actCode);
    % Line ends with "..."
    if (numel(trimmedCode) >= 3 && strcmp(trimmedCode(end - 2:end), '...')) ...
            || (isequal(splittingPos, 1) && isInContinousLine)
        isInContinousLine = true;
        contLineArray{end + 1, 1} = actCode;
        contLineArray{end, 2} = actComment;
        % Step to next line
        continue;
    else
        % End of cont line
        if isInContinousLine
            isInContinousLine = 0;
            contLineArray{end + 1, 1} = actCode;
            contLineArray{end, 2} = actComment;
            
            %% ToDo: Process
            replacedLines = '';
            for iLine = 1:size(contLineArray, 1) - 1
                tempRow = strtrim(contLineArray{iLine, 1});
                tempRow = [tempRow(1:end - 3), [' ', contTokenStruct.Token, ' ']];
                tempRow = regexprep(tempRow, ['\s+', contTokenStruct.Token, '\s+'], [' ', contTokenStruct.Token, ' ']);
                replacedLines = MBeautify.strConcat(replacedLines, tempRow);
                
            end
            
            replacedLines = MBeautify.strConcat(replacedLines, actCode);
            
            actCodeFinal = performReplacements(replacedLines, settingConf);
            
            splitToLine = regexp(actCodeFinal, contTokenStruct.Token, 'split');
            
            line = '';
            for iSplitLine = 1:numel(splitToLine) - 1
                line = MBeautify.strConcat(line, strtrim(splitToLine{iSplitLine}), [' ', contTokenStruct.StoredValue, ' '], contLineArray{iSplitLine, 2}, newLine);
            end
            line = MBeautify.strConcat(line, strtrim(splitToLine{end}), actComment);
            
            [replacedTextArray, lastIndexUsed] = arrayAppend(replacedTextArray, {line, sprintf('\n')}, lastIndexUsed);
            
            contLineArray = cell(0, 2);
            
            continue;
            
            
        end
    end
    
    
    actCodeFinal = performReplacements(actCode, settingConf);
    line = [strtrim(actCodeFinal), ' ', actComment];
    [replacedTextArray, lastIndexUsed] = arrayAppend(replacedTextArray, {line, sprintf('\n')}, lastIndexUsed);
    
end

formattedSource = [replacedTextArray{:}];

end

function [actCode, actComment] = getCodeAndComment(line, commPos)
if isequal(commPos, 1)
    actCode = '';
    actComment = line;
elseif commPos == -1
    actCode = line;
    actComment = '';
else
    actCode = line(1:max(commPos - 1, 1));
    actComment = strtrim(line(commPos:end));
end
end

function actCodeFinal = performReplacements(actCode, settingConf)

tokStruct = MBeautify.getTokenStruct();
%% Transpose
actCode = replaceTransponations(actCode);
trnspTokStruct = tokStruct('TransposeToken');
nonConjTrnspTokStruct = tokStruct('NonConjTransposeToken');


%% Strings
splittedCode = regexp(actCode, '''', 'split');
strTokenStruct = tokStruct('StringToken');

strTokStructs = cell(1, ceil(numel(splittedCode) / 2));

strArray = cell(1, numel(splittedCode));

for iSplit = 1:numel(splittedCode)
    % Not string
    if ~isequal(mod(iSplit, 2), 0)
        
        mstr = splittedCode{iSplit};
        
        strArray{iSplit} = mstr;
    else % String
        strTokenStruct = tokStruct('StringToken');
        
        strArray{iSplit} = strTokenStruct.Token;
        strTokenStruct.StoredValue = splittedCode{iSplit};
        strTokStructs{iSplit} = strTokenStruct;
    end
    
end

strTokStructs = strTokStructs(cellfun(@(x) ~isempty(x), strTokStructs));

actCodeTemp = [strArray{:}];
actCodeTemp = performReplacementsSingleLine(actCodeTemp, settingConf);


splitByStrTok = regexp(actCodeTemp, strTokenStruct.Token, 'split');

if numel(strTokStructs)
    actCodeFinal = '';
    for iSplit = 1:numel(strTokStructs)
        
        actCodeFinal = MBeautify.strConcat(actCodeFinal, splitByStrTok{iSplit}, '''', strTokStructs{iSplit}.StoredValue, '''');
        %         disp(actCodeFinal)
    end
    
    if numel(splitByStrTok) > numel(strTokStructs)
        actCodeFinal = [actCodeFinal, splitByStrTok{end}];
    end
else
    actCodeFinal = actCodeTemp;
end

actCodeFinal = regexprep(actCodeFinal, trnspTokStruct.Token, trnspTokStruct.StoredValue);
actCodeFinal = regexprep(actCodeFinal, nonConjTrnspTokStruct.Token, nonConjTrnspTokStruct.StoredValue);


end

function actCode = replaceTransponations(actCode)
tokStruct = MBeautify.getTokenStruct();
trnspTokStruct = tokStruct('TransposeToken');
nonConjTrnspTokStruct = tokStruct('NonConjTransposeToken');


charsIndicateTranspose = '[a-zA-Z0-9\)\]\}\.]';

tempCode = '';
isLastCharDot = false;
isLastCharTransp = false;
isInStr = false;
for iStr = 1:numel(actCode)
    actChar = actCode(iStr);
    
    if isequal(actChar, '''')
        % .' => NonConj transpose
        if isLastCharDot
            tempCode = tempCode(1:end - 1);
            tempCode = MBeautify.strConcat(tempCode, nonConjTrnspTokStruct.Token);
            isLastCharTransp = true;
        else
            if isLastCharTransp
                tempCode = MBeautify.strConcat(tempCode, trnspTokStruct.Token);
                isLastCharTransp = true;
            else
                
                if numel(tempCode) && numel(regexp(tempCode(end), charsIndicateTranspose)) && ~isInStr
                    
                    tempCode = MBeautify.strConcat(tempCode, trnspTokStruct.Token);
                    isLastCharTransp = true;
                else
                    tempCode = MBeautify.strConcat(tempCode, actChar);
                    isInStr = ~isInStr;
                    isLastCharTransp = false;
                end
            end
        end
        
        isLastCharDot = false;
    elseif isequal(actChar, '.') && ~isInStr
        isLastCharDot = true;
%         tempCode = MBeautify.strConcat(tempCode, actChar);
        tempCode = [tempCode, actChar];
        isLastCharTransp = false;
    else
        isLastCharDot = false;
        tempCode = [tempCode, actChar];
        isLastCharTransp = false;
    end
end
actCode = tempCode;
end

function [retComm, exclamationPos, isInBlockComment, blockCommentDepth] = findComment(line, isInBlockComment, blockCommentDepth)
%% Set the variables
retComm = -1;
exclamationPos = -1;

trimmedLine = strtrim(line);

%% Handle some special cases

if strcmp(trimmedLine, '%{')
    retComm = 1;
    isInBlockComment = true;
    blockCommentDepth = blockCommentDepth + 1;
elseif strcmp(trimmedLine, '%}') && isInBlockComment
    retComm = 1;
    
    blockCommentDepth = blockCommentDepth - 1;
    isInBlockComment = blockCommentDepth > 0;
else
    if isInBlockComment
        retComm = 1;
        isInBlockComment = true;
    end
end

% In block comment, return
if isequal(retComm, 1), return ; end

% Empty line, simply return
if isempty(trimmedLine)
    return;
end


if isequal(trimmedLine, '%')
    retComm = 1;
    return;
end

if isequal(trimmedLine(1), '!')
    exclamationPos = 1;
    return
end

% If line starts with "import ", it indicates a java import, that line is treated as comment
if numel(trimmedLine) > 7 && isequal(trimmedLine(1:7), 'import ')
    retComm = 1;
    return
end

%% Searh for comment signs(%) and exclamation marks(!)

exclamationInd = strfind(line, '!');
commentSignIndexes = strfind(line, '%');
contIndexes = strfind(line, '...');

if ~iscell(exclamationInd)
    exclamationInd = num2cell(exclamationInd);
end
if ~iscell(commentSignIndexes)
    commentSignIndexes = num2cell(commentSignIndexes);
end
if ~iscell(contIndexes)
    contIndexes = num2cell(contIndexes);
end


% Make the union of indexes of '%' and '!' symbols then sort them
indexUnion = {commentSignIndexes{:}, exclamationInd{:}, contIndexes{:}};
indexUnion = sortrows(indexUnion(:))';

% Iterate through the union
commentSignCount = numel(indexUnion);
if commentSignCount
    
    for iCommSign = 1:commentSignCount
        currentIndex = indexUnion{iCommSign};
        
        % Check all leading parts that can be "code"
        % Replace transponation (and noin-conjugate transponations) to avoid not relevant matches
        possibleCode = line(1:currentIndex - 1);
        possibleCode = replaceTransponations(possibleCode);
        
        copSignIndexes = strfind(possibleCode, '''');
        copSignCount = numel(copSignIndexes);
        
        % The line is currently "not in string"
        if isequal(mod(copSignCount, 2), 0)
            if ismember(currentIndex, [commentSignIndexes{:}])
                retComm = currentIndex;
            elseif ismember(currentIndex, [exclamationInd{:}])
                exclamationPos = currentIndex;
            else
                % Branch of '...'
                retComm = currentIndex + 3;
            end
            
            break;
        end
        
    end
else
    retComm = -1;
end

end


function data = performReplacementsSingleLine(data, settingConf)

tokStruct = MBeautify.getTokenStruct();

setConfigOperatorFields = fields(settingConf.OperatorRules);
% At this point, the data contains one line of code, but all user-defined strings enclosed in '' are replaced by #MBeutyString#

keywords = iskeyword();

% Old-style function calls, such as 'subplot 211' or 'disp Hello World' -> return unchanged
if numel(regexp(data,'^[a-zA-Z0-9_]+\s+[^(=]'))
    
    splitData = regexp(strtrim(data), ' ', 'split');
    % The first elemen is not a keyword and does not exist (function on the path)
    if numel(splitData) && ~any(strcmp(splitData{1}, keywords)) && exist(splitData{1})
        return
    end
    
end

% Process matrixes and cell arrays
% All containers are processed element wised. The replaced containers are placed into a map where the key is a token
% inserted to the original data
[data, arrayMapCell] = processContainer(data, settingConf);

% Replace all control flow keywords (if, for, ...) by #MBeauty_KW_...#
for i = 1:length(keywords)
    keyword = keywords{i};
    if strcmp(keyword, 'end')
        % special handling for 'end':
        %   - in 'A(1:end)', it can be treated as a variable.
        %   - in 'for ...' 'end', it is a control flow keyword, but in this case only whitespace and semicolon and nothing
        %       else may be on the line.W
        if ~numel(regexp(data, '^\s*end[\s;]*$'))
            continue
        end
    end
    data = regexprep(data, ['(?<![a-zA-Z0-9_])', keyword, '(?![a-zA-Z0-9_])'], ['#MBeauty_KW_', keyword, '#']);
end

% Convert all operators like + * == etc to #MBeauty_OP_whatever# tokens
for iOpConf = 1:numel(setConfigOperatorFields)
    currField = setConfigOperatorFields{iOpConf};
    currOpStruct = settingConf.OperatorRules.(currField);
    data = regexprep(data, ['\s*', currOpStruct.ValueFrom, '\s*'], ['#MBeauty_OP_', currField, '#']);
end

% Remove all duplicate space
data = regexprep(data, '\s+', ' ');

% Handle special + and - cases:
% 	- unary plus/minus, such as in (+1): replace #MBeauty_OP_Plus/Minus# by #MBeauty_OP_UnaryPlus/Minus#
%   - normalized number format, such as 7e-3: replace #MBeauty_OP_Plus/Minus# by #MBeauty_OP_NormNotation_Plus/Minus#
% Then convert UnaryPlus tokens to '+' signs same for minus)
for iOpConf = 1:numel(setConfigOperatorFields)
    currField = setConfigOperatorFields{iOpConf};
    
    opToken = ['#MBeauty_OP_', currField, '#'];
    unaryOpToken = ['#MBeauty_OP_Unary', currField, '#'];
    normalizedNotationToken = ['#MBeauty_OP_NormNotation_', currField, '#'];
    
    if (strcmp(opToken, '#MBeauty_OP_Plus#') || strcmp(opToken, '#MBeauty_OP_Minus#')) && numel(regexp(data, opToken))
        
        splittedData = regexp(data, opToken, 'split');
        
        replaceTokens = {};
        for iSplit = 1:numel(splittedData) - 1
            beforeItem = strtrim(splittedData{iSplit});
            if ~isempty(beforeItem) && numel(regexp(beforeItem, ...
                    ['([0-9a-zA-Z_)}\]\.]|', tokStruct('TransposeToken').Token, ')$']))
                % + or - is a binary operator after:
                %    - numbers [0-9.],
                %    - variable names [a-zA-Z0-9_] or
                %    - closing brackets )}]
                %    - transpose signs ', here represented as #MBeutyTransp#
                
                % Special treatment for E: 7E-3 or 7e+4 normalized notation
                % In this case the + and - signs are not operators so shoud be skipped
                if strcmpi(beforeItem(end), 'e')
                    replaceTokens{end + 1} = normalizedNotationToken;
                else
                    replaceTokens{end + 1} = opToken;
                end
            else
                replaceTokens{end + 1} = unaryOpToken;
            end
        end
        
        replacedSplittedData = cell(1, numel(replaceTokens) + numel(splittedData));
        tokenIndex = 1;
        for iSplit = 1:numel(splittedData)
            replacedSplittedData{iSplit * 2 - 1} = splittedData{iSplit};
            if iSplit < numel(splittedData)
                replacedSplittedData{iSplit * 2} = replaceTokens{tokenIndex};
            end
            tokenIndex = tokenIndex + 1;
        end
        data = [replacedSplittedData{:}];
    end
end

% At this point the data is in a completely tokenized representation, e.g.'x#MBeauty_OP_Plus#y' instead of the 'x + y'.
% Now go backwards and replace the tokens by the real operators

% Special tokens: Unary Plus/Minus, Normalized Number Format
data = regexprep(data, ['\s*', '#MBeauty_OP_UnaryPlus#', '\s*'], '+');
data = regexprep(data, ['\s*', '#MBeauty_OP_UnaryMinus#', '\s*'], '-');
data = regexprep(data, ['\s*', '#MBeauty_OP_NormNotation_Plus#', '\s*'], '+');
data = regexprep(data, ['\s*', '#MBeauty_OP_NormNotation_Minus#', '\s*'], '-');

% Replace all other operators
for iOpConf = 1:numel(setConfigOperatorFields)
    currField = setConfigOperatorFields{iOpConf};
    currOpStruct = settingConf.OperatorRules.(currField);
    data = regexprep(data, ['\s*', '#MBeauty_OP_', currField, '#', '\s*'], currOpStruct.ValueTo);
end

data = regexprep(data, ' \)', ')');
data = regexprep(data, ' \]', ']');
data = regexprep(data, '\( ', '(');
data = regexprep(data, '\[ ', '[');

% Restore keywords
keywords = iskeyword();
for i = 1:length(keywords)
    keyword = keywords{i};
    data = regexprep(data, ['\s*', '#MBeauty_KW_', keyword, '#', '\s*'], [' ', keyword, ' ']);
end

% Restore containers
data = decodeArrayTokens(data, arrayMapCell, settingConf);

% Fix semicolon whitespace at end of line
data = regexprep(data, '\s+;\s*$', ';');


end

function data = decodeArrayTokens(data, map, settingConf)
arrayTokenList = map.keys();
if isempty(arrayTokenList)
    return;
end

for iKey = numel(arrayTokenList):-1:1
    data = regexprep(data, arrayTokenList{iKey}, map(arrayTokenList{iKey}));
end

data = regexprep(data, '#MBeauty_OP_Comma#', settingConf.OperatorRules.Comma.ValueTo);
end

function [array, lastUsedIndex] = arrayAppend(array, toAppend, lastUsedIndex)
cellLength = numel(array);

if cellLength <= lastUsedIndex
    error();
end

if ischar(toAppend)
    array{lastUsedIndex + 1} = toAppend;
    lastUsedIndex = lastUsedIndex + 1;
elseif iscell(toAppend)
    %% ToDo: Additional check
    
    for i = 1:numel(toAppend)
        array{lastUsedIndex + 1} = toAppend{i};
        lastUsedIndex = lastUsedIndex + 1;
    end
    
else
    error();
end


end


function [containerBorderIndexes, maxDepth] = calculateContainerDepths(data, openingBrackets, closingBrackets)
containerBorderIndexes = {};
depth = 1;
maxDepth = 1;
for i = 1:numel(data)
    borderFound = true;
    if any(strcmp(data(i), openingBrackets))
        newDepth = depth + 1;
        maxDepth = newDepth;
    elseif any(strcmp(data(i), closingBrackets))
        newDepth = depth - 1;
        depth = depth - 1;
    else
        borderFound = false;
    end
    
    if borderFound
        containerBorderIndexes{end + 1, 1} = i;
        containerBorderIndexes{end, 2} = depth;
        depth = newDepth;
    end
end
end

function [data, arrayMap] = processContainer(data, settingConf)

arrayMap = containers.Map();
if isempty(data)
    return
end
openingBrackets = {'[', '{'};
closingBrackets = {']', '}'};

tokStruct = MBeautify.getTokenStruct();

operatorArray = {'+', '-', '&', '&&', '|', '||', '/', '*', ':'};
contTokenStruct = tokStruct('ContinueToken');

[containerBorderIndexes, maxDepth] = calculateContainerDepths(data, openingBrackets, closingBrackets);

id = 0;

while maxDepth > 0
    indexes = find([containerBorderIndexes{:, 2}] == maxDepth, 2);
    
    if ~numel(indexes)
        maxDepth = maxDepth - 1;
        continue;
    end
    
    str = data(containerBorderIndexes{indexes(1), 1}:containerBorderIndexes{indexes(2), 1});
    
    openingBracket = data(containerBorderIndexes{indexes(1), 1});
    closingBracket = data(containerBorderIndexes{indexes(2), 1});
    
    str = regexprep(str, '\s+', ' ');
    str = regexprep(str, [openingBracket, '\s+'], openingBracket);
    str = regexprep(str, ['\s+', closingBracket], closingBracket);
    
    elementsCell = regexp(str, ' ', 'split');
    
    
    firstElem = strtrim(elementsCell{1});
    lastElem = strtrim(elementsCell{end});
    
    if numel(elementsCell) == 1
        elementsCell{1} = firstElem(2:end - 1);
    else
        elementsCell{1} = firstElem(2:end);
        elementsCell{end} = lastElem(1:end - 1);
    end
    
    for iElem = 1:numel(elementsCell)
        elem = strtrim(elementsCell{iElem});
        if numel(elem) && strcmp(elem(1), ',')
            elem = elem(2:end);
        end
        elementsCell{iElem} = elem;
        
    end
    
    isInCurlyBracket = 0;
    for elemInd = 1:numel(elementsCell) - 1
        
        currElem = strtrim(elementsCell{elemInd});
        nextElem = strtrim(elementsCell{elemInd + 1});
        
        if ~numel(currElem)
            continue;
        end
        
        
        hasOpeningBrckt = numel(strfind(currElem, openingBracket));
        isInCurlyBracket = isInCurlyBracket || hasOpeningBrckt;
        hasClosingBrckt = numel(strfind(currElem, closingBracket));
        isInCurlyBracket = isInCurlyBracket && ~hasClosingBrckt;
        
        currElemStripped = regexprep(currElem, ['[', openingBracket, closingBracket, ']'], '');
        nextElemStripped = regexprep(nextElem, ['[', openingBracket, closingBracket, ']'], '');
        
        currElem = strtrim(performReplacementsSingleLine(currElem, settingConf));
        
        if strcmp(openingBracket, '[')
            addCommas = str2double(settingConf.SpecialRules.AddCommasToMatricesValue);
        else
            addCommas = str2double(settingConf.SpecialRules.AddCommasToCellArraysValue);
        end
        
        
        if numel(currElem) && addCommas && ...
                ~(strcmp(currElem(end), ',') || strcmp(currElem(end), ';')) && ~isInCurlyBracket && ...
                ~strcmp(currElem, contTokenStruct.Token) && ...
                ~any(strcmp(currElemStripped, operatorArray)) && ~any(strcmp(nextElemStripped, operatorArray))
            
            
            elementsCell{elemInd} = [currElem, '#MBeauty_OP_Comma#'];
        else
            elementsCell{elemInd} = [currElem, ' '];
        end
        
    end
    
    elementsCell{end} = strtrim(performReplacementsSingleLine(elementsCell{end}, settingConf));
    strNew = [openingBracket, elementsCell{:}, closingBracket];
    
    
    datacell = cell(1, 3);
    if containerBorderIndexes{indexes(1), 1} == 1
        datacell{1} = '';
    else
        datacell{1} = data(1:containerBorderIndexes{indexes(1), 1}-1);
    end
    
    if containerBorderIndexes{indexes(2), 1} == numel(data)
        datacell{end} = '';
    else
        datacell{end} = data(containerBorderIndexes{indexes(2), 1}+1:end);
    end
    
    tokenOfCUrElem = ['#MBeauty_ArrayToken_', num2str(id), '#'];
    arrayMap(tokenOfCUrElem) = strNew;
    id = id + 1;
    datacell{2} = tokenOfCUrElem;
    data = [datacell{:}];
    
    containerBorderIndexes = calculateContainerDepths(data, openingBrackets, closingBrackets); 
end
end


