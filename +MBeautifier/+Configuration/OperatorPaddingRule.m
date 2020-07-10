classdef OperatorPaddingRule
    
    properties (SetAccess = immutable)
        Key
        ValueFrom
        ValueTo
        Token
        ReplacementPattern
    end
    
    properties (Access = private)
        MatrixIndexingReplacementPattern
        CellArrayIndexingReplacementPattern
    end
    
    methods
        function obj = OperatorPaddingRule(key, valueFrom, valueTo)
            obj.Key = key;
            obj.ValueFrom = regexptranslate('escape', valueFrom);
            obj.ValueTo = regexptranslate('escape', valueTo);
            obj.Token = ['#MBeautifier_OP_', key, '#'];
            
            whiteSpaceToken = MBeautifier.Constants.WhiteSpaceToken;
            wsTokenLength = numel(whiteSpaceToken);
            
            tokenizedReplaceString = strrep(obj.ValueTo, ' ', whiteSpaceToken);
            % Calculate the starting white space count
            leadingWSNum = 0;
            matchCell = regexp(tokenizedReplaceString, ['^(', whiteSpaceToken, ')+'], 'match');
            if numel(matchCell)
                leadingWSNum = numel(matchCell{1}) / wsTokenLength;
            end
            
            % Calculate ending whitespace count
            endingWSNum = 0;
            matchCell = regexp(tokenizedReplaceString, ['(', whiteSpaceToken, ')+$'], 'match');
            if numel(matchCell)
                endingWSNum = numel(matchCell{1}) / wsTokenLength;
            end
            
            obj.ReplacementPattern = ['\s*(', whiteSpaceToken, '){0,', num2str(leadingWSNum), '}', obj.Token, ...
                '(', whiteSpaceToken, '){0,', num2str(endingWSNum), '}\s*'];
            
            if numel(regexp(obj.ValueFrom, '\+|\-|\/|\*'))
                obj.MatrixIndexingReplacementPattern = ['\s*(', whiteSpaceToken, '){0,0}', obj.Token, '(', whiteSpaceToken, '){0,0}\s*'];
                obj.CellArrayIndexingReplacementPattern = ['\s*(', whiteSpaceToken, '){0,0}', obj.Token, '(', whiteSpaceToken, '){0,0}\s*'];
            else
                obj.MatrixIndexingReplacementPattern = obj.ReplacementPattern;
                obj.MatrixIndexingReplacementPattern = obj.ReplacementPattern;
            end
        end
        
        function pattern = matrixIndexingReplacementPattern(obj, isPaddingEnabled)
            if isPaddingEnabled
                pattern = obj.ReplacementPattern;
            else
                pattern = obj.MatrixIndexingReplacementPattern;
            end
        end
        
        function pattern = cellArrayIndexingReplacementPattern(obj, isPaddingEnabled)
            if isPaddingEnabled
                pattern = obj.ReplacementPattern;
            else
                pattern = obj.CellArrayIndexingReplacementPattern;
            end
        end
        
        function TF = eq(obj,objB)
            % Returns true if two OperatorPaddingRule objects have the same values.
            % TF = eq(obj,objB)
            TF = false;
            if ~isa(objB,class(obj))
                return
            end
            prop = properties(obj);
            for k = 1:numel(prop)
                if ~isprop(objB,prop{k})
                    return
                end
                
                if ~isa(objB.(prop{k}),class(obj.(prop{k})))
                    return
                end
                
                if ischar(objB.(prop{k}))
                    if ~strcmp(obj.(prop{k}),objB.(prop{k}))
                        return
                    end
                else
                    if ~(obj.(prop{k})  == objB.(prop{k}))
                        return
                    end
                end
            end
            TF = true;
        end
    end
end