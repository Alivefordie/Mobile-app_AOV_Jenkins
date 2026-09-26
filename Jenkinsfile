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
                    git /repo --redact --verbose
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