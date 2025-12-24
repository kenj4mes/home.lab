# PSScriptAnalyzer Settings for HomeLab
# These are CLI scripts where Write-Host is intentional for colored output

@{
    # Exclude rules that don't apply to CLI scripts
    ExcludeRules = @(
        # Write-Host is intentional for colored console output in CLI scripts
        'PSAvoidUsingWriteHost',
        
        # WMI cmdlets are still valid for Windows compatibility
        'PSAvoidUsingWMICmdlet',
        
        # These scripts are run interactively, not as modules
        'PSUseShouldProcessForStateChangingFunctions',
        
        # Plural nouns are acceptable for collection-returning functions
        'PSUseSingularNouns',
        
        # BOM encoding is not required for cross-platform scripts
        'PSUseBOMForUnicodeEncodedFile'
    )
    
    # Rules to include with specific severity
    Rules = @{
        # Treat unused parameters as info, not warning (they may be for future use)
        PSReviewUnusedParameter = @{
            Enable = $true
            Severity = 'Information'
        }
    }
}
