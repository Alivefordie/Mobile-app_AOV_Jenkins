pipeline {
    // agent any

    agent {
        kubernetes {
            yamlFile 'ci/pods/backend.yaml'
            defaultContainer 'ci'
        }
    }
    // tools {
    //     nodejs 'node26'
    // }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'

        GITOPS_REPO   = 'https://github.com/Alivefordie/test-ci-cd-gitops.git'
        GITOPS_BRANCH = 'main'
        GITOPS_DIR    = 'gitops'

        TASKFLOW_CHART = 'taskflow-chart'

        ARGOCD_NAMESPACE = 'argocd'
    }

    options {
        timeout(time: 60, unit: 'MINUTES')

        parallelsAlwaysFailFast()
    }

    stages {
        stage('Environment') {
            steps {
                script {
                    def isFeatureBranch =
                        env.BRANCH_NAME ==~ /^feature\/.+/

                    def isCapstoneBranch =
                        env.BRANCH_NAME == 'feature/lab10-capstone'

                    def isPullRequest =
                        env.CHANGE_ID?.trim()

                    if (isFeatureBranch && !isPullRequest) {
                        env.CI_MODE = 'FAST'
                    } else {
                        env.CI_MODE = 'FULL'
                    }

                    env.COMMIT_SHA = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()

                    env.COMMIT_MESSAGE = sh(
                        script: 'git log -1 --pretty=%s',
                        returnStdout: true
                    ).trim()

                    // -----------------------------
                    // Deployment environment
                    // -----------------------------
                    if (env.BRANCH_NAME == 'develop') {
                        env.ARGOCD_APP = 'taskflow-staging'
                        env.DEPLOY_NAMESPACE = 'taskflow-staging'
                    }

                    if (env.BRANCH_NAME == 'main') {
                        env.ARGOCD_APP = 'taskflow-production'
                        env.DEPLOY_NAMESPACE = 'taskflow-production'
                    }

                    echo """
                    ========================================
                    Pipeline Environment
                    ========================================
                    APP_NAME         : ${env.APP_NAME}
                    NODE_ENV         : ${env.NODE_ENV}
                    BRANCH_NAME      : ${env.BRANCH_NAME}
                    CHANGE_ID        : ${env.CHANGE_ID ?: '-'}
                    CHANGE_BRANCH    : ${env.CHANGE_BRANCH ?: '-'}
                    CHANGE_TARGET    : ${env.CHANGE_TARGET ?: '-'}
                    CI_MODE          : ${env.CI_MODE}
                    ARGOCD_APP       : ${env.ARGOCD_APP ?: '-'}
                    DEPLOY_NAMESPACE : ${env.DEPLOY_NAMESPACE ?: '-'}
                    COMMIT_SHA       : ${env.COMMIT_SHA}
                    ========================================
                    """.stripIndent()
                }

                sh '''
                    node --version
                    npm --version
                '''
            }
        }

        stage('Kubernetes Dynamic Agent') {
            when {
                expression {
                    env.BRANCH_NAME ==~ /^feature\/.+/ &&
                    !env.CHANGE_ID?.trim()
                }
            }

            steps {
                sh '''
                    echo "===== Kubernetes ====="

                    kubectl version --client
                    helm version

                    echo
                    echo "===== Security ====="

                    gitleaks version
                    semgrep --version
                    opa version
                    trivy --version
                    syft version
                    cosign version

                    echo
                    echo "===== Utilities ====="

                    yq --version
                    git --version
                    curl --version
                '''
            }
        }

        stage('Secrets Detection') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                sh '''
                    mkdir -p reports

                    echo "Recent commits:"
                    git log --oneline -5

                    gitleaks git . \
                        --config=.gitleaks.toml \
                        --report-format json \
                        --report-path reports/gitleaks.json \
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

        stage('Install Dependencies') {
            failFast true

            parallel {
                stage('Backend Install') {
                    steps {
                        dir('backend') {
                            sh 'npm ci'
                        }
                    }
                }

                stage('Mobile Install') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    flutter --version
                                    dart --version
                                    flutter pub get
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Quality & Security Gates') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            failFast true

            parallel {
                // =================================================
                // Lint
                // =================================================

                stage('Lint') {
                    steps {
                        dir('backend') {
                            sh 'npm run lint'
                        }
                    }
                }

                // =================================================
                // Unit Test
                // =================================================

                stage('Unit Test + Coverage') {
                    steps {
                        dir('backend') {
                            sh '''
                                npm test -- \
                                    --coverage \
                                    --reporters=jest-junit
                            '''
                        }
                    }

                    post {
                        always {
                            dir('backend') {
                                junit(
                                    allowEmptyResults: true,
                                    testResults: 'reports/junit.xml'
                                )

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

                // =================================================
                // SAST
                // =================================================

                stage('SAST') {
                    stages {
                        stage('ESLint Security') {
                            steps {
                                dir('backend') {
                                    sh '''
                                        mkdir -p reports

                                        npx eslint \
                                            --plugin security \
                                            src/ \
                                            --rule 'prettier/prettier: off' \
                                            -f @microsoft/eslint-formatter-sarif \
                                            -o reports/eslint.sarif

                                        npx eslint \
                                            --plugin security \
                                            src/ \
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

                        stage('Semgrep') {
                            steps {
                                dir('backend') {
                                    sh '''
                                        mkdir -p reports

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
                    }
                }

                // =================================================
                // SCA
                // =================================================

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

                                def audit =
                                    readJSON file: 'reports/npm-audit.json'

                                def vulnerabilities =
                                    audit.metadata?.vulnerabilities ?: [:]

                                int critical =
                                    (vulnerabilities.critical ?: 0) as int

                                int high =
                                    (vulnerabilities.high ?: 0) as int

                                int moderate =
                                    (vulnerabilities.moderate ?: 0) as int

                                int low =
                                    (vulnerabilities.low ?: 0) as int

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
                                    Final enforcement will be handled by OPA.
                                    """.stripIndent()
                                } else if (
                                    high > 0 ||
                                    moderate > 0 ||
                                    low > 0
                                ) {
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
            }
        }

        stage('Policy Gate') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                sh '''
                    echo "Policy violations:"

                    opa eval \
                        --data policy/security.rego \
                        --input backend/reports/npm-audit.json \
                        --format pretty \
                        'data.security.deny'

                    echo "Evaluating policy gate..."

                    opa eval \
                        --fail \
                        --data policy/security.rego \
                        --input backend/reports/npm-audit.json \
                        --format pretty \
                        'data.security.allow'
                '''
            }
        }

        stage('Mobile Quality & Security') {
            failFast true

            parallel {
                stage('Flutter Analyze') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    echo "========================================"
                                    echo "Flutter Analyze"
                                    echo "========================================"

                                    flutter analyze
                                '''
                            }
                        }
                    }
                }

                stage('Flutter Test + Coverage') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    echo "========================================"
                                    echo "Flutter Test"
                                    echo "========================================"

                                    flutter test \
                                        --coverage
                                '''
                            }
                        }
                    }

                    post {
                        always {
                            archiveArtifacts(
                                artifacts: 'frontend/coverage/**',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }

                stage('Mobile SCA - OSV Scanner') {
                    steps {
                        dir('frontend') {
                            sh '''
                                echo "========================================"
                                echo "OSV Scanner"
                                echo "========================================"

                                mkdir -p reports

                                osv-scanner scan source \
                                    --recursive \
                                    .
                            '''
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

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
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                timeout(
                    time: 5,
                    unit: 'MINUTES'
                ) {
                    waitForQualityGate(
                        abortPipeline: true
                    )
                }
            }
        }

        stage('Resolve Image') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                script {
                    def backendCommit = sh(
                        script: '''
                            git log -1 --format=%H -- backend/
                        ''',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG =
                        backendCommit.take(7)

                    env.IMAGE_NAME =
                        "registry:5000/taskflow-api:${env.IMAGE_TAG}"

                    echo """
                    Current commit : ${env.GIT_COMMIT.take(7)}
                    Backend commit : ${env.IMAGE_TAG}
                    Image          : ${env.IMAGE_NAME}
                    """.stripIndent()
                }
            }
        }

        stage('Verify Image Exists') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                script {
                    def status = sh(
                        script: """
                            curl \
                                -s \
                                -o /dev/null \
                                -w "%{http_code}" \
                                -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json' \
                                http://registry:5000/v2/taskflow-api/manifests/${env.IMAGE_TAG}
                        """,
                        returnStdout: true
                    ).trim()

                    if (status == '200') {
                        env.NEED_IMAGE_BUILD = 'false'

                        echo "Image exists: ${env.IMAGE_NAME}"
                    }
                    else if (status == '404') {
                        env.NEED_IMAGE_BUILD = 'true'

                        echo "Image does not exist: ${env.IMAGE_NAME}"
                        echo 'Image will be rebuilt.'
                    }
                    else {
                        error """
                        Unable to check registry.
                        HTTP status: ${status}
                        """
                    }
                }
            }
        }

        stage('Parallel Builds') {
            failFast true

            parallel {
                // =================================================
                // MOBILE - Debug APK
                // Every branch
                // =================================================

                stage('Mobile - Build Debug APK') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    echo "========================================"
                                    echo "Build Debug APK"
                                    echo "========================================"

                                    flutter build apk \
                                        --debug
                                '''
                            }
                        }
                    }

                    post {
                        success {
                            archiveArtifacts(
                                artifacts: 'frontend/build/app/outputs/flutter-apk/app-debug.apk',
                                fingerprint: true
                            )
                        }
                    }
                }

                // =================================================
                // BACKEND - Docker Image
                // FULL only
                // =================================================

                stage('Backend - Build Image') {
                    when {
                        allOf {
                            expression {
                                env.CI_MODE == 'FULL'
                            }

                            anyOf {
                                changeset 'backend/**'

                                expression {
                                    env.NEED_IMAGE_BUILD == 'true'
                                }
                            }
                        }
                    }

                    steps {
                        dir('backend') {
                            script {
                                echo "Building image: ${env.IMAGE_NAME}"

                                sh '''
                                    docker build \
                                        -t "$IMAGE_NAME" \
                                        .

                                    docker push \
                                        "$IMAGE_NAME"
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Image Verification') {
            failFast true

            parallel {
                stage('Container Scan') {
                    when {
                        expression {
                            env.CI_MODE == 'FULL'
                        }
                    }

                    steps {
                        dir('backend') {
                            sh '''
                                mkdir -p reports

                                echo "========================================"
                                echo "Trivy Cache"
                                echo "========================================"

                                echo "Cache directory: $TRIVY_CACHE_DIR"

                                mkdir -p "$TRIVY_CACHE_DIR"

                                du -sh "$TRIVY_CACHE_DIR" || true

                                echo
                                echo "========================================"
                                echo "Trivy Vulnerability Report"
                                echo "========================================"

                                trivy image \
                                    --cache-backend memory \
                                    --image-src remote \
                                    --insecure \
                                    --severity HIGH,CRITICAL \
                                    --format table \
                                    "$IMAGE_NAME"

                                echo
                                echo "========================================"
                                echo "Generate SARIF"
                                echo "========================================"

                                trivy image \
                                    --cache-backend memory \
                                    --image-src remote \
                                    --insecure \
                                    --exit-code 1 \
                                    --severity HIGH,CRITICAL \
                                    --format sarif \
                                    --output reports/trivy-image.sarif \
                                    "$IMAGE_NAME"

                                echo
                                echo "========================================"
                                echo "Persistent Trivy Cache"
                                echo "========================================"

                                du -sh "$TRIVY_CACHE_DIR" || true
                            '''
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

                stage('E2E') {
                    when {
                        expression {
                            env.CI_MODE == 'FULL'
                        }
                    }

                    steps {
                        dir('backend') {
                            withEnv([
                                "API_IMAGE=${env.IMAGE_NAME}"
                            ]) {
                                sh '''
                                    docker compose down --remove-orphans || true

                                    docker compose up -d

                                    docker compose ps
                                '''
                            }
                        }

                        container('playwright') {
                            dir('backend') {
                                sh '''
                                    npm ci

                                    BASE_URL=http://localhost:3000 \
                                        npx playwright test
                                '''
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

                                publishHTML(
                                    target: [
                                        reportDir: 'playwright-report',
                                        reportFiles: 'index.html',
                                        reportName: 'Playwright HTML Report',
                                        keepAll: true,
                                        alwaysLinkToLastBuild: true,
                                        allowMissing: true
                                    ]
                                )

                                archiveArtifacts(
                                    artifacts: 'playwright-report/**',
                                    allowEmptyArchive: true
                                )

                                script {
                                    if (env.IMAGE_NAME?.trim()) {
                                        withEnv([
                                            "API_IMAGE=${env.IMAGE_NAME}"
                                        ]) {
                                            sh '''
                                                docker compose logs api || true
                                                docker compose down --remove-orphans || true
                                            '''
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                stage('SBOM Pipeline') {
                    when {
                        branch 'main'
                    }

                    stages {
                        stage('Generate SBOM') {
                            when {
                                branch 'main'
                            }

                            steps {
                                dir('backend') {
                                    sh '''
                                    mkdir -p reports

                                    SYFT_REGISTRY_INSECURE_USE_HTTP=true \
                                        syft \
                                        "registry:$IMAGE_NAME" \
                                        -o cyclonedx-json=reports/taskflow-api.cdx.json
                                '''
                                }
                            }
                        }

                        stage('Sign SBOM') {
                            when {
                                branch 'main'
                            }

                            steps {
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
                                    dir('backend') {
                                        sh '''
                                        set +x

                                        mkdir -p reports

                                        cosign sign-blob \
                                            --yes \
                                            --key "$COSIGN_KEY_FILE" \
                                            --bundle reports/taskflow-api.cdx.sigstore.json \
                                            reports/taskflow-api.cdx.json
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
                                }
                            }
                        }

                        stage('Verify SBOM Signature') {
                            when {
                                branch 'main'
                            }

                            steps {
                                withCredentials([
                                file(
                                    credentialsId: 'cosign-public-key',
                                    variable: 'COSIGN_PUB_FILE'
                                )
                            ]) {
                                    dir('backend') {
                                        sh '''
                                        cosign verify-blob \
                                            --key "$COSIGN_PUB_FILE" \
                                            --bundle reports/taskflow-api.cdx.sigstore.json \
                                            reports/taskflow-api.cdx.json
                                    '''
                                    }
                            }
                            }
                        }
                    }
                }
            }
        }

        stage('Unit Test - Fast') {
            when {
                expression {
                    env.CI_MODE == 'FAST'
                }
            }

            steps {
                dir('backend') {
                    echo '''
                    ========================================
                    Fast unit tests
                    Coverage disabled for feature branch.
                    ========================================
                    '''

                    sh 'npm test -- --runInBand'
                }
            }
        }

        stage('Production Approval') {
            when {
                beforeInput true
                branch 'main'
            }

            input {
                message "Deploy ${env.IMAGE_NAME} to production?"
                ok 'Deploy'
            }

            steps {
                echo 'Production deployment approved.'
            }
        }

        stage('Checkout GitOps Repo') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    deleteDir()

                    git(
                        branch: "${GITOPS_BRANCH}",
                        credentialsId: 'github-jenkins',
                        url: "${GITOPS_REPO}"
                    )

                    sh '''
                        echo "GitOps repository:"
                        git remote -v

                        echo "Branch:"
                        git branch --show-current

                        echo "Commit:"
                        git log -1 --oneline
                    '''
                }
            }
        }

        stage('Lint Helm Chart') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    sh '''
                        echo "Lint Taskflow chart..."
                        helm lint "$TASKFLOW_CHART"
                    '''
                }
            }
        }

        stage('Update GitOps Manifest') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    script {
                        if (env.BRANCH_NAME == 'develop') {
                            env.GITOPS_VALUES = "${env.TASKFLOW_CHART}/values-staging.yaml"
                        }

                        if (env.BRANCH_NAME == 'main') {
                            env.GITOPS_VALUES = "${env.TASKFLOW_CHART}/values-production.yaml"
                        }
                    }

                    sh '''
                        echo "Updating:"
                        echo "$GITOPS_VALUES"

                        yq -i \
                        '.image.repository = "registry:5000/taskflow-api" |
                        .image.tag = strenv(IMAGE_TAG)' \
                        "$GITOPS_VALUES"

                        echo "Updated image:"
                        yq '.image' "$GITOPS_VALUES"

                        git diff -- "$GITOPS_VALUES"
                    '''
                }
            }
        }

        stage('Commit GitOps Change') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    script {
                        sh '''
                            git config user.name "jenkins"
                            git config user.email "jenkins@taskflow.local"

                            git add "$GITOPS_VALUES"
                        '''

                        def hasChanges = sh(
                            script: 'git diff --cached --quiet',
                            returnStatus: true
                        )

                        if (hasChanges == 0) {
                            env.GITOPS_CHANGED = 'false'
                            echo 'No GitOps changes.'
                        } else {
                            env.GITOPS_CHANGED = 'true'

                            sh '''
                                git commit \
                                    -m "deploy(${BRANCH_NAME}): taskflow-api ${IMAGE_TAG}"
                            '''

                            env.GITOPS_COMMIT = sh(
                                script: 'git rev-parse HEAD',
                                returnStdout: true
                            ).trim()

                            echo "GitOps commit: ${env.GITOPS_COMMIT}"
                        }
                    }
                }
            }
        }

        stage('Push GitOps change') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression {
                        env.GITOPS_CHANGED == 'true'
                    }
                }
            }

            steps {
                dir("${GITOPS_DIR}") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'github-jenkins',
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_TOKEN'
                        )
                    ]) {
                        sh '''
                            echo "Pushing GitOps commit..."

                            git push \
                              https://$GIT_USERNAME:$GIT_TOKEN@github.com/Alivefordie/test-ci-cd-gitops.git \
                              HEAD:$GITOPS_BRANCH
                        '''
                    }

                    echo "GitOps repo updated with tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Connect to Cluster') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression {
                        env.GITOPS_CHANGED == 'true'
                    }
                }
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'taskflow-kubeconfig',
                        variable: 'KUBE_CONFIG_FILE'
                    )
                ]) {
                    withEnv([
                        'KUBECONFIG=$KUBE_CONFIG_FILE'
                    ]) {
                        sh '''
                            echo "========================================"
                            echo "Kubernetes / Argo CD"
                            echo "========================================"

                            kubectl cluster-info

                            kubectl \
                                -n "$ARGOCD_NAMESPACE" \
                                get application "$ARGOCD_APP"
                        '''
                    }
                }
            }
        }

        stage('Wait for Argo CD') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression {
                        env.GITOPS_CHANGED == 'true'
                    }
                }
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'taskflow-kubeconfig',
                        variable: 'KUBE_CONFIG_FILE'
                    )
                ]) {
                    withEnv([
                        'KUBECONFIG=$KUBE_CONFIG_FILE'
                    ]) {
                        timeout(time: 10, unit: 'MINUTES') {
                            sh '''
                                echo "Waiting for Argo CD: $ARGOCD_APP"

                                while true; do
                                    SYNC=$(kubectl \
                                        -n "$ARGOCD_NAMESPACE" \
                                        get application "$ARGOCD_APP" \
                                        -o jsonpath='{.status.sync.status}')

                                    HEALTH=$(kubectl \
                                        -n "$ARGOCD_NAMESPACE" \
                                        get application "$ARGOCD_APP" \
                                        -o jsonpath='{.status.health.status}')

                                    REVISION=$(kubectl \
                                        -n "$ARGOCD_NAMESPACE" \
                                        get application "$ARGOCD_APP" \
                                        -o jsonpath='{.status.sync.revision}')

                                    echo "sync=$SYNC health=$HEALTH revision=$REVISION"

                                    echo "Expected revision: $GITOPS_COMMIT"
                                    echo "Actual revision  : $REVISION"
                                    echo "sync=$SYNC health=$HEALTH"

                                    if [ "$REVISION" = "$GITOPS_COMMIT" ] &&
                                    [ "$SYNC" = "Synced" ] &&
                                    [ "$HEALTH" = "Healthy" ]; then

                                        echo "Argo CD deployed expected GitOps revision."
                                        break
                                    fi

                                    sleep 5
                                done
                            '''
                        }
                    }
                }
            }
        }

        stage('Verify Deployment') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression {
                        env.GITOPS_CHANGED == 'true'
                    }
                }
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'taskflow-kubeconfig',
                        variable: 'KUBE_CONFIG_FILE'
                    )
                ]) {
                    withEnv([
                        'KUBECONFIG=$KUBE_CONFIG_FILE'
                    ]) {
                        sh '''
                            echo "========================================"
                            echo "Deployment Verification"
                            echo "========================================"

                            kubectl \
                                -n "$DEPLOY_NAMESPACE" \
                                get pods

                            echo

                            kubectl \
                                -n "$DEPLOY_NAMESPACE" \
                                get svc

                            echo

                            kubectl \
                                -n "$DEPLOY_NAMESPACE" \
                                get deployment \
                                -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[*].image
                        '''
                    }
                }
            }
        }

        stage('Smoke Test') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    expression {
                        env.GITOPS_CHANGED == 'true'
                    }
                }
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'taskflow-kubeconfig',
                        variable: 'KUBE_CONFIG_FILE'
                    )
                ]) {
                    withEnv([
                        'KUBECONFIG=$KUBE_CONFIG_FILE'
                    ]) {
                        sh '''
                            kubectl \
                                -n "$DEPLOY_NAMESPACE" \
                                port-forward \
                                service/taskflow-api \
                                18081:3000 \
                                >/tmp/taskflow-port-forward.log 2>&1 &

                            PF_PID=$!

                            trap 'kill $PF_PID 2>/dev/null || true' EXIT

                            sleep 3

                            curl \
                                --fail \
                                --retry 5 \
                                --retry-delay 2 \
                                http://127.0.0.1:18081/health

                            kill "$PF_PID" 2>/dev/null || true
                            trap - EXIT
                        '''
                    }
                }
            }
        }
        stage('Archive Artifacts') {
            steps {
                echo 'Preparing build artifacts...'
            }

            post {
                success {
                    echo """
                    ${env.APP_NAME} Pipeline completed successfully.

                    Branch : ${env.BRANCH_NAME}
                    Mode   : ${env.CI_MODE}
                    Env    : ${env.NODE_ENV}
                    """
                }

                failure {
                    echo """
                    ${env.APP_NAME} Pipeline failed.

                    Branch : ${env.BRANCH_NAME}
                    Mode   : ${env.CI_MODE}
                    Stage  : ${env.STAGE_NAME}
                    """
                }

                always {
                    archiveArtifacts(artifacts: '**/npm-debug.log*', allowEmptyArchive: true)

                    archiveArtifacts(artifacts: 'backend/reports/**', allowEmptyArchive: true)
                }
            }
        }
    }
    post {
        success {
            emailext(
                to: 'the78639@gmail.com',
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                mimeType: 'text/html',
                body: '${JELLY_SCRIPT,template="taskflow-ci"}'
            )
        }

        failure {
            emailext(
                to: 'the78639@gmail.com',
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                mimeType: 'text/html',
                body: '${JELLY_SCRIPT,template="taskflow-ci"}'
            )
        }
    }
}
