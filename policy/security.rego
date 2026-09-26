package security

deny contains msg if {
    input.metadata.vulnerabilities.critical > 0
    msg := sprintf(
        "Build denied: %d CRITICAL vulnerabilities found",
        [input.metadata.vulnerabilities.critical]
    )
}

allow if count(deny) == 0