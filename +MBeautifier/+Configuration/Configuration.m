classdef Configuration < handle
    
    properties (Access = private)
        OperatorPaddingRules;
        OperatorPaddingRuleNamesInOrder;
        KeywordPaddingRules;
        SpecialRules;
    end
    
    methods (Access = private)
        function obj = Configuration(operatorPaddingRules, operatorPaddingRuleNamesInOrder, keywordRules, specialRules)
            obj.OperatorPaddingRules = operatorPaddingRules;
            obj.SpecialRules = specialRules;
            obj.KeywordPaddingRules = keywordRules;
            obj.OperatorPaddingRuleNamesInOrder = operatorPaddingRuleNamesInOrder;
        end
    end
    
    methods
        function rule = specialRule(obj, name)
            rule = obj.SpecialRules(lower(name));
        end
        
        function rules = specialRules(obj)
            rules = obj.SpecialRules.values;
            % rules is a cell array of
            % MBeautifier.Configuration.KeyWordPaddingRule objects
            %             rules = [rules{:}];
        end
        
        function rule = operatorPaddingRule(obj, name)
            rule = obj.OperatorPaddingRules(lower(name));
        end
        
        function rules = operatorPaddingRules(obj)
            rules = obj.OperatorPaddingRules.values;
            % rules is a cell array of
            % MBeautifier.Configuration.KeyWordPaddingRule objects
            %             rules = [rules{:}];
        end
        
        function rule = keywordPaddingRule(obj, name)
            rule = obj.KeywordPaddingRules(lower(name));
        end
        
        function rules = keywordPaddingRules(obj)
            rules = obj.KeywordPaddingRules.values;
            % rules is a cell array of
            % MBeautifier.Configuration.KeyWordPaddingRule objects
            %             rules = [rules{:}];
        end
        
        function names = operatorPaddingRuleNames(obj)
            keys = obj.OperatorPaddingRuleNamesInOrder;
            names = cell(1, numel(keys));
            for i = 1:numel(keys)
                names{i} = obj.operatorPaddingRule(keys{i}).Key;
            end
        end
        
        function characters = operatorCharacters(obj)
            keys = obj.OperatorPaddingRules.keys();
            characters = cell(1, numel(keys));
            for i = 1:numel(keys)
                characters{i} = obj.operatorPaddingRule(keys{i}).ValueFrom;
            end
        end
        
        function updateSpecialRule(obj,name,value)
            name = lower(name);
            
            if obj.SpecialRules.isKey(name)
                remove(obj.SpecialRules, name);
                if isa(value,'MBeautifier.Configuration.SpecialRule')
                    obj.SpecialRules(name) = value;
                else
                    obj.SpecialRules(name) = MBeautifier.Configuration.SpecialRule(name,value);
                end
            else
                
            end
        end
        
        function updateKeywordPaddingRule(obj,name,value)
            name = lower(name);
            
            if obj.KeywordPaddingRules.isKey(name)
                remove(obj.KeywordPaddingRules, name);
                if isa(value,'MBeautifier.Configuration.KeywordPaddingRule')
                    obj.KeywordPaddingRules(name) = value;
                else
                    obj.KeywordPaddingRules(name) = MBeautifier.Configuration.KeywordPaddingRule(name,value);
                end
            else
                
            end
        end
        
        function updateOperatorPaddingRule(obj,name,value)
            name = lower(name);
            
            if obj.OperatorPaddingRules.isKey(name)
                remove(obj.OperatorPaddingRules, name);
                if isa(value,'MBeautifier.Configuration.OperatorPaddingRule')
                    obj.OperatorPaddingRules(name) = value;
                else
                    obj.OperatorPaddingRules(name) = MBeautifier.Configuration.OperatorPaddingRule(name,value);
                end
            else
                
            end
        end
        
        function TF = isequal(obj, objB)
            % Returns true if two Configuration objects have the same values.
            % TF = isequal(obj,objB)
            TF = false;
            if ~isa(objB,class(obj))
                return
            end
            
            if obj.OperatorPaddingRules.Count == objB.OperatorPaddingRules.Count
                opKeys = keys(obj.OperatorPaddingRules);
                for k = 1:obj.OperatorPaddingRules.Count
                    if ~objB.OperatorPaddingRules.isKey(opKeys{k})
                        return
                    end
                    if ~(obj.OperatorPaddingRules(opKeys{k}) == objB.OperatorPaddingRules(opKeys{k}))
                        return
                    end
                end
            else
                return
            end
            
            if obj.KeywordPaddingRules.Count == objB.KeywordPaddingRules.Count
                opKeys = keys(obj.KeywordPaddingRules);
                for k = 1:obj.KeywordPaddingRules.Count
                    if ~objB.KeywordPaddingRules.isKey(opKeys{k})
                        return
                    end
                    if ~(obj.KeywordPaddingRules(opKeys{k}) == objB.KeywordPaddingRules(opKeys{k}))
                        return
                    end
                end
            else
                return
            end
            
            if obj.SpecialRules.Count == objB.SpecialRules.Count
                opKeys = keys(obj.SpecialRules);
                for k = 1:obj.SpecialRules.Count
                    if ~objB.SpecialRules.isKey(opKeys{k})
                        return
                    end
                    if ~(obj.SpecialRules(opKeys{k}) == objB.SpecialRules(opKeys{k}))
                        return
                    end
                end
            else
                return
            end
            
            TF = true;
        end
        
        function toFile(obj,file)
            operatorPaddingNames = obj.operatorPaddingRuleNames;
            keywordPadding = obj.keywordPaddingRules;
            specialRules = obj.specialRules;
            
            docNode = com.mathworks.xml.XMLUtils.createDocument('MBeautifyRuleConfiguration');
            docRootNode = docNode.getDocumentElement;
            
            operatorPaddingNode = docNode.createElement('OperatorPadding');
            for k = 1:numel(operatorPaddingNames)
                thisRule = docNode.createElement('OperatorPaddingRule');
                thisOperatorPaddingRule = obj.operatorPaddingRule(operatorPaddingNames{k});
                key = docNode.createElement('Key');
                key.appendChild(docNode.createTextNode(thisOperatorPaddingRule.Key));
                thisRule.appendChild(key);
                ValueFrom = docNode.createElement('ValueFrom');
                ValueFrom.appendChild(docNode.createTextNode(addXMLEscaping(thisOperatorPaddingRule.ValueFrom)));
                thisRule.appendChild(ValueFrom);
                ValueTo = docNode.createElement('ValueTo');
                ValueTo.appendChild(docNode.createTextNode(addXMLEscaping(thisOperatorPaddingRule.ValueTo)));
                thisRule.appendChild(ValueTo);
                operatorPaddingNode.appendChild(thisRule);
            end
            docRootNode.appendChild(operatorPaddingNode);
            
            keywordPaddingNode = docNode.createElement('KeyworPadding');
            for k = 1:numel(keywordPadding)
                thisRule = docNode.createElement('KeyworPaddingRule');
                thisKeyWordPadding = keywordPadding{k};
                Keyword = docNode.createElement('Keyword');
                Keyword.appendChild(docNode.createTextNode(thisKeyWordPadding.Keyword));
                thisRule.appendChild(Keyword);
                RightPadding = docNode.createElement('RightPadding');
                RightPadding.appendChild(docNode.createTextNode(num2str(thisKeyWordPadding.RightPadding)));
                thisRule.appendChild(RightPadding);
                keywordPaddingNode.appendChild(thisRule);
            end
            docRootNode.appendChild(keywordPaddingNode);
            
            specialRuleNode = docNode.createElement('SpecialRules');
            for k = 1:numel(specialRules)
                thisRule = docNode.createElement('SpecialRule');
                thisSpecialRule = specialRules{k};
                Key = docNode.createElement('Key');
                Key.appendChild(docNode.createTextNode(thisSpecialRule.Key));
                thisRule.appendChild(Key);
                
                Value = docNode.createElement('Value');
                Value.appendChild(docNode.createTextNode(thisSpecialRule.Value));
                thisRule.appendChild(Value);
                specialRuleNode.appendChild(thisRule);
            end
            docRootNode.appendChild(specialRuleNode);
            
            % Save the XML document.
            [folName, filename] = fileparts(file);
            xmlFileName = fullfile(folName,[filename, '.xml']);
            xmlwrite(xmlFileName,docNode);
            
            function nonEscapedValue = addXMLEscaping(value)
                nonEscapedValue = replace(value, '&', '&amp;');
                nonEscapedValue = replace(nonEscapedValue, '<', '&lt;');
                nonEscapedValue = replace(nonEscapedValue, '>', '&gt;');
                nonEscapedValue = replace(nonEscapedValue, '\+', '+');
                nonEscapedValue = replace(nonEscapedValue, '\-', '-');
                nonEscapedValue = replace(nonEscapedValue, '\.', '.');
                nonEscapedValue = replace(nonEscapedValue, '\^', '^');
                nonEscapedValue = replace(nonEscapedValue, '\|', '|');
                nonEscapedValue = replace(nonEscapedValue, '\*', '*');
                nonEscapedValue = replace(nonEscapedValue, '\\', '\');
            end
        end
    end
    
    methods (Static)
        function obj = fromFile(xmlFile)
            obj = MBeautifier.Configuration.Configuration.readSettingsXML(xmlFile);
        end
    end
    
    methods (Static, Access = private)
        function configuration = readSettingsXML(xmlFile)
            XMLDoc = xmlread(xmlFile);
            
            allOperatorItems = XMLDoc.getElementsByTagName('OperatorPaddingRule');
            operatorRules = containers.Map();
            operatorCount = allOperatorItems.getLength();
            operatorPaddingRuleNamesInOrder = cell(1, operatorCount);
            
            for iOperator = 0:operatorCount - 1
                currentOperator = allOperatorItems.item(iOperator);
                key = char(currentOperator.getElementsByTagName('Key').item(0).getTextContent().toString());
                from = removeXMLEscaping(char(currentOperator.getElementsByTagName('ValueFrom').item(0).getTextContent().toString()));
                to = removeXMLEscaping(char(currentOperator.getElementsByTagName('ValueTo').item(0).getTextContent().toString()));
                
                operatorPaddingRuleNamesInOrder{iOperator+1} = lower(key);
                operatorRules(lower(key)) = MBeautifier.Configuration.OperatorPaddingRule(key, from, to);
            end
            
            allSpecialItems = XMLDoc.getElementsByTagName('SpecialRule');
            specialRules = containers.Map();
            
            for iSpecRule = 0:allSpecialItems.getLength() - 1
                currentRule = allSpecialItems.item(iSpecRule);
                key = char(currentRule.getElementsByTagName('Key').item(0).getTextContent().toString());
                value = char(currentRule.getElementsByTagName('Value').item(0).getTextContent().toString());
                
                specialRules(lower(key)) = MBeautifier.Configuration.SpecialRule(key, value);
            end
            
            allKeywordItems = XMLDoc.getElementsByTagName('KeyworPaddingRule');
            keywordRules = containers.Map();
            
            for iKeywordRule = 0:allKeywordItems.getLength() - 1
                currentRule = allKeywordItems.item(iKeywordRule);
                keyword = char(currentRule.getElementsByTagName('Keyword').item(0).getTextContent().toString());
                rightPadding = str2double(char(currentRule.getElementsByTagName('RightPadding').item(0).getTextContent().toString()));
                
                keywordRules(lower(keyword)) = MBeautifier.Configuration.KeywordPaddingRule(keyword, rightPadding);
            end
            
            configuration = MBeautifier.Configuration.Configuration(operatorRules, operatorPaddingRuleNamesInOrder, keywordRules, specialRules);
            
            function escapedValue = removeXMLEscaping(value)
                escapedValue = regexprep(value, '&lt;', '<');
                escapedValue = regexprep(escapedValue, '&amp;', '&');
                escapedValue = regexprep(escapedValue, '&gt;', '>');
            end
        end
    end
end