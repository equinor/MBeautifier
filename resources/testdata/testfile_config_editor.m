defConfig = MBeautify.getConfiguration();
defConfig2 = MBeautify.getConfiguration();
assert(isequal(defConfig,defConfig2),'Failed when comparing default configuration to itself');

conf = MBeautify.getConfiguration('test_MBeautyConfigurationRules.xml');
assert(~eq(conf,defConfig),'conf and defConfig point to the same object');

% Convert cellarray to object array
kwPadRules = [defConfig.keywordPaddingRules{:}];
for k = 1:numel(kwPadRules)
    conf.updateKeywordPaddingRule(kwPadRules(k).Keyword,kwPadRules(k));
end

opPadRules = [defConfig.operatorPaddingRules{:}];
for k = 1:numel(opPadRules)
    conf.updateOperatorPaddingRule(opPadRules(k).Key,opPadRules(k));
end

spRules = [defConfig.specialRules{:}];
for k = 1:numel(spRules)
    conf.updateSpecialRule(spRules(k).Key,spRules(k));
end

assert(~eq(conf,defConfig),'conf and defConfig point to the same object');

assert(isequal(conf,defConfig),'conf and defconfig have different values after transferring values from defconf');

fPath = 'tmpTestConfig.xml';
c = onCleanup(@()delete(fPath));
conf.toFile(fPath);
conf2 = MBeautify.getConfiguration(fPath);
delete(c);

assert(~eq(conf,conf2),'conf and conf2 point to the same object')

assert(isequal(conf,conf2),'conf and conf2 does not have the same values')
% conf.updateKeywordPaddingRule(kwPadRules(1).Keyword,kwPadRules(1));
% assert(conf == conf,'Failed when comparing default configuration to itself with a single');