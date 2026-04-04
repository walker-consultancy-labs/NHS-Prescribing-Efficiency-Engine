@{
    # Only include rules that promote "Clean Code"
    IncludeRules = @(
        'PSAvoidUsingAbbreviatedAliases',
        'PSProvideDefaultParameterValue',
        'PSUseApprovedVerbs'
    )
    # Exclude rules that might be too noisy for a small project
    ExcludeRules = @()
}