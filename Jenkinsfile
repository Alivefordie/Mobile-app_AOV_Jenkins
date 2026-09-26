pipeline {
    agent {
        label 'linux-agent'
    }
    tools {
        nodejs 'node26'
    }
    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'
    }

    options {
        // A pipeline should never run unbounded because a hung build
        // can waste agent resources indefinitely.
        timeout(time: 10, unit: 'MINUTES')
    }

    stages {
        stage('Environment') {
            steps {
                echo "APP_NAME=${APP_NAME}, NODE_ENV=${NODE_ENV}"

                sh '''
                    node --version
                    npm --version
                    docker --version
                    docker compose version
                '''
            }
        }

        stage('Secrets Detection') {
            steps {
                sh '''
                    echo "Recent commits:"
                    git log --oneline -5

                    docker run --rm \
                        -v "$WORKSPACE:/repo" \
                        ghcr.io/gitleaks/gitleaks:latest \
                        git /repo \
                        --config=/repo/.gitleaks.toml \
                        --redact \
                        --verbose
                '''
            }
        }

        stage('Install') {
            steps {
                dir('backend') {
                    sh 'npm ci'
                }
            }
        }

        stage('SAST - ESLint Security') {
            steps {
                dir('backend') {
                    sh '''
                        mkdir -p reports

                        npx eslint --plugin security src/ \
                        --rule 'prettier/prettier: off' \
                        -f @microsoft/eslint-formatter-sarif \
                        -o reports/eslint.sarif

                        npx eslint --plugin security src/ \
                        --rule 'prettier/prettier: off'
                    '''
                }
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: 'backend/reports/eslint.sarif',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('SAST - Semgrep') {
            steps {
                dir('backend') {
                    sh '''
                        mkdir -p reports

                        docker run --rm \
                        -v "$PWD:/src" \
                        -w /src \
                        semgrep/semgrep:latest \
                        semgrep scan \
                        --config=p/owasp-top-ten \
                        --config=p/nodejs \
                        --sarif \
                        --output=reports/semgrep.sarif \
                        .
                    '''
                }
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: 'backend/reports/semgrep.sarif',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('SCA - npm audit') {
            steps {
                dir('backend') {
                    script {
                        sh '''
                            mkdir -p reports

                            npm audit \
                            --audit-level=high \
                            --json \
                            > reports/npm-audit.json || true
                        '''

                        def audit = readJSON file: 'reports/npm-audit.json'

                        def vulnerabilities = audit.metadata?.vulnerabilities ?: [:]

                        int critical = (vulnerabilities.critical ?: 0) as int
                        int high     = (vulnerabilities.high ?: 0) as int
                        int moderate = (vulnerabilities.moderate ?: 0) as int
                        int low      = (vulnerabilities.low ?: 0) as int

                        echo """
                        npm audit summary:
                        Critical: ${critical}
                        High:     ${high}
                        Moderate: ${moderate}
                        Low:      ${low}
                        """.stripIndent()

                        if (critical > 0) {
                            error("SCA gate failed: ${critical} critical vulnerabilities found.")
                        }

                        if (high > 0 || moderate > 0 || low > 0) {
                            unstable(
                                "SCA warning: vulnerabilities found, but no critical vulnerabilities."
                            )
                        } else {
                            echo 'SCA passed: no vulnerabilities found.'
                        }
                    }
                }
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: 'backend/reports/npm-audit.json',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('Generate SBOM') {
            steps {
                dir('backend') {
                    sh '''
                        mkdir -p reports

                        docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v "$PWD/reports:/reports" \
                        anchore/syft:latest \
                        taskflow-api:latest \
                        -o cyclonedx-json=/reports/taskflow-api.cdx.json
                    '''
                }
            }
        }

        stage('Lint') {
            steps {
                dir('backend') {
                    sh 'npm run lint'
                }
            }
        }

        stage('Unit Test') {
            steps {
                dir('backend') {
                    sh 'npm test -- --coverage --reporters=jest-junit'
                }
            }

            post {
                always {
                    dir('backend') {
                        junit 'reports/junit.xml'

                        recordCoverage(
                            tools: [[
                                parser: 'COBERTURA',
                                pattern: 'coverage/cobertura-coverage.xml'
                            ]]
                        )
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            npx @sonar/scan \
                              -Dsonar.projectKey=taskflow-api \
                              -Dsonar.sources=src \
                              -Dsonar.tests=src \
                              -Dsonar.exclusions=**/*.spec.ts \
                              -Dsonar.test.inclusions=**/*.spec.ts \
                              -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('E2E') {
            steps {
                dir('backend') {
                    sh '''
                        docker compose down --remove-orphans || true
                        docker compose up -d --build
                        docker compose ps
                    '''

                    script {
                        docker.image('mcr.microsoft.com/playwright:v1.63.0-noble')
                            .inside('--network backend_default') {

                            sh '''
                                npm ci

                                BASE_URL=http://api:3000 \
                                npx playwright test
                            '''
                        }
                    }
                }
            }

            post {
                always {
                    dir('backend') {
                        junit(
                            allowEmptyResults: true,
                            testResults: 'reports/e2e-junit.xml'
                        )

                        publishHTML(target: [
                            reportDir: 'playwright-report',
                            reportFiles: 'index.html',
                            reportName: 'Playwright HTML Report',
                            keepAll: true,
                            alwaysLinkToLastBuild: true,
                            allowMissing: true
                        ])

                        archiveArtifacts(
                            artifacts: 'playwright-report/**',
                            allowEmptyArchive: true
                        )

                        sh '''
                            docker compose logs api || true
                            docker compose down --remove-orphans || true
                        '''
                    }
                }
            }
        }   
    }

    post {
        success {
            echo "${env.APP_NAME} Pipeline completed successfully on ${env.NODE_ENV} environment."
        }

        failure {
            echo "${env.APP_NAME} Pipeline failed at stage: ${env.STAGE_NAME}."
        }

        always {
            archiveArtifacts(
                artifacts: '**/npm-debug.log*',
                allowEmptyArchive: true
            )
        }
    }
}