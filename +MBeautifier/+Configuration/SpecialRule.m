classdef SpecialRule
    
    properties (SetAccess = immutable)
        Key
        Value
    end
    
    properties (Dependent)
        ValueAsDouble
    end
    
    methods
        function obj = SpecialRule(key, value)
            obj.Key = key;
            obj.Value = value;
        end
        
        function value = get.ValueAsDouble(obj)
            value = str2double(obj.Value);
        end
        
        function TF = eq(obj,objB)
            % Returns true if two SpecialRule objects have the same values.
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
                elseif isnumeric(obj.(prop{k}))
                    if ~isequaln(obj.(prop{k}),objB.(prop{k}))
                        return
                    end
                else
                    if ~(obj.(prop{k}) == objB.(prop{k}))
                        return
                    end
                end
            end
            TF = true;
        end
    end
end