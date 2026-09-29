pipeline {
    agent any
    // agent {
    //     label 'linux-agent'
    // }
    tools {
        nodejs 'node26'
    }
    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'

        AWS_ACCESS_KEY_ID     = 'test'
        AWS_SECRET_ACCESS_KEY = 'test'
        AWS_DEFAULT_REGION    = 'us-east-1'

        AWS_ENDPOINT_URL    = 'http://localstack:4566'
        AWS_ENDPOINT_URL_S3 = 'http://localstack:4566'
    }

    options {
        // A pipeline should never run unbounded because a hung build
        // can waste agent resources indefinitely.
        timeout(time: 20, unit: 'MINUTES')
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
                    mkdir -p reports

                    echo "Recent commits:"
                    git log --oneline -5

                    docker run --rm \
                        -v "$WORKSPACE:/repo" \
                        ghcr.io/gitleaks/gitleaks:latest \
                        git /repo \
                        --config=/repo/.gitleaks.toml \
                        --report-format json \
                        --report-path /repo/reports/gitleaks.json \
                        --redact \
                        --verbose
                '''
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: 'reports/gitleaks.json',
                        allowEmptyArchive: true
                    )
                }
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

                        def vulnerabilities =
                            audit.metadata?.vulnerabilities ?: [:]

                        int critical = (vulnerabilities.critical ?: 0) as int
                        int high = (vulnerabilities.high ?: 0) as int
                        int moderate = (vulnerabilities.moderate ?: 0) as int
                        int low = (vulnerabilities.low ?: 0) as int

                        echo """
                        npm audit summary:
                        Critical: ${critical}
                        High:     ${high}
                        Moderate: ${moderate}
                        Low:      ${low}
                        """.stripIndent()

                        if (critical > 0) {
                            echo """
                            SCA detected ${critical} critical vulnerabilities.
                            Final enforcement will be handled by the OPA Policy Gate.
                            """.stripIndent()
                        } else if (high > 0 || moderate > 0 || low > 0) {
                            unstable(
                                'SCA warning: vulnerabilities found, but no critical vulnerabilities.'
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

        stage('Resolve Image') {
            steps {
                script {
                    def backendCommit = sh(
                        script: 'git log -1 --format=%H -- backend/',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = backendCommit.take(7)
                    env.IMAGE_NAME = "registry:5000/taskflow-api:${env.IMAGE_TAG}"

                    echo "Current commit : ${env.GIT_COMMIT.take(7)}"
                    echo "Backend commit : ${env.IMAGE_TAG}"
                    echo "Image          : ${env.IMAGE_NAME}"
                }
            }
        }

        stage('Verify Image Exists') {
            steps {
                script {
                    def status = sh(
                        script: """
                            curl -s -o /dev/null \
                            -w "%{http_code}" \
                            -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json' \
                            http://registry:5000/v2/taskflow-api/manifests/${env.IMAGE_TAG}
                        """,
                        returnStdout: true
                    ).trim()

                    if (status == '200') {
                        env.NEED_IMAGE_BUILD = 'false'
                        echo "Image exists: ${env.IMAGE_NAME}"
                    } else if (status == '404') {
                        env.NEED_IMAGE_BUILD = 'true'
                        echo "Image does not exist: ${env.IMAGE_NAME}"
                        echo 'Image will be rebuilt.'
                    } else {
                        error "Unable to check registry. HTTP status: ${status}"
                    }
                }
            }
        }

        stage('Build Image') {
            when {
                anyOf {
                    changeset 'backend/**'

                    expression {
                        env.NEED_IMAGE_BUILD == 'true'
                    }
                }
            }

            steps {
                dir('backend') {
                    script {
                        // def imageTag = env.GIT_COMMIT.take(7)
                        def imageName = env.IMAGE_NAME

                        echo "Building image: ${imageName}"

                        sh """
                            docker build -t ${imageName} .
                            docker push ${imageName}
                        """
                    }
                }
            }
        }

        stage('Container Scan') {
            when {
                anyOf {
                    branch 'main'

                    changeset 'backend/**'

                    expression {
                        env.NEED_IMAGE_BUILD == 'true'
                    }
                }
            }

            steps {
                dir('backend') {
                    script {
                        // def imageTag = env.GIT_COMMIT.take(7)
                        def imageName = env.IMAGE_NAME

                        sh """
                            mkdir -p reports

                            echo "===== Trivy Vulnerability Report ====="

                            docker run --rm \
                            --network host \
                            aquasec/trivy:latest \
                            image \
                            --insecure \
                            --severity HIGH,CRITICAL \
                            --format table \
                            ${imageName}

                            docker run --rm \
                            --network host \
                            -v "\$PWD/reports:/reports" \
                            aquasec/trivy:latest \
                            image \
                            --insecure \
                            --exit-code 1 \
                            --severity HIGH,CRITICAL \
                            --format sarif \
                            --output /reports/trivy-image.sarif \
                            ${imageName}
                        """
                    }
                }
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: 'backend/reports/trivy-image.sarif',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('Generate SBOM') {
            when {
                branch 'main'
            }

            steps {
                dir('backend') {
                    script {
                        // def imageTag = env.GIT_COMMIT.take(7)
                        def imageName = env.IMAGE_NAME

                        sh """
                            mkdir -p reports

                            docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v "\$PWD/reports:/reports" \
                            anchore/syft:latest \
                            docker:${imageName} \
                            -o cyclonedx-json=/reports/taskflow-api.cdx.json
                        """
                    }
                }
            }
        }

        stage('Sign SBOM') {
            when {
                branch 'main'
            }

            steps {
                dir('backend') {
                    withCredentials([
                        file(
                            credentialsId: 'cosign-private-key',
                            variable: 'COSIGN_KEY_FILE'
                        ),
                        string(
                            credentialsId: 'cosign-password',
                            variable: 'COSIGN_PASSWORD'
                        )
                    ]) {
                        sh '''
                            docker rm -f cosign-sbom-sign || true

                            docker create \
                              --name cosign-sbom-sign \
                              --user 0 \
                              -e COSIGN_PASSWORD="$COSIGN_PASSWORD" \
                              ghcr.io/sigstore/cosign/cosign:latest \
                              sign-blob \
                              --yes \
                              --key /tmp/cosign.key \
                              --bundle /tmp/taskflow-api.cdx.sigstore.json \
                              /tmp/taskflow-api.cdx.json

                            docker cp reports/taskflow-api.cdx.json \
                              cosign-sbom-sign:/tmp/taskflow-api.cdx.json

                            docker cp "$COSIGN_KEY_FILE" \
                              cosign-sbom-sign:/tmp/cosign.key

                            docker start -a cosign-sbom-sign

                            docker cp \
                              cosign-sbom-sign:/tmp/taskflow-api.cdx.sigstore.json \
                              reports/taskflow-api.cdx.sigstore.json

                            docker rm cosign-sbom-sign
                        '''
                    }
                }
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: '''
                            backend/reports/taskflow-api.cdx.json,
                            backend/reports/taskflow-api.cdx.sigstore.json
                        ''',
                        allowEmptyArchive: true
                    )

                    sh 'docker rm -f cosign-sbom-sign || true'
                }
            }
        }

        stage('Verify SBOM Signature') {
            when {
                branch 'main'
            }

            steps {
                dir('backend') {
                    withCredentials([
                        file(
                            credentialsId: 'cosign-public-key',
                            variable: 'COSIGN_PUB_FILE'
                        )
                    ]) {
                        sh '''
                            docker rm -f cosign-sbom-verify || true

                            docker create \
                            --name cosign-sbom-verify \
                            --user 0 \
                            ghcr.io/sigstore/cosign/cosign:latest \
                            verify-blob \
                            --key /tmp/cosign.pub \
                            --bundle /tmp/taskflow-api.cdx.sigstore.json \
                            /tmp/taskflow-api.cdx.json

                            docker cp reports/taskflow-api.cdx.json \
                            cosign-sbom-verify:/tmp/taskflow-api.cdx.json

                            docker cp reports/taskflow-api.cdx.sigstore.json \
                            cosign-sbom-verify:/tmp/taskflow-api.cdx.sigstore.json

                            docker cp "$COSIGN_PUB_FILE" \
                            cosign-sbom-verify:/tmp/cosign.pub

                            docker start -a cosign-sbom-verify

                            docker rm cosign-sbom-verify
                        '''
                    }
                }
            }

            post {
                always {
                    sh 'docker rm -f cosign-sbom-verify || true'
                }
            }
        }

        stage('Policy Gate') {
            steps {
                sh '''
                    echo "Policy violations:"

                    docker run --rm \
                    -v "$WORKSPACE:/workspace" \
                    -w /workspace \
                    openpolicyagent/opa:latest \
                    eval \
                    --data policy/security.rego \
                    --input backend/reports/npm-audit.json \
                    --format pretty \
                    'data.security.deny'

                    echo "Evaluating policy gate..."

                    docker run --rm \
                    -v "$WORKSPACE:/workspace" \
                    -w /workspace \
                    openpolicyagent/opa:latest \
                    eval \
                    --fail \
                    --data policy/security.rego \
                    --input backend/reports/npm-audit.json \
                    --format pretty \
                    'data.security.allow'
                '''
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

        stage('IaC Lint & Validate') {
            parallel {
                stage('Terraform Lint & Validate') {
                    steps {
                        sh '''
                    echo "========================================"
                    echo "Terraform Format Check"
                    echo "========================================"
                    terraform -chdir=terraform fmt -check -recursive

                    echo "========================================"
                    echo "Terraform Init"
                    echo "========================================"
                    terraform -chdir=terraform init -backend=false

                    echo "========================================"
                    echo "Terraform Validate"
                    echo "========================================"
                    terraform -chdir=terraform validate
                    '''
                    }
                }

                stage('Ansible Lint') {
                    steps {
                        sh '''
                    echo "========================================"
                    echo "Ansible Lint"
                    echo "========================================"
                    ansible-lint ansible/playbook.yml
                    '''
                    }
                }
            }
        }

        stage('IaC Security Scan') {
            parallel {
                stage('tfsec') {
                    steps {
                        sh '''
                    echo "========================================"
                    echo "Terraform Security Scan - tfsec"
                    echo "========================================"

                    tfsec terraform \
                        --no-color
                '''
                    }
                }

                stage('Checkov') {
                    steps {
                        sh '''
                    echo "========================================"
                    echo "Terraform Security Scan - Checkov"
                    echo "========================================"

                    checkov \
                        --directory terraform \
                        --framework terraform \
                        --skip-check CKV_AWS_135,CKV2_AWS_41
                '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
            echo "========================================"
            echo "Terraform Init"
            echo "========================================"

            terraform -chdir=terraform init -input=false -reconfigure

            echo "========================================"
            echo "Terraform Plan"
            echo "========================================"

            terraform -chdir=terraform plan \
                -input=false \
                -no-color \
                -out=tfplan

            echo "========================================"
            echo "Terraform Plan Summary"
            echo "========================================"

            terraform -chdir=terraform show \
                -no-color \
                tfplan | tee terraform/plan.txt
        '''

                archiveArtifacts artifacts: 'terraform/tfplan,terraform/plan.txt',
                         fingerprint: true
            }
        }

        stage('Approval') {
            steps {
                script {
                    def planSummary = sh(
                script: '''
                    grep -E '^Plan:|^No changes\\.' terraform/plan.txt \
                    | tail -1
                ''',
                returnStdout: true
            ).trim()

                    if (!planSummary) {
                        planSummary = 'Plan generated. Review terraform/plan.txt artifact for full details.'
                    }

                    timeout(time: 30, unit: 'MINUTES') {
                        input(
                    message: """Terraform plan is ready.

${planSummary}

Review terraform/plan.txt before approving.

Apply this exact Terraform plan?""",
                    ok: 'Approve Apply'
                )
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
            echo "========================================"
            echo "Terraform Apply - Approved Plan"
            echo "========================================"

            test -f terraform/tfplan

            terraform -chdir=terraform apply \
                -input=false \
                tfplan
        '''
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
                        script {
                            // def imageTag = env.GIT_COMMIT.take(7)
                            def imageName = env.IMAGE_NAME

                            withEnv(["API_IMAGE=${imageName}"]) {
                                sh '''
                                    docker compose down --remove-orphans || true
                                    docker compose up -d
                                    docker compose ps
                                '''
                            }
                        }

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

                        withEnv(["API_IMAGE=${env.IMAGE_NAME}"]) {
                            sh '''
                                docker compose logs api || true
                                docker compose down --remove-orphans || true
                            '''
                        }
                    }
                }
            }
        }

        stage('Kubernetes Connectivity') {
            when {
                branch 'develop'
            }

            steps {
                sh '''
                    echo "=== Kubernetes context ==="
                    kubectl config current-context

                    echo "=== Kubernetes nodes ==="
                    kubectl get nodes

                    echo "=== Current workloads ==="
                    kubectl get deployments
                    kubectl get svc
                '''
            }
        }

        stage('Deploy — Staging') {
            when {
                branch 'develop'
            }
            environment {
                FORCE_POST_SWITCH_FAILURE = 'false'
            }
            steps {
                script {
                    def currentColor = sh(
                        script: '''
                            kubectl get service taskflow-api \
                            -o jsonpath='{.spec.selector.color}'
                        ''',
                        returnStdout: true
                    ).trim()

                    def nextColor = currentColor == 'blue' ? 'green' : 'blue'

                    // เก็บไว้ให้ post.failure ใช้
                    env.PREVIOUS_COLOR = currentColor
                    env.NEXT_COLOR = nextColor
                    env.SERVICE_SWITCHED = 'false'

                    echo "Current active color : ${currentColor}"
                    echo "Deploying to         : ${nextColor}"
                    echo "Image                : ${env.IMAGE_NAME}"

                    // Deploy inactive color
                    sh """
                        kubectl set image \
                        deployment/taskflow-${nextColor} \
                        taskflow-api=${env.IMAGE_NAME}

                        kubectl rollout status \
                        deployment/taskflow-${nextColor} \
                        --timeout=120s
                    """

                    echo "${nextColor} rollout completed."

                    // Health check inactive deployment
                    sh """
                        kubectl port-forward \
                        deployment/taskflow-${nextColor} \
                        18080:3000 \
                        > /tmp/taskflow-port-forward.log 2>&1 &

                        PF_PID=\$!

                        trap 'kill \$PF_PID 2>/dev/null || true' EXIT

                        sleep 3

                        echo "Checking ${nextColor} health..."

                        curl --fail \
                        --retry 5 \
                        --retry-delay 2 \
                        http://127.0.0.1:18080/health

                        kill \$PF_PID 2>/dev/null || true
                        trap - EXIT
                    """

                    echo "${nextColor} health check passed. Switching traffic..."

                    // Switch Service
                    sh """
                        kubectl patch service taskflow-api \
                        --type merge \
                        -p '{"spec":{"selector":{"app":"taskflow-api","color":"${nextColor}"}}}'
                    """

                    // ตั้งหลัง switch สำเร็จเท่านั้น
                    env.SERVICE_SWITCHED = 'true'
                    sh """
                        echo "Running post-switch smoke test through Service..."

                        kubectl port-forward \
                        service/taskflow-api \
                        18081:3000 \
                        > /tmp/taskflow-service-port-forward.log 2>&1 &

                        PF_PID=\$!
                        trap 'kill \$PF_PID 2>/dev/null || true' EXIT

                        sleep 3

                        curl --fail \
                        --retry 5 \
                        --retry-delay 2 \
                        http://127.0.0.1:18081/health

                        kill \$PF_PID 2>/dev/null || true
                        trap - EXIT
                    """

                    echo 'Post-switch smoke test passed.'

                    if (env.FORCE_POST_SWITCH_FAILURE == 'true') {
                        error 'Injected failure after Service switch for rollback demonstration.'
                    }
                    def activeColor = sh(
                        script: '''
                            kubectl get service taskflow-api \
                            -o jsonpath='{.spec.selector.color}'
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Service now points to: ${activeColor}"

                    if (activeColor != nextColor) {
                        error 'Service switch verification failed.'
                    }
                }
            }

            post {
                failure {
                    script {
                        if (
                            env.SERVICE_SWITCHED == 'true' &&
                            env.PREVIOUS_COLOR?.trim()
                        ) {
                            echo 'Deployment failed after traffic switch.'
                            echo "Rolling Service back to: ${env.PREVIOUS_COLOR}"

                            def rollbackStatus = sh(
                                script: """
                                    kubectl patch service taskflow-api \
                                    --type merge \
                                    -p '{"spec":{"selector":{"app":"taskflow-api","color":"${env.PREVIOUS_COLOR}"}}}'
                                """,
                                returnStatus: true
                            )

                            if (rollbackStatus == 0) {
                                def rollbackColor = sh(
                                script: '''
                                    kubectl get service taskflow-api \
                                    -o jsonpath='{.spec.selector.color}'
                                ''',
                                returnStdout: true
                            ).trim()

                                if (rollbackColor == env.PREVIOUS_COLOR) {
                                    echo "Rollback successful. Service restored to ${rollbackColor}."
                            } else {
                                    echo "WARNING: Rollback command succeeded but Service points to ${rollbackColor}."
                                }
                        } else {
                                echo 'WARNING: Automatic rollback failed.'
                            }
                        } else {
                            echo 'Failure occurred before traffic switch. No Service rollback required.'
                        }
                    }
                }
            }
        }

        stage('Deploy — Production') {
            when {
                beforeInput true
                branch 'main'
            }
            input {
                message 'Deploy to production?'
            }
            steps {
                sh 'echo deploying to production--.'
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

            archiveArtifacts(
                artifacts: 'backend/reports/**',
                allowEmptyArchive: true
            )

            sh '''
                echo "Cleaning dangling Docker images..."
                docker image prune -f || true
            '''
        }
    }
}
