classdef KeywordPaddingRule
    
    properties (SetAccess = immutable)
        Keyword
        RightPadding
    end
    
    properties (Dependent)
        ReplaceTo
    end
    
    methods
        function obj = KeywordPaddingRule(keyword, rightPadding)
            obj.Keyword = lower(keyword);
            obj.RightPadding = rightPadding;
        end
        
        function value = get.ReplaceTo(obj)
            wsPadding = '';
            for i = 1:obj.RightPadding
                wsPadding = [' ', wsPadding];
            end
            
            value = [obj.Keyword, wsPadding];
        end
        
        function TF = eq(obj,objB)
            % Returns true if two KeyWordPaddingRule objects have the same values.
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